# 58 — Gémeo `0x829E8`, `3FC18C` morto, `3FBE84` morto

**Data:** 2026-09-25  
**Status:** estático; `sub_829E8` já definida; `0x91E3C` continua `.byte`  
**Dependência:** docs 56, 57  
**Call:** dispatcher `0x9E898` imediatamente após `0x82520`

---

## Resumo Executivo

1. **FATO:** `3FC188` é **sobreescrito** com modo `0x2B`/`0x2C`/… @ `0x82928`. `lfs` de `3FC18C` no intervalo `0x10000`–`0xC0000` = **0**. O float `0x9571C` não tem consumidor.
2. **FATO:** o gémeo `sub_829E8` grava o bitmask **cru** em `0x3FC190` e o modo em `0x3FC411`. `3FC190` tem leitores vivos. `3FC411` não (só `0x9F0D0` inalcançável).
3. **FATO:** `3FBE84=1` não tem writer vivo. `byte_18A8C0=0` → `sub_B9DB8` (`r3=0x2D`) sai em `0xB9F74` sem `stb 0(r12)`. Unique store = clear @ `0x84C7C`. Abort `r31=4` / `r6=4` é morto em AA.

---

## `3FC188` / `3FC18C` (FATO)

```
82770  stb   r31, 0(r30)           ; r30=0x3FC188  bitmask cru
82928  stb   r8,  0(r30)           ; SOBRESCREVE: 0x2B se 3FC3A1==1, senão 0x2C
                                   ; outros: 1→0x3C, 2→0x46/0x32, 4→0x15, 8→0x16, ≥0x20→0xA
956fc  lbz   r12, -0x3E78(r12)     ; 0x3FC188
9571c  stfs  f11, -0x3E74(r10)     ; 0x3FC18C = float(byte) via 0x43300000
```

`0x955AC` (entry usada `0x955B0`) é `blrl` @ `0x9D7EC` (antes do dispatcher) e `0x9ED1C` (depois). Snapshot do **modo**, não do bitmask.

Scan SIMM `C18C`/`3E74` com opcode `lfs` = 0.  
`stb 0x9EFF4` / `stfs 0x9F044` na região sem xref (doc 56).

**HIPÓTESE:** `0x2B`/`0x2C` em `3FC188` e o float `3FC18C` são resíduo. O sinal vivo do classificador `0x8251C` é o one-hot `3FC34C`.

---

## Gémeo `sub_829E8` (FATO)

```
9e88c  lis   r9, 8
9e890  addi  r9, r9, 0x29E8        ; sub_829E8
9e898  blrl
```

```
829ec  addi  r5, r5, -0x3E70       ; ptr 0x3FC190
82be4  stb   r6, 0(r5)             ; 3FC190 = {1,2,4,8,0x10,0x20,0x40,0x80}
82d88  stb   r5, -0x3BEF(r12)      ; 0x3FC411 = modo 0x2B/0x2C/…  (não pisa 3FC190)
```

One-hot se `r6 < 0x20` (`0x82BF0`):

| `r6`   | `stb`     | Destino        |
| ------ | --------- | -------------- |
| `0x10` | `0x82C80` | **`0x3FC34E`** |
| `8`    | `0x82C9C` | `0x3FC3D4`     |
| `4`    | `0x82CB8` | `0x3FC381`     |
| `2`    | `0x82CD4` | `0x3FC39F`     |
| `1`    | `0x82CF0` | `0x3FC3B1`     |

`li r6, 0x10` @ `0x82B98`:

```
82b70  cmpwi r6, 0
82b74  bne   82B88
82b7c  lbz   3FC350
82b84  bne   82B98                 ; r6==0 ∧ 3FC350≠0  (SEM 3FBF54)
82b8c  lbz   3FBBB0
82b94  beq   82BA0
82b98  li    r6, 0x10
```

Diferença vs `0x826E8` (doc 57): o gémeo **não** exige `3FBF54==0.25` no ramo A.

`3FC411`: unique `stb` @ `0x82D88`; unique outro hit `addi` @ `0x9F0D0` (sem xref). Modo do gémeo **sem leitor**.

---

## Leitores de `3FC190` (FATO)

`lbz -0x3E70`:

| EA        | Fn / contexto                                                                            | Teste                                                            |
| --------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `0x9C900` | `cal_mod_switch_and_pipeline_9AE3C`                                                      | `cmpwi 0x20` / `bgt 0x9C980` (salta pipeline se bitmask `>0x20`) |
| `0x91F64` | `.byte`; call `0x91E40` @ `0x935E8` em `shift_threshold_compute_with_mode` se `3FBBCC≠0` | `cmpwi 0x10` / `bne`                                             |
| `0x91FD4` | mesmo bloco                                                                              | idem `0x10`                                                      |

`3FC190==0x10` **não** passa o `bgt 0x20` @ `0x9C908`. `0x40`/`0x80` sim.

Gate extra @ `0x9C8E0`: se `f31==4762.5` (`flt_1882B8`) salta o teste `3FC190`.

---

## Leitores de `3FC34E` (FATO — não é S28)

`3FC34C` (doc 55/56) escolhe S28. `3FC34E` **não** entra no dispatcher 1D.

OR-group `{3FC34E, 3FC3D4, 3FC381}` = gémeo `{0x10, 8, 4}`:

| EA                    | Fn          | Acção se OR≠0                                          |
| --------------------- | ----------- | ------------------------------------------------------ |
| `0x86E1C` / `0x86E8C` | `sub_86CFC` | `fmadds` `3FC1A4 + 3FC1A8·3FC22C`, cap `1882F4=31.875` |
| `0x88124`             | `sub_87F8C` | `fsubs` `3FD3E4 − 3FBC1C`; skip se todos 0             |
| `0x8675C`             | `sub_86654` | mesmo OR                                               |

**HIPÓTESE:** `3FC34E` habilita um blend/ajuste paralelo; não escolhe tabela 1D.

---

## `3FC34C` extra (FATO — além do dispatcher)

| EA        | Fn                                          | Se `3FC34C≠0`                                                                            |
| --------- | ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `0x83674` | `gear_zone_evaluator` `0x83484`             | rate-limit **S24** `0x3FBC24` (`cal_rate_limiter_step_slot24`). `==0` → `0x837B0` (skip) |
| `0x88254` | `cal_mod_pre_gate_3FC008_3FC00C`            | OR com `3FC3D2` (`-0x3C2E`) e `3FC37C` (`-0x3C84`)                                       |
| `0x98150` | `shift_adj_1d_bank_97FA4`                   | OR com `3FC3D2` → `stb 3FC36E` (`-0x3C92`)                                               |
| `0x8497C` | fn indefinida (mesmo cluster que `0x84C7C`) | `==0` ∧ outros 0 → skip `0x84B10`                                                        |

---

## `3FBE84` (FATO — abort morto)

```
84c74  addi r30, r30, -0x417C      ; 0x3FBE84
84c7c  stb  r11, 0(r30)            ; r11=0  CLEAR
84c84  lbz  3FDC51
84c88  cmpwi 2
84c8c  bne  84CBC
84cb4  li   r3, 0x2D
84cb8  blrl sub_B9DB8              ; r4 = &ptr(3FBE84) no stack
```

`sub_B9DB8`:

```
b9dd4  lbz   3FDC51
b9dd8  cmpwi 2
b9ddc  bne   B9F74                 ; return
b9e10  lbz   byte_18A8C0           ; ROM 0x18A8C0 = 0x00 (bytes 00 18 9D 98 …)
b9e18  cmpwi r4, 0
b9e1c  ble   B9F74                 ; SEMPRE — tabela vazia, sem stb 0(r12)
```

Scan `stb` SIMM `DC51` = 0. Scan `stb` SIMM `BE84` = 0 (só `lbz` + o clear via ptr).

Abort:

```
82550  cmpwi 3FBE84, 1  → r31=4     ; sub_8251C
829F8  cmpwi 3FBE84, 1  → r6=4      ; sub_829E8
9D5A4  cmpwi 3FBE84, 0  → skip 9D124 se ≠0  ; sub_9D518
```

**HIPÓTESE:** `3FBE84` é canal IO id `0x2D` desligado na cal AA (`18A8C0=0`). Não mata `0x10` em stock.

---

## Impacto

O byte de modo `0x2B`/`0x2C` **não** escolhe mapa. O dispatcher lê `3FC34C`. O gémeo lê `3FC190` (bitmask) e `3FC34E` (blend).  
`3FC34C≠0` também rate-limita S24 — efeito **fora** do slot S28.

---

## Dump vivo — diferido (acrescentar)

| EA         | Porquê                                    |
| ---------- | ----------------------------------------- |
| `0x3FC190` | bitmask gémeo (esperado `0x10` se ramo B) |
| `0x3FC34E` | one-hot gémeo                             |
| `0x3FC411` | modo gémeo; sem leitor                    |
| `0x3FC18C` | float morto; confirmar 43/44              |
| `0x3FBE84` | esperado 0                                |
| `0x3FDC51` | gate B9DB8; esperado ≠2                   |

---

## Resumo Executivo BRUTAL

- **Provado:** `3FC18C` sem `lfs`. `3FC188` termina como modo `0x2B`/`0x2C`, não como bitmask.
- **Provado:** `sub_829E8` é o gémeo: cru→`3FC190`, one-hot `3FC34E`, modo morto→`3FC411`. Ramo `0x10` @ `0x82B98` **sem** teste `3FBF54`.
- **Provado:** `3FBE84=1` inalcançável (`18A8C0=0`). Abort `r31=4` morto.
- **Próximo estático:** doc 59. `fmadds` `3FC1A4` → `3FC3D0` → `sub_91E3C` (`3FC190==0x10` só se `3FBBCC==8`).
