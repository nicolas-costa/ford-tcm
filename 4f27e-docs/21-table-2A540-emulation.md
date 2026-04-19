# 21 — Emulação Offline da Tabela 0x2A540: Resultados

**Data:** 2026-03-22  
**Status:** ✅ Tabela decodificada. 3 seções identificadas. Conexão task→solenoid mapeada.  
**Dependência:** Binário corrigido (PHF carry-byte fix, doc 20)

---

## Resumo Executivo

A tabela ROM @ 0x2A540 contém **3 seções** que juntas definem a infraestrutura de runtime do TCM:

1. **Range entries**: 5 regiões RAM zeradas no boot (31 KB total)
2. **Slot descriptors**: 24 canais (incluindo 7 solenóides) com IDs e tamanhos
3. **Task descriptors**: 6 tasks mapeando task_id → code_ptr

**FATO CRÍTICO:** Os fills 0xB6 e 0x27 que apareciam nos args das range entries eram **artefatos da corrupção PHF**. Todos os fills são **0x00 (zero)**. A RAM inteira (incluindo 0x3FA400..0x3FCB00) nasce zerada.

---

## Seção 1: Range Entries (5 × 16 bytes @ 0x2A540)


| #   | Start    | End      | Size    | Op             | Fill |
| --- | -------- | -------- | ------- | -------------- | ---- |
| 0   | 0x3F8000 | 0x3F8F00 | 3840 B  | 0x04 (memset)  | 0x00 |
| 1   | 0x3F9500 | 0x3F9D00 | 2048 B  | 0x04 (memset)  | 0x00 |
| 2   | 0x3F9D00 | 0x3FA400 | 1792 B  | 0x04 (memset)  | 0x00 |
| 3   | 0x3FA400 | 0x3FCB00 | 9984 B  | 0x04 (memset)  | 0x00 |
| 4   | 0x3FCB00 | 0x400000 | 13568 B | 0x14 (unknown) | 0x00 |


**Total coberto:** 31.232 bytes (30.5 KB)

**Resultado:** Após init, `*(0x3FA400) = NULL`, `r13+0x15D0 = NULL`. Bloco inteiro zerado.

---

## Seção 2: Slot/Channel Descriptors (24 × 12 bytes @ 0x2A5A8)


| ID        | Size  | Descrição                                |
| --------- | ----- | ---------------------------------------- |
| 0x00      | 2 B   | Metadata/count                           |
| 0x00–0x03 | 16 B  | Canais básicos (4)                       |
| **0x30**  | 16 B  | **SS1 (1-2 Shift)**                      |
| **0x31**  | 16 B  | **SS2 (2-3 Shift)**                      |
| **0x32**  | 16 B  | **SS3 (3-4 Shift)**                      |
| **0x33**  | 16 B  | **SS4 (TCC/Lockup)**                     |
| **0x34**  | 16 B  | **EPC (Line Pressure)**                  |
| **0x35**  | 16 B  | **SS5 (Coast Clutch)**                   |
| **0x36**  | 16 B  | **SS6 (Intermediate)**                   |
| 0x40–0x43 | 384 B | Estruturas grandes (init_data @ 0x2A59C) |
| 0x70–0x72 | 384 B | Estruturas grandes (init_data @ 0x2A59C) |
| 0x74–0x78 | 16 B  | Canais adicionais (5)                    |


**7 solenóides confirmados** (IDs 0x30–0x36), consistente com a transmissão 4F27E.

---

## Seção 3: Task Descriptors (6 × 28 bytes @ 0x2A6D8)


| Task ID | Flags      | Code Ptr     | Função                                           |
| ------- | ---------- | ------------ | ------------------------------------------------ |
| 0       | 0x01000000 | 0x048794     | task0_init_entry                                 |
| 1       | 0x01000000 | 0x048818     | task1_init_entry                                 |
| 2       | 0x01000000 | 0x04889C     | (não analisada)                                  |
| **3**   | 0x01000000 | **0x031598** | **tasktable_or_slot_init_from_2A744_and_3FA400** |
| **3**   | 0x01000000 | **0x041604** | **task3_secondary_entry**                        |
| 4       | 0x00001100 | 0xFFFFFFF8   | SENTINEL (terminador)                            |


**FATO:** Task ID 3 tem DOIS entries — um para init da slot table (0x31598) e outro secundário (0x41604).

---

## Conexão: Tabela → Solenoid Control

```
boot
 ├─ init_copy_or_zero_ranges @ 0x17AE8  (zera RAM via tabela 0x10B40)
 ├─ table 0x2A540 range entries         (zera RAM bloco 0x3FA400..0x3FCB00)
 │
 ├─ task_id=3 → 0x31598                 (popula slot table em 0x3FA400)
 │               ↓
 │   tasktable_dispatch_3FA400 @ 0x30C98
 │     root = *(0x3FA400)
 │     slots = *(root + 8)
 │     slot[i] = slots + i * 0xC
 │     fnptr = *(slot[i] + 8 + 4)
 │     blrl → fnptr
 │               ↓
 │   tpu_pwm_queue_build_and_schedule_task3 @ 0x395B4
 │     → controle de solenóides (EPC/TCC/shift)
 │
 └─ slot IDs 0x30–0x36 = 7 solenóides da 4F27E
```

---

## Funções Renomeadas no IDA


| Endereço | Nome Anterior                | Nome Novo                 |
| -------- | ---------------------------- | ------------------------- |
| 0x44460  | init_range_table_2A540_apply | bitmap_index_lookup_2A540 |
| 0x447BC  | sub_447BC                    | bitmap_set_clear_bit      |
| 0x48790  | sub_48790                    | task0_init_entry          |
| 0x48814  | sub_48814                    | task1_init_entry          |
| 0x41600  | sub_41600                    | task3_secondary_entry     |
| 0x48738  | sub_48738                    | task_section_default_init |


---

## Próximo Passo de Maior ROI

**Task 3: Trace estático do mini-interpreter @ 0x31C84** — entender como os slot descriptors (IDs 0x30-0x36) são processados para popular a slot table em RAM. Com os 7 IDs de solenóide agora identificados, o trace pode focar diretamente na cadeia que os conecta ao dispatcher.

---

**FIM DO DOCUMENTO**