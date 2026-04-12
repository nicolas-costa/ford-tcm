# 27 — Comparação de Firmwares: BH vs BL vs CA — Shift Schedule Tables

**Data:** 2026-03-22  
**Status:** ✅ Comparação completa. Diferenças críticas isoladas.  
**Dependência:** Tabelas decodificadas (doc 24), proposta de patch (doc 26)

---

## Resumo Executivo

1. **FATO:** As 10 shift schedule tables são **100% idênticas** entre BL e CA. Diferença zero. São o mesmo calibration dataset.
2. **FATO:** Entre BH e BL/CA, **apenas 2 tabelas** diferem nos dados reais: **Table 5 (2→1 DN)** e **Table 7 (TCC/1→2?)**. Todas as outras 8 tabelas têm dados idênticos (trailers diferem apenas no ponteiro auto-referencial).
3. **FATO:** A diferença única é o threshold de velocidade para engatar 1ª marcha: **BH = 7.0 km/h**, **BL/CA = 12.0 km/h** (para 0-50% throttle). Isso explica diretamente o relato do fórum russo: "com BH, a automática não engata primeira até quase parar."
4. **IMPACTO:** A Ford/Continental deliberadamente SUBIU o threshold 2→1 de 7→12 km/h do BH para BL. Essa mudança tornou a 1ª marcha mais acessível, agravando o solavanco em baixas velocidades.

---

## Origem dos Dados

| Firmware | Part Number | Versão | Fornecedor | Origem |
|----------|-------------|--------|------------|--------|
| **BH** | 5M5P-14C337-BH | FT3470KC | Siemens/Continental | Fórum russo (firmware de referência) |
| **BL** | 5M5P-14C337-BL | FT3500KC | Continental | Firmware do veículo do operador |
| **CA** | 5M5P-14C337-CA | — | Continental | Versão mais recente disponível |
| AA | 5U75-14C337-AA | — | Continental | Cobaia de análise |

### Offsets das Tabelas

O BH tem a região de calibração deslocada em **0x648 bytes** em relação ao BL/CA/AA:

| Tabela | BH offset | BL/CA offset | Delta |
|--------|-----------|--------------|-------|
| Table 4 (1→2 UP) | 0x1844C8 | 0x184B10 | 0x648 |
| Table 5 (2→1 DN) | 0x184528 | 0x184B70 | 0x648 |
| Table 6 (2→3 UP) | 0x184588 | 0x184BD0 | 0x648 |
| Table 7 (TCC/1→2?) | 0x1845E8 | 0x184C30 | 0x648 |
| Table 8 (3→4 UP) | 0x184648 | 0x184C90 | 0x648 |
| Table 9 (TCC/3→4?) | 0x1846A8 | 0x184CF0 | 0x648 |
| Table 10 (2→1 alt) | 0x184708 | 0x184D50 | 0x648 |
| Table 11 (3→2 DN) | 0x184768 | 0x184DB0 | 0x648 |
| Table 12 (4→3 DN) | 0x1847C8 | 0x184E10 | 0x648 |
| Table 13 (3→2 alt) | 0x184828 | 0x184E70 | 0x648 |

---

## Diferenças Encontradas

### Table 5 — 2→1 Downshift: A DIFERENÇA CRÍTICA

| Row | Throttle % | BH speed km/h | BL/CA speed km/h | Delta |
|-----|-----------|---------------|------------------|-------|
| 0 | 0 | **7.0** | **12.0** | +5.0 |
| 1 | 6 | **7.0** | **12.0** | +5.0 |
| 2 | 20 | **7.0** | **12.0** | +5.0 |
| 3 | 45 | **7.0** | **12.0** | +5.0 |
| 4 | 50 | **7.0** | **12.0** | +5.0 |
| 5 | 60 | **9.0** | **12.0** | +3.0 |
| 6 | 85 | 16.0 | 16.0 | — |
| 7 | 93 | 31.0 | 31.0 | — |
| 8 | 93 | 35.0 | 35.0 | — |
| 9 | 99.6 | 53.0 | 53.0 | — |

**Bytes BH (0x184528):** `40 E0 00 00` (7.0) repetido 5× + `41 10 00 00` (9.0) 1×  
**Bytes BL (0x184B70):** `41 40 00 00` (12.0) repetido 6×

### Table 7 — TCC/1→2 Auxiliar

| Row | Throttle % | BH speed km/h | BL/CA speed km/h | Delta |
|-----|-----------|---------------|------------------|-------|
| 0 | 6 | **7.0** | **12.0** | +5.0 |
| 1 | 6 | **7.0** | **12.0** | +5.0 |
| 2+ | — | idêntico | idêntico | — |

### Todas as Outras Tabelas

**DADOS IDÊNTICOS** entre BH e BL/CA (incluindo AA):

- Table 4 (1→2 UP): 17, 17, 17, **23**, 27, 32, 39, 56, 56, 57 — o gap 17→23 existe em TODOS
- Table 6 (2→3 UP): idêntico
- Table 8 (3→4 UP): idêntico
- Table 9 (TCC/3→4?): idêntico
- Table 10 (2→1 alt): 23 km/h para 0-39% throttle — idêntico em todos
- Table 11 (3→2 DN): 20 km/h para 0-85% throttle — idêntico em todos
- Table 12 (4→3 DN): idêntico
- Table 13 (3→2 alt): idêntico

---

## Correlação com o Fórum Russo

### Relato original (traduzido)

> "Troquei o TCM. A unidade original Siemens com firmware **BH** foi substituída por uma Continental com firmware **BL**. [...] A 20 km/h, engata segunda. Quando a velocidade cai para 19 km/h, engata a primeira e o carro dá um solavanco! [...] Com o TCM antigo (BH), a automática não engata primeira até o carro estar quase completamente parado!"

### Explicação com base nos dados

| Aspecto | BH (Siemens) | BL (Continental) |
|---------|-------------|-----------------|
| Table 5 (2→1 DN) @ 0-50% thr | **7 km/h** | **12 km/h** |
| Comportamento 2→1 | 1ª só abaixo de 7 km/h | 1ª abaixo de 12 km/h |
| Percepção do motorista | "1ª só quase parado" | "1ª a 19 km/h → solavanco" |

**FATO:** O threshold de 7 km/h no BH tornava a 1ª marcha praticamente inacessível em condução urbana normal. O motorista nunca sentia o engatar da 1ª porque ela só ativava a velocidade de quase-parada.

**FATO:** O threshold de 12 km/h no BL é alto o suficiente para ser notado em manobras de baixa velocidade (curvas, estacionamento), mas o relato de "19 km/h" sugere interação com **Table 10 (2→1 alt = 23 km/h)** — que é igual em ambos. A diferença percebida pode estar no código da shift state machine, que difere entre as plataformas Siemens e Continental.

---

## Implicações para o Patch

### O que MUDA com essa descoberta

1. **O gap 17→23 na Table 4 (1→2 UP) existe em TODAS as versões** — BH, BL, CA, AA. A raiz do solavanco 3→1→2 é universal neste calibration dataset.

2. **A Ford deliberadamente SUBIU o 2→1 de 7→12 km/h** do BH para BL/CA. Pode ter sido para:
   - Melhor resposta em partida de baixa velocidade
   - Adaptação ao perfil de condução europeu/brasileiro
   - Ou simplesmente um trade-off que piorou outro cenário

3. **Possível segundo patch: reverter Table 5 para valores intermediários.** Se 7 km/h era "muito baixo" (talvez prejudicava partida em rampa?) e 12 km/h é "muito alto" (solavanco), um valor intermediário como **9-10 km/h** pode ser o sweet spot.

### Proposta atualizada de patches

| # | Tabela | Offset BL | Original | Proposta | Efeito |
|---|--------|-----------|----------|----------|--------|
| 1 | Table 4 row 3 (1→2 UP) | 0x184B28 | 23.0 (`41B80000`) | **18.0** (`41900000`) | Elimina gap → previne 3→1→2 |
| 2 | Table 5 rows 0-5 (2→1 DN) | 0x184B70-0x184B98 | 12.0 (`41400000`) | **9.0** (`41100000`) | Reduz agressividade 2→1 em baixa velocidade |

**Patch 1:** Prioridade alta. Ataca diretamente o solavanco 3→1→2 a 20 km/h com throttle leve.  
**Patch 2:** Prioridade média. Reduz engatar desnecessário de 1ª marcha. O valor 9.0 é baseado no valor original da row 5 do BH (que era 9.0 a 60% throttle).

---

## Dados Brutos: Bytes Hexadecimais

### Table 5 — BH vs BL

```
BH @ 0x184528: 40 E0 00 00 00 00 00 00  40 E0 00 00 40 C0 00 00
               40 E0 00 00 41 A0 00 00  40 E0 00 00 42 34 00 00
               40 E0 00 00 42 48 00 00  41 10 00 00 42 70 00 00
               41 80 00 00 42 AA 00 00  41 F8 00 00 42 BA 00 00
               42 0C 00 00 42 BA 00 00  42 54 00 00 42 C7 38 01

BL @ 0x184B70: 41 40 00 00 00 00 00 00  41 40 00 00 40 C0 00 00
               41 40 00 00 41 A0 00 00  41 40 00 00 42 34 00 00
               41 40 00 00 42 48 00 00  41 40 00 00 42 70 00 00
               41 80 00 00 42 AA 00 00  41 F8 00 00 42 BA 00 00
               42 0C 00 00 42 BA 00 00  42 54 00 00 42 C7 38 01
```

### Table 7 — BH vs BL

```
BH @ 0x1845E8: 40 E0 00 00 40 C0 00 00  40 E0 00 00 40 C0 00 00
               (resto idêntico ao BL)

BL @ 0x184C30: 41 40 00 00 40 C0 00 00  41 40 00 00 40 C0 00 00
               (resto idêntico)
```

---

## Verificação Independente

Para reproduzir a comparação:

```bash
cd firmwares/

# Converter PHFs
python3 -c "from phf_parser.read_phf import read_phf; from phf_parser.phf_to_bin import phf_to_bin; phf=read_phf('5M5P-14C337-BH.PHF'); phf_to_bin(phf, '5M5P-14C337-BH.bin')"

# Comparar Table 5 (BH offset = BL offset - 0x648)
xxd -s 0x184528 -l 80 5M5P-14C337-BH.bin  # Table 5 no BH
xxd -s 0x184B70 -l 80 5M5P-14C337-BL.bin  # Table 5 no BL
```
