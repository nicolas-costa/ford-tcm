# Busca pelos Writers de Duty Commands (PWM Queue)

**Data:** 2026-01-03  
**Status:** EM ANDAMENTO - Writer não localizado  
**Firmware:** 5U75-14C337-AA.bin (MPC555, PPC+VLE)

---

## Objetivo
Encontrar quem **escreve** nos campos `duty_command` (+0x4, u16) das entries da fila PWM, para entender a origem dos comandos de controle dos solenoides.

---

## O Que JÁ Sabemos (FATOS COMPROVADOS)

### 1. Builder PWM @ 0x395B4
**Nome:** `tpu_pwm_queue_build_and_schedule_task3`  
**Tamanho:** 0x11C bytes

**Evidências:**
- @ **0x395B4**: Função recebe `ctx` pointer em `r3`
- @ **0x395E8-0x39610**: Loop processa entries com stride 0x10:
  ```asm
  395e4  lwz   r4, 4(r30)        # Pega ctx->entries
  395e8  lbz   r12, 0(r4)        # Lê channel ID
  39600  addi  r4, r4, 0x10      # Stride 0x10 (próxima entry)
  ```
- @ **0x3968C**: `stw r30, 0x15A8(r13)` ← **PUBLICA ctx** na fila global (SDA base 0x3F8F00)

**Conclusão:** Builder CONSOME ctx já montado, não escreve duty_command.

---

### 2. Apply Function @ 0x21CB8
**Nome:** `tpu_pwm_entry_apply_via_tpu_regs`  
**Tamanho:** 0x2BC bytes

**Evidências:**
- @ **0x21CD4**: `lwz r11, 4(r29)` ← Pega entries pointer
- @ **0x21CD0**: `slwi r26, r28, 4` ← Calcula stride 0x10
- @ **0x21E50**: `lhz r12, 4(r29)` ← **LÊ duty_command** (offset +0x4)!
- @ **0x21E54-0x21E7C**: Multiplica duty por fatores e escreve em TPU regs (+0x8):
  ```asm
  21e54  mullw  r0, r12, r5
  21e58  mulhwu r3, r12, r6
  21e84  sth    r12, 8(r30)      # Escreve no TPU register
  ```

**Conclusão:** Apply LÊ duty_command e converte para registro TPU. Não escreve duty.

---

### 3. Service Function @ 0x394C8
**Nome:** `tpu_pwm_queue_service_15A8`  
**Tamanho:** 0xEC bytes

**Evidências:**
- @ **0x394E0**: `lwz r11, 0x15A8(r13)` ← Pega ctx já publicado
- @ **0x394F0-0x39590**: Loop drena fila, chama:
  - `tpu_channel_update_cfgbit1_or_arm @ 0x38F38`
  - `tpu_channel_update_cfgbit8_or_enable @ 0x38FF0`
  - `tpu_pwm_post_apply_dispatch_and_callbacks @ 0x21ACC`
- @ **0x39598**: `stw r12, 0x15A8(r13)` ← **ZERA fila** após drenar

**Conclusão:** Service DRENA fila já publicada. Não monta ctx.

---

### 4. Task Entry Point @ 0x4A264
**Nome:** `task_service_pwm_queue_and_housekeeping`  
**Tamanho:** 0x24 bytes

**Evidências:**
- @ **0x4A274**: `bl tpu_pwm_queue_service_15A8` ← Chama service

**Conclusão:** Task wrapper que invoca service. Não prepara ctx.

---

### 5. Layout da Entry (stride 0x10)
Baseado em análise prévia (doc 08-tpu-pwm-producers.md):

```c
struct pwm_entry {
    u8  channel_id;     // +0x0
    u8  mode_flags;     // +0x1
    u8  group_mux;      // +0x2
    u8  pad;            // +0x3
    u16 duty_command;   // +0x4 ← ALVO
    u16 pad2;           // +0x6
    u32 callback_ptr;   // +0x8
    u32 callback_data;  // +0xC
};

struct pwm_ctx {
    u32         count;      // +0x0
    pwm_entry*  entries;    // +0x4
    // ...
};
```

---

## O Que NÃO Encontramos

### Tentativas de Busca

1. **XREFs diretos para builder (0x395B4):** Zero matches
   - Confirma dispatch indireto via TaskTable @ 0x3FA400

2. **XREFs diretos para fila (0x3F9FA8 = r13+0x15A8):** Zero matches
   - Acesso via r13+offset (SDA), sem formar endereço absoluto

3. **Pattern `sth rX, 4(rY)` (stores halfword offset 4):**
   - Buscou `B0 ?? 00 04`, `B1 ?? 00 04`: Zero matches
   - Buscou `A0 ?? 00 04`, `A1 ?? 00 04` (loads): Zero matches
   - **Possível causa:** Código VLE (instruções de 16-bit misturadas)

4. **500 instruções `sth` analisadas:**
   - Nenhuma com offset +4 em contexto stride 0x10
   - Exemplos checados: 0x3954 (offset 0x12), 0x3980 (offset 0x10), 0x39B8 (offset 0xE)

5. **Funções "solenoid/epc/tcc":** Nenhuma encontrada
   - Firmware ainda não tem funções renomeadas com semântica de controle

6. **Funções "build/prepare/init" relacionadas:**
   - `task_prepare_output_cycle_from_table_252F4 @ 0x42674` → Escreve em r13+0x23A2 (não relacionado)
   - `tasktable_or_slot_init_from_2A744_and_3FA400 @ 0x31594` → Inicializa task table, não ctx

7. **Offsets próximos a 0x15A8:**
   - r13+0x15AC (5548 decimal): 11 matches, todos em funções que LEEM fila (ex: 0x38F38, 0x39010, 0x39624)
   - r13+0x15B0 (5552 decimal): 9 matches, incluindo dentro do builder (contador temporário)

---

## Hipóteses sobre o Writer

### Hipótese 1: Código VLE (MAIS PROVÁVEL)
**Evidência:**
- Decompiler IDA falhou em 0x395B4: `JUMPOUT(0x395BC)` → Indicador de VLE
- Pattern stores PPC não encontrados, mas apply **comprovadamente** lê duty_command @ 0x21E50
- Região 0x305F58 (referenciada como "apply via mios") não é função válida → VLE

**Implicação:** Writer pode estar em instrução VLE `se_sth` (16-bit) que não é capturada por busca de opcodes PPC.

### Hipótese 2: Montagem na Stack
**Evidência fraca:**
- Builder recebe `r3=ctx` mas não vimos quem prepara r3
- Ctx pode ser alocado localmente por função upstream não identificada

### Hipótese 3: Cópia de Template ROM
**Evidência fraca:**
- Nenhuma função `memcpy`-like encontrada operando em blocos stride 0x10
- Task table @ 0x2A744 tem dados mas não templates de entries

### Hipótese 4: Writer Indireto via Callback
**Especulação pura:**
- Entry tem `callback_ptr` (+0x8) que poderia modificar duty_command antes de apply
- Mas apply lê duty DIRETAMENTE sem chamar callback primeiro

---

## Fluxo Comprovado (Parcial)

```
┌──────────────────────────────────────────────────┐
│ ??? (WRITER NÃO LOCALIZADO)                      │
│ Escreve duty_command em ctx->entries[i]+0x4     │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ Builder @ 0x395B4                                │
│ - Recebe ctx em r3 (já montado)                 │
│ - Loop entries stride 0x10                       │
│ - Publica ctx em r13+0x15A8 @ 0x3968C           │
│ - Posta Task3 no scheduler                      │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ Task @ 0x4A264 → Service @ 0x394C8               │
│ - Drena fila publicada                           │
│ - Chama update_cfgbit1/8 por entry              │
│ - Chama post_apply_dispatch @ 0x21ACC           │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ Apply @ 0x21CB8                                  │
│ - LÊ duty_command @ 0x21E50: lhz r12, 4(r29)    │
│ - Multiplica por fatores (r5/r6 de r13+0x1EE8) │
│ - Escreve em TPU register @ 0x21E84             │
└──────────────────────────────────────────────────┘
```

---

## Próximos Passos (ROI Decrescente)

### Alta Prioridade
1. **Análise VLE Manual:**
   - Disassemblear região 0x305F58 forçando modo VLE
   - Buscar pattern `se_sth` (opcode VLE) em região 0x39xxx-0x3Axxx
   - Verificar se builder @ 0x395B4 tem trecho VLE após 0x395BC

2. **Rastreamento Backward do Builder:**
   - Analisar TaskTable @ 0x3FA400 (RAM, precisa dump dinâmico)
   - Identificar quem registra builder (task ID 3) e passa `r3`
   - Buscar em funções de inicialização (0x17xxx, 0x31xxx)

3. **Instrumentação Dinâmica (REQUER HARDWARE):**
   - Breakpoint em 0x21E50 (apply lê duty)
   - Watchpoint write em r29+4 para capturar writer
   - Dump de ctx completo antes de builder @ 0x395B4

### Média Prioridade
4. **Análise de Funções Upstream:**
   - Buscar callers de funções que acessam r13+0x15AC
   - Analisar funções na região 0x21xxx-0x22xxx (producers PWM)
   - Procurar por loops com `addi rX, rX, 0x10`

5. **Busca por Dados Constantes:**
   - Procurar tabelas ROM com valores 0x0000-0x7FFF (duty range)
   - Analisar tabelas em 0x252F4, 0x2A744 para templates

### Baixa Prioridade
6. **Engenharia Reversa Semântica:**
   - Identificar qual entry (channel ID) corresponde a EPC/TCC/Shift
   - Buscar funções de controle de transmissão (gear logic, pressure control)
   - Isso pode revelar quem calcula duty antes de montar ctx

---

## Resumo Executivo BRUTAL

### O Que Está PROVADO
1. **Apply @ 0x21E50 LÊ duty_command** (offset +0x4, halfword) ← FATO ABSOLUTO
2. **Builder @ 0x395B4 publica ctx** mas NÃO escreve duty ← FATO
3. **Service @ 0x394C8 drena fila** mas NÃO monta ctx ← FATO

### O Que Está QUEBRADO
- **ZERO stores de halfword com offset +4 encontrados** em 500 instruções PPC `sth`
- **ZERO XREFs para fila** (r13+0x15A8) via ferramental IDA
- **Writer de duty_command PERMANECE FANTASMA**

### Por Que Isso É Um Problema
Sem achar o writer, NÃO podemos:
- Mapear qual solenoid recebe qual duty (EPC? TCC? SS1-4?)
- Entender lógica de controle (PID? Lookup table? Algoritmo adaptativo?)
- Modificar comportamentos (ex: aumentar pressão EPC, ajustar TCC slip)

### Próxima Ação de MAIOR ROI
**Análise VLE forçada em 0x305F58 e 0x395BC.**  
Se falhar: **Hardware debug** (BDM/JTAG) com watchpoint em `ctx->entries[0].duty_command`.  
Não há atalho sem evidência direta.

---

## Apêndice: Evidências de Código

### Builder Loop (stride 0x10)
```asm
395e4  lwz   r4, 4(r30)        # r4 = ctx->entries
395e8  lbz   r12, 0(r4)        # r12 = entries[i].channel_id
395ec  cmpwi r12, 0x20
395f0  blt   loc_39600
395f4  lbz   r12, 0x15B0(r13)  # contador temporário
395f8  addi  r12, r12, 1
395fc  stb   r12, 0x15B0(r13)
39600  addi  r4, r4, 0x10      # ← Stride 0x10 (próxima entry)
39604  addi  r31, r31, 1
39608  lbz   r10, 0(r30)       # r10 = ctx->count
3960c  cmplw r10, r31
39610  bgt   loc_395E8         # Loop continua
```

### Apply Lê Duty
```asm
21e50  lhz   r12, 4(r29)       # ← LÊ duty_command (r29 = entry ptr)
21e54  mullw r0, r12, r5       # Multiplica por fator low
21e58  mulhwu r3, r12, r6      # Multiplica por fator high
21e60  mullw r4, r12, r6
...
21e78  cmplwi r28, 0x7FFF      # Clamp duty máximo
21e7c  xori   r1, r28, 0x10
21e80  li     r12, 0x7FFF
21e84  sth    r12, 8(r30)      # Escreve no TPU register (+8)
```

### Service Drena Fila
```asm
394e0  lwz   r11, 0x15A8(r13)  # Pega ctx publicado
394e4  lbz   r11, 0(r11)       # count
394e8  cmpwi r11, 0
394ec  ble   loc_39594         # Se vazio, pula
394f0  lwz   r12, 0x15A8(r13)  # Loop: pega ctx
394f4  lwz   r12, 4(r12)       # entries
394f8  slwi  r11, r30, 4       # stride 0x10
...
39598  stw   r12, 0x15A8(r13)  # ZERA fila após drenar
```

---

**FIM DO DOCUMENTO**


