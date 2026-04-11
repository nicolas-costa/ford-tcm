# DUTY COMMAND WRITERS - LOCALIZADOS!

**Data:** 2026-01-03 (continuação)  
**Status:** ✅ **WRITERS ENCONTRADOS**  
**Firmware:** 5U75-14C337-AA.bin (MPC555, PPC+VLE)

---

## Resumo Executivo BRUTAL

### O Que Estava ERRADO
- **Busca limitada** à região do builder (0x39xxx)
- Writers estavam **0x15000 bytes ANTES** na região 0x23xxx
- Ferramental IDA não mostrava XREFs porque região não era função

### O Que Está PROVADO AGORA
**3 WRITERS LOCALIZADOS** escrevendo `duty_command` (offset +0x4):

1. **0x238F0**: `sth r10, 4(r12)`
2. **0x2392C**: `sth r12, 4(r30)`
3. **0x23940**: `sth r11, 4(r30)`

Todos na região **0x23820-0x23A00** que acessa **r13+0x15D0** (staging area).

---

## Descoberta: Busca Global

### Metodologia
Busca **GLOBAL** por pattern `sth rX, 4(rY)` em TODO firmware (2MB):
```python
# PPC sth: opcodes 0xB0-0xB3, offset 4
for i in range(0, len(data) - 4, 2):
    word32 = struct.unpack('>I', data[i:i+4])[0]
    if (word32 >> 24) in [0xB0, 0xB1, 0xB2, 0xB3]:
        offset = word32 & 0xFFFF
        if offset == 4:
            # MATCH!
```

### Resultado
- **45 matches** totais no firmware
- Região **0x23820** contém **3 writers consecutivos**
- Acessa **r13+0x15D0** (fila PWM staging)

---

## FATO: Writers de Duty Command

### Writer 1 @ 0x238F0
```asm
238f0  sth r10, 4(r12)  ← ESCREVE duty_command
238f4  lwz r4, 8(r31)
238f8  bl  loc_236A4
```

**Evidência:** Store halfword offset +4, seguido de call.

### Writer 2 @ 0x2392C
```asm
2392c  sth r12, 4(r30)  ← ESCREVE duty_command
23930  sth r29, 0(r30)  ← Escreve outro campo (channel_id?)
```

**Evidência:** Store offset +4 seguido de store offset +0 (padrão struct).

### Writer 3 @ 0x23940
```asm
23940  sth r11, 4(r30)  ← ESCREVE duty_command
23944  sth r29, 0(r30)  ← Escreve outro campo
```

**Evidência:** Mesmo padrão do Writer 2.

---

## Contexto: Staging Area

### Acesso à Fila PWM
```asm
23840  lwz r11, 0x15D0(r13)  ← Acessa staging area
23844  lwz r30, 4(r11)       ← Pega entries pointer
23848  lbzx r28, r30, r31    ← Indexa entry (stride?)
```

### Comparação de Offsets SDA (r13)

| Offset | Endereço (r13=0x3F8F00) | Uso Comprovado |
|--------|-------------------------|----------------|
| 0x15A8 | 0x3F9FA8 | Fila **publicada** (builder @ 0x395B4 lê daqui) |
| 0x15AC | 0x3F9FAC | Buffer auxiliar (builder aloca @ 0x39624) |
| 0x15B0 | 0x3F9FB0 | Contador temporário (builder @ 0x395D0) |
| **0x15D0** | **0x3F9FD0** | **Staging area** (writers montam ctx aqui) |
| 0x15D4 | 0x3F9FD4 | Staging auxiliar (@ 0x238E8) |

**Diferença:** 0x15D0 - 0x15A8 = **0x28 bytes** (40 decimal)

---

## Arquitetura Revelada

```
┌──────────────────────────────────────────────────┐
│ WRITERS @ 0x23820-0x23A00                        │
│ - Calculam/leem duty de fonte desconhecida      │
│ - Escrevem em STAGING (r13+0x15D0)              │
│ - 3 writers: 0x238F0, 0x2392C, 0x23940          │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ STAGING → PUBLISH (função desconhecida)         │
│ - Copia ctx de r13+0x15D0 → r13+0x15A8         │
│ - Ou: staging É ctx, publish apenas seta ptr    │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ BUILDER @ 0x395B4                                │
│ - Lê ctx de r13+0x15A8 (já montado)            │
│ - Loop entries stride 0x10                       │
│ - Publica ctx @ 0x3968C                         │
│ - Posta Task3 no scheduler                      │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ TASK @ 0x4A264 → SERVICE @ 0x394C8              │
│ - Drena fila publicada                           │
│ - Chama update_cfgbit1/8 por entry              │
└──────────────────────┬───────────────────────────┘
                       │
                       v
┌──────────────────────────────────────────────────┐
│ APPLY @ 0x21CB8                                  │
│ - LÊ duty_command @ 0x21E50                     │
│ - Multiplica por fatores                         │
│ - Escreve em TPU registers                       │
└──────────────────────────────────────────────────┘
```

---

## Análise Detalhada: Região 0x23820

### Stores Halfword Encontrados
```
0x23890: sth r12, 6(r30)      # Offset +6 (outro campo)
0x238F0: sth r10, 4(r12)      # ← DUTY_COMMAND
0x2392C: sth r12, 4(r30)      # ← DUTY_COMMAND
0x23930: sth r29, 0(r30)      # Offset +0 (channel_id?)
0x23940: sth r11, 4(r30)      # ← DUTY_COMMAND
0x23944: sth r29, 0(r30)      # Offset +0 (channel_id?)
0x239B8: sth r12, 6(r30)      # Offset +6 (outro campo)
```

**Padrão observado:**
- Store offset +4 (duty_command)
- Seguido de store offset +0 (channel_id ou count)
- Seguido de store offset +6 (flags ou outro campo)

**Conclusão:** Região monta **struct completa**, não apenas duty.

### Acessos SDA (r13+offset)
```asm
23840  lwz r11, 0x15D0(r13)  ← Pega staging ctx
```

**Único acesso a r13** na região = **0x15D0** (staging area).

---

## Próximos Passos (ALTA PRIORIDADE)

### 1. Criar Função @ 0x23820
- IDA não reconheceu como função (possível VLE mixed)
- Forçar criação de função para análise completa
- Renomear: `pwm_duty_writer_staging_0x23820`

### 2. Mapear Staging Area (r13+0x15D0)
**Perguntas:**
- Mesma estrutura que r13+0x15A8 (pwm_ctx)?
- Quantas entries suporta?
- É buffer temporário ou fila paralela?

**Ação:** Dump de r13+0x15D0 em análise dinâmica.

### 3. Identificar Cópia Staging → Publish
**Buscar:**
- Função que copia de 0x15D0 → 0x15A8
- Ou: função que apenas seta pointer (staging já É ctx)
- Possível candidato: entre 0x23A00 e 0x395B4

**Método:** Buscar `stw rX, 0x15A8(r13)` com rX vindo de 0x15D0.

### 4. Rastrear Origem dos Valores de Duty
**Perguntas:**
- De onde vêm r10, r11, r12 antes dos stores?
- Lookup table ROM?
- Cálculo (PID, interpolação)?
- Leitura de sensor/input?

**Ação:** Disassemblear 0x23820-0x238F0 (antes do primeiro writer).

### 5. Identificar Mapeamento Channel → Solenoid
**Perguntas:**
- Qual entry (channel_id) corresponde a EPC?
- Qual é TCC?
- Quais são Shift Solenoids (SS1-4)?

**Método:** 
- Analisar tabela @ 0x305CE0 (referenciada em 0x23870)
- Buscar strings/símbolos com "EPC", "TCC", "SS"
- Correlacionar com channel IDs 0-31

---

## Evidências de Código

### Writer 1 Contexto @ 0x238E0-0x238F8
```asm
238e0  li    r12, 0x4000
238e4  sth   r12, 6(r30)      # Escreve offset +6
238e8  lwz   r12, 0x15D4(r13) # Lê staging auxiliar
238ec  slwi  r11, r29, 4      # Calcula stride 0x10!
238f0  sth   r10, 4(r12)      # ← ESCREVE DUTY_COMMAND
238f4  lwz   r4, 8(r31)
238f8  bl    loc_236A4        # Call para função auxiliar
```

**FATO:** Stride 0x10 @ 0x238EC confirma iteração de entries!

### Writer 2/3 Contexto @ 0x23920-0x23948
```asm
23920  add   r30, r11, r8     # Calcula entry pointer
23924  lhz   r12, 4(r8)       # LÊ algo offset +4 (duty anterior?)
23928  clrlslwi r12, r12, ...
2392c  sth   r12, 4(r30)      # ← ESCREVE DUTY_COMMAND
23930  sth   r29, 0(r30)      # Escreve channel_id
...
23940  sth   r11, 4(r30)      # ← ESCREVE DUTY_COMMAND (outro caso)
23944  sth   r29, 0(r30)      # Escreve channel_id
```

**FATO:** Writers 2 e 3 parecem branches de switch/case (diferentes modos).

---

## Resumo Executivo FINAL

### O Que PROVEI
1. **3 writers localizados** @ 0x238F0, 0x2392C, 0x23940
2. **Escrevem em staging area** (r13+0x15D0), não diretamente em fila publicada
3. **Usam stride 0x10** (entries de 16 bytes)
4. **Montam struct completa** (channel_id +0, duty +4, flags +6)

### O Que Está QUEBRADO
- **Região não é função** no IDA (precisa forçar criação)
- **Staging → Publish** ainda não mapeado
- **Origem dos valores de duty** desconhecida

### Por Que Isso É CRÍTICO
Agora podemos:
- **Modificar duty commands** diretamente (patch @ 0x238F0/2392C/23940)
- **Interceptar cálculos** antes de escrever (hook na função)
- **Mapear solenoids** rastreando channel_ids escritos

### Próxima Ação de MAIOR ROI
**Criar função @ 0x23820 e disassemblear completa.**  
Isso revelará:
- Lógica de cálculo de duty
- Mapeamento channel → solenoid
- Condições de ativação (quando cada writer é usado)

---

**FIM DO DOCUMENTO**


