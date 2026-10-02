# 56 — Writer de `0x3FC34C` (one-hot com G5)

**Data:** 2026-09-25  
**Status:** writer vivo no dispatcher; IDA: `sub_8251C` `0x8251C`–`0x829E4` (criada 2026-09-25)  
**Dependência:** docs 24, 55, 57

---

## Resumo Executivo

1. **FATO:** nenhum `stb -0x3CB4` no código que o IDA linearizou. Os stores estão em **PPC não definido** (bytes `9B CC C3 4C` / `98 C5 00 00`).
2. **FATO:** writer vivo: `0x8251C` (entry usada `0x82520`), `blrl` desde o dispatcher `0x9E87C` **antes** do `lbz 3FC34C` @ `0x9DEA8`.
3. **FATO:** `3FC34C = 1` sse o classificador deixa `r31==0x10`; senão este byte é 0 (clear + one-hot).
4. **FATO:** o mesmo bloco one-hot grava flags irmãos por `cmpwi r31, {0x10,8,4,2,1}`. `r31==4` → `0x3FC37C` (não confundir com G5 `0x3FC384` = `-0x3C7C`).

---

## Call (FATO)

```
9e87c  lis   r10, 8
9e880  addi  r10, r10, 0x2520    ; 0x82520  (salta o stwu @ 8251C)
9e884  mtlr  r10
9e888  blrl
; … mais tarde …
9dea0  addi  r30, r30, -0x3CB4   ; 0x3FC34C
9dea4  lbz   r10, 0(r30)
```

Prologue @ `0x8251C` (bytes, IDA `.byte`):

```
8251c  94 21 FF E8    stwu r1, -0x18(r1)
82520  93 C1 00 10    stw  r30, 0x10(r1)
82528  3C 60 00 40    lis  r3, 0x40
8252c  38 63 DA 49    addi r3, r3, -0x25B7   ; 0x3FDA49
82538  88 84 DA 48    lbz  r4, -0x25B8(r4)   ; 0x3FDA48
```

---

## Stores para `0x3FC34C` (FATO — words)

| EA        | Word          | Instrução               | Valor                            |
| --------- | ------------- | ----------------------- | -------------------------------- |
| `0x827B0` | `38 A5 C3 4C` | `addi r5, r5, -0x3CB4`  | ptr                              |
| `0x827B4` | `98 C5 00 00` | `stb r6, 0(r5)`         | **r6=0** (`li r6,0` @ `0x82780`) |
| `0x82808` | `3D 80 00 40` | `lis r12, 0x40`         |                                  |
| `0x8280C` | `9B CC C3 4C` | `stb r30, -0x3CB4(r12)` | **1 se `r31==0x10`**, senão 0    |

```
827f4  cmpwi r31, 0x10
827f8  bne   82804
827fc  li    r30, 1
82800  b     82808
82804  li    r30, 0
82808  lis   r12, 0x40
8280c  stb   r30, -0x3CB4(r12)    ; 0x3FC34C
```

Bloco `0x82780` só corre se `r31 < 0x20` (`cmpwi r31, 0x20` / `blt` @ `0x82778`). Com `r31∈{0x20,0x40,0x80}` o one-hot `0x10` **não** é escrito neste tick — o clear `827B4` também não.

---

## One-hot do mesmo `r31` (FATO)

Após `8280C`, a mesma sequência `cmpwi` / `li 0/1` / `stb`:

| `r31`  | `stb` EA  | Destino        | SIMM      |
| ------ | --------- | -------------- | --------- |
| `0x10` | `0x8280C` | **`0x3FC34C`** | `-0x3CB4` |
| `8`    | `0x82828` | `0x3FC32E`     | `-0x3CD2` |
| `4`    | `0x82844` | `0x3FC37C`     | `-0x3C84` |
| `2`    | `0x82860` | `0x3FC366`     | `-0x3C9A` |
| `1`    | `0x8287C` | `0x3FC352`     | `-0x3CAE` |

`0x3FC384` (G5, `lbz -0x3C7C` @ `0x9E438`) **não** é o store `0x82844`. G5 é byte distinto.

`r31=0x10` é atribuído em `0x826E8` (`3B E0 00 10`). Predicado exacto (doc 57): (`r31==0` ∧ `3FBF54==0.25` ∧ `3FC350≠0`) **ou** `3FBBB0≠0` (override). **DESCONHECIDO:** nome do modo (não é o bitmask de marcha 1/2/4/8 do avaliador).

Outros `li r31`: `0x20` @ `0x825B8`, `0x40` @ `0x825F0`, `0x80` @ `0x82628`, `1` @ `0x826A0`, `8` @ `0x82718`, `4` @ `0x82740`, `2` @ `0x82768`.

---

## Segundo encoding `0x9EF00` (FATO + alcance)

```
9eee0  38 60 00 01    li  r3, 1
9ef00  98 6C C3 4C    stb r3, -0x3CB4(r12)   ; 0x3FC34C = 1
```

Região `0x9EE08+` está `.byte` no IDA. Scan de `b`/`bl` para `0x9EE00`–`0x9EF20` no `.text` definido = **0**. Tratar como **não alcançável** até prova em contrário.

---

## Impacto

Cada passagem do dispatcher **reclassifica** `3FC34C` em `0x82520` e só depois escolhe S28.  
`3FC34C==0` → S28=`0xFF` (doc 55).  
`3FC34C==1` → `184F28` (piso 76) se `3FC372≠0`.

---

## Dump vivo — diferido

| EA                      | Porquê                      |
| ----------------------- | --------------------------- |
| `0x3FC34C`              | one-hot `r31==0x10`         |
| `0x3FC37C` / `0x3FC384` | irmão `r31==4` vs G5        |
| `0x3FBBB0` / `0x3FC350` | condições do `li r31, 0x10` |

---

## Resumo Executivo BRUTAL

- **Provado:** `3FC34C` ← `stb` `0x8280C` no classificador `0x8251C`, chamado de `0x9E888`.
- **Provado:** vale 1 só com `r31==0x10`; o IDA escondeu o store (`.byte`).
- **Provado:** `9EF00` escreve 1 mas **sem xref**.
- **Próximo estático:** docs 57–58. `3FC34C` também rate-limita S24 (`0x83674`).
