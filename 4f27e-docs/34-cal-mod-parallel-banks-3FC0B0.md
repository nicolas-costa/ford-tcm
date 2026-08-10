# 34 — `0x3FC0B0` ↛ `0x3FC070`: bancos paralelos cal_mod

**Data:** 2026-08-07  
**Status:** ✅ Ponte mode-modulator → threshold **falsificada** como dataflow direto  
**Dependência:** docs 31–33

---

## Resumo Executivo

1. **FATO:** O pipeline default `0x8841C–0x88E00` (`cal_mod_lookup_*` + `cal_mod_max_*_to_3FC070`) **não lê** `0x3FC0B0` / `0x3FC0B8` / `0x3FC0BC` / `0x3FBD00` / índices `0x3FC128+` / flag `0x3FC35F`.
2. **FATO:** `shift_threshold_compute_with_mode @ 0x93510` lê **`0x3FC070`** (`lfs -0x3F90` @ `0x93648`, `0x93690`, `0x93794`, `0x937c8`) e **não** os moduladores mode0.
3. **FATO:** `0x3FC070` é escrito só em `cal_mod_max_064_068_06C_to_3FC070 @ 0x88AD8` (`stfs` @ `0x88BBC` / `0x88BD0` / `0x88C04`) = max(`0x3FC068`,`0x3FC064`,`0x3FC06C`) (+ clamp).
4. **FATO:** Mode0/1 e o pipeline default são **bancos paralelos** no mesmo `0x9AE3C` (sequência temporal no stub), **sem** aresta de dados `3FC0B0→3FC070`.
5. **FATO (diff case1):** `0x89D6C` é o mesmo *shape* de reset que `0x896E0`, com schedule ROM diferente.

---

## Dataflow (FATO)

```
MODE CASES (0..11,32,37,49)
  reset/schedule 3FC264 / 3FC27C / 3FC294
  lookups → 3FC0B0 / 3FC0B8 / 3FC0BC / 3FBD00 / 3FBD08
  consumidores: outros workers de mode (ex. 0x8A688)
        ✕  (sem load no pipeline default)
        ✕  (sem load em 0x93510)

DEFAULT (após b 0x9CFD4)
  0x88420 → stfs 3FC068
  0x88890 → stfs 3FC06C
  0x889AC → stfs 3FC064
  0x88ADC → max → stfs 3FC070
        │
        ▼
  shift_threshold_compute_with_mode @ 0x93510
```

Citação max:

```
88b98  lfs  f1, -0x3F98(r12)   ; 0x3FC068
88ba0  lfs  f2, -0x3F9C(r11)   ; 0x3FC064
88bb8  addi r4, r4, -0x3F90    ; 0x3FC070
88bbc  stfs f2, 0(r4)          ; max parcial
88bc4  lfs  f1, -0x3F94(r11)   ; 0x3FC06C
88bd0  stfs f1, 0(r4)          ; se maior
```

---

## Scan SDA (método)

Rastreamento de `lis r*,0x40` + `addi`/`lfs`/`stfs` no binário 2 MiB.

| EA | Loads externos ao writer mode0 | Nota |
|----|--------------------------------|------|
| `0x3FC0B0` | `0x8A688`, `0x911BC`/`0x91218`, + reloads internos `0x99B54`/`0x9A048`/`0x9A9DC` | `0x8A688` ∈ case3 chain |
| `0x3FBD00` | stores em vários mode-blocks; load absoluto raro | uso pesado irmão **`0x3FBD08`** (28 loads) |
| `0x3FC070` | `0x88BEC+`, `0x8B164`, **`0x93648+`**, `0x958CC` | threshold path |

**DESCONHECIDO:** se algum eixo compartilhado (ex. `0x3FC1F8`) é escrito pelo mode e lido pelo lookup default — fora do escopo desta ponte; a ponte **direta** modulador→`3FC070` está falsificada.

---

## Diff Mode0 vs Mode1 reset (FATO)

| Item | Mode0 `0x896E0` | Mode1 `0x89D6C` |
|------|-----------------|-----------------|
| Índices `3FC128/129/12B` | `=0` | `=0` |
| `3FC35F` | `=1` | `=1` |
| `3FC264[0]` | `0.25` | **`0.30` se `*(0x3FBE9C)==9` else `0.25`**; resto `0.25` |
| `3FC27C` | `{1.5, 0.5, 1.0, 1.0, 0.025+*(3FC2B4), 0.0}` | **`{1.5, 0.25×5}`** (`flt_1862C0` + sentinelas) |
| `3FC294` | `0.25` ×6 | **`{0.25, 0.8, 2.0, 2.0, 0+*(3FC2B4), 0.25}`** (`1862D4/CC/C8/C4`) |

Citação mode1: `0x89D6C–0x89E78`.  
ROM: `flt_1862C0=1.5`, `1862D4=0.8`, `1862CC=2.0`, `1862C8=2.0`, `1862C4=0.0`, `1862BC=0.3`.

**Interpretação objetiva:** cases = **perfis de schedule de fase** (quais slots começam “vivos” vs sentinela 0.25), não algoritmos distintos.

**FATO (footprint cases 2–5):** os resets `0x8A0DC` / `0x8A53C` / `0x8A88C` / `0x8AD68` escrevem o **mesmo cluster** (`3FC128+`, `3FC264..`, `3FC27C..`, ±`3FC294..`, ±flags `3FC35F`/`3FC394`). Confirma família única; só mudam literais ROM.

**Impacto:** inventariar cases 2–11 como diffs de constantes/`3FC27C`/`3FC294` tem ROI maior que re-desmontar cada lookup block do zero.

---

## Consumidor exemplo de `0x3FC0B0`

`cal_mod_mode_gate_on_3FC0B0 @ 0x8A61C` (call em case3):

```
8a688  lfs   f13, -0x3F50(r12)  ; 0x3FC0B0
8a690  lfs   f12, flt_185CEC    ; 0.203125
8a694  fcmpu …
8a6d4  stfs  0.25 → 0x3FC298    ; se ramo ativo
```

**FATO:** `0x3FC0B0` modula **estado interno mode**, não o max threshold.

---

## IDA

| EA | Nome / comentário |
|----|-------------------|
| `0x89D6C` | `cal_mod_mode1_reset_state` |
| `0x8A61C` | `cal_mod_mode_gate_on_3FC0B0` |
| `0x88BBC`, `0x93648`, `0x9A994` | comentários da ponte falsificada |

---

## Resumo Executivo BRUTAL

- **Provado:** `3FC0B0/B8/BC/3FBD00` ≠ inputs de `3FC070`; threshold só bebe `3FC070` do max `064/068/06C`.
- **Provado:** mode switch e pipeline default são **paralelos** (mesma função, bancos distintos).
- **Provado:** mode1 = mesmo reset com schedule ROM diferente (tabela acima).
- **Próximo ROI:** ver doc 35 (resets tabulados + transform `3FC070`; falta `3FBF6C`→slots / caller `0x9D774`).
