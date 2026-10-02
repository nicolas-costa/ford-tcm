# 55 — Inventário 1D do dispatcher `0x9D860`

**Data:** 2026-09-25  
**Status:** 42 lookups no fn; papéis por store/Y; IDB = AA stock  
**Dependência:** docs 24, 50, 54

---

## Resumo Executivo

1. **FATO:** `shift_table_group_dispatcher` @ `0x9D860`–`0x9EBCC` faz **42** `lis r3,0x18` + `addi` → trampolim 1D. 30 footers únicos.
2. **FATO:** eixo dos 184/182 de marcha neste fn é `0x3FC1BC` (exceto GATE `0x3FD464` e o blend Group5 que mistura `0x3FD3F4` em T4).
3. **FATO:** S28 (`0x3FBC28`) **não** é T8 único. Três fontes: `0xFF`, `184F28` (piso 76), blend T8 `184CE8` (+ `182898` Y=−5 @ WOT).
4. **FATO:** a maioria das 182 no blend tem Y=0; as que não: `182AE0` −7, `182898`/`1828F0` −5, `180xxx` −1…−3 (doc 54).

---

## Árvore de grupos (FATO — `cmp`/`beq` no dispatcher)

| Condição                              | Destino   | S24–S27                                        | S28                                               | S29                                          |
| ------------------------------------- | --------- | ---------------------------------------------- | ------------------------------------------------- | -------------------------------------------- |
| `*(0x3FC34C)==0` @ `0x9DEA8`          | `0x9E12C` | (segue Group1/2/…)                             | **`0xFF`** `0x9E134`                              | ROM `0x186765`=**13**                        |
| `3FC34C≠0` ∧ `3FC3A1==0` ∧ `3FC372≠0` | `0x9DEEC` | —                                              | **`184F28`** `stb 0x9DF04`                        | **`184F88`** `stb 0x9E148` (salta `0x9E13C`) |
| `3FC34C≠0` ∧ G5=`3FC384`≠0            | `0x9DF60` | —                                              | **`182788` Y=255**                                | `1827A0` Y=255 → r31, mesmo `0x9E140`        |
| `3FC34C≠0` ∧ G5=0                     | `0x9DFA8` | —                                              | blend **T8 `184CE8`** + 0·`182DD0` + `182898`·wB0 | blend T9 `184D48` + `182E28` + `1828F0`      |
| `3FC3F0≠0` ∨ `3FC392≠0` @ `0x9E168`   | Group1    | T6/T5/T4/T7                                    | **`0xFF`** `0x9E19C`                              | `186765`=13                                  |
| `3FC364≠0` ∧ `3FC366==0` @ `0x9E2C4`  | Group3    | `1826F8`→S26 **e** S24; `182728`→S25 **e** S27 | —                                                 | —                                            |
| `3FC372≠0` @ `0x9E360`                | Group2    | T12/T13/T10/T11                                | (vem do bloco S28 acima)                          |                                              |
| G5=`3FC384≠0` @ `0x9E434`             | Group4    | T6→S26, T7→S27, T4→S24, T5                     | —                                                 |                                              |
| G5=0                                  | Group5    | T4/T6 + blend 182/180 (doc 54)                 | (bloco S28)                                       |                                              |

Citação S28=`0xFF` quando `3FC34C==0`:

```
9dea8  lbz  0x3FC34C
9deac  beq  9E12C
9e12c  li   r11, 0xFF
9e134  stb  r11, -0x43D8     ; 0x3FBC28
```

`gear_zone_evaluator`: em 3ª, `speed >= S28` → target 4ª (`0x83804`). S28=255 **bloqueia 3→4** por este slot.

---

## Mapas 184xxx (já no doc 24) — confirmação de store

| Footer   | Doc 24      | Y @ X baixo | Store                |
| -------- | ----------- | ----------- | -------------------- |
| `184B68` | T4 1→2      | 17          | S24 Group1/4/5       |
| `184BC8` | T5 2→1      | 12          | S25                  |
| `184C28` | T6 2→3      | 28          | S26                  |
| `184C88` | T7 stay-3rd | 12          | S27 Group4 `0x9E4A8` |
| `184CE8` | T8 3→4      | 40          | S28 blend G5         |
| `184D48` | T9 3→4 alt  | 28          | S29 blend G5         |
| `184DA8` | T10         | 23          | S24 Group2           |
| `184E08` | T11         | 20          | S25/S26 Group2       |
| `184E68` | T12         | 50          | S26 Group2           |
| `184EC8` | T13         | 44          | S27 Group2           |

---

## Não estavam no conjunto “10 tabelas”

### `184F28` / `184F88` → S28 / S29 (flag `3FC34C`)

| Footer                | n   | Y (stock)                             | X        |
| --------------------- | --- | ------------------------------------- | -------- |
| `184F28` ptr `184ED0` | 11  | **76** até X=55; 109 @ 59; 154 @ 99.6 | throttle |
| `184F88` ptr `184F30` | 11  | **60** até X=54; 93 @ 78; 144 @ 99.6  | throttle |

Piso 76 vs T8 piso 40: com `3FC34C` ligado, 3→4 pede **mais velocidade** que o blend T8.

### Group3 `1826F8` / `182728` (n=5, eixo `3FC1BC`)

| Footer   | Y                                | Store                             |
| -------- | -------------------------------- | --------------------------------- |
| `1826F8` | 25 @ X=12–70; 40 @ 79; 53 @ 99.6 | S26 **e** S24 `0x9E31C`/`0x9E320` |
| `182728` | 12 @ X=20–87; 33 @ 88; 45 @ 99.6 | S25 **e** S27 `0x9E354`/`0x9E358` |

### Saturadores `182788` / `1827A0`

Y=**255** (n=2). S28/S29 → 0xFF quando G5≠0 no ramo `3FC34C`.

### Override `182758` @ `0x9E284`

Y=30 @ 12–76; 77 @ 80; 90 @ 99.6 → **S26** `0x9E29C`. Ao lado: S28=`0xFF`, S27=`*(0x18676E)`=**2**, S24=0 (`0x9E2B8`).

### GATE `185708` / `185750`

Y stock 5/10 (doc 50; v6 zera no bin de pista, **não** neste IDB).

---

## Blend 182/180 — o que não é zero (AA)

| Footer                                                                  | Y ≠ 0              | Slot              |
| ----------------------------------------------------------------------- | ------------------ | ----------------- |
| `182AE0`                                                                | −7 @ X≈99.6        | S26 Group5        |
| `182898`                                                                | −5 @ 99.6          | S28 blend         |
| `1828F0`                                                                | −3 @ 93; −5 @ 99.6 | S29 blend         |
| `180A38`/`180AD8`/`180B10`/`180A70`                                     | −1…−3              | S24/S26/GATE path |
| `182D78` `182C70` `182D20` `1829A0` `182CC8` `182948` `182DD0` `182E28` | **0**              | mortos            |

---

## Contagem

42 sites. Primários 184: 10 do doc 24 + **2** (`184F28`/`184F88`). Resto: GATE, Group3, saturadores, aditivos, zeros.

---

## Dump vivo — diferido (acrescento)

| EA                      | Porquê                      |
| ----------------------- | --------------------------- |
| `0x3FC34C`              | liga `184F28` vs S28=`0xFF` |
| `0x3FBC28` / `0x3FBC29` | S28/S29 efetivos            |
| `0x3FC364` / `0x3FC366` | Group3                      |

---

## Resumo Executivo BRUTAL

- **Provado:** 42 lookups; S28=`0xFF` se `3FC34C==0` (3→4 por este slot off).
- **Provado:** `184F28` piso **76** é 3→4 alternativo, não T8.
- **Provado:** Group3 `1826F8`/`182728` grava pares de slots iguais.
- **Próximo estático:** cadeia `r31==0x10` fechada no doc 57.
