# 59 — `fmadds` `3FC1A4` e `sub_91E3C` (`3FC190==0x10`)

**Data:** 2026-09-25  
**Status:** estático; `add_func(0x91E3C)` → `sub_91E3C` `0x91E3C`–`0x92290`  
**Dependência:** docs 54, 58  
**Calls no dispatcher:** `0x9EB64` → `0x86D00` (`sub_86CFC`); `0x935E8` → `0x91E40`

---

## Resumo Executivo

1. **FATO:** o OR `{3FC34E, 3FC3D4, 3FC381}` **não** escolhe tabela 1D. Em `sub_86CFC` habilita _slew_ de `0x3FC1A4`: `fmadds` para cima (cap `31.875`) ou `fnmsubs` para baixo (floor `0.25`).
2. **FATO:** `3FC1A4==31.875` → `stb 1` em `0x3FC3D0`; `==0.25` → `stb 0` (`0x86F2C`). Unique `stb` SIMM `C3D0`.
3. **FATO:** `sub_91E3C` só corre se `3FC3D0≠0`. Com `3FBBCC==8` exige `3FC190==0x10` (`0x91F64` / `0x91FD4`). Output: `stb 0x3FC3CE` @ `0x92120`.
4. **FATO:** o `fsubs` de `3FC34E` em `sub_87F8C` está **morto**: `lbz 0x18677A` = **2**, `cmpwi 1` / `bne 0x88214`.

---

## `sub_86CFC` (FATO)

```
86d1c  r26 = 0x3FC08C                 ; writer: cal_mod_weighted_blend_to_3FC08C @ 0x88DC0
86d10  f1 = 75.0 (186194)
86d28  blt → se 75 < 3FC08C então f2=0 senão f2=100.0
86d50  stfs  3FBCCC / 3FC05C
86d6c  1D 186E24 / 186D3C via sub_81544 → stfs 3FBD90
; 2ª passagem com 0.40 (186198) → stfs 3FBD94 @ 86E00
86e04  lfs   f1, 3FC0DC               ; shift_threshold_compute @ 0x935C4
86e0c  lfs   f11, 3FBD90
86e14  bge   86E80                    ; 3FC0DC >= envelope alta
```

### Slew (FATO)

`3FC22C` ← `f3 * 20.0` (`188290`) @ `0x814CC` em `sub_81238`.  
`f3` = `fdivs … / 40.0` (`18828C`) também `stfs 3FBC1C` @ `0x81468`.

`3FC1A8` ← 1D `184700` eixo **`3FBD6C`** @ `0x982A0` (`shift_adj_1d_bank_97FA4`).  
`3FC1AC` ← 1D `184748` mesmo eixo @ `0x982C4`.

```
; UP: 3FC0DC < 3FBD90 e OR{3FC34E,3FC3D4,3FC381}≠0
86e5c  fmadds f2, 3FC1A8, 3FC22C, 3FC1A4
86e6c  cap 31.875 (1882F4)

; DOWN: 3FC0DC > 3FBD94, ou UP com OR==0
86ed0  fnmsubs f2, 3FC1AC, 3FC22C, 3FC1A4
86ee0  floor 0.25 (1882A4)

86ef4  stfs f2, 3FC1A4                 ; unique stfs SIMM C1A4
86f08  se 3FC1A4==31.875 → r31=1
86f1c  se 3FC1A4==0.25  → r31=0
86f2c  stb r31, 3FC3D0                 ; senão não escreve
```

Se OR≠0 e `3FBD90 ≤ 3FC0DC ≤ 3FBD94`: `b 0x86EF8` — **não** slewa neste tick.

Scan `lfs`/`stfs` SIMM `C1A4` = só este fn. `3FC1A4` é estado interno; o efeito exportado é `3FC3D0`.

---

## `sub_87F8C` (FATO — morto)

```
87f9c  lbz  byte_18677A               ; ROM = 2
87fa0  cmpwi r12, 1
87fa4  bne  88214                     ; salta o fsubs 3FD3E4−3FBC1C @ 88160
```

OR `{3FC34E,…}` neste fn **não corre** em AA.

---

## `sub_91E3C` (FATO)

Prologue `0x91E3C` (`stwu`); call `0x91E40` @ `0x935E8` se `lhz 3FBBCC ≠ 0`.

```
91e44  lhz  r5, 3FBBCC
91e4c  lbz  r3, 3FC3D0
91e54  beq  +0x224                    ; 3FC3D0==0 → sai sem store
91e58  cmpwi r5, 3 / 5 / 6 / 7 / 8 / 9 / 0x21 / 0x32 …
91f40  cmpwi r5, 8
91f64  lbz  3FC190
91f68  cmpwi 0x10
91f6c  bne  skip
91f74  lbz  3FC128  vs byte_186730=3
91f8c  lbz  3FC12B  vs byte_186733=2
92120  stb  r4, 3FC3CE                ; r4∈{0,1}
```

`3FC128`/`3FC12B` writers: `cal_mod_mode0_reset_state` `0x896E0` e clones `0x89D84` / `0x8A0F4` / …

`3FC3CE` é também escrito em `shift_threshold_compute_with_mode` (`0x9230C`+). `sub_91E3C` é um **override** com `3FC3D0` armado.

---

## `sub_86654` (FATO — outro OR, outro alvo)

Mesmo OR @ `0x8675C` → `stfs 0.25 → 3FBF80` e `stb 3FC395/396`. Não toca `3FC1A4`. Call `0x9EB34`.

---

## Impacto

`3FC34E` (gémeo `r6==0x10`) **não** muda S28. Liga o slew que pode pôr `3FC3D0=1`, o que autoriza `sub_91E3C` a escrever `3FC3CE` — flag do compute de threshold (`0x93510`), **se** `3FBBCC==8` e `3FC190==0x10`.

Sem `3FC3D0=1`, o teste `3FC190==0x10` @ `0x91F64` **não executa**.

`3FC1A8`/`3FC1AC` dependem do eixo de peso `3FBD6C` (doc 54). O OR do gémeo só liga/desliga o passo; o tamanho do passo vem da cal 184700/184748.

---

## Dump vivo — diferido

| EA         | Porquê                           |
| ---------- | -------------------------------- |
| `0x3FC1A4` | slew; sentinelas 0.25 / 31.875   |
| `0x3FC3D0` | gate de `sub_91E3C`              |
| `0x3FC3CE` | output do helper                 |
| `0x3FC0DC` | threshold comparado às envelopes |
| `0x3FBBCC` | case; `8` exige `3FC190==0x10`   |
| `0x18677A` | confirmar 2 (já ROM)             |

---

## Resumo Executivo BRUTAL

- **Provado:** `{3FC34E,8,4}` slewa `3FC1A4` ∈ `[0.25, 31.875]` vs `3FC0DC` e 1D de `3FC08C`. Export = `3FC3D0`.
- **Provado:** `3FC190==0x10` só é consultado em `sub_91E3C` com `3FC3D0≠0` e `3FBBCC==8`.
- **Provado:** `sub_87F8C` / `18677A≠1` — o `fsubs` do mesmo OR está morto.
- **Próximo estático:** **esgotado neste bloco.** `3FC3CE` unique `lbz` = `0x86F4C`. `3FC210` unique SIMM no bin = `addi 0x86F54`; `lfs`/`stfs` SIMM `C210`/`3DF0` = 0. O gémeo **não** tem efeito de scheduling provado. Impacto vivo = `3FC34C`→S28/S24 (docs 55–56). Dump `3FC34C`/`3FBBB0`.
