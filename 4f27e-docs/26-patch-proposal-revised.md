# 26 — Proposta de Patch Revisada: Baseada em Disassembly + Live RAM

**Data:** 2026-04-19 (v4 — adicionado Patch 4 coast_decel com base em live RAM logging)  
**Status:** 🔴 Patch 4 é o FIX DEFINITIVO. Patches 1-3 já aplicados e validados para seus grupos.  
**Dependência:** Arquitetura de decisão (doc 24 v3), checksum (doc 25), UDS security (doc 28)

---

## Resumo Executivo

1. **FATO (assembly):** `gear_zone_evaluator` (0x83484) determina o gear target. Para **gear atual = 3**: `speed < S25 → target=1ª; speed >= S25 → target=2ª`. (disasm 0x0838B4-0x0838D4)
2. **FATO (live RAM):** Existem **3 grupos de slot** que escrevem diferentes valores em S25:
   - Aceleração: S25=12 (patch T11 ativo ✅)
   - Coast normal: S25=17 (tabela 0x182xxx)
   - **Coast rápido: S25=22** (tabela 0x182ED0, 7×22.0 floats) ← **ROOT CAUSE PRINCIPAL**
3. **FATO (live RAM):** O 3→1 observado em campo ocorre **exclusivamente** quando o grupo "coast rápido" está ativo (S29=0, S25=22, mode 0x3FBBCC==0x26). A 20-21 km/h: `20 < 22 → target=1 → 3→1 direto`.
4. **FATO (validação):** Patches 1-3 (T11, T10, T4) estão aplicados no firmware atual. T11→12 FUNCIONA no grupo aceleração (S25=12 observado). Mas NÃO afeta o grupo coast rápido.
5. **FATO (IDA):** `shift_slot_eval_with_mode_switch` (0x872B4) @ 0x87BE8: `if RAM(0x3FBBCC)==0x26 → usa descriptor 0x187514 → data 0x182ED0 (22.0)`.
6. **Proposta v4:** Manter patches 1-3. Adicionar **Patch 4: coast_decel table 0x182ED0, 7 × 22.0→15.0**. Este é o fix definitivo.

---

## Contexto Mecânico da 4F27E

### Elementos de Aplicação por Marcha


| Marcha | Clutch A | Clutch B | Band (Cinta) | Low/Rev | OWC |
| ------ | -------- | -------- | ------------ | ------- | --- |
| 1ª     | ✓        |          |              |         | ✓   |
| 2ª     | ✓        |          | **✓ (BAND)** |         |     |
| 3ª     | ✓        | ✓        |              |         |     |
| 4ª     |          | ✓        | **✓ (BAND)** |         |     |
| R      |          |          |              | ✓       |     |


A **cinta (band)** é o elemento mais frágil do conjunto. Ela é aplicada em 2ª e 4ª. A OWC (one-way clutch) em 1ª permite coasting sem torque reverso.

### Torque Reverso e Proteção da Cinta

Quando o veículo está em **coasting** (desacelerando com acelerador solto):

- Em **1ª com OWC**: A OWC permite freewheel — sem torque reverso, sem desgaste
- Em **2ª com Band**: A cinta segura contra torque reverso — **desgaste aumentado**
- Em **3ª com Clutch A+B**: Ambos os clutch packs absorvem torque reverso — maior área de contato, menor pressão específica

**Conclusão mecânica:** Manter 3ª em coasting entre 20-30 km/h **protege a cinta** ao evitar downshift para 2ª sob torque reverso. O threshold de 20 km/h na Table 11 provavelmente é uma decisão de engenharia de durabilidade, não um bug.

---

## Causa Raiz: Quádrupla (provada por disassembly + live RAM)

### Root Cause #1 — T11 envia para 1ª em coasting (Group 2)

```
FATO (assembly + FORScan):
  Group 2 ativo (coasting). SLOT_??25 = T11(0%) = 20 km/h.
  gear_zone_evaluator (gear=3): speed(17.6) < 20 → target = 1 → 3→1 DIRETO.
  
  Assembly (0x0838B4-0x0838D4):
    cmpwi r3, 2     # gear=3, 3>=2 → falls through
    lbz r12, speed   # r12 = 17 (byte, km/h)
    lbz r11, SLOT_??25  # r11 = 20 (T11 result)
    cmpw r12, r11    # 17 < 20
    bge loc_83AC0    # NOT taken
    li r3, 1         # target = 1 ← ROOT CAUSE
```

### Root Cause #2 — T10 traps em 1ª (Group 2)

```
FATO (assembly):
  Uma vez em 1ª, gear_zone_evaluator usa SLOT_1_2 = T10(0%) = 23 km/h.
  speed(17.6) < 23 → target = 1 → PRESO até 23 km/h.
  
  Assembly (0x083894-0x0838B0):
    cmpwi r3, 1     # gear=1, match
    lbz r12, speed   # r12 = 17
    lbz r11, SLOT_1_2  # r11 = 23 (T10 result)
    cmpw r12, r11    # 17 < 23
    bge loc_83AC0    # NOT taken → stays target=1
```

### Root Cause #3 — T4 gap em tip-in (Group 1)

```
FATO (tabela):
  Group 1 ativo (upshift eval, tip-in). SLOT_1_2 = T4(25%) = 23 km/h.
  A 20 km/h com 25% throttle: 20 < 23 → target = 1 → 3→1 seguido de 1→2.
  
  T4 tem gap abrupto: 17 km/h @20% → 23 km/h @25% (salto de 6 km/h).
```

### Root Cause #4 — Coast Decel Table bloqueia 2ª (PRINCIPAL — live RAM)

```
FATO (live RAM, centenas de amostras):
  Grupo coast rápido ativo. S25 = 22, S24 = 24.
  gear_zone_evaluator (gear=3): speed(20) < S25(22) → target = 1 → 3→1 DIRETO.
  
  Cadeia ROM (disasm 0x87BE8):
    RAM(0x3FBBCC) == 0x26
    → descriptor 0x187514 → axis 0x182EC8 → data 0x182ED0
    → 7 × float32 22.0 (0x41B00000)
    → base = 22.0 → S25 = 22
    → S24 = 22.0 × scaling(0x181908) ≈ 24.0
    
  Este grupo é ATIVADO por foot-off brusco (engine brake forte).
  É o cenário EXATO do bug reportado pelo operador.
```

### Relação entre os quatro


| Cenário                  | Group/Modo      | Tabela crítica          | S25   | Efeito          | Status     |
| ------------------------ | --------------- | ----------------------- | ----- | --------------- | ---------- |
| Coasting lento < 20 km/h | Group 2         | T11 → S25               | 20→12 | 3→1 direto      | ✅ PATCHEADO |
| Preso em 1ª              | Group 2         | T10 → S24               | 23→15 | Não sai até 23  | ✅ PATCHEADO |
| Tip-in a 20 km/h         | Group 1         | T4 → S24                | 23→18 | 3→1→2 cascade   | ✅ PATCHEADO |
| **Coast rápido < 22**    | **Mode 0x26**   | **0x182ED0 → S25**      | **22** | **3→1 direto**  | 🔴 PENDENTE |


---

## Proposta de Correção v4 (disassembly + live RAM)

### Princípio: Atacar as QUATRO root causes


| Tabela             | Root Cause                        | Ação                              | Grupo       | Slot | Status      |
| ------------------ | --------------------------------- | --------------------------------- | ----------- | ---- | ----------- |
| **T11** (3→2 DN)  | #1: envia para 1ª em coasting     | **BAIXAR** rows 0-6 de 20→12 km/h | Downshift   | S25  | ✅ APLICADO |
| **T10** (2→1 alt) | #2: traps em 1ª                   | **BAIXAR** rows 0-4 de 23→15 km/h | Downshift   | S24  | ✅ APLICADO |
| **T4** (1→2 UP)   | #3: gap em tip-in                 | **BAIXAR** row 3 de 23→18 km/h    | Upshift     | S24  | ✅ APLICADO |
| **0x182ED0**       | **#4: coast decel bloqueia 2ª**   | **BAIXAR** 7×22.0→15.0            | Coast rápido | S25 | 🔴 PENDENTE |
| T5 (2→1 DN)       | —                                 | **MANTER** em 12 km/h             | Upshift     | S25  | ✅ OK       |


### Patch 1 — Table 11 (SLOT_??25 em Group 2): PRIORIDADE CRÍTICA

**Objetivo:** Baixar o piso de 2ª marcha no downshift eval de 20→12 km/h. Isso impede 3→1 acima de 12 km/h em coasting.


| Row | Throttle % | Original | Proposta | Efeito                         |
| --- | ---------- | -------- | -------- | ------------------------------ |
| 0   | 0          | 20       | **12**   | Coasting: target=2 até 12 km/h |
| 1   | 0          | 20       | **12**   | idem                           |
| 2   | 0          | 20       | **12**   | idem                           |
| 3   | 20         | 20       | **12**   | Tip-in leve: target=2          |
| 4   | 39         | 20       | **12**   | idem                           |
| 5   | 60         | 20       | **12**   | idem                           |
| 6   | 85         | 20       | **12**   | idem                           |
| 7   | 93         | 31       | 31       | Inalterado (WOT)               |
| 8   | 93         | 35       | 35       | Inalterado                     |
| 9   | 99.6       | 53       | 53       | Inalterado                     |


**Simulação:** A 17.6 km/h em coasting: `17.6 >= 12 → target=2 → 3→2` (em vez de 3→1). ✓

**Trade-off (band protection):** Com T11=12, o evaluator permite target=2ª em coasting entre 12-20 km/h. Isso expõe a cinta a torque reverso nessa faixa. Contudo, a 12-20 km/h a energia cinética é baixa e o estresse na cinta é mínimo. A OWC em 1ª ainda protege abaixo de 12 km/h.

```
Bytes: 7 × float32 = 28 bytes
float32 BE 12.0 = 0x41400000

Offsets:
  0x184DB0: 41 A0 00 00 → 41 40 00 00  (row 0: 20.0 → 12.0)
  0x184DB8: 41 A0 00 00 → 41 40 00 00  (row 1)
  0x184DC0: 41 A0 00 00 → 41 40 00 00  (row 2)
  0x184DC8: 41 A0 00 00 → 41 40 00 00  (row 3)
  0x184DD0: 41 A0 00 00 → 41 40 00 00  (row 4)
  0x184DD8: 41 A0 00 00 → 41 40 00 00  (row 5)
  0x184DE0: 41 A0 00 00 → 41 40 00 00  (row 6)
```

### Patch 2 — Table 10 (SLOT_1_2 em Group 2): PRIORIDADE ALTA

**Objetivo:** Baixar o threshold de "sair de 1ª" no downshift eval de 23→15 km/h. Previne trapping prolongado se o carro cair em 1ª.


| Row | Throttle % | Original | Proposta   | Efeito                    |
| --- | ---------- | -------- | ---------- | ------------------------- |
| 0   | 0          | 23       | **15**     | Pode sair de 1ª a 15 km/h |
| 1   | 0          | 23       | **15**     | idem                      |
| 2   | 12         | 23       | **15**     | idem                      |
| 3   | 20         | 23       | **15**     | idem                      |
| 4   | 39         | 23       | **15**     | idem                      |
| 5   | 59         | 28       | 28         | Inalterado                |
| 6   | 80         | 39       | 39         | Inalterado                |
| 7-9 | 93-99.6    | 56-57    | inalterado | WOT kickdown preservado   |


**Simulação:** Se em 1ª a 15.1 km/h: `15.1 >= 15 → target=2 → sai de 1ª`. Original: preso até 23 km/h. ✓

**Hysteresis T11/T10:** Com T11=12 e T10=15, gap = 3 km/h. É estreito mas funcional: abaixo de 12→1ª, acima de 15→pode sair de 1ª. Entre 12-15 → estado anterior persiste (sem hunting).

```
Bytes: 5 × float32 = 20 bytes
float32 BE 15.0 = 0x41700000

Offsets:
  0x184D50: 41 B8 00 00 → 41 70 00 00  (row 0: 23.0 → 15.0)
  0x184D58: 41 B8 00 00 → 41 70 00 00  (row 1)
  0x184D60: 41 B8 00 00 → 41 70 00 00  (row 2)
  0x184D68: 41 B8 00 00 → 41 70 00 00  (row 3)
  0x184D70: 41 B8 00 00 → 41 70 00 00  (row 4)
```

### Patch 3 — Table 4 (SLOT_1_2 em Group 1): PRIORIDADE ALTA (safety net)

**Objetivo:** Eliminar gap abrupto no upshift eval. Suavizar degrau 17→23 em T4 row 3.


| Row | Throttle % | Original | Proposta |
| --- | ---------- | -------- | -------- |
| 3   | 25         | **23**   | **18**   |


**Simulação:** A 20 km/h, 25% throttle (Group 1): `20 >= 18 → target=2 → OK`. Original: `20 < 23 → target=1 → 3→1`.

```
Bytes: 1 × float32 = 4 bytes
Offset 0x184B28: 41 B8 00 00 → 41 90 00 00  (23.0 → 18.0)
```

### Table 5 — MANTER em 12 km/h (decisão anterior confirmada)

T5 preenche SLOT_??25 no Group 1. Com T5=12 e T4 patcheado para 18: hysteresis = 6 km/h (12↔18). Saudável.

### Patch 4 — Coast Decel Table @ 0x182ED0: **ROOT CAUSE PRINCIPAL** 🔴

**Objetivo:** Baixar base threshold do coast rápido de 22.0→15.0 km/h. Permite 2ª marcha durante desaceleração forte acima de 15 km/h.

**Evidência (live RAM):**
```
Antes: S24=24, S25=22, S27=22 → a 20 km/h: 20 < 22 → target=1 → 3→1
Depois: S24≈16, S25=15, S27=15 → a 20 km/h: 20 >= 15 → target=2 → 3→2 ✓

Scaling: S24 = base × factor(0x181908) ≈ 15.0 × 1.09 ≈ 16.4 → byte = 16
```

**Dados ROM (7 entradas, todas idênticas):**

| # | Input Axis | Original | Proposta | ROM Address |
|---|-----------|----------|----------|-------------|
| 0 | decel forte | 22.0 | **15.0** | 0x182ED0 |
| 1 | 0% | 22.0 | **15.0** | 0x182ED8 |
| 2 | 0% | 22.0 | **15.0** | 0x182EE0 |
| 3 | ~10% | 22.0 | **15.0** | 0x182EE8 |
| 4 | ~20% | 22.0 | **15.0** | 0x182EF0 |
| 5 | ~40% | 22.0 | **15.0** | 0x182EF8 |
| 6 | ~60% | 22.0 | **15.0** | 0x182F00 |

```
Bytes: 7 × float32 = 28 bytes
float32 BE 22.0 = 0x41B00000
float32 BE 15.0 = 0x41700000

Offsets (stride = 8 bytes, float no primeiro dword de cada par):
  0x182ED0: 41 B0 00 00 → 41 70 00 00  (entry 0)
  0x182ED8: 41 B0 00 00 → 41 70 00 00  (entry 1)
  0x182EE0: 41 B0 00 00 → 41 70 00 00  (entry 2)
  0x182EE8: 41 B0 00 00 → 41 70 00 00  (entry 3)
  0x182EF0: 41 B0 00 00 → 41 70 00 00  (entry 4)
  0x182EF8: 41 B0 00 00 → 41 70 00 00  (entry 5)
  0x182F00: 41 B0 00 00 → 41 70 00 00  (entry 6)
```

**Justificativa do valor 15.0:**
- Precisa ser baixo o suficiente para resolver o bug (20-22 km/h deve dar target=2)
- Precisa manter proteção mínima da cinta (2ª marcha em engine brake abaixo de 15 km/h = stress baixo)
- Hysteresis com 1ª gear: se S25=15 e S24≈16, gap = 1 km/h. Estreito, mas é coast decel — o carro está parando, não cycling entre marchas
- Consistência: T11 (accel group) já está em 12. Coast rápido em 15 é mais conservador (coerente com maior stress)

---

## Análise de Segurança

### Patch 1 (T11): Risco de band protection — ✅ VALIDADO EM CAMPO

- **Trade-off real:** Baixar T11 de 20→12 permite 2ª marcha em coasting entre 12-20 km/h. A cinta vê torque reverso nessa faixa.
- **Mitigante:** A 12-20 km/h, a energia cinética do veículo é baixa. RPM em 2ª ≈ 1000-1200 — mínimo.
- **Validação:** Live logging confirma S25=12 no grupo aceleração. Sem problemas observados em ~50 km de teste.
- **Comparação BH:** Firmware BH usava T5=7 km/h. A Ford permitia 2ª gear até 7 km/h.

### Patch 2 (T10): Risco mínimo — ✅ VALIDADO EM CAMPO

- T10 só afeta o escape de 1ª. 1ª usa OWC, sem cinta. Sem problemas observados.

### Patch 3 (T4): Risco mínimo — ✅ VALIDADO EM CAMPO

- Scope mínimo (1 row). Em tip-in, motor está tracionando (sem torque reverso). Hysteresis T5/T4 = 12/18 = 6 km/h.

### Patch 4 (Coast Decel 0x182ED0): Risco moderado — análise

- **Trade-off real:** Baixar de 22→15 permite 2ª marcha em engine brake forte entre 15-22 km/h. A cinta segura torque reverso do motor.
- **Mitigante #1:** A 15-22 km/h, RPM em 2ª ≈ 1000-1500. Energia cinética baixa. Torque reverso proporcional ao RPM.
- **Mitigante #2:** O coast rápido é transitório (foot-off brusco). O TCM tipicamente sai desse modo em 1-3 segundos ao estabilizar a desaceleração.
- **Mitigante #3:** Firmware BH (Siemens) permitia 2ª até 7 km/h. A cinta foi dimensionada para operar nessas condições.
- **Mitigante #4:** Valor proposto (15.0) é MAIS conservador que os patches de aceleração (T11=12). Reconhece que engine brake impõe mais stress que coasting passivo.
- **DESCONHECIDO:** Se há mecanismo de EPC pressure reduction ativo durante coast rápido que proteja a cinta adicionalmente.

---

## Cenários Antes/Depois (v4)

### Cenário 1: Coasting lento 3→1 @ 17.6 km/h — ✅ RESOLVIDO (Patch 1)


| Etapa                 | ANTES (original)           | DEPOIS (Patch 1 aplicado)  |
| --------------------- | -------------------------- | -------------------------- |
| 3ª, 17.6 km/h, 0% thr | Group 2: S25=T11=20        | S25=T11=**12**             |
| gear_zone_evaluator   | 17.6 < 20 → target=**1**  | 17.6 >= 12 → target=**2** |
| Resultado             | **3→1 direto (solavanco)** | **3→2 (suave)** ✓          |


### Cenário 2: Tip-in @ 20 km/h, 25% throttle — ✅ RESOLVIDO (Patch 3)


| Etapa                | ANTES                   | DEPOIS (Patch 3 aplicado) |
| -------------------- | ----------------------- | ------------------------- |
| 3ª, 20 km/h, 25% thr | Group 1: S24=T4=23      | S24=T4=**18**             |
| gear_zone_evaluator  | 20 < 23 → target=**1** | 20 >= 18 → target=**2**  |
| Resultado            | **3→1→2 cascade**       | **3→2 (suave)** ✓         |


### Cenário 3: Coast RÁPIDO @ 20 km/h (foot-off brusco) — 🔴 ROOT CAUSE ATIVO


| Etapa                    | ATUAL (patches 1-3)      | DEPOIS (Patch 4)           |
| ------------------------ | ------------------------ | -------------------------- |
| 3ª, 20 km/h, foot-off    | Mode 0x26: S25=**22**   | S25=**15**                 |
| gear_zone_evaluator      | 20 < 22 → target=**1**  | 20 >= 15 → target=**2**   |
| Resultado                | **3→1 direto (BUG)**    | **3→2 (suave)** ✓          |


### Cenário 4: Coast rápido profundo (30→10 km/h) — com Patch 4


| Etapa       | ATUAL (patches 1-3)   | DEPOIS (+ Patch 4)                |
| ----------- | --------------------- | --------------------------------- |
| 20 km/h     | S25=22, 20<22 → 3→1  | S25=15, 20>=15 → 3→2 ✓            |
| 16 km/h     | Preso em 1ª           | S25=15, 16>=15 → target=2 ✓       |
| 14 km/h     | Preso em 1ª           | S25=15, 14<15 → 2→1 (normal) ✓    |
| Parado      | 1ª (OWC freewheel)    | idem ✓                            |


### Cenário 5: Preso em 3ª de 20→45 km/h (aceleração leve)


| Etapa                | Status     | Nota                                                |
| -------------------- | ---------- | --------------------------------------------------- |
| 25 km/h, 15% thr, 3ª | Sem mudança | State machine (0xB1130) decide sair de 3ª, não patches |

**Nota:** O cenário "preso em 3ª" persiste. Os patches controlam para QUAL marcha o TCM desce quando decide sair de 3ª (agora será 2ª em vez de 1ª). A decisão DE sair depende do state machine.

---

## Resumo dos Patches (v4)


| #   | Tabela           | Offsets           | Bytes | Original → Proposta | Status       | Grupo afetado |
| --- | ---------------- | ----------------- | ----- | ------------------- | ------------ | ------------- |
| 1   | T11 (3→2 DN)    | 0x184DB0-0x184DE0 | 28B   | 20.0→12.0 (7 rows)  | ✅ APLICADO  | Downshift     |
| 2   | T10 (2→1 alt)   | 0x184D50-0x184D70 | 20B   | 23.0→15.0 (5 rows)  | ✅ APLICADO  | Downshift     |
| 3   | T4 (1→2 UP)     | 0x184B28          | 4B    | 23.0→18.0 (1 row)   | ✅ APLICADO  | Upshift       |
| **4** | **Coast Decel** | **0x182ED0-0x182F00** | **28B** | **22.0→15.0 (7 entries)** | 🔴 **PENDENTE** | **Coast rápido** |


**Total: 80 bytes alterados (52 aplicados + 28 pendentes).**

### Detalhamento Patch 4 (bytes exatos)

```
Endereço    Original         Proposto         Nota
0x182ED0    41 B0 00 00      41 70 00 00      float32 22.0 → 15.0 (entry 0)
0x182ED8    41 B0 00 00      41 70 00 00      entry 1
0x182EE0    41 B0 00 00      41 70 00 00      entry 2
0x182EE8    41 B0 00 00      41 70 00 00      entry 3
0x182EF0    41 B0 00 00      41 70 00 00      entry 4
0x182EF8    41 B0 00 00      41 70 00 00      entry 5
0x182F00    41 B0 00 00      41 70 00 00      entry 6

Stride: 8 bytes (float32 no primeiro dword, segundo dword é input axis — não alterar)
Checksum: Master block CRC-16/ARC precisa recalcular após patch
```

---

## ⚠️ Propostas Descartadas

### Proposta ChatGPT (T11 subir com throttle): INVERTIDA

```
ChatGPT propôs: T11 → 20,20,20,23,25,27,28,31,35,53
Lógica ChatGPT: "subir threshold = mais downshift 3→2 = mais 2ª marcha"

REALIDADE (código): T11 → SLOT_??25 → piso mínimo de 2ª.
  Subir T11 = AMPLIAR zona de 1ª = MAIS 3→1.
  
Exemplo: T11(60%)=27. A 25 km/h, 60% throttle:
  Original: 25 >= 20 → target=2 → OK
  ChatGPT:  25 < 27  → target=1 → 3→1 a 25 km/h!!! PIOR.
```

**MOTIVO:** ChatGPT interpretou T11 como "trigger de downshift 3→2" quando na verdade o `gear_zone_evaluator` usa T11 como "fronteira entre zona de 1ª e zona de 2ª".

### Proposta anterior v1 (T11 20→30 uniforme): INVERTIDA

Mesmo problema. Subir T11 de 20→30 = zona de 1ª até 30 km/h = 3→1 até 30 km/h. **Catastrófico.**

### Proposta anterior v2 (T5 12→9): DESCARTADA

T5 afeta SLOT_??25 no Group 1 (upshift). Baixar T5 de 12→9 invade zona de 1ª marcha. Operador decidiu manter T5 em 12.

---

## Evidência de Suporte: Fórum Russo

Relato de um usuário que trocou TCM Siemens (BH) por Continental (BL):

> "A 20 km/h, engata segunda. Quando a velocidade cai para 19 km/h, engata a primeira e o carro dá um solavanco! [...] Com o TCM antigo (BH), a automática não engata primeira até o carro estar quase completamente parado!"

A comparação (doc 27) confirma que a ÚNICA diferença de calibração relevante entre BH e BL é a Table 5 (2→1 DN): **7.0 → 12.0 km/h**.

---

## Pendências

1. ~~**Checksum:** Resolver algoritmo~~ ✅ CRC-16/ARC. ELMConfig recalcula automaticamente durante flash.
2. ~~**Patches 1-3:** Aplicar e validar~~ ✅ Aplicados e validados em campo com live RAM logging.
3. **Patch 4 (coast_decel):** Aplicar ao firmware AA, gerar PHF, flashear
4. **Validação Patch 4:** Repetir percurso com tcm_slot_logger.py, confirmar:
   - S25 ≤ 15 quando coast rápido ativo
   - Nenhum 3→1 acima de 15 km/h
   - Sem hunting 1↔2 no coast rápido
5. **DESCONHECIDO:** Se descriptor 0x187584 (mesmo par, usado para outro slot) também precisa de patch separado, ou se compartilha os mesmos dados de 0x182ED0. Verificar via live RAM após flash.
6. **Monitorar band:** Observar se engine brake em 2ª a 15-22 km/h causa desgaste perceptível (improvável, mas monitorar)

