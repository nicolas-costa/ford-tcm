# 24 — Shift Schedule Tables: Extração, Mapeamento e Arquitetura de Decisão

**Data:** 2026-03-22 (atualizado com arquitetura de slots e gear_zone_evaluator)  
**Status:** ✅ 10 tabelas decodificadas. Arquitetura completa de decisão de marcha mapeada via disassembly.  
**Dependência:** Binário corrigido (doc 20), mapeamento solenóide (doc 23)

---

## Resumo Executivo

1. **FATO:** 10 shift schedule tables localizadas em ROM @ 0x184B10-0x184EC4. Formato: pares (speed_km/h, throttle_%) com count=11 rows cada. Interpolação feita via 1D lookup em `qword_BBDC8` (ROM @ 0xBBDC8).
2. **FATO:** `shift_table_group_dispatcher` (0x9D860, 4972B) seleciona um **grupo de tabelas** (upshift ou downshift) baseado em flags RAM e escreve thresholds em **6 slots RAM** (0x3FBC24-0x3FBC29).
3. **FATO:** `gear_zone_evaluator` (0x83484, 1624B) consome os slots e determina o **gear target** (1, 2, ou 8), armazenado em RAM 0x3FC239.
4. **FATO:** Para marcha atual = 3, a decisão 1ª vs 2ª depende **exclusivamente** de SLOT_??25: `speed < SLOT_??25 → target=1, speed >= SLOT_??25 → target=2`.
5. **FATO:** No Group 2 (downshift), **T11 preenche SLOT_??25 (20 km/h @0%)** e **T10 preenche SLOT_1_2 (23 km/h @0%)**. A 17.6 km/h em coasting: `17.6 < 20 → target=1 → 3→1 direto` (confirmado por FORScan). Uma vez em 1ª, preso até 23 km/h (T10).

---

## Arquitetura de Decisão de Marcha

### Pipeline completo (FATO — assembly verificado)

```
                   ┌─────────────────────────┐
                   │  RAM flags (0x3FC3F0,    │
                   │  0x3FC392, 0x3FC372...)  │
                   └──────────┬──────────────┘
                              │ selecionam grupo
                              ▼
              ┌──────────────────────────────────┐
              │  shift_table_group_dispatcher     │
              │  (0x9D860, 4972 bytes)           │
              │                                  │
              │  Group 1 (upshift):              │
              │    T8→SLOT_FLAG, T6→SLOT_2_3,    │
              │    T5→SLOT_??25, T4→SLOT_1_2     │
              │                                  │
              │  Group 2 (downshift):            │
              │    T12→SLOT_2_3, T13→SLOT_3_2a,  │
              │    T10→SLOT_1_2, T11→SLOT_??25   │
              │                                  │
              │  Group 3 (variant upshift):      │
              │    T6,T7,T4,T5→slots             │
              └──────────┬───────────────────────┘
                         │ escreve 6 bytes em RAM
                         ▼
              ┌──────────────────────────────┐
              │  Slots RAM 0x3FBC24-0x3FBC29 │
              │  (speed thresholds, byte)    │
              └──────────┬───────────────────┘
                         │ lidos por
                         ▼
              ┌──────────────────────────────────┐
              │  gear_zone_evaluator              │
              │  (0x83484, 1624 bytes)           │
              │                                  │
              │  Lê gear atual de RAM 0x3FC106   │
              │  Compara speed (0x3FD493) vs     │
              │  slots                           │
              │  Retorna target gear: 1, 2 ou 8  │
              │  Grava em RAM 0x3FC239           │
              └──────────────────────────────────┘
```

### Mapeamento de Slots por Grupo (FATO — endereços verificados em assembly)

| Slot | RAM | Group 1 (Upshift) | Addr Group1 | Group 2 (Downshift) | Addr Group2 |
|------|-----|-------------------|-------------|---------------------|-------------|
| SLOT_1_2 | 0x3FBC24 | T4 (1→2 UP) 17km/h @0% | stb@0x9E23C | **T10 (2→1 alt) 23km/h @0%** | stb@0x9E404 |
| SLOT_??25 | 0x3FBC25 | T5 (2→1 DN) 12km/h @0% | stb@0x9E208 | **T11 (3→2 DN) 20km/h @0%** | stb@0x9E6A4 |
| SLOT_2_3 | 0x3FBC26 | T6 (2→3 UP) | stb@0x9E1D4 | T12 (4→3 DN) | stb@0x9E3A4 |
| SLOT_3_2a | 0x3FBC27 | T7 (TCC/alt) | — | T13 (3→2 alt) | stb@0x9E3D4 |
| SLOT_FLAG | 0x3FBC28 | T8/T9 | — | — | — |
| SLOT_CNT | 0x3FBC29 | — | — | — | — |

### Lógica do gear_zone_evaluator para gear=3 (FATO — disasm 0x83484)

```
Para gear atual = 3:
  1. Skipa check 2→3 (gear > 2)       @ 0x83848: bgt
  2. Skipa check 3→4 (gear < 4)       @ 0x83878: blt
  3. Cai no eval 1↔2:
     - Lê speed byte de RAM 0x3FD493
     - Lê SLOT_??25 de RAM 0x3FBC25
     - Se speed >= SLOT_??25 → target = 2  (loc_83AC0)
     - Se speed <  SLOT_??25 → target = 1  (0x838D4: li r3, 1)
  4. Grava target em RAM 0x3FC239      @ 0x83AD0: stb r3

Para gear atual = 1:
  - Usa SLOT_1_2 (não SLOT_??25)
  - Se speed >= SLOT_1_2 → target = 2 (pode sair de 1ª)
  - Se speed <  SLOT_1_2 → target = 1 (preso em 1ª)
```

**Consequência direta:** No Group 2, `SLOT_??25 = T11 = 20 km/h` e `SLOT_1_2 = T10 = 23 km/h`. A 17.6 km/h: `17.6 < 20 → target=1 → 3→1 direto`. Uma vez em 1ª: `17.6 < 23 → preso até 23 km/h`.

### Funções de Lookup (ROM)

| Função | EA | Nome IDA | Papel |
|--------|-----|----------|-------|
| 1D Lookup | 0xBBDC8 | qword_BBDC8 | Busca linear em array de breakpoints float (é código, não data) |
| 2D Wrapper | 0xBBE44 | cal_2d_lookup_interpolate | Chama 1D lookup para cada eixo, depois interpola 2D |
| 2D Interpolation | 0xBBEC8 | — | Interpolação bilinear com 4 pontos adjacentes |
| Table Dispatcher | 0x9D860 | shift_table_group_dispatcher | 4972B, seleciona grupo e escreve slots RAM |
| Gear Evaluator | 0x83484 | gear_zone_evaluator | 1624B, consome slots, retorna target gear |
| Shift Evaluator | 0x9F060 | shift_point_2d_eval_from_cal | Chama 2D lookup com tabelas ROM (0x186874, 0x18AD70) |
| Shift State Machine | 0xB1130 | shift_state_machine_transition | 2520B, estados 0/1/2/3, consome ROM 0x189500+ |
| Shift Calculator | 0xB0740 | shift_schedule_evaluator | 2544B, paralela a B1130 |

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
|-----------|-----------|
| 0 | 17 |
| 12 | 17 |
| 20 | 17 |
| 25 | 23 |
| 39 | 27 |
| 59 | 32 |
| 80 | 39 |
| 93 | 56 |
| 93 | 56 |
| 99.6 | 57 |

#### Table 6 — 2→3 Upshift (0x184BD0) — Footer: 0x184C28
**Papel no código:** Group 1 → SLOT_2_3. Group 3 → SLOT_2_3.

| Throttle % | Speed km/h |
|-----------|-----------|
| 8 | 28 |
| 12 | 28 |
| 25 | 34 |
| 39 | 49 |
| 54 | 61 |
| 68 | 74 |
| 88 | 87 |
| 93 | 105 |
| 93 | 105 |
| 99.6 | 108 |

#### Table 8 — 3→4 Upshift (0x184C90) — Footer: 0x184CE8
**Papel no código:** Group 1 → SLOT_FLAG.

| Throttle % | Speed km/h |
|-----------|-----------|
| 6 | 40 |
| 12 | 40 |
| 20 | 46 |
| 29 | 59 |
| 39 | 73 |
| 55 | 86 |
| 59 | 109 |
| 70 | 115 |
| 78 | 135 |
| 99.6 | 154 |

### Tabelas de Downshift (velocidade ABAIXO do threshold → desce marcha)

#### Table 5 — 2→1 Downshift (0x184B70) — Footer: 0x184BC8
**Papel no código:** Group 1 → SLOT_??25. Group 3 → SLOT_??25. Define "piso mínimo de 2ª marcha" durante upshift eval. Abaixo de T5 → target=1ª.

| Throttle % | Speed km/h |
|-----------|-----------|
| 0 | 12 |
| 6 | 12 |
| 20 | 12 |
| 45 | 12 |
| 50 | 12 |
| 60 | 12 |
| 85 | 16 |
| 93 | 31 |
| 93 | 35 |
| 99.6 | 53 |

#### Table 11 — 3→2 Downshift ⚠️ (0x184DB0) — Footer: 0x184E08 — ROOT CAUSE #1
**Papel no código:** Group 2 → **SLOT_??25**. Define "piso mínimo de 2ª marcha" durante **downshift eval**. Abaixo de T11 → target=**1ª** (não 2ª!).

| Throttle % | Speed km/h |
|-----------|-----------|
| **0** | **20** |
| **0** | **20** |
| **0** | **20** |
| **20** | **20** |
| **39** | **20** |
| **60** | **20** |
| **85** | **20** |
| 93 | 31 |
| 93 | 35 |
| 99.6 | 53 |

**⚠️ ROOT CAUSE:** No `gear_zone_evaluator`, para gear=3: `speed < SLOT_??25 → target=1`. Com T11=20km/h, qualquer velocidade abaixo de 20 km/h em coasting → **target é 1ª marcha** (skip direto 3→1). Confirmado por FORScan: 3→1 @ 17.6 km/h em Closed Throttle.

**Semântica real (provada por código):** T11 NÃO é simplesmente "3→2 downshift threshold". Na prática, o evaluator usa T11 como fronteira entre zona de 1ª e zona de 2ª. Abaixo de T11 → 1ª é o target.

#### Table 10 — 2→1 Alt ⚠️ (0x184D50) — Footer: 0x184DA8 — ROOT CAUSE #2 (trapping)
**Papel no código:** Group 2 → **SLOT_1_2**. Define "velocidade mínima para sair de 1ª" durante **downshift eval**. Abaixo de T10 e já em 1ª → **preso em 1ª**.

| Throttle % | Speed km/h |
|-----------|-----------|
| **0** | **23** |
| **0** | **23** |
| **12** | **23** |
| **20** | **23** |
| **39** | **23** |
| 59 | 28 |
| 80 | 39 |
| 93 | 56 |
| 93 | 56 |
| 99.6 | 57 |

**⚠️ TRAPPING:** Uma vez em 1ª (causado por T11), `gear_zone_evaluator` usa SLOT_1_2 = T10 para avaliar se pode sair. Com T10=23 @0%: `17.6 < 23 → target=1 → preso até 23 km/h`. Gap morto entre T11(20) e T10(23) = zona sem 2ª marcha acessível.

#### Table 12 — 4→3 Downshift (0x184E10) — Footer: 0x184E68
**Papel no código:** Group 2 → SLOT_2_3.

| Throttle % | Speed km/h |
|-----------|-----------|
| 8 | 50 |
| 12 | 50 |
| 20 | 50 |
| 39 | 50 |
| 54 | 50 |
| 68 | 72 |
| 88 | 87 |
| 93 | 105 |
| 93 | 105 |
| 99.6 | 108 |

#### Table 13 — 3→2 Alt (0x184E70) — Footer: 0x184EC8
**Papel no código:** Group 2 → SLOT_3_2a. Boundary entre 3ª e 4ª zona no downshift eval.

| Throttle % | Speed km/h |
|-----------|-----------|
| 0 | 44 |
| 6 | 44 |
| 12 | 44 |
| 20 | 44 |
| 29 | 44 |
| 45 | 44 |
| 83 | 44 |
| 93 | 89 |
| 93 | 89 |
| 99.6 | 99 |

### Tabelas Auxiliares / Group 3

#### Table 7 — 1→2 Alt (0x184C30) — Footer: 0x184C88
**Papel no código:** Usado no cálculo inicial de f29/f30 em `shift_table_group_dispatcher` (0x9DA34). Group 3 → SLOT_??25 ou SLOT_3_2a.

| Throttle % | Speed km/h |
|-----------|-----------|
| 6 | 12 |
| 6 | 12 |
| 12 | 14 |
| 20 | 19 |
| 29 | 25 |
| 51 | 34 |
| 83 | 56 |
| 93 | 89 |
| 93 | 89 |
| 99.6 | 99 |

#### Table 9 — 3→4 Alt (0x184CF0) — Footer: 0x184D48
**Papel no código:** Group 1 → SLOT_FLAG ou SLOT_CNT (cálculo paralelo a T8).

| Throttle % | Speed km/h |
|-----------|-----------|
| 0 | 28 |
| 0 | 28 |
| 12 | 28 |
| 15 | 28 |
| 38 | 34 |
| 54 | 70 |
| 78 | 93 |
| 93 | 130 |
| 93 | 130 |
| 99.6 | 144 |

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

**Movida para doc 26 (patch-proposal-revised.md).** Ver doc 26 para análise detalhada de patches em T10 e T11.

**⚠️ ALERTA:** A proposta anterior (T11 20→30 km/h uniforme) e a proposta ChatGPT (T11 subir com throttle) são **AMBAS INCORRETAS** — baseadas na interpretação errada de que T11 é "threshold para downshift 3→2". Na realidade, o `gear_zone_evaluator` usa T11 como **piso mínimo para 2ª marcha**: subir T11 = AMPLIAR zona de 1ª = PIORAR o problema.

---

## Dados Adicionais Encontrados

### Gear Ratios (0x189700)

Grupos de 3 (nominal, max, min):

| Grupo | Nominal | Max | Min | Possível Significado |
|-------|---------|-----|-----|---------------------|
| 1 | 4.22 | 4.31 | 4.19 | 1ª × final drive |
| 2 | 2.53 | 2.56 | 2.53 | 2ª × final drive |
| 3 | 1.66 | 1.69 | 1.62 | 3ª × final drive |
| 4 | 1.22 | 1.25 | 1.19 | 4ª × final drive |
| 5 | 1.00 | 1.06 | 1.00 | Direct (ref) |
| 6 | 0.70 | 0.94 | 1.00 | Reverse/overdrive |

### Torque Converter Curve (0x18AD10)

Stall ratio: 2.117. Speed ratio vs torque ratio (8 pontos):

| Speed Ratio | Torque Ratio |
|------------|-------------|
| 0.10 | 1.994 |
| 0.20 | 1.861 |
| 0.30 | 1.740 |
| 0.40 | 1.606 |
| 0.50 | 1.468 |
| 0.60 | 1.324 |
| 0.70 | 1.189 |
| 0.80 | — |

---

## Funções Identificadas (renomeadas no IDA)

| EA | Nome IDA | Tamanho | Papel |
|----|----------|---------|-------|
| 0x83484 | **gear_zone_evaluator** ✅ | 1624B | Consome slots RAM, retorna target gear (1/2/8) → 0x3FC239 |
| 0x9D860 | **shift_table_group_dispatcher** ✅ | 4972B | Seleciona grupo de tabelas, escreve slots RAM 0x3FBC24-29 |
| 0xBBDC8 | qword_BBDC8 | — | 1D lookup (trampolim, chamado via blrl) |
| 0xBBE44 | cal_2d_lookup_interpolate | — | 2D wrapper (chama 1D + interpola) |
| 0xBBEC8 | — | — | 2D interpolação bilinear |
| 0x9F060 | shift_point_2d_eval_from_cal | — | Chama 2D lookup com descriptors 0x186874/0x18AD70 |
| 0xB1130 | shift_state_machine_transition | 2520B | Estados 0/1/2/3, comparações float vs ROM 0x189500+ |
| 0xB0740 | shift_schedule_evaluator | 2544B | Paralela a B1130 |
| 0xB1E48 | shift_ratio_guard_eval | — | Guard de ratio |

### RAM Slots Documentados

| Endereço | Offset de 0x400000 | Nome | Papel |
|----------|-------------------|------|-------|
| 0x3FBC24 | -0x43DC | SLOT_1_2 | Threshold 1↔2 (T4 ou T10) |
| 0x3FBC25 | -0x43DB | SLOT_??25 | Piso mínimo para 2ª (T5 ou T11) |
| 0x3FBC26 | -0x43DA | SLOT_2_3 | Threshold 2↔3 (T6 ou T12) |
| 0x3FBC27 | -0x43D9 | SLOT_3_2a | Threshold 3↔4 (T7 ou T13) |
| 0x3FBC28 | -0x43D8 | SLOT_FLAG | Flag/threshold alto (T8/T9) |
| 0x3FBC29 | -0x43D7 | SLOT_CNT | Contador/threshold secundário |
| 0x3FC106 | -0x3EFA | — | Marcha atual (byte, lido por gear_zone_evaluator) |
| 0x3FC239 | -0x3DC7 | — | Gear target output (byte, escrito por gear_zone_evaluator) |
| 0x3FD493 | -0x2B6D | — | Velocidade atual (byte, km/h) |
