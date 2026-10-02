# 61 — Pipeline GT → request → GR (`0x83AE0` / `0x83E04` / `0x84774`)

Escopo: despacho após `gear_zone_evaluator`. Sem dump vivo. Sem PHF.

## Dispatcher (FATO)

`0x9E974` `blrl` `gear_zone_evaluator` → `0x9E994` `blrl` `0x83AE0` → `0x9E9A4` `blrl` `0x83E04` → flags `3FC3CD` @ `0x9E9E8` → `0x9E9F8` `blrl` `0x84774` → `0x9EA08` `blrl` `0x84DE8`.

Antes do evaluator, se `r3==0`:

```
9E93C  lbz  r11, -0x3EFA(r11)   ; 3FC106 GR
9E944  stb  r11, -0x3EFB(r12)   ; 3FC105
```

Cópia GR→`3FC105` também em `0x832A8`–`0x832B4` (`lbz 3FC106` / `stb 3FC105` / `blr`). O `blrl` seguinte do dispatcher aponta `0x832BC` (função seguinte), não este snippet.

IDA: `add_func` `0x83AE0`–`0x83E00`, `0x83E04`–`0x84720`, `0x84774`–`0x84DE4`, `0x84DE8`–`0x84FC8`. Nomes: `gear_filter_GT_to_3FC238`, `gear_commit_3FC104`, `gear_update_GR_3FC106`.

## Bytes de marcha (FATO)

| EA       | Papel no código desta cadeia                                       |
| -------- | ------------------------------------------------------------------ |
| `3FC239` | GT: escrito pelo evaluator; lido `0x83D64`                         |
| `3FC238` | request filtrado: único `stb` runtime `0x83DF4` (`r7` ∈ {1,2,4,8}) |
| `3FC104` | commit: `stb` `0(r4)` com `r4=3FC104` @ `0x83F50` e SIMM `C104`    |
| `3FC105` | snapshot; dispatcher copia GR; `0x83E04` lê como estado            |
| `3FC106` | GR: lido pelo evaluator; **escrito em runtime só via `0(r28)`**    |

Init `0x9EE7C` `li r4, 8` depois `0x9F014`/`0x9F01C`/`0x9F024`/`0x9F02C` `stb r4` → `3FC239`/`3FC238`/`3FC104`/`3FC106` (default bitmask 4ª). Único `stb` com SIMM `C106` no range `0x8000`–`0xC0000`.

## `gear_filter_GT_to_3FC238` (`0x83AE0`)

Flags booleanas (não são GR):

| EA      | store             | dest     |
| ------- | ----------------- | -------- |
| `83B60` | `stb r7, -0x43BA` | `3FBC46` |
| `83BC0` | `stb r3, -0x3C8B` | `3FC375` |
| `83C1C` | `stb r7, -0x3C89` | `3FC377` |
| `83CB4` | `stb r6, -0x3C88` | `3FC378` |
| `83D5C` | `stb r5, -0x3C87` | `3FC379` |

Cauda (GT → request):

```
83D64  lbz   r4, -0x3DC7(r4)    ; 3FC239 GT
83D68  cmpwi r4, 8
...
83D94  li    r7, 8
...
83DC0  li    r7, 4
...
83DE4  li    r7, 2
83DEC  li    r7, 1
83DF4  stb   r7, -0x3DC8(r12)   ; 3FC238
83DFC  blr
```

Interpretação: `3FC238` é one-hot {1,2,4,8} derivado de `3FC239` com gates (`r3`/`r5`/`r6`/`r7` e `3FC376` @ `83D88`). Não escreve `3FC106`.

## `gear_commit_3FC104` (`0x83E04`)

```
83F40  lis   r4, 0x40
83F44  addi  r4, r4, -0x3EFC    ; 3FC104
83F48  lis   r31, 0x40
83F4C  lbz   r31, -0x3DC8(r31)  ; 3FC238
83F50  stb   r31, 0(r4)         ; *3FC104 = request
```

Outros `stb -0x3EFC`: `84394` (`li r11,4`), `843D8`, `84400` (copia `3FC238`), `84468` (`li r7,1`). Pointer `r3` desta função é `3FBDB5` (`83E74`), não GR. `lbz 3FC106` @ `83E88`/`84444` só lê.

`3FC104` SIMM-`stb` no ROM: `84394`, `843D8`, `84400`, `84468`, init `9F024`.

## `gear_update_GR_3FC106` (`0x84774`)

```
8490C  lis   r28, 0x40
84910  addi  r28, r28, -0x3EFA  ; 3FC106
84914  addi  r29, r28, 0        ; r29 = GR
```

`r28` permanece o ponteiro GR até `84CF4` (`lbz r28, 0(r29)` clobber). Stores GR:

| EA      | valor escrito em `3FC106`                     |
| ------- | --------------------------------------------- |
| `84C48` | `stb 0(r29)` ← `*(3FD52A)` (`-0x2AD6`)        |
| `84C6C` | `stb r30, 0(r28)`                             |
| `84CF0` | `stb r31, 0(r28)` ← mapa de `*3FBE84` {2,4,8} |

Fontes de `r30` que caem em `84C6C` (XREF):

- `84B0C`: `r30 = *3FBDB4` (após cadeia `849C4` que copia `3FC104` para `3FBDB4` e pode promover 1→2→4→8).
- `84BD8`/`84BE8`/`84BF8`/`84C00`: `r30 ∈ {1,2,4,8}` a partir de `*(3FD8AD)` (`-0x2753`).
- `84C5C`: se `r31==1` @ `84C4C`, `r30 = *(3FD52B)` (`-0x2AD5`).
- `84C60` (de `84C0C`/`84C2C` `bne`): `lbz 3FC104` → `r30` → mesmo `stb`.

`84C74` `addi r30, -0x417C` → `3FBE84`. Se `*3FBE84 != 0`, corre `84CF0`. Com `18A8C0=0` a cadeia que põe `3FBE84=1` está morta (doc 58): esse store de GR não dispara no cal AA.

`0x849C4` `lbz 3FC104` → `stb 0(r31)` com `r31=3FBDB4` (staging, não GR directo).

## `sub_84DE8` (consumo)

Lê `3FC105` @ `84E64` e `3FC106` @ `84E74`+; espalha GR para ponteiros `3FC3B9`/`3FC3BB`/`3FC3BC`/`3FC3BE`/`3FC3BF`/`3FC3C1`/`3FC3CA` se `3FC36C` (`-0x3C94`) ≠ 0. **DESCONHECIDO:** se esses bytes são comando de solenóide (não citado doc 05 nesta sessão).

## HIPÓTESE

`3FC104` é o comando one-hot pós-filtro; `3FC106` é o GR que o evaluator usa no ciclo seguinte; `3FC105` é o GR do ciclo anterior (cópia pré-eval). Coerente com `9E93C`–`9E944` e com `83E04` lendo `3FC105` vs `3FC238`.

## DESCONHECIDO

- Condição exacta `r31` @ `84C4C` (origem do valor).
- Consumidores PWM/TPU de `3FC3B9`–`3FC3CA`.
- Corpo `0x84FCC` / `0x8518C` / `0x8534C`.

## Resumo executivo

- GT `3FC239` → filtro `0x83AE0` → `3FC238` @ `83DF4`.
- `0x83E04` grava `3FC238` em `3FC104` @ `83F50`; não grava `3FC106`.
- GR runtime: `stb 0(r28)` em `0x84774` (`84C48`/`84C6C`/`84CF0`); SIMM `C106` só no init `r4=8`.

**Próximo passo (ROI):** linearizar `0x84FCC` e quem lê `3FC3B9`–`3FC3CA` até TPU/PWM.
