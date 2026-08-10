# 35 — Resets mode 0–5/8 + fio `0x3FC070` → threshold

**Data:** 2026-08-07  
**Status:** ✅ Tabela de schedules + transform de `0x3FC070` documentados  
**Dependência:** docs 32–34, [24-shift-schedule-tables.md](24-shift-schedule-tables.md)

---

## Resumo Executivo

1. **FATO:** Resets mode **0–5** e **8** escrevem o mesmo cluster (`3FC128+`, `3FC264/27C/294`); só mudam literais ROM (tabela abaixo). Cases **6/7** 1º worker **não** são reset (gate float — doc 32).
2. **FATO:** `0x3FC070` entra em `shift_threshold_compute_with_mode @ 0x93510` e vira escala em **`0x3FC088`** + working **`0x3FBF6C`**, depois soma com 1D `0x183DE0`.
3. **FATO:** `0x93510` é chamado via `blrl` de **`shift_compute_sequencer_9D774 @ 0x9D774`** e do mirror **`0x9EBCC`** (entry+4 @ `0x9EBD0` ← `sub_C06EC @ 0xC06FC`).
4. **DESCONHECIDO:** caller estático de `0x9D774` (0 hits `lis`/`addi`; função órfã como `0x9AE3C`).

---

## Tabela de schedules (FATO — bytes dos resets)

Sentinela **`0.25`** = `dbl_1882A4 @ 0x1882A4`.  
`3FC264` / `3FC27C` / `3FC294` = bancos A / B / C (6 floats).

| Case | Reset EA | `3FC264` (A) | `3FC27C` (B) | `3FC294` (C) | Flags extras |
|------|----------|--------------|--------------|--------------|--------------|
| **0** | `0x896E0` | `0.25` ×6 | `{1.5, 0.5, 1.0, 1.0, 0.025[+RAM], 0.0}` | `0.25` ×6 | `3FC35F=1`, zera `3FC330/394` |
| **1** | `0x89D6C` | `[0]=0.30 se *(0x3FBE9C)==9 else 0.25`; resto `0.25` | `{1.5, 0.25×5}` | `{0.25, 0.8, 2.0, 2.0, 0[+RAM], 0.25}` | `3FC35F=1` |
| **2** | `0x8A0DC` | `{0.10, 0.25×5}` | `{0.45, 0.25×5}` | `{0.25, 0.6, 2.0, 0.8, 0.25, 0.25}` | só índices |
| **3** | `0x8A53C` | `0.25` ×6 | `{0.25, 0.25, 1.0, 1.0, 0.0, 0.25}` | `{0.25, 2.0, 0.25×4}` | `3FC35F=1` |
| **4** | `0x8A88C` | `{0.25, 0.25, 0.05, 0.25×3}` | `0.25` ×6 | `{0.25, 0.4, 2.0, 0.25, 0.25, 0.25}` | só índices |
| **5** | `0x8AD68` | `{1.0, 0.25×5}` | `{0.25, 0.5, 1.0, 1.0, 0.0, 0.25}` | `0.25` ×6 | `3FC35F=1` |
| **8** | `0x8D304` | `{1.0, 1.0, 1.0, 0.25×3}` | `{0.5, 0.2, 1.0, 0.25, 1.5, 0.25}` | `0.25` ×6 | só índices |

ROM refs (amostra): `0x1862A4+` (case0), `0x1862DC/E0/EC…` (case2), `0x186318+` (case3), `0x186328+` (case4), `0x1863BC+` (case5), `0x1863D0+` (case8).

**Interpretação objetiva:** cada mode ID arma um **perfil de fase** (quais slots ≥ sentinela). Não é mapa de pressão.

**Impacto:** patch de “modo” sem tocar `0x3FC070` / tabelas de slot **não** move thresholds de marcha.

---

## Transform `0x3FC070` @ `0x93648` (FATO)

```
93648  lfs   f1, -0x3F90(r12)     ; 0x3FC070
93650  lfs   f12, qword_188314    ; 0.05
93654  fcmpu f1, 0.05
93658  blt   loc_93668            ; if 3FC070 < 0.05
9365c  lfs   f2, flt_186138       ; -5.0          (≥ 0.05)
93664  b     loc_9367C
93668  lfs   f13, flt_18613C      ; 400.0
93674  lfs   f12, flt_186134      ; 1100.0
93678  fmadds f2, f12, f1, f13    ; 1100*3FC070 + 400
93680  stfs  f2, -0x3F78(r12)     ; → 0x3FC088
93684  fmr   f1, f2
9369c  stfs  f1, 0(r28)           ; → 0x3FBF6C
936a0  … cal_1d_lookup(0x183DE0) …
936c4  fadds f1, lookup, 3FBF6C
93704  stfs  f31, 0(r28)          ; 3FBF6C atualizado
```

| Condição | `*(0x3FC088)` |
|----------|----------------|
| `*(0x3FC070) ≥ 0.05` | **-5.0** |
| `*(0x3FC070) < 0.05` | **1100×x + 400** |

**HIPÓTESE (lastro numérico):** `0x3FC070` opera como fator pequeno (domínio ~0..1); ≥0.05 força ramo saturado `-5.0`. Confirmar com dump vivo.

Outros stores em `0x93510` (amostra): `0x3FC0D0/D4/DC`, `0x3FC21C`, `0x3FC2E8/EC`, flags `0x3FC3CE/CF` — path completo até slots `0x3FBC24+` já parcialmente no doc 24 (via `0x872B4` / dispatcher), não re-derivado aqui linha a linha.

---

## Call graph (FATO)

```
sub_C06EC @ 0xC06FC
  blrl 0x9EBD0  (= cal_mod_pipeline_mirror_9EBCC+4)
    … 0x88420 / 88890 / 889AC / 88ADC …   ; mesma cadeia max→3FC070
    blrl 0x93510                           ; @ 0x9ECEC
    blrl 0x94E74, 0x80798, 0x955B0, …      ; pós-threshold
    stb  1 → 0x3FC343                      ; @ 0x9ED78

shift_compute_sequencer_9D774 @ 0x9D774
  blrl 0x91424, 0x91C34, 0x91D10
  blrl 0x93510                             ; @ 0x9D7BC
  blrl 0x94E74, 0x80798, 0x955B0, …        ; mesma cauda
  stb  1 → 0x3FC343                        ; @ 0x9D848

shift_table_group_dispatcher @ 0x9D860
  ← blrl from 0x9DE90 (único construtor estático achado)
```

**DESCONHECIDO:** quem invoca `0x9D774` (nenhum `lis`/`addi` → EA; dword absoluto ausente no scan).  
**FATO:** `0x9EBCC` tem pelo menos um caller: `0xC06EC`.

---

## IDA (2026-08-07)

| EA | Nome |
|----|------|
| `0x9D774` | `shift_compute_sequencer_9D774` |
| `0x8A0DC`…`0x8AD68`, `0x8D304` | `cal_mod_mode{2,3,4,5,8}_reset_state` |

Comentários em `0x93680`, `0x9369C`, `0x9D7BC`.

---

## Resumo Executivo BRUTAL

- **Provado:** modes 0–5/8 = perfis ROM em `3FC264/27C/294` (tabela); irrelevante para EPC.
- **Provado:** `3FC070` → escala `3FC088` / `3FBF6C` (+ lookup `0x183DE0`) dentro de `0x93510`.
- **Provado:** `0x93510` sobe em sequenciadores `0x9D774` e mirror `0x9EBCC` (este via `0xC06EC`).
- **Próximo ROI:** docs 36–37 — eixo/`3FDF68` fechados; próximo `0xBBC3C`.
