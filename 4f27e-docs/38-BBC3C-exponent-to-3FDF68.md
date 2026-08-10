# 38 — `0xBBC3C`: ajuste de expoente → `0x3FDF68`

**Data:** 2026-08-07  
**Status:** ✅ Contrato de `0xBBC3C` e ligação a `0x3FDF68` documentados  
**Dependência:** doc 37

---

## Resumo Executivo

1. **FATO:** `float_adjust_exponent_BBC3C @ 0xBBC3C` recebe **`r3`** (inteiro) e **`r4`** (delta de expoente IEEE), devolve **`f1`**.
2. **FATO:** algoritmo pós-conversão: extrai expoente do float; `new_exp = exp - r4`; se fora de 1..254 clampeia; senão reconstrói float (mantissa/sinal de `r6`, expoente novo).
3. **FATO:** em `veh_signal_to_3FDF68_block @ 0xBD400`, se `*(0x3FA7F2) != 255`, chama `BBC3C(r3=*(0x3FA7F2), r4=1)` e **`stfs f1 → 0x3FDF68`** (`0xBD4D8–0xBD4E0`).
4. **FATO (corrigido doc 43):** `*(0x3FA7F0)` → double/`fsub 1023.0` (`0x18A410`) → `0x3FE104` — opcode é **`fsub`**, não `fdiv`.
5. **FATO (doc 39):** writers via `r13+0x18Ex` em `0x4A90C` / `0x434D4` — não via `lis 0x40`.

---

## Função `0xBBC3C` (FATO — assembly)

```
bbc3c  lis   r12, 0x4330
bbc40  stw   r12, 0x10(r1)
bbc44  xoris r11, r3, 0x8000
bbc48  stw   r11, 0x14(r1)
bbc50  lfd   f13, 0x10(r1)         ; double(0x4330 || r3^0x8000)
bbc54  lfs   f12, flt_18A02C       ; **0.0** @ 0x18A02C
bbc58  fsub  f13, f13, f12
bbc5c  frsp  f13, f13
bbc60  stfs  / lwz → bits em r6
bbc68  extrwi r5, r6, 8,1          ; IEEE exponent
bbc6c  cmpwi r5, 0
bbc70  bne   …
bbc78  lfs   f1, -FLT_MAX          ; 0x18A030 = 0xFF7FFFFF
       blr
bbc80  subf  r3, r4, r5            ; r3 := exp - r4
bbc84  cmpwi r3, 0
bbc88  bgt   …
       → f1 = -FLT_MAX
bbc98  cmplwi r3, 0xFF
bbc9c  blt   rebuild
       → se sign bit: +FLT_MAX (0x18A034); else 0.0 (0x18A038)
bbcc4  rebuild: mantissa/sign | (new_exp<<23)
bbcd4  lfs   f1, …
bbcdc  blr
```

| Constante ROM | Valor |
|---------------|-------|
| `0x18A02C` | `0.0` |
| `0x18A030` | **-FLT_MAX** (`0xFF7FFFFF`) |
| `0x18A034` | **+FLT_MAX** (`0x7F7FFFFF`) |
| `0x18A038` | `0.0` |

**Interpretação objetiva:** `r4` escolhe quantos degraus de expoente subtrair (≈ dividir por `2^r4` no caminho “rebuild”).  
**Nota:** o `fsub` com `0.0` torna o preâmbulo `0x4330` atípico vs magic clássico `0x4330000080000000` (ausente no binário). O contrato **observável** e usado pelo caller é o bloco `extrwi` / rebuild / clamp.

---

## Uso em `0xBD400` → `0x3FDF68` (FATO)

Struct base **`0x3FA7E0`** (só lidas neste bloco):

| Off | EA | Uso |
|-----|-----|-----|
| +0 | `0x3FA7E0` | enable (`lbz`); se 0, ramo alternativo |
| +1 | `0x3FA7E1` | gate segundo estágio |
| +0xE | `0x3FA7EE` | `r3` na 1ª chamada `BBC3C` (`r4=0`) → `stfs` `0x3FE128` |
| +0x10 | `0x3FA7F0` | **u16** → float / **1023.0** → `0x3FE104` |
| +0x12 | `0x3FA7F2` | se **≠255**: `BBC3C(r3=byte, r4=1)` → **`0x3FDF68`**; se **==255**: skip (não atualiza `3FDF68` por este path) |

Citação path `3FDF68`:

```
bd4b0  lbz   r4, -0x… (0x3FA7F2)
bd4b4  cmpi  r4, 255
bd4b8  bne   loc_BD4C4          ; BO=4,BI=2 → bne
bd4bc  li    r4, 1
bd4c0  b     loc_BD510          ; skip BBC3C / skip stfs 3FDF68
bd4c4  …
bd4d0  addi  r3, r4, 0          ; r3 = byte 3FA7F2
bd4d4  li    r4, 1
bd4d8  blrl  ; BBC3C
bd4e0  stfs  f1 → 0x3FDF68
```

**Impacto:** `0x3FDF68` (eixo opcional em `0x81B4C`) só refresca quando `*(0x3FA7F2) ≠ 255`. Com `255`, o eixo dos slots cai nos outros ramos (`100.0` / `0.25`).

---

## Escala 10-bit (FATO)

```
bd488  lhz   r11, 0x3FA7F0
       … int/float …
bd498  lfs   f12, 1023.0        ; 0x18A410
bd4a0  fsub/… (normaliza)
bd4ac  stfs  → 0x3FE104
```

**DESCONHECIDO:** semântica de `3FA7F0` pós-`fsub 1023` (não tratar como “/1023”). Origem = CAN MB1 (doc 40–42).  
**DESCONHECIDO:** canal lógico / ANx — sem writer SDA e sem mapa estático para este buffer.

---

## Call graph (atualizado)

```
0xC0664 → blrl 0xBD400
            ├─ BBC3C(*(3FA7EE), 0) → 0x3FE128
            ├─ (lhz 3FA7F0)/1023 → 0x3FE104
            └─ if *(3FA7F2)!=255:
                 BBC3C(*(3FA7F2), 1) → 0x3FDF68
                      │
                      ▼
0x9E800 → 0x81B4C → pode lfs 0x3FDF68 → 0x3FC1B8/BC → slots
```

---

## IDA

| EA | Nome |
|----|------|
| `0xBBC3C` | `float_adjust_exponent_BBC3C` |

---

## Resumo Executivo BRUTAL

- **Provado:** `BBC3C` = **re-expoente** de float (`exp -= r4`) com clamps ±FLT_MAX/0.
- **Provado:** `3FDF68 ← BBC3C(*(3FA7F2), 1)` quando byte ≠ 255.
- **Provado:** `3FA7F0` tratado como raw **/1023**.
- **Próximo ROI:** CAN-ID numérico MB1 B — doc 41.
