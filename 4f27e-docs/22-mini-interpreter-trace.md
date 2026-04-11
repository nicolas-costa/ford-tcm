# 22 — Trace Estático: Mini-Interpreter @ 0x31C84 e Cadeia Boot→Solenoid

**Data:** 2026-03-22  
**Status:** ✅ Arquitetura mapeada. Cadeia completa Boot→SDA Roots→Root Structure→Slot Alloc→Slot Init.  
**Dependência:** Binário corrigido (PHF carry-byte fix, doc 20), tabela 0x2A540 (doc 21)

---

## Resumo Executivo

1. **FATO:** O mini-interpreter @ 0x31C84 processa um bytecode stream de 6 opcodes (0-5) e publica 3 ponteiros SDA root: `r13+0x1638`, `r13+0x163C`, `r13+0x166C`. Estes são a infraestrutura central do OS dispatcher.
2. **FATO:** A cadeia de inicialização de solenóides (IDs 0x30-0x36) passa por 5 estágios verificados: mini-interpreter → root creation @ 0x3FA400 → bitmap pool allocation → channel config lookup → slot init handler (436 instruções com 4 sub-handlers).
3. **FATO:** TODAS as funções de init são chamadas via dispatch indireto (zero callers diretos no ROM). O sistema usa tabelas de ponteiros em ROM + mtlr/blrl para despacho.
4. **Próximo passo de maior ROI:** Task 4 — mapear channel_id → solenóide físico via `channel_config_lookup_from_hw_table` @ 0x38260 (requer decode do grupo=0, tipo=1, instância=16-22 para IDs 0x30-0x36).

---

## 1. Mini-Interpreter: Estrutura e Opcodes

**Função:** `mini_interpreter_publish_sda_roots` @ 0x31C84 (64 instruções)  
**Chamado por:** `os_init_sda_roots_via_mini_interpreter` @ 0x31D84 via `bl` @ 0x31DB8  
**Input:** r3 = ponteiro para bytecode stream em ROM (obtido de `*(config+8)`)

### Formato de Record

```
Record (variável):
  word[0]: opcode (u32) — 0=terminator, 1-5=operações
  word[1]: payload_size (u32) — tamanho extra em bytes APÓS os 8 bytes iniciais
  word[2..]: payload (depende do opcode)
  
Avanço: next_record = current + payload_size + 8
```

### Tabela de Opcodes

| Opcode | Ação | Evidência |
|--------|------|-----------|
| **0** | Terminator — sai do loop | `cmpwi r10, 0` @ 0x31D60 → branch para epilogo |
| **1** | `r13+0x1638 = &record.payload` — publica SDA root 1 | `stw r12, 0x1638(r13)` @ 0x31CE0 |
| **2** | `r13+0x163C = &record.payload` — publica SDA root 2 | `stw r12, 0x163C(r13)` @ 0x31D50 |
| **3** | `r13+0x166C = &record.payload` — publica SDA root 3 | `stw r12, 0x166C(r13)` @ 0x31D44 |
| **4** | Memcpy/Memset: `count=word[2], src=word[3], dst=word[4]`. Se src==0: fill 0xFF. | `mtctr r4` @ 0x31CF8, loop bdnz @ 0x31D0C / 0x31D24 |
| **5** | Call `nullsub_21` (no-op neste build) | `bl nullsub_21` @ 0x31D38 |

### SDA Roots Publicados → Consumidores

| SDA Offset | Set by Opcode | Consumidores Principais | Count |
|------------|--------------|------------------------|-------|
| `r13+0x1638` | 1 | `dispatch_via_1638_slot60`, 25+ funções em 0x31xxx-0x33xxx | 25 |
| `r13+0x163C` | 2 | `callback_gate_via_163c_with_1664_guard`, `sub_32208`, `sub_32348` | 10 |
| `r13+0x166C` | 3 | `sub_32A2C` (2 refs) | 5 |

---

## 2. Cadeia de Chamada (Call Chain)

Todas as funções de init têm **zero callers diretos** no ROM — são chamadas via dispatch indireto.

```
Boot (RTOS kernel)
  │
  ├─► os_cold_start_setup_timers_and_dispatch @ 0x31DFC  [via indirect]
  │     │  Desabilita interrupts (mtspr eid)
  │     │  Reseta PISCR/TBSCR (timers MPC555)
  │     │  Configura stack frame a partir de config data
  │     │
  │     ├─► os_init_sda_roots_via_mini_interpreter @ 0x31D84
  │     │     │  Zera: r13+{0x1678, 0x167C, 0x166C, 0x163C, 0x1668}
  │     │     │  Loads bytecode from *(config+8)
  │     │     │
  │     │     ├─► mini_interpreter_publish_sda_roots @ 0x31C84
  │     │     │     Executa bytecode → seta r13+{0x1638, 0x163C, 0x166C}
  │     │     │
  │     │     └─► tail-call to chunk @ 0x31BC8 (mais init)
  │     │
  │     ├─► Executa startup callbacks de *(r13+0x1638)+0x5C (array terminado em NULL)
  │     └─► Loop principal de dispatch
  │
  ├─► root_3FA400_create_and_populate @ 0x2FFFC  [via indirect]
  │     │  Aloca arrays em RAM: *(0x3FA404), *(0x3FA408), *(0x3FA40C)
  │     │  Popula a root structure usando config ROM:
  │     │    config+0 byte = slot_count (23)
  │     │    config+1 byte = sub_count (11)
  │     │    config+8 ptr  = slot_config_data
  │     │    config+0x10 ptr = mapping_table
  │     │  Escreve root pointer em *(0x3FA400)
  │     │
  │     └─► Cria cross-references: mapping[i].slot_id → 3FA404 entries
  │
  └─► task3_slot_alloc_and_init_from_2A744 @ 0x31594  [Task 3 entry, code_ptr=0x31598]
        │  r27 = 0x2A744 (hardcoded ROM address, task descriptor entry 4)
        │
        ├─ OUTER LOOP: repeat until all channels allocated
        │   │
        │   ├─► slot_pool_alloc_channel_id @ 0x381D0
        │   │     Reads pool @ r13+0x1598 (index from *(0x2A74C)=1)
        │   │     cntlzw → finds first set bit in bitmap
        │   │     Clears bit, decrements count
        │   │     Returns channel_id via ID mapping table (u16)
        │   │     Returns 0xFFFF when pool exhausted → exits outer loop
        │   │
        │   └─ INNER LOOP: iterate slots in *(0x3FA400)
        │       │  root = *(0x3FA400)
        │       │  count = *(root+2) byte
        │       │  mapping_table = *(root+0x10)
        │       │
        │       ├─ Match: mapping_table[i].id == allocated_channel_id
        │       │   │
        │       │   ├─ slot_array[sub_id].status_bits == 0:
        │       │   │   └─► slot_init_handler_by_channel @ 0x30EC4 (via mtlr/blrl)
        │       │   │         436 instructions. Processes channel init.
        │       │   │
        │       │   └─ slot_array[sub_id].status_bits != 0:
        │       │       └─► slot_update_handler_by_channel @ 0x3099C (via mtlr/blrl)
        │       │             548 bytes. Updates existing slot.
        │       │
        │       └─ No match: next slot
```

---

## 3. Slot Init Handler: Decodificação de Canais

**Função:** `slot_init_handler_by_channel` @ 0x30EC0 (436 instruções)

### Fluxo de Dados

```
slot_init_handler_by_channel(slot_index):
  root       = *(0x3FA400)
  mapping    = *(root + 0x10)
  channel_id = mapping[slot_index].halfword[0]    # e.g. 0x0030 para SS1
  sub_id     = mapping[slot_index].byte[2]
  slot_array = *(root + 8)
  
  # Store slot_index → *(0x3FA404) para cross-reference
  *(0x3FA404)[sub_id*3 + 1] = slot_index
  
  # Chama hardware config lookup
  result = channel_config_lookup_from_hw_table(channel_id, 8, 0, &buffer, 0)
  
  if result < 2: return (skip)
  
  type_nibble = buffer[0] >> 4
  switch (type_nibble):
    case 0: init_type0 @ 0x30F74   # Basic init (function pointers, slot metadata)
    case 1: init_type1 @ 0x310A0   # Extended init
    case 2: init_type2 @ 0x31208   # Alternate init
    case 3: init_type3 @ 0x31478   # Complex init
```

### Channel Config Lookup

**Função:** `channel_config_lookup_from_hw_table` @ 0x38260 (186 instruções)

Decodifica channel_id em 3 campos (PPC bit numbering):

| Campo | Bits (MSB=0) | Para 0x30 (SS1) | Para 0x36 (EPC) |
|-------|-------------|------------------|------------------|
| group | 20-21 (2 bits) | 0 | 0 |
| type | 22-26 (5 bits) | 1 | 1 |
| instance | 27-31 (5 bits) | 16 | 22 |

**FATO:** Todos os solenóides 0x30-0x36 pertencem a **group=0, type=1**, variando apenas em instance (16-22).

Lookup multi-nível:
```
hw_config_table = *(r13+0x1588)
group_table     = *(hw_config_table + 0xC)
sub_table       = *(group_table[group*16] + 0xC)
hw_index        = sub_table[type*8]       # byte lookup
bitmap_check    = *(0x3FAE1C + group*4)   # availability bitmap
pool_map        = *(0x3FAE28 + group*4)   # pool mapping
slot_ref        = *(r13+0x158C) + computed_offset
```

---

## 4. RAM Structures Criadas (Endereços Fixos)

| Endereço RAM | Conteúdo | Escrito por |
|-------------|----------|-------------|
| `0x3FA400` | Root structure pointer (principal) | `root_3FA400_create_and_populate` |
| `0x3FA404` | Array per-slot (count*3 bytes) | `root_3FA400_create_and_populate` |
| `0x3FA408` | Array per-channel (count*14 bytes) | `root_3FA400_create_and_populate` |
| `0x3FA40C` | Config buffer (16 bytes) | `root_3FA400_create_and_populate` |
| `0x3FAE1C` | Availability bitmap per-group (4 x u32) | Init chain (TBD) |
| `0x3FAE28` | Pool mapping per-group (4 x u32) | Init chain (TBD) |

### SDA Root Pointers (r13-relative)

| Offset | Nome | Set By | Used By |
|--------|------|--------|---------|
| `0x1588` | hw_config_table | Init @ 0x368B8 | `channel_config_lookup_from_hw_table` |
| `0x158C` | slot_pool_mapping | Init @ 0x36AD4 | `channel_config_lookup_from_hw_table` |
| `0x1598` | slot_pool_array | Init @ 0x36AC0 (malloc count*12) | `slot_pool_alloc_channel_id` |
| `0x1638` | dispatch_root_1 | Mini-interp opcode 1 | 25+ dispatch functions |
| `0x163C` | dispatch_root_2 | Mini-interp opcode 2 | callback_gate, 10+ functions |
| `0x1640` | config_ptr_backup | `os_init_sda_roots_via_mini_interpreter` | OS dispatch |
| `0x164C` | task_sequence_counter | `os_cold_start_setup_timers_and_dispatch` | OS dispatch |
| `0x1664` | runtime_flags | `os_cold_start_setup_timers_and_dispatch` | Guard checks |
| `0x166C` | dispatch_root_3 | Mini-interp opcode 3 | `sub_32A2C` |

---

## 5. Formato do ROM Config Struct (Parcial)

O header da tabela de slots está em **0x2A6C8**:

```
0x2A6C8: 17 0B 00 00    → byte[0]=0x17(23 slots), byte[1]=0x0B(11 sub-slots)
0x2A6CC: 00 02 A5 B8    → ptr[+4] = 0x2A5B8 → slot descriptor array (ROM)
0x2A6D0: 01 00 00 00    → flags
0x2A6D4: 00 04 87 3C    → code_ptr (task entry 0)
```

O slot descriptor array em 0x2A5B8 contém 23 entries de 12 bytes cada, incluindo os 7 solenóides:

```
SS1 = 0x30 @ 0x2A5E4: {id=0x30, size=0x10, data=0, 0}
SS2 = 0x31 @ 0x2A5F0: {id=0x31, size=0x10, data=0, 0}
SS3 = 0x32 @ 0x2A5FC: {id=0x32, size=0x10, data=0, 0}
SS4 = 0x33 @ 0x2A608: {id=0x33, size=0x10, data=0, 0}
SS5 = 0x34 @ 0x2A614: {id=0x34, size=0x10, data=0, 0}
SS6 = 0x35 @ 0x2A620: {id=0x35, size=0x10, data=0, 0}
EPC = 0x36 @ 0x2A62C: {id=0x36, size=0x10, data=0, 0}
```

---

## 6. Conexão Solenoid: Boot → Control Function

```
                    ┌─────────────────────────────────────────────┐
                    │  ROM Table @ 0x2A540                        │
                    │  ┌─────────────────────────────────┐        │
                    │  │ Range entries (zero RAM)         │        │
                    │  ├─────────────────────────────────┤        │
                    │  │ Slot descs (0x30-0x36 = 7 sol.) │        │
                    │  ├─────────────────────────────────┤        │
                    │  │ Task descs (code_ptrs)           │        │
                    │  └────────────┬────────────────────┘        │
                    └───────────────┼─────────────────────────────┘
                                    │
                    ┌───────────────▼──────────────────────┐
                    │  Boot: OS Cold Start @ 0x31DFC       │
                    │  ├─ Disable interrupts                │
                    │  ├─ Mini-interpreter → SDA roots      │
                    │  └─ Start dispatch loop                │
                    └───────────────┬──────────────────────┘
                                    │
                    ┌───────────────▼──────────────────────┐
                    │  Root Init @ 0x2FFFC                  │
                    │  malloc → *(0x3FA400) root structure  │
                    │  Populate with slot desc data         │
                    └───────────────┬──────────────────────┘
                                    │
                    ┌───────────────▼──────────────────────┐
                    │  Task 3 Slot Alloc @ 0x31594          │
                    │  FOR EACH channel in bitmap pool:     │
                    │    alloc_id ← slot_pool_alloc(bitmap) │
                    │    MATCH against root table            │
                    └───────────────┬──────────────────────┘
                                    │
                    ┌───────────────▼──────────────────────┐
                    │  Slot Init Handler @ 0x30EC0          │
                    │  channel_config_lookup(channel_id)     │
                    │  → type_nibble dispatch (0/1/2/3)     │
                    │  → Store function ptrs in slot entry  │
                    │  → Solenoid control linked here       │
                    └──────────────────────────────────────┘
```

---

## 7. Funções Renomeadas no IDA

| EA | Nome Anterior | Nome Atual |
|----|--------------|------------|
| 0x031D84 | sub_31D84 | `os_init_sda_roots_via_mini_interpreter` |
| 0x031DFC | sub_31DFC | `os_cold_start_setup_timers_and_dispatch` |
| 0x02FFFC | init_roots_write_3FA400_from_r3 | `root_3FA400_create_and_populate` |
| 0x031594 | tasktable_or_slot_init_from_2A744_and_3FA400 | `task3_slot_alloc_and_init_from_2A744` |
| 0x038260 | sub_38260 | `channel_config_lookup_from_hw_table` |
| 0x031C84 | — | `mini_interpreter_publish_sda_roots` (já nomeado) |
| 0x0381D0 | — | `slot_pool_alloc_channel_id` (já nomeado) |
| 0x030EC0 | — | `slot_init_handler_by_channel` (já nomeado) |
| 0x030998 | — | `slot_update_handler_by_channel` (já nomeado) |

---

## 8. Limitações da Análise Estática

- **Bytecode stream**: O endereço exato do bytecode processado pelo mini-interpreter depende de qual config structure é passada via dispatch indireto. A config é provavelmente uma das entries na pointer table @ 0x2A7B0+, mas a cadeia de chamada usa mtlr/blrl sem referência direta.
- **type_nibble para solenóides**: O valor retornado por `channel_config_lookup_from_hw_table` para IDs 0x30-0x36 depende de dados em RAM (`r13+0x1588`, `0x3FAE1C`) que são preenchidos por outra init chain. Análise estática pura não resolve — necessário emulação ou debug dinâmico.
- **Function pointers finais**: Os ponteiros de função armazenados nos slot entries (que eventualmente apontam para a rotina de controle PWM tipo 0x395B4) são escritos pelo type_nibble handler, cuja lógica depende do type_nibble.

---

## 9. Próximos Passos (ROI ordenado)

1. **Task 4** (Channel→Physical Solenoid Map): Analisar `channel_config_lookup_from_hw_table` com inputs estáticos group=0, type=1, instance=16-22. Requer decode da tabela apontada por `r13+0x1588`.
2. **Task 5** (QEMU deeper boot): Com o mini-interpreter emulado, travar SDA roots e observar os type_nibble handlers em runtime.
3. **Alternativa**: XREFs de 0x395B4 (`tpu_pwm_queue_build_and_schedule_task3`) para encontrar quem armazena esse ponteiro nos slot entries → trace reverso até o type_nibble handler.
