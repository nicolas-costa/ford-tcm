# 24 — Shift Schedule Tables: Extração, Mapeamento e Arquitetura de Decisão

**Data:** 2026-04-19 (v3 — live RAM logging, 3 grupos de slot confirmados, coast_decel table identificada)  
**Status:** ✅ 10 tabelas + coast_decel table. Pipeline completo mapeado com dados ao vivo via UDS 0x23.  
**Dependência:** Binário corrigido (doc 20), mapeamento solenóide (doc 23), UDS security (doc 28)

---

## Resumo Executivo

1. **FATO:** 10 shift schedule tables localizadas em ROM @ 0x184B10-0x184EC4 + coast_decel table @ 0x182ED0. Formato: pares (speed_km/h, throttle_%) com count=7-11 rows. Interpolação feita via 1D lookup em `qword_BBDC8` (ROM @ 0xBBDC8) e 2D via `cal_2d_lookup_interpolate` (0xBBE44).
2. **FATO:** `shift_table_group_dispatcher` (0x9D860) e `shift_slot_eval_with_mode_switch` (0x872B4) selecionam um **grupo de tabelas** baseado em flags RAM e mode selector (0x3FBBCC) e escrevem thresholds em **6 slots RAM** (0x3FBC24-0x3FBC29).
3. **FATO:** `gear_zone_evaluator` (0x83484) consome os slots e determina o **gear target**, armazenado em RAM 0x3FC239.
4. **FATO (live RAM):** Gear encoding é bitmask: 1=1ª, 2=2ª, 4=3ª, 8=4ª.
5. **FATO (live RAM):** Existem **3 grupos de slot distintos**, confirmados por leitura RAM em tempo real:


| Grupo            | Condição             | S24    | S25    | S27    | Origem ROM                 |
| ---------------- | -------------------- | ------ | ------ | ------ | -------------------------- |
| **Aceleração**   | INPUT > ~7%          | 17     | 12     | 12-21  | T4/T5/T10/T11 (0x184xxx)   |
| **Coast normal** | INPUT=0, decel lenta | 19     | 17     | 17     | Tabelas 0x182xxx (G3)      |
| **Coast rápido** | INPUT=0, decel forte | **24** | **22** | **22** | **coast_decel @ 0x182ED0** |


1. **FATO (live RAM):** O bug 3→1 ocorre **exclusivamente** no grupo "coast rápido". A 20 km/h: S24=24, S25=22 → SPD(20) < S25(22) → 2ª bloqueada → 3→1 direto.

---

## Arquitetura de Decisão de Marcha

### Pipeline completo (FATO — assembly + live RAM verificados)

```
                   ┌─────────────────────────────────┐
                   │  RAM flags / mode selectors:     │
                   │  0x3FC3F0, 0x3FC392, 0x3FC372,   │
                   │  byte_186750 (mode 1/2/3),       │
                   │  0x3FBBCC (0x26 = coast decel)   │
                   └──────────┬──────────────────────┘
                              │ selecionam grupo + modo
                              ▼
          ┌──────────────────────────────────────────────┐
          │  CAMADA 1: shift_table_group_dispatcher      │
          │  (0x9D860, 4972 bytes)                       │
          │                                              │
          │  Group 1 (upshift):                          │
          │    T8→S28, T6→S26, T5→S25, T4→S24            │
          │                                              │
          │  Group 2 (downshift):                        │
          │    T12→S26, T13→S27, T10→S24, T11→S25        │
          │                                              │
          │  Group 3 (variant): T6,T7,T4,T5→slots        │
          └──────────┬───────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────────────────────────────┐
          │  CAMADA 2: shift_threshold_compute_with_mode │
          │  (0x93510)                                   │
          │                                              │
          │  byte_186750==3 → coast decel path:          │
          │    shift_mode3_coast_decel_handler (0x92A4C)  │
          │      └→ shift_slot_eval_with_mode_switch      │
          │         (0x872B4)                             │
          │           ├─ 0x3FBBCC==0x26 → 0x187514       │
          │           │  (coast_decel: 7×22.0 @ 0x182ED0)│
          │           │  → S24=24, S25=22, S27=22  ← BUG │
          │           └─ else → 0x184218 (normal)        │
          └──────────┬───────────────────────────────────┘
                     │ escreve 6 bytes em RAM
                     ▼
          ┌──────────────────────────────────┐
          │  Slots RAM 0x3FBC24-0x3FBC29     │
          │  (speed thresholds, byte, km/h)  │
          └──────────┬───────────────────────┘
                     │ lidos por
                     ▼
          ┌──────────────────────────────────────────────┐
          │  gear_zone_evaluator (0x83484, 1624B)        │
          │                                              │
          │  Lê gear atual de RAM 0x3FC106 (bitmask)     │
          │  Compara speed (0x3FD493) vs slots            │
          │  Para gear=3: speed < S25 → target=1 (BUG)   │
          │  Retorna target gear: 1, 2, 4, ou 8          │
          │  Grava em RAM 0x3FC239 (bitmask)             │
          └──────────────────────────────────────────────┘
```

### Evidência de 3 Grupos (FATO — amostra de log ao vivo)

```
Dados extraídos de tcm_slot_logger.py via UDS 0x23:

ACELERAÇÃO (INPUT=12, SPD=22):
  S24=17 S25=12 S26=28 S27=12 S28=33 S29=1 GR=4(3ª) GT=4(3ª)

COAST NORMAL (INPUT=0, SPD=33, decel lenta):
  S24=19 S25=17 S26=28 S27=17 S28=42 S29=0 GR=4(3ª) GT=4(3ª)

COAST RÁPIDO (INPUT=0, SPD=21, foot-off brusco):
  S24=24 S25=22 S26=28 S27=22 S28=42 S29=0 GR=4(3ª) GT=1(1ª) ← BUG
```

### Mapeamento de Slots por Grupo (FATO — endereços verificados em assembly)


| Slot         | RAM      | Group 1 (Upshift)               | Addr Group1 | Group 2 (Downshift)          | Addr Group2 |
| ------------ | -------- | ------------------------------- | ----------- | ---------------------------- | ----------- |
| SLOT_1_2     | 0x3FBC24 | T4 (1→2 UP) 17km/h @0%          | stb@0x9E23C | **T10 (2→1 alt) 23km/h @0%** | stb@0x9E404 |
| SLOT_??25    | 0x3FBC25 | T5 (2→1 DN) 12km/h @0%          | stb@0x9E208 | **T11 (3→2 DN) 20km/h @0%**  | stb@0x9E6A4 |
| SLOT_2_3     | 0x3FBC26 | T6 (2→3 UP)                     | stb@0x9E1D4 | T12 (4→3 DN)                 | stb@0x9E3A4 |
| SLOT27_stay3 | 0x3FBC27 | **T7 (stay-in-3rd gatekeeper)** | stb@0x9E1A0 | T13 (3→2 alt)                | stb@0x9E3D4 |
| SLOT_FLAG    | 0x3FBC28 | T8/T9                           | —           | —                            | —           |
| SLOT_CNT     | 0x3FBC29 | —                               | —           | —                            | —           |


### Lógica COMPLETA do gear_zone_evaluator (FATO — disasm 0x837E4-0x83AD0)

```
Para gear atual = 4 (3ª marcha, bitmask):
  1. speed >= S28?  → target = 8 (4ª)    @ 0x83804: cmpw → 0x8383C: li r3, 8
  2. speed >= S27?  → target = 4 (3ª)    @ 0x8388C: cmpw → 0x83A30: li r3, 4
     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
     S27 é o GATEKEEPER de saída da 3ª.
     Enquanto speed >= S27, a 3ª marcha é mantida.
  3. speed >= S25?  → target = 2 (2ª)    @ 0x838CC: cmpw → 0x83AC0: li r3, 2
  4. else           → target = 1 (1ª)    @ 0x838D4: li r3, 1
  5. Grava target em RAM 0x3FC239        @ 0x83AD0: stb r3

Para gear atual = 2 (2ª marcha):
  1. speed >= S26?  → target = 4 (3ª)    @ 0x8385C
  2. speed >= S25?  → target = 2 (2ª)    @ 0x838CC
  3. else           → target = 1 (1ª)

Para gear atual = 1 (1ª marcha):
  - speed >= S24?   → target = 2 (2ª)    @ 0x838AC
  - else            → target = 1 (1ª)

Para gear atual = 8 (4ª marcha):
  - speed >= S29?   → target = 8 (4ª)    @ 0x83834
  - speed >= S27?   → target = 4 (3ª)    @ 0x8388C → 0x83A30: li r3, 4
  - (cai no eval 1/2 abaixo)
```

**Consequência para 3→2 (RC #4 + RC #5):**

- **Coast rápido:** S27=22, S25=22. A 20 km/h: 20<22 → sai de 3ª → 20<22 → target=1 (3→1 BUG).
- **Retomada:** S27=T7(15%)≈17. A 26 km/h: 26>=17 → FICA na 3ª (arrastando). Para 3→2, S27 precisa ser > speed.

### Funções de Lookup (ROM)


| Função              | EA      | Nome IDA                          | Papel                                                           |
| ------------------- | ------- | --------------------------------- | --------------------------------------------------------------- |
| 1D Lookup           | 0xBBDC8 | cal_1d_lookup_trampoline          | Busca linear em array de breakpoints float (é código, não data) |
| 2D Wrapper          | 0xBBE44 | cal_2d_lookup_interpolate         | Chama 1D lookup para cada eixo, depois interpola 2D             |
| 2D Interpolation    | 0xBBEC8 | —                                 | Interpolação bilinear com 4 pontos adjacentes                   |
| Table Dispatcher    | 0x9D860 | shift_table_group_dispatcher      | 4972B, seleciona grupo e escreve slots RAM                      |
| Mode Switch         | 0x872B4 | shift_slot_eval_with_mode_switch  | Decide entre tabela normal (0x184218) e coast_decel (0x187514)  |
| Threshold Compute   | 0x93510 | shift_threshold_compute_with_mode | 702 insns, despacha por mode_selector (byte_186750)             |
| Coast Decel Handler | 0x92A4C | shift_mode3_coast_decel_handler   | Chamado quando mode_selector=3                                  |
| Coast Decel Counter | 0x926BC | shift_mode3_counter_state_machine | Counters em 0x3FC040/0x3FC409/0x3FC40A                          |
| Gear Evaluator      | 0x83484 | gear_zone_evaluator               | 1624B, consome slots, retorna target gear                       |
| Shift Evaluator     | 0x9F060 | shift_point_2d_eval_from_cal      | Chama 2D lookup com descriptors 0x186874/0x18AD70               |
| Shift State Machine | 0xB1130 | shift_state_machine_transition    | 2520B, estados 0/1/2/3, consome ROM 0x189500+                   |
| Shift Calculator    | 0xB0740 | shift_schedule_evaluator          | 2544B, paralela a B1130                                         |


---

## Descobertas via Live RAM (UDS 0x23)

### Método de Leitura

Leitura ao vivo de RAM via UDS service 0x23 (ReadMemoryByAddress). Formato Ford proprietário:

```
Request:  23 [4-byte addr BE] 00 [size]  (size ≤ 4, sem format byte)
Response: 63 [data bytes]
```

SecurityAccess (0x27 subfunction 03→04) necessário. Algoritmo: LFSR 24-bit, 5 XOR taps, 2 rounds de 32 iterações + bit shuffle final. Documentado em doc 28.

### Gear Encoding (FATO — observação direta)

RAM 0x3FC106 (gear atual) e 0x3FC239 (gear target) usam **bitmask**, não ordinal:


| Valor | Marcha |
| ----- | ------ |
| 0x01  | 1ª     |
| 0x02  | 2ª     |
| 0x04  | 3ª     |
| 0x08  | 4ª     |


### Três Grupos de Slot (FATO — observação RAM direta, centenas de amostras)

A leitura contínua dos slots 0x3FBC24-0x3FBC29 durante condução revelou que o TCM usa **3 conjuntos distintos de thresholds**, que alternam dinamicamente:

**Grupo ACELERAÇÃO** (INPUT > ~7%):

```
S24=17  S25=12  S26=28  S27=12-21  S28=33  S29=1
```

- S25=12 corresponde ao nosso T11 patcheado (20→12). PROVA que o patch T11 está ativo.
- S24=17 corresponde a T4 @0% (17 km/h).

**Grupo COAST NORMAL** (INPUT=0, desaceleração lenta):

```
S24=19  S25=17  S26=28  S27=17  S28=42  S29=0
```

- Origem ROM: tabelas na região 0x182xxx, possivelmente 0x182728.
- S25=17 provém de uma tabela DIFERENTE de T11. Group 3 ou blend.

**Grupo COAST RÁPIDO** (INPUT=0, desaceleração forte / foot-off abrupto):

```
S24=24  S25=22  S26=28  S27=22  S28=42  S29=0
```

- **ROOT CAUSE do 3→1.** Origem: coast_decel table @ 0x182ED0 (7 × 22.0 floats).
- Ativado quando RAM 0x3FBBCC == 0x26 (mode selector).
- A 20 km/h: SPD(20) < S25(22) → 2ª inelegível → target=1ª → 3→1 direto.

### Cadeia de Despacho: Coast Rápido (FATO — disasm verificado)

```
shift_threshold_compute_with_mode (0x93510)
  └── byte_186750 == 3 (mode3) → shift_mode3_coast_decel_handler (0x92A4C)
        └── shift_slot_eval_with_mode_switch (0x872B4)
              ├── RAM 0x3FBBCC == 0x26 → r3 = 0x187514 (coast_decel descriptor)
              │     └── 0x187514 → PTR → 0x182EC8 (axis) → 0x182ED0 (data: 7×22.0)
              └── RAM 0x3FBBCC != 0x26 → r3 = 0x184218 (normal table)
```

**FATO (disasm 0x87BE8):**

```asm
lwz     r3, 0(r25)          ; r3 = RAM[0x3FBBCC] = mode
cmpwi   r3, 0x26            ; is coast decel?
bne     loc_87C64           ; no → normal path (r3=0x184218)
lis     r3, 0x18            ; yes →
ori     r3, r3, 0x7514      ; r3 = 0x187514 (coast_decel descriptor)
```

### Coast Decel Table @ 0x182ED0 (FATO — dados ROM)

Tabela 2D referenciada por descriptor 0x187514 → 0x182EC8. Controla base threshold para S25/S27.

**Dados (7 entradas, INPUT vs threshold base):**


| Input (throttle proxy) | Threshold Base (km/h) | Bytes       |
| ---------------------- | --------------------- | ----------- |
| ≤ 0% (decel forte)     | **22.0**              | 41 B0 00 00 |
| 0%                     | **22.0**              | 41 B0 00 00 |
| 0%                     | **22.0**              | 41 B0 00 00 |
| ~10%                   | **22.0**              | 41 B0 00 00 |
| ~20%                   | **22.0**              | 41 B0 00 00 |
| ~40%                   | **22.0**              | 41 B0 00 00 |
| ~60%                   | **22.0**              | 41 B0 00 00 |


**Scaling (FATO):** S24 = base × factor. Factor vem de 1D scaling table @ 0x181908. Para S24: 22.0 × ~1.09 ≈ 24.0 (observado em RAM).

**ROM Addresses:**

- Descriptor: `0x187514` (referenced by shift_slot_eval_with_mode_switch @0x87C20)
- Axis pointer: `0x182EC8`
- Data start: `0x182ED0`
- Data end: `0x182F00` (28 bytes = 7 × float32)

---

### Formato da Tabela

Cada tabela de shift schedule consiste em:

```
[N pairs de (speed_float, throttle_float)]  — N = count (7 ou 11)
[u32 count]                                  — 0x07 ou 0x0B
[u32 pointer_to_data_start]                  — auto-referencial (footer)
[u32 null/padding]
```

O **footer pointer** é o endereço passado a `qword_BBDC8` via `lis r3, 0x18; addi r3, r3, offset`.

- **Coluna 0:** Speed threshold em km/h (float32 big-endian)
- **Coluna 1:** Throttle breakpoint em % (float32 big-endian, 0.0-99.6%)
- **Interpretação:** "Se throttle <= col1, o threshold de velocidade para esta transição é col0"

---

## Tabelas de Shift Schedule

> **NOTA:** Os "Grupos" abaixo refletem a função lógica original (upshift/downshift). No código, a atribuição é feita por `shift_table_group_dispatcher` que usa tabelas de **ambos** os grupos, reorganizadas por finalidade de avaliação (ver mapeamento de slots acima).

### Tabelas de Upshift (velocidade ACIMA do threshold → sobe marcha)

#### Table 4 — 1→2 Upshift (0x184B10) — Footer: 0x184B68

**Papel no código:** Group 1 → SLOT_1_2. Group 3 → SLOT_1_2. Define "velocidade mínima para estar em 2ª" durante upshift.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 0          | 17         |
| 12         | 17         |
| 20         | 17         |
| 25         | 23         |
| 39         | 27         |
| 59         | 32         |
| 80         | 39         |
| 93         | 56         |
| 93         | 56         |
| 99.6       | 57         |


#### Table 6 — 2→3 Upshift (0x184BD0) — Footer: 0x184C28

**Papel no código:** Group 1 → SLOT_2_3. Group 3 → SLOT_2_3.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 8          | 28         |
| 12         | 28         |
| 25         | 34         |
| 39         | 49         |
| 54         | 61         |
| 68         | 74         |
| 88         | 87         |
| 93         | 105        |
| 93         | 105        |
| 99.6       | 108        |


#### Table 8 — 3→4 Upshift (0x184C90) — Footer: 0x184CE8

**Papel no código:** Group 1 → SLOT_FLAG.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 6          | 40         |
| 12         | 40         |
| 20         | 46         |
| 29         | 59         |
| 39         | 73         |
| 55         | 86         |
| 59         | 109        |
| 70         | 115        |
| 78         | 135        |
| 99.6       | 154        |


### Tabelas de Downshift (velocidade ABAIXO do threshold → desce marcha)

#### Table 5 — 2→1 Downshift (0x184B70) — Footer: 0x184BC8

**Papel no código:** Group 1 → SLOT_??25. Group 3 → SLOT_??25. Define "piso mínimo de 2ª marcha" durante upshift eval. Abaixo de T5 → target=1ª.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 0          | 12         |
| 6          | 12         |
| 20         | 12         |
| 45         | 12         |
| 50         | 12         |
| 60         | 12         |
| 85         | 16         |
| 93         | 31         |
| 93         | 35         |
| 99.6       | 53         |


#### Table 11 — 3→2 Downshift ⚠️ (0x184DB0) — Footer: 0x184E08 — ROOT CAUSE #1

**Papel no código:** Group 2 → **SLOT_??25**. Define "piso mínimo de 2ª marcha" durante **downshift eval**. Abaixo de T11 → target=**1ª** (não 2ª!).


| Throttle % | Speed km/h |
| ---------- | ---------- |
| **0**      | **20**     |
| **0**      | **20**     |
| **0**      | **20**     |
| **20**     | **20**     |
| **39**     | **20**     |
| **60**     | **20**     |
| **85**     | **20**     |
| 93         | 31         |
| 93         | 35         |
| 99.6       | 53         |


**⚠️ ROOT CAUSE:** No `gear_zone_evaluator`, para gear=3: `speed < SLOT_??25 → target=1`. Com T11=20km/h, qualquer velocidade abaixo de 20 km/h em coasting → **target é 1ª marcha** (skip direto 3→1). Confirmado por FORScan: 3→1 @ 17.6 km/h em Closed Throttle.

**Semântica real (provada por código):** T11 NÃO é simplesmente "3→2 downshift threshold". Na prática, o evaluator usa T11 como fronteira entre zona de 1ª e zona de 2ª. Abaixo de T11 → 1ª é o target.

#### Table 10 — 2→1 Alt ⚠️ (0x184D50) — Footer: 0x184DA8 — ROOT CAUSE #2 (trapping)

**Papel no código:** Group 2 → **SLOT_1_2**. Define "velocidade mínima para sair de 1ª" durante **downshift eval**. Abaixo de T10 e já em 1ª → **preso em 1ª**.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| **0**      | **23**     |
| **0**      | **23**     |
| **12**     | **23**     |
| **20**     | **23**     |
| **39**     | **23**     |
| 59         | 28         |
| 80         | 39         |
| 93         | 56         |
| 93         | 56         |
| 99.6       | 57         |


**⚠️ TRAPPING:** Uma vez em 1ª (causado por T11), `gear_zone_evaluator` usa SLOT_1_2 = T10 para avaliar se pode sair. Com T10=23 @0%: `17.6 < 23 → target=1 → preso até 23 km/h`. Gap morto entre T11(20) e T10(23) = zona sem 2ª marcha acessível.

#### Table 12 — 4→3 Downshift (0x184E10) — Footer: 0x184E68

**Papel no código:** Group 2 → SLOT_2_3.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 8          | 50         |
| 12         | 50         |
| 20         | 50         |
| 39         | 50         |
| 54         | 50         |
| 68         | 72         |
| 88         | 87         |
| 93         | 105        |
| 93         | 105        |
| 99.6       | 108        |


#### Table 13 — 3→2 Alt (0x184E70) — Footer: 0x184EC8

**Papel no código:** Group 2 → SLOT_3_2a. Boundary entre 3ª e 4ª zona no downshift eval.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 0          | 44         |
| 6          | 44         |
| 12         | 44         |
| 20         | 44         |
| 29         | 44         |
| 45         | 44         |
| 83         | 44         |
| 93         | 89         |
| 93         | 89         |
| 99.6       | 99         |


### Tabelas Auxiliares / Group 3

#### Table 7 — 1→2 Alt (0x184C30) — Footer: 0x184C88

**Papel no código:** Usado no cálculo inicial de f29/f30 em `shift_table_group_dispatcher` (0x9DA34). Group 3 → SLOT_??25 ou SLOT_3_2a.


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 6          | 12         |
| 6          | 12         |
| 12         | 14         |
| 20         | 19         |
| 29         | 25         |
| 51         | 34         |
| 83         | 56         |
| 93         | 89         |
| 93         | 89         |
| 99.6       | 99         |


#### Table 9 — 3→4 Alt (0x184CF0) — Footer: 0x184D48

**Papel no código:** Group 1 → SLOT_FLAG ou SLOT_CNT (cálculo paralelo a T8).


| Throttle % | Speed km/h |
| ---------- | ---------- |
| 0          | 28         |
| 0          | 28         |
| 12         | 28         |
| 15         | 28         |
| 38         | 34         |
| 54         | 70         |
| 78         | 93         |
| 93         | 130        |
| 93         | 130        |
| 99.6       | 144        |


---

## Análise do Comportamento Reportado

### Cenário 1: "Fica em 3ª de 20 a 60 km/h com aceleração leve"

```
Cenário: throttle ~15%, velocidade 25 km/h, marcha atual = 3ª

Group 2 ativo (TCM avaliando downshift):
  SLOT_??25 = T11(15%) = 20 km/h
  gear_zone_evaluator: 25 >= 20 → target = 2 (2ª OK)
  MAS: car is in 3rd, not 2nd → state machine mantém 3ª

Upshift 3→4 (Table 8): threshold ~46 km/h @ 20% throttle
  → 25 < 46 → NÃO sobe para 4ª ✓

Resultado: PRESO EM 3ª entre 20 e ~45 km/h (dead band confirmada)
```

### Cenário 2: "3→1 em coasting a 17.6 km/h" (FORScan confirmado)

```
Group 2 ativo (coasting, Closed Throttle):
  SLOT_??25 = T11(0%) = 20 km/h
  SLOT_1_2  = T10(0%) = 23 km/h

gear_zone_evaluator (gear=3):
  speed(17.6) < SLOT_??25(20) → target = 1  ← 3→1 DIRETO

Uma vez em 1ª:
  speed(17.6) < SLOT_1_2(23) → target = 1  ← PRESO em 1ª até 23 km/h

FORScan confirma: 3→1 @ 17.6 km/h, TPMODE=CT (Closed Throttle)
```

### Cenário 3: "Solavanco 3→1→2 em retomada a 20 km/h"

```
Carro em 3ª, 20 km/h, motorista aplica ~20% throttle:

Se Group 2 ainda ativo:
  SLOT_??25 = T11(20%) = 20 km/h
  speed(20) >= 20 → target = 2 → 3→2 (OK, sem solavanco)

Se Group 1 ativo (transição para upshift eval):
  SLOT_??25 = T5(20%) = 12 km/h
  SLOT_1_2  = T4(25%) = 23 km/h
  speed(20) >= 12 → target = 2 → OK

MAS a 19.9 km/h em Group 2: 19.9 < 20 → target = 1 → 3→1 → solavanco
```

### Proposta de Correção

**Movida para doc 26 (patch-proposal-revised.md).** Ver doc 26 v4 para análise completa incluindo:

- Patches anteriores (T11, T10, T4) — já aplicados, eficazes para seus respectivos grupos
- **NOVO Patch 4:** coast_decel table @ 0x182ED0 — ROOT CAUSE PRINCIPAL do 3→1

**⚠️ ALERTA (v2, ainda válido):** A proposta ChatGPT de subir T11 era INVERTIDA. Subir T11 = ampliar zona de 1ª.

**⚠️ NOVA DESCOBERTA (v3):** Os patches T10/T11/T4 corrigem APENAS o grupo "aceleração" e parcialmente o "downshift". O grupo "coast rápido" (que causa a maioria dos 3→1 observados em campo) usa tabelas **completamente diferentes** em 0x182ED0, e precisa de patch próprio.

---

## Dados Adicionais Encontrados

### Gear Ratios (0x189700)

Grupos de 3 (nominal, max, min):


| Grupo | Nominal | Max  | Min  | Possível Significado |
| ----- | ------- | ---- | ---- | -------------------- |
| 1     | 4.22    | 4.31 | 4.19 | 1ª × final drive     |
| 2     | 2.53    | 2.56 | 2.53 | 2ª × final drive     |
| 3     | 1.66    | 1.69 | 1.62 | 3ª × final drive     |
| 4     | 1.22    | 1.25 | 1.19 | 4ª × final drive     |
| 5     | 1.00    | 1.06 | 1.00 | Direct (ref)         |
| 6     | 0.70    | 0.94 | 1.00 | Reverse/overdrive    |


### Torque Converter Curve (0x18AD10)

Stall ratio: 2.117. Speed ratio vs torque ratio (8 pontos):


| Speed Ratio | Torque Ratio |
| ----------- | ------------ |
| 0.10        | 1.994        |
| 0.20        | 1.861        |
| 0.30        | 1.740        |
| 0.40        | 1.606        |
| 0.50        | 1.468        |
| 0.60        | 1.324        |
| 0.70        | 1.189        |
| 0.80        | —            |


---

## Funções Identificadas (renomeadas no IDA)


| EA      | Nome IDA                           | Tamanho | Papel                                                     |
| ------- | ---------------------------------- | ------- | --------------------------------------------------------- |
| 0x83484 | **gear_zone_evaluator** ✅          | 1624B   | Consome slots RAM, retorna target gear (1/2/8) → 0x3FC239 |
| 0x9D860 | **shift_table_group_dispatcher** ✅ | 4972B   | Seleciona grupo de tabelas, escreve slots RAM 0x3FBC24-29 |
| 0xBBDC8 | qword_BBDC8                        | —       | 1D lookup (trampolim, chamado via blrl)                   |
| 0xBBE44 | cal_2d_lookup_interpolate          | —       | 2D wrapper (chama 1D + interpola)                         |
| 0xBBEC8 | —                                  | —       | 2D interpolação bilinear                                  |
| 0x9F060 | shift_point_2d_eval_from_cal       | —       | Chama 2D lookup com descriptors 0x186874/0x18AD70         |
| 0xB1130 | shift_state_machine_transition     | 2520B   | Estados 0/1/2/3, comparações float vs ROM 0x189500+       |
| 0xB0740 | shift_schedule_evaluator           | 2544B   | Paralela a B1130                                          |
| 0xB1E48 | shift_ratio_guard_eval             | —       | Guard de ratio                                            |


### RAM Slots e Variáveis Documentados


| Endereço | Nome            | Tipo | Papel                                         |
| -------- | --------------- | ---- | --------------------------------------------- |
| 0x3FBC24 | S24 / SLOT_1_2  | byte | Threshold 1↔2 (T4, T10, ou coast_decel)       |
| 0x3FBC25 | S25 / SLOT_??25 | byte | Piso mínimo para 2ª (T5, T11, ou coast_decel) |
| 0x3FBC26 | S26 / SLOT_2_3  | byte | Threshold 2↔3 (T6, T12, ou coast_decel)       |
| 0x3FBC27 | S27 / SLOT_3_2a | byte | Threshold 3↔2 (T7, T13, ou coast_decel)       |
| 0x3FBC28 | S28 / SLOT_FLAG | byte | Flag/threshold alto (T8/T9)                   |
| 0x3FBC29 | S29 / SLOT_CNT  | byte | Grupo ativo: 1=accel, 0=coast                 |
| 0x3FBBCC | mode_selector   | u32  | Modo do coast: 0x26=coast_decel rápido        |
| 0x3FC106 | gear_current    | byte | Marcha atual (bitmask: 1/2/4/8)               |
| 0x3FC239 | gear_target     | byte | Gear target (bitmask: 1/2/4/8)                |
| 0x3FC359 | group3_flag     | byte | Flag do group 3 (coast_decel ativo)           |
| 0x3FC372 | group_flag      | byte | Flag de grupo de shift                        |
| 0x3FD493 | vehicle_speed   | byte | Velocidade atual (km/h)                       |


