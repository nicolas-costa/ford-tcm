# 24 — Shift Schedule Tables: Extração, Mapeamento e Arquitetura de Decisão

**Data:** 2026-04-19 (v3 — live RAM). **Revisto 2026-10-01** contra docs 26, 50, 63, 71, 72.  
**Status:** amostras de slot (abr/2026) permanecem. A causa "coast_decel @ 0x182ED0 → S24/S25" está **revogada**.  
**Dependência:** Binário corrigido (doc 20), mapeamento solenóide (doc 23), UDS security (doc 28)

## Correções posteriores (ler antes do resto)

| Trecho deste doc                                                 | Estado em 2026-10                                                                                                                                                                                                                                                                                                   | Fonte           |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `0x182ED0` = 7×22.0 km/h, root cause do 3→1, patch alvo          | **Revogado.** `22.0` é a 2ª word de outro objeto. O call em `0x87C20` passa `r3=0x187514` e grava `3FBC14`, não S24/S25.                                                                                                                                                                                            | docs 71, 72     |
| Disasm `lwz r3,0(r25)` / `ori r3,0x7514` / `bne loc_87C64`       | **Não é o que está na ROM.** O sítio real é `lhz 3FBBCC` @ `0x87BEC`, `cmpwi 0x26` @ `0x87BF0`, `addi r3,0x7514` @ `0x87C20`, normal em `0x87C70` (`r3=0x184218`).                                                                                                                                                  | doc 71          |
| S25=17 e S25=22 em coast vêm de tabelas `0x182xxx` / `0x182ED0`  | **Revogado para MODE=0.** S25 = `T5(12) + Y`, Y da 1D `0x185708` (Y=5 → 17, Y=10 → 22) com GATE `3FD48C=1`. Espelho `0x185750` alimenta S27.                                                                                                                                                                        | doc 50          |
| Patches T10/T11/T4 são o estado atual; falta patch em `0x182ED0` | **Histórico de abr/2026.** v5 aplicou T11 20→12, T10, T4 row3 23→18. v6.2 (doc 26) soma T4 rows 0–1 → 15.0 e zera Y de `185708`/`185750`. Não patchar `0x182ED0`.                                                                                                                                                   | docs 26, 50     |
| `3FBBCC` é u32 "mode selector = coast"                           | É **u16** (`sth`/`lhz`), ID de tipo de troca. `0x26` quando `3FC3AA≠0`. No cal_mod o índice `0x26` é no-op.                                                                                                                                                                                                         | docs 63, 69, 71 |
| Bitmask `{1,2,4,8}` = 1ª..4ª como fato de encoder                | Os **números** 1/2/4/8 nos logs são observação de campo. O encoder não prova sozinho que 1=1ª.                                                                                                                                                                                                                      | doc 63          |
| Formato "col0 = km/h, col1 = throttle"                           | O 1D compara o **primeiro** float do par como breakpoint e devolve o **segundo** (`0xBBDDC`/`0xBBDE8`). Nas tabelas abaixo o breakpoint mostrado é o throttle e o valor é a velocidade. O count está na word **anterior** ao endereço passado ao lookup; `lbz 0(r3)` no entry `0xBBDC8` lê o byte alto do ponteiro. | doc 72          |

---

## Resumo Executivo

1. **FATO:** 10 shift schedule tables em ROM @ 0x184B10–0x184EC4. Interpolação 1D em `0xBBDC8`, 2D em `0xBBE48` (o entry do wrapper é `0xBBE48`, não `0xBBE44`). A tabela citada como coast_decel @ `0x182ED0` **não** é o grid desse call — doc 72.
2. **FATO:** `shift_table_group_dispatcher` (0x9D860) e `shift_slot_eval_with_mode_switch` (0x872B4) selecionam um **grupo de tabelas** baseado em flags RAM e mode selector (0x3FBBCC) e escrevem thresholds em **6 slots RAM** (0x3FBC24-0x3FBC29).
3. **FATO:** `gear_zone_evaluator` (0x83484) consome os slots e determina o **gear target**, armazenado em RAM 0x3FC239.
4. **Observação de campo (abr/2026):** `0x3FC106` / `0x3FC239` usam os valores 1, 2, 4, 8. O rótulo 1ª..4ª é o que os logs assumiram. Doc 63: o encoder usa esse bitmask como eixo do ID de troca e **não** prova sozinho 1=1ª.
5. **FATO (live RAM):** Existem **3 grupos de slot distintos**, confirmados por leitura RAM em tempo real:

| Grupo            | Condição             | S24    | S25    | S27    | Origem ROM                                                                        |
| ---------------- | -------------------- | ------ | ------ | ------ | --------------------------------------------------------------------------------- |
| **Aceleração**   | INPUT > ~7%          | 17     | 12     | 12-21  | T4/T5/T10/T11 (0x184xxx)                                                          |
| **Coast normal** | INPUT=0, decel lenta | 19     | 17     | 17     | Tabelas 0x182xxx (G3)                                                             |
| **Coast rápido** | INPUT=0, decel forte | **24** | **22** | **22** | **T5(12)+Y=10** (`0x185708`) e espelho S27 (`0x185750`), GATE=1. Não é `0x182ED0` |

1. **FATO (live RAM, abr/2026):** com S25=22 e speed abaixo de S25 o evaluator pede o bitmask 1. A atribuição desse pacote 24/22 a `0x182ED0` está revogada (doc 50).

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
          │  byte_186750==3 → handler 0x92A4C            │
          │    (nome "coast_decel" é rótulo antigo)      │
          │      └→ 0x872B4                              │
          │           0x26 grava 3FBC14, não os slots    │
          │           S25/S27 de coast: doc 50           │
          │           (T5+Y em 185708 / 185750)          │
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
| SLOT??25     | 0x3FBC25 | T5 (2→1 DN) 12km/h @0%          | stb@0x9E208 | **T11 (3→2 DN) 20km/h @0%**  | stb@0x9E6A4 |
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

- **Amostra coast com GATE=1:** S27=22, S25=22 = T5/T7 base + Y=10 (`185708`/`185750`). A 20 km/h os dois compares falham e o evaluator pede bitmask 1. v6.2 zera esse Y.
- **Retomada:** S27=T7(15%)≈17. A 26 km/h: 26>=17 → FICA na 3ª (arrastando). Para 3→2, S27 precisa ser > speed.

### Funções de Lookup (ROM)

| Função              | EA      | Nome IDA                          | Papel                                                                                                |
| ------------------- | ------- | --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| 1D Lookup           | 0xBBDC8 | cal_1d_lookup_trampoline          | Busca linear em array de breakpoints float (é código, não data)                                      |
| 2D Wrapper          | 0xBBE48 | cal_2d_lookup_interpolate         | Entry real do wrapper. `0xBBE44` não é o alvo do `blrl`                                              |
| 2D Interpolation    | 0xBBEC8 | —                                 | Interpolação bilinear com 4 pontos adjacentes                                                        |
| Table Dispatcher    | 0x9D860 | shift_table_group_dispatcher      | 4972B, seleciona grupo e escreve slots RAM                                                           |
| Mode Switch         | 0x872B4 | shift_slot_eval_with_mode_switch  | `0x26` → `3FBC14 = 1D 0x181908 × 2D(r3=0x187514)`; senão `1D 0x184218 × 3FC148`. Não escreve S24–S29 |
| Threshold Compute   | 0x93510 | shift_threshold_compute_with_mode | 702 insns, despacha por mode_selector (byte_186750)                                                  |
| Coast Decel Handler | 0x92A4C | shift_mode3_coast_decel_handler   | Chamado quando mode_selector=3                                                                       |
| Coast Decel Counter | 0x926BC | shift_mode3_counter_state_machine | Counters em 0x3FC040/0x3FC409/0x3FC40A                                                               |
| Gear Evaluator      | 0x83484 | gear_zone_evaluator               | 1624B, consome slots, retorna target gear                                                            |
| Shift Evaluator     | 0x9F060 | shift_point_2d_eval_from_cal      | Chama 2D lookup com descriptors 0x186874/0x18AD70                                                    |
| Shift State Machine | 0xB1130 | shift_state_machine_transition    | 2520B, estados 0/1/2/3, consome ROM 0x189500+                                                        |
| Shift Calculator    | 0xB0740 | shift_schedule_evaluator          | 2544B, paralela a B1130                                                                              |

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

- S25=12, neste log, é T11 já patcheado 20→12 (v5). No AA stock T11@0% é 20. v6.2 não mexe em T11.
- S24=17 é T4@0% do v5 (17 km/h). v6.2 baixa as rows 0–1 de T4 para 15.0 (doc 26).

**Grupo COAST NORMAL** (INPUT=0, desaceleração lenta):

```
S24=19  S25=17  S26=28  S27=17  S28=42  S29=0
```

- S25=17 com GATE=1 é `T5(12)+Y=5` da 1D `0x185708` (doc 50), não uma tabela `0x182xxx`.

**Grupo COAST RÁPIDO** (INPUT=0, desaceleração forte / foot-off abrupto):

```
S24=24  S25=22  S26=28  S27=22  S28=42  S29=0
```

- S25=22 com GATE=1 é `T5(12)+Y=10` (`0x185708`). S27 segue o espelho `0x185750` (doc 50).
- `3FBBCC==0x26` **não** escreve estes slots. Esse tipo grava o canal `3FBC14` (doc 71).
- Amostra de campo: speed abaixo de S25=22 pede bitmask 1. A frase "origem = 0x182ED0" está revogada.

### Cadeia que este doc atribuía ao coast rápido — revogada

O bloco abaixo foi o disasm publicado em abr/2026. **Não confere com a ROM** (doc 71). Mantido só para não perder o rastro do erro.

```
; TEXTO ANTIGO, INCORRETO:
lwz     r3, 0(r25)
cmpwi   r3, 0x26
bne     loc_87C64
ori     r3, r3, 0x7514
```

O que a ROM faz em `0x872B4` está no doc 71: `3FBBCC==0x26` escolhe a 1D `0x181908` vezes a 2D chamada com `r3=0x187514`, e grava `**3FBC14**`. O normal (`!=0x26`) usa a 1D `0x184218` vezes `3FC148`, no mesmo store. Nenhum dos dois caminhos escreve S24/S25.

`0x182ED0` (`41 B0 00 00` = 22.0) não é o payload desse descritor (doc 72). S25=22 medido em coast é `12+10` do modifier `0x185708` (doc 50), não `22.0 × 1.09`.

---

### Formato da Tabela

Cada tabela de shift schedule consiste em:

```
[pares float BE]                 ; 1º = breakpoint, 2º = valor devolvido (0xBBDDC / 0xBBDE8)
[u32 com count no byte alto]    ; ex. 08 00 00 00, 4 bytes ANTES do endereço passado
[u32 pointer_to_data_start]     ; este é o endereço do lis/addi
[u32 0]
```

Nas tabelas T4–T13 deste doc o breakpoint é o throttle e o valor é a velocidade. A frase antiga "col0 = km/h, col1 = throttle" inverte o par. O entry `0xBBDC8` faz `lbz` no endereço passado (byte alto do ponteiro = 0); o count da cal está em `addr−4` (doc 72).

---

## Tabelas de Shift Schedule

> **NOTA:** Os "Grupos" abaixo refletem a função lógica original (upshift/downshift). No código, a atribuição é feita por `shift_table_group_dispatcher` que usa tabelas de **ambos** os grupos, reorganizadas por finalidade de avaliação (ver mapeamento de slots acima).

### Tabelas de Upshift (velocidade ACIMA do threshold → sobe marcha)

#### Table 4 — 1→2 Upshift (0x184B10) — Footer: 0x184B68

**Papel no código:** Group 1 → SLOT_1_2. Valores abaixo são o AA de origem. v6.2 grava 15.0 nas rows 0 e 1 (0x184B10 e 0x184B18).

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

**Papel no código:** Group 1 → SLOT*??25. Group 3 → SLOT*??25. Define "piso mínimo de 2ª marcha" durante upshift eval. Abaixo de T5 → target=1ª.

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

**Papel no código:** Group 2 → **SLOT??25**. Define "piso mínimo de 2ª marcha" durante **downshift eval**. Abaixo de T11 → target=**1ª** (não 2ª!).

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

**AA stock:** T11@0% = 20. v5 já gravou 12 nessas rows. O 17/22 visto em coast depois disso não é T11; é T5(12)+Y (doc 50). O compare `speed < S25 → bitmask 1` no evaluator permanece.

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

**Papel no código:** Usado no cálculo inicial de f29/f30 em `shift_table_group_dispatcher` (0x9DA34). Group 3 → SLOT??25 ou SLOT_3_2a.

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

Estado atual da cal, não deste texto de abr/2026: **doc 26**.

- v5: T11 20→12, T10, T4 row 3 (23→18). T5 permanece 12.
- v6.2: v5 + T4 rows 0–1 → 15.0 + Y=0 em `0x185708` e `0x185750` (doc 50). O 22/17 de S25 em coast era esse Y, não `0x182ED0`.
- **Não aplicar** o "Patch 4" deste doc em `0x182ED0`.

Subir T11 amplia a zona do bitmask 1. Isso continua válido (doc 26).

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

| EA      | Nome IDA                            | Tamanho | Papel                                                     |
| ------- | ----------------------------------- | ------- | --------------------------------------------------------- |
| 0x83484 | **gear_zone_evaluator** ✅          | 1624B   | Consome slots RAM, retorna target gear (1/2/8) → 0x3FC239 |
| 0x9D860 | **shift_table_group_dispatcher** ✅ | 4972B   | Seleciona grupo de tabelas, escreve slots RAM 0x3FBC24-29 |
| 0xBBDC8 | qword_BBDC8                         | —       | 1D lookup (trampolim, chamado via blrl)                   |
| 0xBBE48 | cal_2d_lookup_interpolate           | —       | 2D wrapper. Entry do `blrl` (não `0xBBE44`)               |
| 0xBBEC8 | —                                   | —       | 2D interpolação bilinear                                  |
| 0x9F060 | shift_point_2d_eval_from_cal        | —       | Chama 2D lookup com descriptors 0x186874/0x18AD70         |
| 0xB1130 | shift_state_machine_transition      | 2520B   | Estados 0/1/2/3, comparações float vs ROM 0x189500+       |
| 0xB0740 | shift_schedule_evaluator            | 2544B   | Paralela a B1130                                          |
| 0xB1E48 | shift_ratio_guard_eval              | —       | Guard de ratio                                            |

### RAM Slots e Variáveis Documentados

| Endereço | Nome            | Tipo | Papel                                                                 |
| -------- | --------------- | ---- | --------------------------------------------------------------------- |
| 0x3FBC24 | S24 / SLOT_1_2  | byte | Threshold 1↔2 (T4 ou T10). Coast com GATE soma outro caminho (doc 50) |
| 0x3FBC25 | S25 / SLOT??25  | byte | T5 ou T11, mais Y de `0x185708` quando GATE=1                         |
| 0x3FBC26 | S26 / SLOT_2_3  | byte | Threshold 2↔3 (T6, T12)                                               |
| 0x3FBC27 | S27 / SLOT_3_2a | byte | T7 ou T13, mais Y de `0x185750` quando GATE=1                         |
| 0x3FBC28 | S28 / SLOT_FLAG | byte | Flag/threshold alto (T8/T9)                                           |
| 0x3FBC29 | S29 / SLOT_CNT  | byte | 1 no log de aceleração, 0 no log de coast. Não é o tipo `0x26`        |
| 0x3FBBCC | shift type id   | u16  | `sth` em `0x86BB0`. `0x26` se `3FC3AA≠0`. Não escreve estes slots     |
| 0x3FC106 | gear_current    | byte | Marcha atual (bitmask: 1/2/4/8)                                       |
| 0x3FC239 | gear_target     | byte | Gear target (bitmask: 1/2/4/8)                                        |
| 0x3FC359 | group3_flag     | byte | Flag lida no dispatcher. Não é o bit que seleciona `0x182ED0`         |
| 0x3FC372 | group_flag      | byte | Flag de grupo de shift                                                |
| 0x3FD493 | vehicle_speed   | byte | Velocidade atual (km/h)                                               |
