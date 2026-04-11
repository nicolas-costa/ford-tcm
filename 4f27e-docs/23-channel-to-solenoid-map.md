# 23 — Mapeamento Channel_ID → Solenóide Físico (TPU Hardware)

**Data:** 2026-03-22  
**Status:** ✅ Tabela ROM @ 0x252F4 decodificada. 7 canais mapeados para pinos TPU. ON/OFF vs PWM diferenciados por calibração.  
**Dependência:** Cadeia boot→solenoid (doc 22), tabela 0x2A540 (doc 21)

---

## Resumo Executivo

1. **FATO:** A ROM table @ 0x252F4 contém 7 entries de 4 bytes cada, mapeando `{hw_channel, io_index, flags, ordinal}`. 6 canais físicos (0x30-0x35) usam TPU_A ch12-15 e TPU_B ch0-1. O 7º (0x36) é virtual (flags=0x05, io compartilhado).
2. **FATO:** Calibração @ 0x18A2A8 + 0x18A1DE classifica: **4 solenóides ON/OFF** (SSA-SSD, period=0) + **1 PWM ~100Hz** (EPC) + **1 PWM ~33Hz** (SSE proporcional). Total: **6 solenóides físicos** conforme 4F27E.
3. **FATO:** A cadeia de output é: `solenoid_output_group_update_cycle` → `solenoid_outputs_prepare_cycle` → `solenoid_outputs_update_7ch` → `io_set_float_by_id_and_dispatch_15D0` → `tpu_pwm_entry_apply_via_tpu_regs` → registros TPU em 0x304100+ch*16.
4. **Próximo passo:** Task 5 — QEMU harness para validar os duty cycles em runtime e observar a lógica de shift (gear selection → solenoid pattern).

---

## 1. ROM Mapping Table @ 0x252F4

### Header @ 0x252F0

```
0x252F0: 0B 01 00 00
  byte[0] = 0x0B (11) → total IO channel count (incl. non-solenoid)
  byte[1] = 0x01       → first solenoid io_index
```

### 7 Entries (4 bytes each, @ 0x252F4..0x2530F)

| Idx | Slot ID | hw_ch | io_idx | flags | ord | TPU Unit   | TPU Channel | Reg Base         |
|-----|---------|-------|--------|-------|-----|-----------|-------------|------------------|
| 0   | 0x30    | 0x0D  | 3      | 0x00  | 1   | TPU_A     | ch13        | 0x304000+0x1D0   |
| 1   | 0x31    | 0x0C  | 2      | 0x00  | 2   | TPU_A     | ch12        | 0x304000+0x1C0   |
| 2   | 0x32    | 0x0E  | 4      | 0x00  | 3   | TPU_A     | ch14        | 0x304000+0x1E0   |
| 3   | 0x33    | 0x0F  | 5      | 0x00  | 4   | TPU_A     | ch15        | 0x304000+0x1F0   |
| 4   | 0x34    | 0x11  | 7      | 0x00  | 5   | TPU_B     | ch1         | 0x304400+0x110   |
| 5   | 0x35    | 0x10  | 6      | 0x00  | 6   | TPU_B     | ch0         | 0x304400+0x100   |
| 6   | 0x36    | 0x03  | 4      | 0x05  | 6   | TPU_A     | ch3         | 0x304000+0x130   |

**Cálculo do endereço de registros TPU:**
`reg_addr = tpu_base + 0x100 + channel * 16`
- TPU_A base = 0x304000
- TPU_B base = 0x304400
- Função: `tpu_channel_regs_ptr_from_id` @ 0x33BAC

**Nota sobre Entry 6 (0x36):** Flags=0x05 (único não-zero), io_index=4 (compartilhado com entry 2). Provável canal virtual, de diagnóstico, ou fallback — NÃO um solenóide físico independente.

---

## 2. Calibração: ON/OFF vs PWM

### Period Table @ 0x18A2A8 (indexada por ordinal)

| Ordinal | Raw (u16 BE) | Period (×10) | Frequência Estimada |
|---------|-------------|-------------|---------------------|
| 0       | 0x0000      | 0           | (unused)            |
| 1       | 0x0000      | 0           | **ON/OFF** (sem PWM)|
| 2       | 0x0000      | 0           | **ON/OFF**          |
| 3       | 0x0000      | 0           | **ON/OFF**          |
| 4       | 0x0000      | 0           | **ON/OFF**          |
| 5       | 0x000A      | 100         | **~100 Hz** (PWM)   |
| 6       | 0x001E      | 300         | **~33 Hz** (PWM)    |

### Config Table @ 0x18A1DE (stride 2, por loop index)

| Loop Idx | Slot ID | Config Value | Interpretação |
|----------|---------|-------------|---------------|
| 0        | 0x30    | 0x0004      | Mode A        |
| 1        | 0x31    | 0x0002      | Mode B (diferente!) |
| 2        | 0x32    | 0x0004      | Mode A        |
| 3        | 0x33    | 0x0004      | Mode A        |
| 4        | 0x34    | 0x0004      | Mode A        |
| 5        | 0x35    | 0x0000      | Mode C (PWM)  |
| 6        | 0x36    | 0x0000      | Mode C (PWM)  |

**Observação:** 0x31 tem config=0x0002, diferente de todos os outros ON/OFF (0x0004). Pode indicar um tipo de acionamento diferente (ex.: polaridade invertida, open-drain vs push-pull).

---

## 3. Classificação dos 7 Canais

### Grupo 1: ON/OFF (4 canais, period=0)

| Slot ID | TPU Channel | Config | Candidato Físico |
|---------|------------|--------|------------------|
| 0x30    | TPU_A ch13 | 0x04   | Shift Solenoid A |
| 0x31    | TPU_A ch12 | 0x02   | Shift Solenoid B (config diferente!) |
| 0x32    | TPU_A ch14 | 0x04   | Shift Solenoid C |
| 0x33    | TPU_A ch15 | 0x04   | Shift Solenoid D |

### Grupo 2: PWM (2 canais, period≠0)

| Slot ID | TPU Channel | Period | Freq | Candidato Físico |
|---------|------------|--------|------|------------------|
| 0x34    | TPU_B ch1  | 100    | ~100Hz | **EPC** (Electronic Pressure Control) |
| 0x35    | TPU_B ch0  | 300    | ~33Hz  | **TCC** (Torque Converter Clutch) |

### Grupo 3: Especial (1 canal)

| Slot ID | TPU Channel | Flags | Nota |
|---------|------------|-------|------|
| 0x36    | TPU_A ch3  | 0x05  | io_index compartilhado com 0x32. Provável virtual/diag. |

### Mapeamento: 6 Solenóides Físicos (EPC + SSA-SSE)

A 4F27E possui **6 solenóides**: EPC, SSA, SSB, SSC, SSD, SSE.

| Slot ID | TPU Channel | Tipo | Period | **Solenóide** | Evidência |
|---------|------------|------|--------|---------------|-----------|
| 0x30 | TPU_A ch13 | ON/OFF | 0 | **SSA** (Shift Solenoid A) | ON/OFF, config=0x04 |
| 0x31 | TPU_A ch12 | ON/OFF | 0 | **SSB** (Shift Solenoid B) | ON/OFF, config=0x02 (driver diferente) |
| 0x32 | TPU_A ch14 | ON/OFF | 0 | **SSC** (Shift Solenoid C) | ON/OFF, config=0x04 |
| 0x33 | TPU_A ch15 | ON/OFF | 0 | **SSD** (Shift Solenoid D) | ON/OFF, config=0x04 |
| 0x34 | TPU_B ch1  | PWM   | 100 (~100Hz) | **EPC** (Electronic Pressure Control) | Único PWM alta freq, controle de pressão de linha |
| 0x35 | TPU_B ch0  | PWM   | 300 (~33Hz) | **SSE** (Shift Solenoid E) | PWM baixa freq, solenóide proporcional |

**Canal 0x36** (TPU_A ch3, flags=0x05, io_index compartilhado com SSC): canal virtual/diagnóstico, NÃO solenóide físico.

**Notas:**
- SSB (0x31) tem config=0x02 vs 0x04 para os demais ON/OFF. Pode indicar polaridade invertida ou driver de potência diferente no circuito.
- SSE (0x35) opera como solenóide proporcional via PWM (~33Hz), não ON/OFF como SSA-SSD.
- EPC (0x34) tem a maior frequência PWM (~100Hz), consistente com controle fino de pressão de linha.

---

## 4. Cadeia de Execução: Output Update Cycle

```
solenoid_output_group_update_cycle @ 0x4A60C
  │
  ├─► solenoid_outputs_prepare_cycle_from_252F4 @ 0x42674
  │     Itera 252F4 table: lê hw_channel (byte[0])
  │     Chama loc_35CD0 para cada entry
  │     Escreve resultados em r13+0x23A2 (array de words)
  │
  ├─► solenoid_outputs_update_7ch_from_252F5 @ 0x42584
  │     Loop 7x (r30=0..6):
  │       io_id = 252F5_table[r30*4] (byte[1] of entry)
  │       runtime = r13+0x17C4 + r30*0x14 (20 bytes per output)
  │       IF runtime.status.bit0:
  │         value = computed duty cycle
  │       ELSE:
  │         value = 0 (off)
  │       ├─► io_set_float_by_id_and_dispatch_15D0(io_id, value)
  │       │     Reads hw_channel from *(r13+0x15D0)+4 entry[io_id*16]
  │       │     IF hw_channel < 0x64:
  │       │       ├─► tpu_pwm_entry_apply_via_tpu_regs
  │       │       │     ├─► tpu_channel_regs_ptr_from_id(hw_channel)
  │       │       │     │     Returns 0x304x00 + 0x100 + ch*16
  │       │       │     └─► Writes duty cycle to TPU channel registers
  │       │     ELIF hw_channel >= 0x64:
  │       │       └─► tpu_pwm_entry_apply_via_mios (MIOS registers @ 0x305F58)
  │
  └─► task_update_output_cycle_snapshot @ 0x41050
        Snapshots state for next cycle
```

---

## 5. Funções Renomeadas no IDA

| EA | Nome Anterior | Nome Atual |
|----|-------------|------------|
| 0x0421C4 | sub_421C4 | `solenoid_outputs_init_7ch_from_252F4` |
| 0x042584 | task_update_outputs_from_id_table_252F5 | `solenoid_outputs_update_7ch_from_252F5` |
| 0x042674 | task_prepare_output_cycle_from_table_252F4 | `solenoid_outputs_prepare_cycle_from_252F4` |
| 0x04A60C | task_group_output_update_cycle | `solenoid_output_group_update_cycle` |
| 0x021BC4 | tpu_pwm_entry_apply_via_mios_305f58 | `tpu_pwm_entry_apply_via_mios` |

---

## 6. Registros TPU MPC555 Usados

### Endereços Base
- TPU_A: 0x304000
- TPU_B: 0x304400
- MIOS: 0x305000+

### Registros por Canal (offset 0x100 + ch*16)
| Offset | Registro | Largura | Uso |
|--------|----------|---------|-----|
| +0x00  | CFSR     | 16-bit  | Channel Function Select |
| +0x02  | HSQR     | 16-bit  | Host Sequence |
| +0x04  | HSRR     | 16-bit  | Host Service Request |
| +0x06  | CPR      | 16-bit  | Channel Priority |
| +0x08  | CISR     | 16-bit  | Channel Interrupt Status |
| +0x0A  | LR       | 16-bit  | Link Register |
| +0x0C  | SGLR     | 16-bit  | Service Grant Latch |
| +0x0E  | DCR      | 16-bit  | Decoded Channel |

### Canais Alocados para Solenóides

```
TPU_A: [.] [.] [.] [36?] [.] [.] [.] [.] [.] [.] [.] [30h] [31] [30] [32] [33]
         0   1   2    3    4   5   6   7   8   9  10   11   12   13   14   15

TPU_B: [35] [34] [.] [.] [.] [.] [.] [.] [.] [.] [.] [.] [.] [.] [.] [.]
         0    1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
```

Note: `30h` = header/entry-1 (hw_ch=0x0B, io_idx=1, ord=0).
