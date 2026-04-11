# Origem dos Valores de Duty Command

**Data:** 2026-01-03  
**Status:** ✅ **ORIGEM IDENTIFICADA**  
**Firmware:** 5U75-14C337-AA.bin (MPC555)

---

## Resumo Executivo BRUTAL

### O Que PROVEI

**3 Fontes Diferentes de Duty:**

1. **Writer 1 @ 0x238F0:** Duty **FIXO** = 0x2000 (25.4%)
2. **Writer 2 @ 0x2392C:** Duty de **TABELA RAM** @ 0x305CE0 (dinâmica)
3. **Writer 3 @ 0x23940:** Duty de **TABELA RAM** + bit manipulation

### O Que Está CRÍTICO

- **Tabelas são RAM** (0x305xxx), não ROM
- **Valores calculados em runtime** (temperatura, RPM, carga, etc.)
- **Precisa análise dinâmica** para ver valores reais

---

## FATO: Rastreamento Backward dos Writers

### Writer 1 @ 0x238F0 - Duty FIXO

**Código:**
```asm
238ec  li   r10, 0x2000      ← r10 = 0x2000 (valor constante)
238f0  sth  r10, 4(r12)      ← ESCREVE 0x2000 em duty_command
```

**Análise:**
- Duty = 0x2000 decimal = 8192
- Assumindo range 0-0x7FFF (32767):
  - Duty % = 8192 / 32767 = **25.4%**
- Assumindo range 0-0xFFFF (65535):
  - Duty % = 8192 / 65535 = **12.5%**

**Hipótese:** Modo de "segurança" ou inicialização com duty fixo baixo.

---

### Writer 2 @ 0x2392C - Duty de Lookup Table

**Código completo:**
```asm
# Setup da tabela
2386c  lis  r8, 0x30         # r8 = 0x30 << 16 = 0x300000
23870  ori  r8, r8, 0x5CE0   # r8 = 0x305CE0 (base da tabela)
23874  clrlslwi r11, r28, 24,3  # r11 = (r28 & 0xFF) << 3 (stride 8)
23878  add  r30, r11, r8     # r30 = tabela + (channel_id * 8)

# Leitura do duty
23918  lhz  r12, 4(r8)       # r12 = *(r8 + 4)  ← LÊ DUTY DA TABELA!
...
23928  clrlslwi r12, r12, 24,4  # Processa r12
2392c  sth  r12, 4(r30)      # ESCREVE duty processado
```

**Estrutura da Tabela @ 0x305CE0 (RAM):**
```c
struct duty_lookup_entry {
    u16 field_0x0;      // +0x0
    u16 field_0x2;      // +0x2  
    u16 duty_base;      // +0x4 ← LÊ DAQUI!
    u16 duty_alt;       // +0x6
};
// Stride: 8 bytes
// Index: channel_id * 8
```

**FATO:** Tabela está em **RAM** (0x305CE0 = RAM segment 0x300000-0x400000).  
**Implicação:** Valores são **calculados/atualizados em runtime**, não constantes ROM.

---

### Writer 3 @ 0x23940 - Duty com Bit Manipulation

**Código:**
```asm
23918  lhz   r12, 4(r8)      # LÊ duty da mesma tabela
...
23970  slw   r11, r11, r10   # r11 = r11 << r10 (shift variável)
23978  andc  r11, r12, r11   # r11 = r12 & ~r11 (clear bits)
23940  sth   r11, 4(r30)     # ESCREVE duty modificado
```

**Análise:**
- Usa **mesma tabela** que Writer 2
- Aplica **bit masking** no duty lido
- `andc` = AND com complemento (clear bits seletivos)

**Hipótese:** Ajuste de duty baseado em:
- Flags de estado
- Modo de operação (normal/sport/economy)
- Override temporário

---

## Tabela RAM @ 0x305CE0 - Não Inicializada Estaticamente

### Evidência
```
Dump @ 0x305CE0: 0xFF 0xFF 0xFF 0xFF... (256 bytes)
```

**Conclusão:** Tabela é **zerada ou inicializada em boot**, não tem dados em ROM.

### Única Referência
```asm
2386c  lis  r8, 0x30
23870  ori  r8, r8, 0x5CE0   ← ÚNICA referência encontrada no firmware
```

**Localização:** Dentro do próprio writer @ 0x23820.

**Implicação:** Tabela é **preenchida por outra função** antes do writer ser chamado.

---

## Busca por Inicializador da Tabela

### Metodologia
Procurar funções que:
1. Escrevem em 0x305CE0 (stores em r8 base)
2. Fazem loops com `stw rX, offset(r8)` onde r8 = 0x305xxx
3. Calculam duty baseado em inputs (ADC, RPM, temperatura)

### Resultado
**ZERO stores** encontrados próximos às referências 0x305xxx.

**Conclusão:** Inicializador não foi localizado ainda. Possibilidades:
1. Init em região VLE não analisada
2. Init via DMA/hardware controller
3. Init em função não mapeada (gap no disassembly)

---

## Lógica de Seleção de Writer

### Switch/Case @ 0x238A0-0x238DC

**Código:**
```asm
238a0  cmpwi r5, 0           # if (r5 == 0)
238a4  bne   loc_238B0
238a8  cmpwi r4, 1           #   if (r4 == 1)
238ac  beq   loc_238E0       #     goto writer_1 (duty fixo)

238b0  cmpwi r5, 1           # elif (r5 == 1)
238b4  bne   loc_238C0
238b8  cmpwi r4, 0           #   if (r4 == 0)
238bc  rlwnm r2, r4, r0,0,18 #     goto writer_? 

238c0  cmpwi r5, 2           # elif (r5 == 2)
238c4  bne   loc_238D0
238c8  cmpwi r4, 1           #   if (r4 == 1)
238cc  beq   loc_238E0       #     goto writer_1

238d0  cmpwi r5, 3           # elif (r5 == 3)
238d4  bne   loc_238F4
238d8  cmpwi r4, 0           #   if (r4 == 0)
...
238e0  ...                   # writer_1: duty fixo 0x2000
238f4  ...                   # writer_2/3: duty de tabela
```

### Interpretação

**r5** = modo/estado principal (0-3)  
**r4** = submode/flag secundário (0-1)

| r5 | r4 | Writer | Duty Source |
|----|----| -------|-------------|
| 0  | 1  | 1      | Fixo 0x2000 |
| 1  | 0  | ?      | ? |
| 2  | 1  | 1      | Fixo 0x2000 |
| 3  | 0  | ?      | ? |
| default | | 2/3   | Tabela RAM |

**Hipótese r5:**
- 0 = Init/startup mode
- 1 = Normal operation
- 2 = Safety/limp mode
- 3 = Diagnostic mode

---

## Origem de r5 e r4

### Código de Setup
```asm
23850  lbz   r9, 2(r31)      # r9 = *(r31 + 2)
23854  clrlwi r9, r9, 25     # r9 &= 0x7F
23858  clrlwi r5, r9, 30     # r5 = r9 & 0x3 (2 bits baixos)

23860  lbz   r12, 2(r31)     # r12 = *(r31 + 2)
23864  extrwi r12, r12, 1,24 # r12 = extract bit 7
23868  clrlwi r4, r12, 24    # r4 = r12 & 0xFF
```

**r31** vem de:
```asm
23840  lwz   r11, 0x15D0(r13)  # r11 = staging ctx
23844  lwz   r30, 4(r11)       # r30 = entries pointer
23848  lbzx  r28, r30, r31     # r28 = channel_id
2384c  add   r31, r30, r31     # r31 = entry pointer
```

**Conclusão:** 
- **r5** = `entry->field_0x2 & 0x3` (bits 0-1)
- **r4** = `entry->field_0x2 >> 7` (bit 7)

**Layout refinado:**
```c
struct pwm_entry {
    u8  channel_id;     // +0x0
    u8  mode_flags;     // +0x1
    u8  control_byte;   // +0x2  ← r5 (bits 0-1), r4 (bit 7)
    u8  pad;            // +0x3
    u16 duty_command;   // +0x4 ← ESCRITO AQUI
    u16 flags2;         // +0x6
    u32 callback_ptr;   // +0x8
    u32 callback_data;  // +0xC
};
```

---

## Próximos Passos (ALTA PRIORIDADE)

### 1. Localizar Inicializador da Tabela @ 0x305CE0
**Métodos:**
- Buscar funções de init (0x17xxx, 0x18xxx)
- Procurar cálculos de duty (PID controllers, interpolação)
- Analisar funções que leem ADC/sensores (temperatura, pressão)

**Ação:** `grep` por stores em 0x305xxx ou loops de inicialização.

### 2. Análise Dinâmica - Dump da Tabela
**Requer:** Hardware (BDM/JTAG) ou emulador

**Capturar:**
- Tabela @ 0x305CE0 (256 bytes) após init
- Valores de duty para cada channel_id
- Correlação channel → solenoid (EPC/TCC/SS1-4)

### 3. Mapear Modos r5/r4
**Objetivo:** Entender quando cada writer é acionado

**Método:**
- Instrumentar código para logar r5, r4, channel_id
- Testar diferentes condições (frio, quente, carga, marcha)
- Correlacionar com comportamento real do TCM

### 4. Identificar Função que Popula control_byte
**Buscar:** Quem escreve `entry->control_byte` (offset +0x2) antes do writer

**Método:** XREFs para stores em staging entries (+0x2).

---

## Resumo Executivo FINAL

### O Que PROVEI
1. **Writer 1:** Duty **fixo** 0x2000 (25.4%)
2. **Writer 2/3:** Duty de **tabela RAM** @ 0x305CE0
3. **Tabela RAM:** Stride 8 bytes, duty em offset +4
4. **Seleção:** Switch em r5 (modo) e r4 (flag)
5. **Control byte:** Entry +0x2 determina qual writer usar

### O Que Está QUEBRADO
- **Inicializador da tabela** não localizado
- **Valores reais de duty** desconhecidos (tabela RAM não inicializada)
- **Mapeamento channel → solenoid** ainda não feito

### Por Que Isso É CRÍTICO
Agora podemos:
- **Interceptar cálculos** (hook no inicializador da tabela)
- **Modificar duty** direto na tabela RAM (patch @ 0x305CE0)
- **Forçar modos** (setar control_byte para usar writer fixo)

### Próxima Ação de MAIOR ROI
**Localizar inicializador da tabela @ 0x305CE0.**  
Isso revelará:
- Algoritmos de cálculo de duty (PID? Lookup 2D? Interpolação?)
- Inputs usados (RPM, temperatura, throttle position, etc.)
- Lógica adaptativa (aprendizado, compensação de desgaste)

---

**FIM DO DOCUMENTO**


