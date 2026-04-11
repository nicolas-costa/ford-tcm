# 24 — Shift Schedule Tables: Extração e Mapeamento Completo

**Data:** 2026-03-22  
**Status:** ✅ 10 tabelas de shift schedule decodificadas. Causa raiz do comportamento "preso em 3ª" identificada.  
**Dependência:** Binário corrigido (doc 20), mapeamento solenóide (doc 23)

---

## Resumo Executivo

1. **FATO:** 10 shift schedule tables localizadas em ROM @ 0x184B10-0x184EC4. Formato: pares (speed_km/h, throttle_%) com count=11 rows cada. Interpolação feita via 2D lookup em `sub_BBE44` (ROM @ 0xBBE44).
2. **FATO:** A tabela de **downshift 3→2** (Table 11 @ 0x184DB0) tem threshold FIXO em 20.0 km/h para 0-85% throttle — causa raiz do "ficar preso em 3ª marcha de 20 a 60 km/h" reportado.
3. **FATO:** A state machine de shift está em `sub_B1130` (0xB1130, 2520 bytes) com estados 0/1/2/3 e comparações float contra calibração ROM 0x189500+.
4. **Próximo passo:** Para corrigir o comportamento, modificar os valores 20.0 em 0x184DB0 para ~30.0 km/h (aumentar zona de downshift 3→2).

---

## Arquitetura do Lookup

### Funções de Lookup (ROM)

| Função | EA | Papel |
|--------|-----|-------|
| 1D Lookup | 0xBBDC8 | Busca linear em array de breakpoints float (IDA: `qword_BBDC8`, é código) |
| 2D Wrapper | 0xBBE44 (`sub_BBE44`) | Chama 1D lookup para cada eixo, depois interpola 2D |
| 2D Interpolation | 0xBBEC8 | Interpolação bilinear com 4 pontos adjacentes |
| Shift Evaluator | 0x9F060 (`sub_9F060`) | Chama 2D lookup com tabelas ROM (0x186874, 0x18AD70) |
| Shift State Machine | 0xB1130 (`sub_B1130`) | 2520B, estados 0/1/2/3, leaf function (zero BL calls) |
| Shift Calculator | 0xB0740 (`sub_B0740`) | 2544B, leaf function paralela a B1130 |

### Formato da Tabela

Cada tabela de shift schedule consiste em:

```
[N pairs de (speed_float, throttle_float)]  — N = count (7 ou 11)
[u32 count]                                  — 0x07 ou 0x0B
[u32 pointer_to_data_start]                  — auto-referencial
[u32 null/padding]
```

- **Coluna 0:** Speed threshold em km/h (float32 big-endian)
- **Coluna 1:** Throttle breakpoint em % (float32 big-endian, 0.0-99.6%)
- **Interpretação:** "Se throttle <= col1, o threshold de velocidade para esta transição é col0"

---

## Tabelas de Shift Schedule

### Grupo 1: Upshift Tables (velocidade ACIMA do threshold → sobe marcha)

#### Table 4 — 1→2 Upshift (0x184B10)

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

#### Table 6 — 2→3 Upshift (0x184BD0)

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

#### Table 8 — 3→4 Upshift (0x184C90)

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

### Grupo 2: Downshift Tables (velocidade ABAIXO do threshold → desce marcha)

#### Table 5 — 2→1 Downshift (0x184B70)

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

#### Table 11 — 3→2 Downshift ⚠️ (0x184DB0) — CAUSA RAIZ

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

**⚠️ PROBLEMA:** De 0% a 85% throttle, o downshift 3→2 SÓ acontece abaixo de 20 km/h.
Isso significa que em aceleração leve (~15% throttle), o carro fica em 3ª de 20 km/h até ~46 km/h (upshift 3→4).

#### Table 10 — (Possível) 2→1 Alt ou TCC-related (0x184D50)

| Throttle % | Speed km/h |
|-----------|-----------|
| 0 | 23 |
| 0 | 23 |
| 12 | 23 |
| 20 | 23 |
| 39 | 23 |
| 59 | 28 |
| 80 | 39 |
| 93 | 56 |
| 93 | 56 |
| 99.6 | 57 |

#### Table 12 — 4→3 Downshift (0x184E10)

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

#### Table 13 — (Possível) 3→2 Alt ou TCC-related (0x184E70)

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

### Grupo 3: Tabelas Auxiliares

#### Table 7 — (Possível) TCC Engage ou 1→2 Alt (0x184C30)

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

#### Table 9 — (Possível) TCC/3→4 Alt (0x184CF0)

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

### "Fica em 3ª de 20 a 60 km/h com aceleração leve"

```
Cenário: throttle ~15%, velocidade 25 km/h, marcha atual = 3ª

Downshift 3→2 (Table 11): threshold = 20 km/h @ 15% throttle
  → 25 > 20 → NÃO desce para 2ª ✓ (confirma o sintoma)

Upshift 3→4 (Table 8): threshold = 40 km/h @ 6% throttle → 46 km/h @ 20% throttle
  → 25 < 40-46 → NÃO sobe para 4ª ✓

Resultado: PRESO EM 3ª entre 20 e ~45 km/h
```

### "Retomada de 20 a 60 km/h em 3ª com pouca intensidade"

Mesmo cenário: com throttle baixo, o carro literalmente não pode sair de 3ª porque:
- 3→2 threshold = 20 km/h (muito baixo)
- 3→4 threshold = 40-46 km/h (razoável, mas longe)

A **banda morta** de 3ª marcha é de 20 km/h a ~45 km/h em throttle leve — exatamente o reportado.

### Proposta de Correção

Modificar Table 11 @ **0x184DB0** (3→2 downshift):

| Original | Proposta | Efeito |
|----------|----------|--------|
| 20.0 km/h (0-85% throttle) | 30.0 km/h | Downshift 3→2 a 30 km/h em aceleração leve |

Bytes a alterar no binário:

```
Offset 0x184DB0: 41 E0 00 00 → 41 F0 00 00  (20.0 → 30.0)
                  repetir para as 7 instâncias de 20.0 na tabela
```

**float32 big-endian 30.0 = 0x41F00000**

⚠️ ATENÇÃO: Alterar APENAS os valores de 20.0. Os valores de 31.0, 35.0, 53.0 (WOT) devem permanecer inalterados.

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

## Funções Identificadas (para renomear no IDA)

| EA | Nome Atual | Nome Proposto |
|----|-----------|--------------|
| 0xBBE44 | sub_BBE44 | cal_2d_lookup_interpolate |
| 0xB1130 | sub_B1130 | shift_state_machine_transition |
| 0xB0740 | sub_B0740 | shift_schedule_evaluator |
| 0x9F060 | sub_9F060 | shift_point_2d_eval_from_cal |
| 0xB1E48 | sub_B1E48 | shift_ratio_guard_eval |
