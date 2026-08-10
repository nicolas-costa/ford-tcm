# 26 — Proposta de Patch: Shift Schedule Calibration

**Data:** 2026-08-03 (v6.2 — v5 + T4→15 + modifiers 185708/185750 Y→0; T7 adiado)  
**Firmware alvo:** `5U75-14C337-AA.from_phf.bin` (**AA é o nativo do TCM** — ver doc 30 §3)  
**Status:** Patches 1-5 aplicados em `AA_v5_block3ck_89E4` (Block3 ck 0x89E4 verificado). Pendente teste de rodagem.  
**Dependência:** Arquitetura de decisão (doc 24 v3), checksum (**doc 30**, não doc 25), UDS security (doc 28)

> ### ⚠️ Requisito real (v6 — corrigido com o operador)
> O objetivo **não** é proteger a 3ª. É **eliminar o excesso de 3ª entre ~18-30 km/h (velocímetro) = ~15-26 km/h TCM** e **preferir a 2ª** nesse range quando há **aceleração leve** (tip-in ou retomada após coasting). **Não** há requisito de passar pela 2ª em coasting puro (desaceleração até parar).
>
> Consequência para os patches:
> - **Patch 5 (T7/S27 no grupo aceleração)** é o lever principal: sobe o porteiro de saída da 3ª em tip-in → força 3→2 em 15-26 TCM.
> - **Patch 4 (coast_decel 22→15)** NÃO cria 2ª em coasting (impossível: S25==S27 travados no modo coast). Seu papel real é **manter a 3ª durante o coast** para que, ao tocar o acelerador, o carro caia limpo em 2ª (via Patch 5) em vez de já ter despencado para 1ª — e suavizar/adiar o tranco 3→1.

> ### ⚠️ Checksum (leia antes de gerar qualquer PHF)
> O modelo correto é **CRC-16/ARC sobre `BIN[start-4 : end-4+1]`, init=0xFFFF** (doc 30 §1.5). O script `scripts/build_patched_firmware.py` usa o modelo **antigo sem shift** e é **PROVADAMENTE ERRADO** para o Block3 (seu self-test é circular contra o `v5.bin` que nunca bootou). **NÃO** usar aquele patcher para gerar firmware de flash. Verificar o ck com `scripts/verify_v5_checksum.py`.

---

## Resumo Executivo

1. **FATO (assembly):** `gear_zone_evaluator` (0x83484) para gear=3ª avalia nesta ordem:
  - `speed >= S28` → target=4ª (upshift)
  - `speed >= S27` → target=3ª (**fica na 3ª**)
  - `speed >= S25` → target=2ª (downshift 3→2)
  - else → target=1ª (downshift 3→1)
2. **FATO (live RAM, 3272 amostras):** 3 grupos de slot confirmados, com S27 como gatekeeper de saída da 3ª:


| Grupo        | Condição             | S27        | S25              | Fonte ROM    |
| ------------ | -------------------- | ---------- | ---------------- | ------------ |
| Aceleração   | INPUT > ~7%          | 12-27 (T7) | 12 (T11 patched) | 0x184xxx     |
| Coast normal | INPUT=0, decel lenta | 17         | 17               | 0x182xxx     |
| Coast rápido | INPUT=0, decel forte | **22**     | **22**           | **0x182ED0** |


1. **FATO (live RAM):** O bug 3→1 em coast rápido ocorre porque S25=S27=22. A 20 km/h: speed < S27(22) → sai de 3ª → speed < S25(22) → target=1ª (skip 2ª).
2. **FATO (live RAM, 606 amostras em 3ª com throttle):** A 12-15% throttle, S27 médio = 17-19. A 21-26 km/h TCM (25-30 vel.): `speed >> S27` → **preso em 3ª durante retomada**. O downshift 3→2 só acontece a ~35% throttle ou por resíduo acidental do coast_decel.
3. **Proposta v5:** 5 patches — 3 já aplicados, 2 novos (coast_decel + retomada T7).

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


A **cinta (band)** é o elemento mais frágil. Aplicada em 2ª e 4ª. A OWC em 1ª permite freewheel sem torque reverso.

### Torque Reverso e Proteção da Cinta

- **1ª com OWC**: Freewheel em coasting — sem torque reverso, sem desgaste
- **2ª com Band**: Cinta segura torque reverso — desgaste aumentado
- **3ª com Clutch A+B**: Área de contato maior, pressão específica menor

**Conclusão mecânica:** Manter 3ª em coasting protege a cinta. Os thresholds originais de T11=20 e coast_decel=22 são decisões de durabilidade. Os patches abaixo aceitam trade-off de durabilidade mínimo em troca de dirigibilidade.

---

## Causas Raiz (provadas por disassembly + live RAM)

### RC #1 — T11 envia para 1ª em coasting (Group 2) — ✅ PATCHEADO

```
Group 2 ativo (coasting). S25 = T11(0%) = 20 km/h.
gear_zone_evaluator (gear=3): speed(17.6) < 20 → target = 1 → 3→1 DIRETO.

Assembly (0x0838B4-0x0838D4):
  lbz r12, speed        # r12 = 17
  lbz r11, SLOT_??25    # r11 = 20 (T11)
  cmpw r12, r11         # 17 < 20
  li r3, 1              # target = 1
```

### RC #2 — T10 traps em 1ª (Group 2) — ✅ PATCHEADO

```
Uma vez em 1ª, S24 = T10(0%) = 23 km/h.
speed(17.6) < 23 → target = 1 → PRESO até 23 km/h.
```

### RC #3 — T4 gap em tip-in (Group 1) — ✅ PATCHEADO

```
Group 1, tip-in. S24 = T4(25%) = 23 km/h.
Gap abrupto: 17 @20% → 23 @25%. A 20 km/h: 20 < 23 → 3→1→2 cascade.
```

### RC #4 — Coast Decel Table bloqueia 2ª (PRINCIPAL) — 🔴 PENDENTE

```
FATO (live RAM, centenas de amostras):
  Grupo coast rápido ativo (RAM 0x3FBBCC == 0x26).
  S25 = S27 = 22 (tabela 0x182ED0, 7 × float32 22.0).
  gear_zone_evaluator: speed(20) < S27(22) → sai de 3ª
                       speed(20) < S25(22) → target=1 → 3→1 DIRETO.

  Cadeia ROM (disasm 0x87BE8):
    0x3FBBCC==0x26 → descriptor 0x187514 → axis 0x182EC8 → data 0x182ED0
```

### RC #5 — T7 muito baixo = preso em 3ª durante retomada — 🔴 PENDENTE

```
FATO (live RAM, 606 amostras em 3ª com throttle):
  Correlação INPUT → S27 (= T7):
    INPUT 9-12%:  S27 avg=17  (range 12-22)
    INPUT 12-15%: S27 avg=19  (range 12-23)
    INPUT 15-18%: S27 avg=20  (range 16-25)

  Cenário: coast 50→30 vel, TCM já em 3ª, retomada com ~15% throttle.
  S27 = T7(15%) ≈ 17 km/h.  speed(26 TCM) >= 17 → FICA NA 3ª.
  Para forçar 3→2, precisa ~35% throttle (kickdown parcial).

  T7 original (0x184C30):
    6%=12, 12%=14, 20%=19, 29%=25, 51%=34
  Hysteresis com T6 (2→3 upshift, 0x184BD0):
    T6: 8%=28, 12%=28, 25%=34 → gap T6-T7 = 14 km/h @12% = ENORME.
```

### Relação entre as cinco


| #   | Cenário                 | Grupo         | Slot crítico | Tabela       | Efeito          | Status      |
| --- | ----------------------- | ------------- | ------------ | ------------ | --------------- | ----------- |
| 1   | Coasting lento < 20     | Group 2       | S25          | T11 20→12    | 3→1 direto      | ✅ PATCHEADO |
| 2   | Preso em 1ª             | Group 2       | S24          | T10 23→15    | Trapping        | ✅ PATCHEADO |
| 3   | Tip-in @ 20 km/h        | Group 1       | S24          | T4 23→18     | 3→1→2           | ✅ PATCHEADO |
| 4   | **Coast rápido < 22**   | **Mode 0x26** | **S25+S27**  | **0x182ED0** | **3→1**         | 🔴 PENDENTE |
| 5   | **Retomada 20-30 vel.** | **Group 1**   | **S27**      | **T7**       | **Preso em 3ª** | 🔴 PENDENTE |


---

## Patches

### Patch 1 — T11 (S25 em Group 2): 20→12 km/h — ✅ APLICADO

**Objetivo:** Baixar piso de 2ª em coasting. Impede 3→1 acima de 12 km/h.


| Row | Throttle | Original | Proposta    |
| --- | -------- | -------- | ----------- |
| 0-6 | 0-85%    | 20       | **12**      |
| 7-9 | 93-99.6% | 31-53    | sem mudança |


```
7 × float32: 0x41A00000 → 0x41400000
Offsets: 0x184DB0, 0x184DB8, 0x184DC0, 0x184DC8, 0x184DD0, 0x184DD8, 0x184DE0
```

### Patch 2 — T10 (S24 em Group 2): 23→15 km/h — ✅ APLICADO

**Objetivo:** Baixar threshold de "sair de 1ª" em downshift. Previne trapping.


| Row | Throttle | Original | Proposta    |
| --- | -------- | -------- | ----------- |
| 0-4 | 0-39%    | 23       | **15**      |
| 5-9 | 59-99.6% | 28-57    | sem mudança |


```
5 × float32: 0x41B80000 → 0x41700000
Offsets: 0x184D50, 0x184D58, 0x184D60, 0x184D68, 0x184D70
```

### Patch 3 — T4 row 3 (S24 em Group 1): 23→18 km/h — ✅ APLICADO

**Objetivo:** Eliminar gap abrupto 17→23 no upshift eval.

```
1 × float32: 0x41B80000 → 0x41900000
Offset: 0x184B28
```

### Patch 4 — Coast Decel Table (S25+S27 em Mode 0x26): 22→15 km/h — 🔴 PENDENTE

**Objetivo (revisado v6):** **Manter a 3ª durante o coast** (foot-off) até ~15 km/h TCM, para que ao tocar o acelerador o carro esteja em 3ª e caia limpo em 2ª (Patch 5), em vez de já ter despencado para 1ª. Suaviza/adia o tranco 3→1. **NÃO cria 2ª em coasting** — no modo coast os slots S25 e S27 vêm travados ao mesmo valor base (S25==S27), então a coast_decel só permite 3ª-ou-1ª. Criar 2ª em coasting exigiria decouplar S25 de S27 via a scaling table `0x181908` (não confirmado — ver "Melhorias Futuras").

**Evidência (live RAM):**

```
ANTES: S24=24, S25=22, S27=22 → a 20 km/h: speed<S27 → sai de 3ª → speed<S25 → target=1
DEPOIS: S24≈16, S25=15, S27=15 → a 20 km/h: speed>=S27 → FICA na 3ª (protegido)
         a 14 km/h: speed<S27 → sai de 3ª → speed<S25 → 2→1 normal
```


| #   | Input Axis  | Original | Proposta | ROM Address |
| --- | ----------- | -------- | -------- | ----------- |
| 0   | decel forte | 22.0     | **15.0** | 0x182ED0    |
| 1   | 0%          | 22.0     | **15.0** | 0x182ED8    |
| 2   | 0%          | 22.0     | **15.0** | 0x182EE0    |
| 3   | ~10%        | 22.0     | **15.0** | 0x182EE8    |
| 4   | ~20%        | 22.0     | **15.0** | 0x182EF0    |
| 5   | ~40%        | 22.0     | **15.0** | 0x182EF8    |
| 6   | ~60%        | 22.0     | **15.0** | 0x182F00    |


```
7 × float32: 0x41B00000 → 0x41700000
Stride: 8 bytes (float no 1º dword de cada par, 2º dword = input axis — NÃO ALTERAR)
Offsets: 0x182ED0, 0x182ED8, 0x182EE0, 0x182EE8, 0x182EF0, 0x182EF8, 0x182F00
```

### Patch 5 — T7 rows 2-4 (S27 em Group 1): Retomada 3→2 — 🔴 PENDENTE

**Objetivo:** Reduzir o "piso de 3ª marcha" durante aceleração leve/moderada. Permite downshift 3→2 automático entre 20-30 km/h (velocímetro) / 17-27 km/h (TCM) com ~12-20% throttle, eliminando a necessidade de kickdown.

**Evidência (live RAM, 606 amostras):**

```
HOJE: 3ª a 26 TCM (~30 vel.), 15% throttle:
  S27 = T7(15%) ≈ 17.  speed(26) >= S27(17) → FICA NA 3ª.
  Downshift exige ~35% throttle.

PROPOSTA: T7(15%) interpolado ≈ 26.  speed(26) < S27(26) → SÁIDA de 3ª.
  S25=12.  speed(26) >= S25(12) → target=2 → 3→2 ✓
```


| Row   | Throttle | T7 Original | T7 Proposta | float32 BE      | Efeito                         |
| ----- | -------- | ----------- | ----------- | --------------- | ------------------------------ |
| 0     | 6%       | 12          | **12**      | — (sem mudança) | Sem downshift em idle residual |
| 1     | 6%       | 12          | **12**      | — (sem mudança) | idem                           |
| **2** | **12%**  | **14**      | **26**      | **0x41D00000**  | 3→2 até 26 TCM (~30 vel.)      |
| **3** | **20%**  | **19**      | **27**      | **0x41D80000**  | 3→2 até 27 TCM (~31 vel.)      |
| **4** | **29%**  | **25**      | **29**      | **0x41E80000**  | 3→2 até 29 TCM (~33 vel.)      |
| 5     | 51%      | 34          | **34**      | — (sem mudança) | Já funciona                    |
| 6-9   | 83-99.6% | 56-99       | sem mudança | —               | WOT preservado                 |


```
3 × float32:
Offset 0x184C40: 41 60 00 00 → 41 D0 00 00  (row 2: 14.0 → 26.0)
Offset 0x184C48: 41 98 00 00 → 41 D8 00 00  (row 3: 19.0 → 27.0)
Offset 0x184C50: 41 C8 00 00 → 41 E8 00 00  (row 4: 25.0 → 29.0)
```

**Hysteresis T7 (3→2) vs T6 (2→3 upshift):**


| Throttle | T7 proposta (3→2) | T6 existente (2→3) | Gap   | Risco                            |
| -------- | ----------------- | ------------------ | ----- | -------------------------------- |
| 6%       | 12                | 28                 | 16    | Nenhum                           |
| **12%**  | **26**            | **28**             | **2** | Baixo (retomada = speed subindo) |
| **20%**  | **27**            | **~31**            | **4** | Nenhum                           |
| **29%**  | **29**            | **34**             | **5** | Nenhum                           |


**Simulação do cenário de retomada:**

```
Coast 50 → 30 km/h (vel.), TCM em 3ª.
Aplica ~15% throttle (retomada normal):
  S27 = T7(15%) interpolado ≈ 26.  speed(26 TCM) >= S27(26) → borderline → speed cai 1 km/h → EXIT 3ª
  S25 = 12.  speed(25) >= 12 → target = 2 → 3→2 ✓

Em 2ª, acelerando:
  speed(27 TCM ~ 31 vel.) → S26 = T6(15%) ≈ 28 → 2→3 upshift ✓
  Continua em 3ª até ~52 vel. → 3→4 ✓

Fluxo: 3→2 @~30vel → 2→3 @~32vel → 3→4 @~55vel
```

---

## Análise de Segurança

### Patches 1-3 — ✅ VALIDADOS EM CAMPO (~50 km)

- **Patch 1 (T11):** Sem problemas com cinta. RPM em 2ª a 12-20 km/h ≈ 1000-1200 (mínimo). Firmware BH permitia 2ª até 7 km/h.
- **Patch 2 (T10):** Risco mínimo. 1ª usa OWC, sem cinta.
- **Patch 3 (T4):** Risco mínimo. Scope 1 row. Motor tracionando (sem torque reverso).

### Patch 4 (Coast Decel) — Risco moderado

- **Trade-off:** 2ª marcha em engine brake forte entre 15-22 km/h. Cinta segura torque reverso.
- **Mitigante #1:** RPM em 2ª a 15-22 km/h ≈ 1000-1500. Energia cinética baixa.
- **Mitigante #2:** Coast rápido é transitório (1-3 segundos).
- **Mitigante #3:** BH permitia 2ª até 7 km/h — cinta dimensionada para isso.
- **Mitigante #4:** Valor 15.0 é mais conservador que T11=12 (accel). Reconhece maior stress em engine brake.
- **DESCONHECIDO:** Se há EPC pressure reduction durante coast rápido.

### Patch 5 (T7 Retomada) — Risco baixo

- **Trade-off:** 3→2 downshift em retomada expõe cinta a torque POSITIVO (motor tracionando, não reverso). Stress na cinta é MENOR que em coasting.
- **Mitigante #1:** Em retomada, o motor puxa as rodas. A cinta apenas mantém o gear ratio. Sem torque reverso.
- **Mitigante #2:** Hysteresis mínima 2 km/h @12% throttle, mas o carro está acelerando → cruza T6 rapidamente.
- **Mitigante #3:** Rows 0-1 (6%) mantidas em 12 → não causa downshift acidental em idle/coast residual.
- **Risco de hunting @12%:** Teórico a ~28 km/h TCM com throttle estável de 12%. Na prática, 12% é insuficiente para manter velocidade constante no plano — velocidade sobe ou desce, resolvendo a oscilação.

---

## Cenários Antes/Depois (v5)

### Cenário 1: Coasting lento 3→1 @ 17.6 km/h — ✅ RESOLVIDO (Patch 1)


| Etapa             | ANTES                    | DEPOIS                    |
| ----------------- | ------------------------ | ------------------------- |
| 3ª, 17.6 km/h, 0% | S25=T11=20               | S25=T11=**12**            |
| Evaluator         | 17.6 < 20 → target=**1** | 17.6 >= 12 → target=**2** |
| Resultado         | **3→1 (solavanco)**      | **3→2 (suave)** ✓         |


### Cenário 2: Tip-in @ 20 km/h, 25% — ✅ RESOLVIDO (Patch 3)


| Etapa            | ANTES                  | DEPOIS                  |
| ---------------- | ---------------------- | ----------------------- |
| 3ª, 20 km/h, 25% | S24=T4=23              | S24=T4=**18**           |
| Evaluator        | 20 < 23 → target=**1** | 20 >= 18 → target=**2** |
| Resultado        | **3→1→2 cascade**      | **3→2 (suave)** ✓       |


### Cenário 3: Coast rápido @ 20 km/h — 🔴 RESOLVIDO COM PATCH 4


| Etapa                 | ATUAL (patches 1-3)                                    | COM PATCH 4                    |
| --------------------- | ------------------------------------------------------ | ------------------------------ |
| 3ª, 20 km/h, foot-off | S27=22, S25=22                                         | S27=**15**, S25=**15**         |
| Evaluator             | 20 < S27(22) → sai de 3ª → 20 < S25(22) → **target=1** | 20 >= S27(15) → **fica na 3ª** |
| Resultado             | **3→1 (BUG)**                                          | **Mantém 3ª (OK)** ✓           |


### Cenário 4: Coast rápido profundo (30→10 km/h) — COM PATCH 4


| Velocidade | ATUAL               | COM PATCH 4                                           |
| ---------- | ------------------- | ----------------------------------------------------- |
| 20 km/h    | S27=22, 20<22 → 3→1 | S27=15, 20>=15 → fica 3ª ✓                            |
| 16 km/h    | Preso em 1ª         | S27=15, 16>=15 → fica 3ª ✓                            |
| 14 km/h    | Preso em 1ª         | S27=15, 14<15 → sai 3ª → S25=15, 14<15 → 2→1 normal ✓ |
| Parado     | 1ª (OWC)            | idem ✓                                                |


### Cenário 5: Retomada a 30 km/h vel. em 3ª — 🔴 RESOLVIDO COM PATCH 5


| Etapa                      | ATUAL                         | COM PATCH 5                                          |
| -------------------------- | ----------------------------- | ---------------------------------------------------- |
| 3ª, 26 TCM (~30 vel.), 15% | S27=T7≈17                     | S27=T7≈**26**                                        |
| Evaluator                  | 26 >= 17 → **fica 3ª**        | 26 >= 26 → borderline, 25<26 → **sai 3ª → target=2** |
| Após 3→2, acelerando       | —                             | S26=T6≈28 → 2→3 @28 TCM (~32 vel.) ✓                 |
| Resultado                  | **Arrasta em 3ª até 60 km/h** | **3→2→3→4 progressivo** ✓                            |


### Cenário 6: Preso em 3ª de 30→60 km/h (aceleração constante)


| Etapa                | Status               | Nota                                                 |
| -------------------- | -------------------- | ---------------------------------------------------- |
| 30 km/h, 13% thr, 3ª | **COM PATCH 5: 3→2** | S27=T7(13%)≈26, speed(26)>=26 borderline → transição |
| 35 km/h, 13% thr, 2ª | 2→3 upshift          | S26=T6(13%)≈28, speed(31)>=28 → 3ª ✓                 |
| 55 km/h, 13% thr, 3ª | 3→4 upshift          | Normal ✓                                             |


---

## Resumo dos Patches (v5)


| #     | Tabela          | Offsets               | Bytes   | Original → Proposta       | Status      | Grupo        |
| ----- | --------------- | --------------------- | ------- | ------------------------- | ----------- | ------------ |
| 1     | T11 (3→2 DN)    | 0x184DB0-0x184DE0     | 28B     | 20.0→12.0 (7 rows)        | ✅ APLICADO  | Downshift    |
| 2     | T10 (2→1 alt)   | 0x184D50-0x184D70     | 20B     | 23.0→15.0 (5 rows)        | ✅ APLICADO  | Downshift    |
| 3     | T4 row 3        | 0x184B28              | 4B      | 23.0→18.0                 | ✅ APLICADO  | Upshift      |
| **4** | **Coast Decel** | **0x182ED0-0x182F00** | **28B** | **22.0→15.0 (7 entries)** | 🔴 PENDENTE | Coast rápido |
| **5** | **T7 rows 2-4** | **0x184C40-0x184C50** | **12B** | **14/19/25→26/27/29**     | 🔴 PENDENTE | Retomada     |


**Total: 92 bytes (52 aplicados + 40 pendentes).**

### Detalhamento dos bytes pendentes

```
PATCH 4 — Coast Decel (7 × float32, stride 8):
Endereço    Original         Proposto         Nota
0x182ED0    41 B0 00 00      41 70 00 00      22.0 → 15.0 (entry 0)
0x182ED8    41 B0 00 00      41 70 00 00      entry 1
0x182EE0    41 B0 00 00      41 70 00 00      entry 2
0x182EE8    41 B0 00 00      41 70 00 00      entry 3
0x182EF0    41 B0 00 00      41 70 00 00      entry 4
0x182EF8    41 B0 00 00      41 70 00 00      entry 5
0x182F00    41 B0 00 00      41 70 00 00      entry 6

PATCH 5 — T7 retomada (3 × float32, stride 8):
Endereço    Original         Proposto         Nota
0x184C40    41 60 00 00      41 D0 00 00      row 2: 14.0 → 26.0
0x184C48    41 98 00 00      41 D8 00 00      row 3: 19.0 → 27.0
0x184C50    41 C8 00 00      41 E8 00 00      row 4: 25.0 → 29.0

Checksum: Master block CRC-16/ARC precisa recalcular após aplicar ambos.
```

---

## ⚠️ Propostas Descartadas

### Proposta ChatGPT (T11 subir com throttle): INVERTIDA

```
ChatGPT propôs: T11 → 20,20,20,23,25,27,28,31,35,53
REALIDADE: T11 → S25 → piso mínimo de 2ª. Subir = ampliar zona de 1ª = MAIS 3→1.
```

### Proposta v1 (T11 20→30): INVERTIDA

Mesmo erro. Zona de 1ª até 30 km/h. Catastrófico.

### Proposta v2 (T5 12→9): DESCARTADA

Operador decidiu manter T5 em 12 km/h. Hysteresis T5/T4 = 12/18 = 6 km/h saudável.

---

## Evidência de Suporte: Fórum Russo

> "A 20 km/h, engata segunda. Quando a velocidade cai para 19 km/h, engata a primeira e o carro dá um solavanco! [...] Com o TCM antigo (BH), a automática não engata primeira até o carro estar quase completamente parado!"

Comparação BH vs BL (doc 27): ÚNICA diferença relevante é T5 (2→1 DN): 7.0 → 12.0 km/h.

---

## Firmware build v6 (escopo travado 2026-08-03)

**v6.1 (plano):** v5 + T4 rows 0–1 → 15.0 TCM (~18 vel). T7 adiado.

### v6.2 (2026-08-09) — build gerado

**v6.2 = v5 + T4→15 + shift-point modifiers Y→0** (`185708`/`185750`).

| Item | Offset | Antes (v5) | v6.2 | ≈ vel | Notas |
|------|--------|------------|------|-------|-------|
| T4 row 0 | 0x184B10 | 17.0 | **15.0** | **18** | 1→2 leve cedo |
| T4 row 1 | 0x184B18 | 17.0 | **15.0** | **18** | idem |
| Mod S25 Y[] | 0x1856C8…700 | 10/5 | **0.0** | — | doc 50; mata S25=17/22 GATE |
| Mod S27 Y[] | 0x185710…748 | 10/5 | **0.0** | — | espelho S27 |
| T4 row 2+ | — | — | intocado | — | |
| T7 | — | — | adiado | — | |

Artefatos: `firmwares/5U75-14C337-AA_v6.2.bin` / `.PHF`  
Script: `scripts/build_v6_modifier.py`  
Block3 ck: `0x89E4` → `0xD475` (−4 / init `0xFFFF`). Master **inalterado** (`0xD8BF`, estratégia v5 / doc 30).

**Validação em pista (velocímetro):**

1. Coast 2ª: sem 2→1 ~19–22 vel; 2→1 só ~15 vel.
2. Coast saindo de 3ª ~20–25 vel: preferir 3→2.
3. Tip-in leve: 1→2 ~18 vel.
4. Logger: com GATE=1, FS≈12 e S25=12 (sumir 19/17 e 24/22).

```
0x184B10: 41 88 00 00 → 41 70 00 00   (17.0 → 15.0)
0x184B18: 41 88 00 00 → 41 70 00 00   (17.0 → 15.0)
```

Block3 ck: recalcular com modelo −4 / init=0xFFFF (doc 30) e verificar.

## Melhorias Futuras (Bordas) — potencial implementação futura

### Borda A — T7 (topo / throttle rows) — ADIADA

Ajuste de T7 row2 (throttle % e/ou velocidade) foi **descartado por hora** (2026-08-03). Patch 5 (T7 retomada) já está em v5; não mexer na borda alta até validar v6 (só T4).

### Borda B — T4 ainda mais baixo — parcial no v6

v6 baixa rows 0–1 para **15.0** (~18 vel). Se ainda segurar 1ª demais sob pedal leve, candidata futura: row2 também, ou 15→14. Não aplicar sem novo log.

> **Nota:** qualquer edição exige re-recálculo do Block3 ck (modelo −4, doc 30).

---

## Pendências

1. ~~Checksum~~ ✅ CRC-16/ARC. Corrigir no **BIN/PHF** antes de flashear; não depender de opção de “recalcular checksum” no ELMConfig (não consta de forma fidedigna na GUI típica).
2. ~~Patches 1-3~~ ✅ Aplicados e validados em campo (~50 km).
3. **Patches 4+5:** Aplicar ao firmware BL, gerar PHF, flashear.
4. **Validação Patch 4:** Confirmar S25 ≤ 15 e S27 ≤ 15 quando coast rápido ativo. Nenhum 3→1 acima de 15 km/h.
5. **Validação Patch 5:** Confirmar 3→2 automático entre 20-30 vel. com ~12-15% throttle. Sem hunting 2↔3.
6. **DESCONHECIDO:** Se descriptor 0x187584 (par do 0x187514) compartilha dados de 0x182ED0 ou precisa patch separado.
7. **Monitorar band:** Engine brake em 2ª a 15-22 km/h (Patch 4) e retomada em 2ª a 20-30 km/h (Patch 5). Improvável causar desgaste, mas observar.

---

## Histórico de Revisões


| Versão | Data       | Mudanças                                                                                                                 |
| ------ | ---------- | ------------------------------------------------------------------------------------------------------------------------ |
| v1     | 2026-03    | Proposta inicial T11 20→30 (INVERTIDA — descartada)                                                                      |
| v2     | 2026-03    | Correção: T11 20→12, T10 23→15, T4 23→18. T5 12→9 descartada.                                                            |
| v3     | 2026-03    | Reescrita com base em disassembly do gear_zone_evaluator                                                                 |
| v4     | 2026-04-19 | Adicionado Patch 4 (coast_decel 0x182ED0). Root cause #4 identificada via live RAM.                                      |
| v5     | 2026-04-19 | Adicionado Patch 5 (T7 retomada). RC #5. Lógica completa do evaluator (S27=gatekeeper). Firmware alvo corrigido para BL. |
| v6     | 2026-08-02 | Requisito re-alinhado (preferir 2ª em accel 15-26 TCM; sem 2ª em coast puro). Patch 4 re-enquadrado (mantém 3ª no coast, não cria 2ª). Base corrigida para AA. Checksum −4 (doc 30). `AA_v5_block3ck_89E4` verificado. Bordas A/B adiadas para futuro. |
| v6.1   | 2026-08-03 | **Build v6 escopo:** só T4 rows 0–1 → 15.0 (~18 vel). T7 (borda A) descartado por hora. |


