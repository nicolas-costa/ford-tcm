# 33 — Mode 0 cal_mod: reset + lookups (`0x896E0` chain)

**Data:** 2026-08-07  
**Status:** ✅ Cadeia case 0 desembrulhada (stores + tabelas ROM)  
**Dependência:** [32-cal-mod-mode-switch-9C300.md](32-cal-mod-mode-switch-9C300.md)

---

## Resumo Executivo

1. **FATO:** Case 0 **não** é um mapa de pressão. O 1º worker `0x896E0` é um **reset de estado** da máquina de fases cal_mod (índices + tabelas float sentinela/schedule).
2. **FATO:** Depois do reset, `0x9A828` faz **lookups 1D** em ROM (`0x183230`, `0x180F70`, `0x1831F0`, `0x183270`, `0x1831B0`) e escreve moduladores em **`0x3FC0B8` / `0x3FC0BC` / `0x3FC0B0`** e **`0x3FBD00`**.
3. **FATO:** `0.25` (`dbl_1882A4 @ 0x1882A4`) é sentinela de “slot vazio / avançar fase”, não um setpoint físico.
4. **HIPÓTESE (lastro):** os outros cases 1–11 são **variantes do mesmo reset+lookup** com cal ROM / gates diferentes — padrão já visível em `0x89D6C` (início case 1, espelho de `0x896E0`).

---

## Cadeia case 0 (relembre)

```
stub 0x9C404 (gate 0x3FC3AC!=0 para 1º call)
  → 0x896E0  cal_mod_mode0_reset_state
  → 0x897DC  cal_mod_mode_cond_clear_3FC27C
  → 0x898B0  cal_mod_mode_worker_898B0      (avança índices)
  → 0x9A828  cal_mod_mode0_1d_lookup_block
  → 0x89C28  cal_mod_mode_phase_float_scale
  → b 0x9CFD4  (pipeline default 0x88420+)
```

Citação stub: `0x9C404–0x9C460`.

---

## Worker A — `cal_mod_mode0_reset_state @ 0x896E0`

IDA: função criada a partir de bytes (antes `.byte`); prolog efetivo sem `stwu` visível no head (epílogo `addi r1,0x10; blr` @ `0x897D0`).

### Stores (FATO)

| EA | Op | Valor | Instrução |
|----|-----|-------|-----------|
| `0x3FC12B` | `stb 0` | phase idx C | `0x896E8` |
| `0x3FC129` | `stb 0` | phase idx B | `0x896F0` |
| `0x3FC128` | `stb 0` | phase idx A | `0x896F8` |
| `0x3FBF94` | `stfs 0.25` | | `0x89708` |
| `0x3FC100` | `stfs 0.25` | | `0x89710` |
| `0x3FC394` | `stb 0` | | `0x8971C` |
| `0x3FC35F` | `stb 1` | flag ativo | `0x89728` |
| `0x3FC330` | `stb 0` | | `0x89730` |
| **`0x3FC264[0..5]`** | `stfs 0.25` ×6 | sentinela A | `0x8973C–0x89750` |
| **`0x3FC27C[0..5]`** | cal ROM (abaixo) | schedule B | `0x89764–0x897AC` |
| **`0x3FC294[0..5]`** | `stfs 0.25` ×6 | sentinela C | `0x897B8–0x897CC` |

### Layout `0x3FC27C` após reset (FATO — ROM)

| Idx | Fonte ROM | Float |
|-----|-----------|-------|
| 0 | `flt_1862A4` | **1.5** |
| 1 | `flt_1862B8` | **0.5** |
| 2 | `flt_1862B4` | **1.0** |
| 3 | `flt_1862B0` | **1.0** |
| 4 | `flt_1862A8` + `*(0x3FC2B4)` | **0.025 + RAM** (`fadds` @ `0x8979C`) |
| 5 | `flt_1862AC` | **0.0** |

**Interpretação objetiva:** mode 0 **arma** três bancos de 6 floats + três índices de fase; bancos A/C começam “vazios” (0.25); banco B recebe pesos/cal fixos.

**Impacto:** qualquer path que só olhe `0x3FC06x` sem estes bancos perde o estado de fase do mode switch.

---

## Worker B — `0x897DC` (clear condicional)

Lê flags `0x3FC373`, `0x3FC3CC`, `0x3FC335`, `0x3FC3B9`.

Conforme combinação, escreve **0.25** em subconjuntos de **`0x3FC27C`** (`+0/+4`, `+0/+8`, ou **todos** `+0..+0x10`) e pode zerar `0x3FC35F` (`stb 0` @ `0x898A0`).

Citação: `0x897E0–0x898A0`.

---

## Worker C — `0x898B0` (já doc 32)

Avança `0x3FC128` / `0x3FC129` / `0x3FC12B` enquanto `table[idx]==0.25` e `idx<5`.  
Depois usa os índices para operações float (continua após `0x899D4`).

---

## Worker D — `cal_mod_mode0_1d_lookup_block @ 0x9A828`

### Lookups (FATO)

| Condição | Descriptor `r3` | Input float (SDA) |
|----------|-----------------|-------------------|
| `*(0x3FC373)!=0` | `0x183230` + `0x180F70` (soma) | `0x3FC1F8`, `0x3FD3F0` |
| else | `0x1831F0` | `0x3FBD68` |
| sempre (após) | `0x183270` | `0x3FC208` |
| depois | `0x1831B0` (via `frsp` de clamp) | usa `0x3FC0B0` / `0x3FBF94` |

Trampolim: `cal_1d_lookup_trampoline` (`blrl` @ `0x9A8AC` etc.).

### Stores principais (FATO)

| EA | Conteúdo | Citação |
|----|----------|---------|
| `0x3FC0B8` | resultado lookup (soma/ramo) | `stfs` @ `0x9A908` |
| `0x3FC0BC` | 2º lookup | `0x9A93C` |
| `0x3FC0B0` | clamp de soma ∈ [`0.25`, `qword_188314≈0.05` path] — ver fluxo `0x9A950–0x9A994` | `stfs` @ `0x9A994` |
| `0x3FBD00` | `fmadds` final | `stfs` @ `0x9AA04` |
| `0x3FC3A0` | flag derivado | `stb` @ `0x9AA58` |

Headers ROM (dword0 = ptr de eixo/dados):

```
0x183230: 0x1831F8 …
0x180F70: 0x180F38 …
0x1831F0: 0x1831B8 …
0x183270: 0x183238 …
0x1831B0: 0x183180 …
```

**Impacto:** mode 0 **produz** floats de modulação em `0x3FC0B0+` a partir de cal **`0x180xxx/0x183xxx`**, depois o stub salta para o pipeline default (`0x88420` → `0x3FC06x` → shift threshold). Ligação exata `0x3FC0B0`→`0x3FC070` = **DESCONHECIDO** por XREF SDA vazio (mesmo problema de addressing).

---

## Worker E — `0x89C28` (phase float scale)

Usa `lbz` índice **`0x3FC129`**:

- se `==0`: caminho curto, escreve constantes;
- se `1..4`: escala `*(0x3FC0A4)` vs `*(0x3FC08C)`, `stfs` em `0x3FBCCC` / `0x3FC05C`, chama `sub_81544` com tabelas `0x187394` / `0x1872AC`, resultado em **`0x3FC0EC`**;
- clamps com `flt_185D64` / `flt_185D60`.

Citação: `0x89C48–0x89D58`.

**Nota IDA:** a função IDA continua em `0x89D6C` (= início do **reset case 1**, espelho de `0x896E0`). Boundary artificial — o `blrl` do case 0 aponta para `0x89C28`; o case 1 stub aponta para `0x89D6C`.

---

## Mapa RAM da máquina de fases (FATO acumulado)

| EA | Papel |
|----|-------|
| `0x3FC128/129/12B` | índices fase A/B/C |
| `0x3FC264` | 6×float sentinela/valores fase A |
| `0x3FC27C` | 6×float schedule (cal + clear condicional) |
| `0x3FC294` | 6×float sentinela fase C |
| `0x3FC35F` | flag “mode state armed” (1 no reset0) |
| `0x3FC0B0/B8/BC` | saídas de lookup mode0 |
| `0x3FBD00` | saída `fmadds` mode0 |
| `0x3FC3AC` | gate do stub (doc 32) |
| `0x3FBBCC` | seletor de mode (doc 32) |

---

## IDA (2026-08-07)

| EA | Nome |
|----|------|
| `0x896E0` | `cal_mod_mode0_reset_state` |
| `0x897DC` | `cal_mod_mode_cond_clear_3FC27C` |
| `0x9A828` | `cal_mod_mode0_1d_lookup_block` |
| `0x89C28` | `cal_mod_mode_phase_float_scale` |

---

## Resumo Executivo BRUTAL

- **Provado:** mode 0 = reset de índices/tabelas (`0x896E0`) + clear condicional (`0x897DC`) + avanço de fase (`0x898B0`) + **1D ROM `0x180/183xxx` → `0x3FC0B0+`** (`0x9A828`) + escala por fase (`0x89C28`).
- **Provado:** `0.25` = sentinela; schedule `0x3FC27C` inicia em `{1.5, 0.5, 1.0, 1.0, 0.025+RAM, 0.0}`.
- **Provado:** isso alimenta o mesmo mundo cal_mod/threshold — **não** o solenóide EPC.
- **Próximo ROI:** ver doc 35 — `0x3FBF6C`/`0x94E74` → slots, ou invocador `0x9D774`.
