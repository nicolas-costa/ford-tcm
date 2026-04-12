# 26 — Proposta de Patch Revisada: Baseada em Disassembly do gear_zone_evaluator

**Data:** 2026-03-22 (v3 — reescrita com base em análise de assembly do pipeline de decisão)  
**Status:** 🔶 Proposta revisada com base em evidência de código (doc 24 v2). Aguardando resolução do checksum (doc 25).  
**Dependência:** Arquitetura de decisão (doc 24), checksum (doc 25), comparação de firmwares (doc 27)

---

## Resumo Executivo

1. **FATO (assembly):** `gear_zone_evaluator` (0x83484) determina o gear target (1, 2, ou 8). Para **gear atual = 3**, a decisão é: `speed < SLOT_??25 → target=1ª; speed >= SLOT_??25 → target=2ª`. (disasm 0x0838B4-0x0838D4)
2. **FATO (assembly):** No **Group 2** (downshift eval, ativo em coasting), `shift_table_group_dispatcher` (0x9D860) preenche: **SLOT_??25 = T11 (20 km/h @0%)** e **SLOT_1_2 = T10 (23 km/h @0%)**. (stb @0x9E6A4 e @0x9E404)
3. **FATO (FORScan):** A 17.6 km/h em coasting: `17.6 < 20 → target=1 → 3→1 direto`. Uma vez em 1ª: `17.6 < 23 → preso até 23 km/h`.
4. **FATO (assembly):** No **Group 1** (upshift eval), SLOT_1_2 = T4 e SLOT_??25 = T5. T4 tem gap 17→23 @25% throttle que causa o mesmo problema em tip-in.
5. **⚠️ ALERTA:** A proposta anterior do ChatGPT de **subir** T11 com throttle (20→23/25/27/28) é **INVERTIDA**: subir T11 = ampliar zona de 1ª = PIORAR o problema. O evaluator usa T11 como **piso mínimo para 2ª**, não como "trigger de 3→2".
6. **Proposta corrigida:** Baixar T11 (piso de 2ª em downshift), baixar T10 (escape de 1ª em downshift), manter patch T4 (gap em upshift).

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

## Causa Raiz: Dupla (provada por disassembly)

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

### Relação entre os três

| Cenário | Group ativo | Tabela crítica | Threshold @0-20% | Efeito |
|---------|-------------|----------------|-------------------|--------|
| Coasting < 20 km/h | Group 2 | **T11 → SLOT_??25** | 20 km/h | 3→1 direto |
| Preso em 1ª | Group 2 | **T10 → SLOT_1_2** | 23 km/h | Não sai até 23 |
| Tip-in a 20 km/h | Group 1 | **T4 → SLOT_1_2** | 23 km/h @25% | 3→1→2 cascade |

---

## Proposta de Correção v3 (baseada em disassembly)

### Princípio: Atacar as TRÊS root causes

| Tabela | Root Cause | Ação | Group | Slot |
|--------|-----------|------|-------|------|
| **T11** (3→2 DN) | #1: envia para 1ª em coasting | **BAIXAR** rows 0-6 de 20→12 km/h | Group 2 | SLOT_??25 |
| **T10** (2→1 alt) | #2: traps em 1ª | **BAIXAR** rows 0-4 de 23→15 km/h | Group 2 | SLOT_1_2 |
| **T4** (1→2 UP) | #3: gap em tip-in | **BAIXAR** row 3 de 23→18 km/h | Group 1 | SLOT_1_2 |
| T5 (2→1 DN) | — | **MANTER** em 12 km/h | Group 1 | SLOT_??25 |

### Patch 1 — Table 11 (SLOT_??25 em Group 2): PRIORIDADE CRÍTICA

**Objetivo:** Baixar o piso de 2ª marcha no downshift eval de 20→12 km/h. Isso impede 3→1 acima de 12 km/h em coasting.

| Row | Throttle % | Original | Proposta | Efeito |
|-----|-----------|----------|----------|--------|
| 0 | 0 | 20 | **12** | Coasting: target=2 até 12 km/h |
| 1 | 0 | 20 | **12** | idem |
| 2 | 0 | 20 | **12** | idem |
| 3 | 20 | 20 | **12** | Tip-in leve: target=2 |
| 4 | 39 | 20 | **12** | idem |
| 5 | 60 | 20 | **12** | idem |
| 6 | 85 | 20 | **12** | idem |
| 7 | 93 | 31 | 31 | Inalterado (WOT) |
| 8 | 93 | 35 | 35 | Inalterado |
| 9 | 99.6 | 53 | 53 | Inalterado |

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

| Row | Throttle % | Original | Proposta | Efeito |
|-----|-----------|----------|----------|--------|
| 0 | 0 | 23 | **15** | Pode sair de 1ª a 15 km/h |
| 1 | 0 | 23 | **15** | idem |
| 2 | 12 | 23 | **15** | idem |
| 3 | 20 | 23 | **15** | idem |
| 4 | 39 | 23 | **15** | idem |
| 5 | 59 | 28 | 28 | Inalterado |
| 6 | 80 | 39 | 39 | Inalterado |
| 7-9 | 93-99.6 | 56-57 | inalterado | WOT kickdown preservado |

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
|-----|-----------|----------|----------|
| 3 | 25 | **23** | **18** |

**Simulação:** A 20 km/h, 25% throttle (Group 1): `20 >= 18 → target=2 → OK`. Original: `20 < 23 → target=1 → 3→1`.

```
Bytes: 1 × float32 = 4 bytes
Offset 0x184B28: 41 B8 00 00 → 41 90 00 00  (23.0 → 18.0)
```

### Table 5 — MANTER em 12 km/h (decisão anterior confirmada)

T5 preenche SLOT_??25 no Group 1. Com T5=12 e T4 patcheado para 18: hysteresis = 6 km/h (12↔18). Saudável.

---

## Análise de Segurança

### Patch 1 (T11): Risco de band protection

- **Trade-off real:** Baixar T11 de 20→12 permite 2ª marcha em coasting entre 12-20 km/h. A cinta vê torque reverso nessa faixa.
- **Mitigante:** A 12-20 km/h, a energia cinética do veículo é baixa. O estresse na cinta por torque reverso é proporcional à velocidade (e ao RPM resultante em 2ª). A 15 km/h em 2ª, RPM ≈ 1000-1200 — mínimo.
- **Comparação BH:** O firmware BH usava T5=7 km/h (2→1 em Group 1). Se a Ford permitia 2ª gear até 7 km/h no BH, a cinta suporta operação a velocidades baixas.
- **DESCONHECIDO:** Se há outros mecanismos de proteção da cinta (ex: EPC pressure reduction em coasting) que tornem o threshold de T11 menos crítico.

### Patch 2 (T10): Risco mínimo

- T10 só afeta o escape de 1ª. Baixar de 23→15 significa que o carro pode sair de 1ª 8 km/h mais cedo. Não afeta band protection (1ª usa OWC, sem cinta).

### Patch 3 (T4): Risco mínimo (já analisado na v2)

- Scope mínimo (1 row). Em tip-in, motor está tracionando (sem torque reverso). Hysteresis T5/T4 = 12/18 = 6 km/h. Saudável.


---

## Cenários Antes/Depois (v3)

### Cenário 1: Coasting 3→1 @ 17.6 km/h (FORScan confirmado)

| Etapa | ANTES | DEPOIS (Patches 1+2) |
|-------|-------|----------------------|
| 3ª, 17.6 km/h, 0% thr | Group 2: SLOT_??25=T11=20 | SLOT_??25=T11=**12** |
| gear_zone_evaluator | 17.6 < 20 → target=**1** | 17.6 >= 12 → target=**2** |
| Resultado | **3→1 direto (solavanco)** | **3→2 (suave)** ✓ |

### Cenário 2: Tip-in @ 20 km/h, 25% throttle

| Etapa | ANTES | DEPOIS (Patch 3) |
|-------|-------|-------------------|
| 3ª, 20 km/h, 25% thr | Group 1: SLOT_1_2=T4=23 | SLOT_1_2=T4=**18** |
| gear_zone_evaluator | 20 < 23 → target=**1** | 20 >= 18 → target=**2** |
| Resultado | **3→1→2 cascade** | **3→2 (suave)** ✓ |

### Cenário 3: Coasting profundo (30→10 km/h)

| Etapa | ANTES | DEPOIS |
|-------|-------|--------|
| 20 km/h, 0% | 3ª (T11=20, speed=20 → target=2) | 3ª (T11=12, speed=20 → target=2) ✓ |
| 15 km/h, 0% | 3→1 (17.6<20 → target=1) | **3→2** (15 >= 12 → target=2) ✓ |
| 11 km/h, 0% | Preso em 1ª | **2→1** (11 < 12 → target=1) normal |
| Parado | 1ª (OWC freewheel) | idem ✓ |

### Cenário 4: Preso em 3ª de 20→45 km/h (aceleração leve)

| Etapa | ANTES | DEPOIS |
|-------|-------|--------|
| 25 km/h, 15% thr, 3ª | Preso em 3ª | **Ainda preso em 3ª** (não alteramos 3→4/2→3 logic) |

**Nota:** O cenário "preso em 3ª" continua. T11 patcheado impede 3→1, mas não force 3→2. A decisão de sair de 3ª depende do state machine (0xB1130), não apenas do evaluator. A melhoria é que, se o state machine decidir descer, o target agora será 2ª (não 1ª).

---

## Resumo dos Patches (v3)

| # | Tabela | Offsets | Bytes | Original → Proposta | Prioridade |
|---|--------|---------|-------|---------------------|-----------|
| 1 | T11 (3→2 DN) | 0x184DB0-0x184DE0 | 28B | 20.0→12.0 (7 rows) | **CRÍTICA** |
| 2 | T10 (2→1 alt) | 0x184D50-0x184D70 | 20B | 23.0→15.0 (5 rows) | ALTA |
| 3 | T4 (1→2 UP) | 0x184B28 | 4B | 23.0→18.0 (1 row) | ALTA |

**Total: 52 bytes alterados.**

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

1. **Checksum:** Resolver algoritmo (doc 25) antes de aplicar patch
2. **Teste cobaia:** Flashear AA modificado para confirmar que ELMConfig corrige checksums
3. **Decisão do operador:** Aplicar os 3 patches juntos ou em fases?
   - **Sugestão:** Patch 1 (T11) + Patch 3 (T4) primeiro. Se hunting 1↔2 ocorrer, adicionar Patch 2 (T10).
4. **Validação em campo:** Testar cenários 1-4 com FORScan logging
5. **Monitorar band:** Se preocupação com cinta, valores intermediários de T11 podem ser testados (ex: 15 km/h em vez de 12)

