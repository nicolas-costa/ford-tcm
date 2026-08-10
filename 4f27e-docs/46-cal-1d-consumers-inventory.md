# 46 — Inventário consumers `cal_1d_lookup` (~127 funcs / 406 sites)

**Data:** 2026-08-08  
**Status:** ✅ Item 2 da lista ROI — famílias por região ROM + heavy-hitters  
**Dependência:** docs 24, 31–32, 45; trampolim `0xBBDC8`

---

## Resumo Executivo

1. **FATO:** `XrefsTo(0xBBDC8)` = **406** sites em **124** funções (IDA).
2. **FATO:** Dominam **SHIFT** (73) + helpers de shift (90) + **CAL_MOD** (60) — a maioria do 1D **não** é EPC/TCC duty.
3. **FATO:** Existe consumidor directo da tabela **`0x1845E8`** (doc 27 “Table 7 TCC/1→2?”) @ `0x915D8` com eixo `0x3FC1F0`.
4. **DESCONHECIDO:** nenhum consumer 1D deste inventário está **provado** a escrever duty do slot `0x35` (TCC) — isso é **item 3**.

---

## Totais por família (heurística = 1ª tabela `0x18xxxx` no corpo + nomes IDA)

| Família | Funções | XREFs 1D | Critério / papel |
|---------|--------:|---------:|------------------|
| **A_SHIFT** | 5 | 73 | Nomes shift_* já provados |
| **E_SHIFT_HELPER / ADJ** | 4+ | **90** | Callers do dispatcher / tabelas `0x184xxx–0x185xxx` |
| **B_CAL_MOD** | 8 | 60 | `cal_mod_*` / pipeline `0x9AE3C` |
| **H_THRESH_181** | 6 | 19 | 1ª tab em `0x181xxx` (modulador ≠ EPC) |
| **I_TIMING_183** | 16 | 23 | 1ª tab em `0x183xxx` — **candidato timing** |
| **K_COAST_182** | 21 | 25 | 1ª tab em `0x182xxx` |
| **J_MAP_185** | 6 | 14 | 1ª tab em `0x185xxx` |
| **G_MAP_180** | 8 | 12 | 1ª tab em `0x180xxx` — **candidato adapt/misc** |
| **L_DESC_186+** | 22 | 27 | Descriptors / cal alta |
| **Z_OTHER_184000** | 9 | 11 | Inclui **`0x1845E8`** |
| **Z_OTHER / engine / CAN** | resto | ~25 | Sem 1ª tab clara / 2D wrap / `0xA1400` |

*Heurística de família = região da **primeira** tabela vista no scan — uma função pode usar várias regiões.*

---

## Família A — SHIFT (provado)

| XREFs | EA | Nome |
|------:|-----|------|
| 42 | `0x9D860` | `shift_table_group_dispatcher` |
| 16 | `0x872B4` | `shift_slot_eval_with_mode_switch` |
| 10 | `0x93510` | `shift_threshold_compute_with_mode` |
| 4 | `0x83484` | `gear_zone_evaluator` |
| 1 | `0x9F060` | `shift_point_2d_eval_from_cal` |

---

## Família E — Helpers / adj de shift (heavy)

| XREFs | EA | Nome IDA (agora) | Evidência |
|------:|-----|------------------|-----------|
| 41 | `0x97FA4` | `shift_adj_1d_bank_97FA4` | tabs `0x184700+`; `stfs` → `0x3FC1AC`, `0x3FC2C0`, `0x3FC098`, `0x3FBCA0`, … |
| 28 | `0x8546C` | `shift_helper_1d_maps_8546C` | **caller:** `shift_table_group_dispatcher`; `lfs` eixo `0x3FC1BC` |
| 12 | `0x81C6C` | `shift_helper_1d_maps_81C6C` | **caller:** dispatcher epílogo (doc 37); tabs `0x1857xx–0x1859xx` |
| 9 | `0x988B0` | `shift_adj_1d_bank_988B0` | tabs `0x1847xx` / `0x18815x` |

**Impacto:** ~90 lookups “à volta” do schedule — não são duty TCC.

---

## Família B — CAL_MOD

| XREFs | EA | Nome |
|------:|-----|------|
| 21 | `0x8841C` | `cal_mod_lookup_to_3FC068` |
| 17 | `0x9AE3C` | `cal_mod_switch_and_pipeline_9AE3C` |
| 26 | `0x99984` | `cal_mod_mode_worker_1d_99984` (case 5 chain, doc 32) |
| + | workers case6/7/9/37, lookups `3FC064/06C` | |

Tabs tipicamente `0x181xxx` / `0x183xxx` → modulador de threshold (doc 31).

---

## Família I — TIMING_CAND (`0x183xxx`)

Top: `sub_8A9D0` (4), `sub_8E210` (3), `sub_8E8F8` (2), `sub_8F854` (2), cluster `0x918xx–0x91Bxx` (tabs `0x1830xx`).

**HIPÓTESE (lastro: região ROM + densidade):** timers/delays de troca — **não** afirmado sem store→timer hardware.

---

## Família G — MAP_180 (adapt/misc cand)

| XREFs | EA | Nome |
|------:|-----|------|
| 5 | `0x80A78` | `cal_1d_map180_bank_80A78` — tabs `0x180420…0x180520`; `stfs` → `0x3FD3C0` |
| 1× | vários | `0x18033C…0x180BE8` |

**DESCONHECIDO:** se é adaptação NVM ou só cal estática em `0x180xxx`.

---

## Candidato TCC-schedule (handoff item 3)

**EA call:** `0x915D4`–`0x915DC` (chunk sem função IDA)

```
915cc  addi  r29, … -0x3E10     ; 0x3FC1F0
915d0  lfs   f1, 0(r29)
915d4  lis   r3, 0x18
915d8  addi  r3, r3, 0x45E8     ; 0x1845E8  ← Table 7 (doc 27)
915dc  blrl                     ; cal_1d
```

| Campo | Valor | Nota |
|-------|-------|------|
| Tabela | `0x1845E8` | Doc 27 nomeou “TCC/1→2?” — **rótulo histórico, não prova de solenóide** |
| Eixo | `0x3FC1F0` | float SDA |
| Depois | cmp + 1D `0x1823D0` | mesmo bloco |

**FATO:** este 1D **lê** a tabela que difere BH→BL.  
**DESCONHECIDO:** ligação a duty slot `0x35` / TPU_B ch0.

---

## O que **não** aparece no inventário 1D

- Writer de duty TCC (`0x3FA6xx` / slot `0x35`) — **ausente** como destino directo destes 1D.
- Path EPC QADC (doc 31) — **não** passa por `0xBBDC8` como fonte do duty.

→ Pressão/TCC “de verdade” no sentido solenóide = **item 3** (rastro invertido), não mais varredura 1D.

---

## Renames IDA (assinatura por caller/tabs)

| EA | Nome |
|----|------|
| `0x8546C` | `shift_helper_1d_maps_8546C` |
| `0x81C6C` | `shift_helper_1d_maps_81C6C` |
| `0x97FA4` | `shift_adj_1d_bank_97FA4` |
| `0x988B0` | `shift_adj_1d_bank_988B0` |
| `0x99984` | `cal_mod_mode_worker_1d_99984` |
| `0x80A78` | `cal_1d_map180_bank_80A78` |

---

## Resumo Executivo BRUTAL

- **Provado:** 406×1D em 124 funcs; peso = shift + cal_mod + adj.
- **Provado:** `0x1845E8` é consumida @ `0x915D8` (eixo `0x3FC1F0`).
- **Provado:** inventário **não** liga 1D → duty TCC/EPC.
- **Próximo ROI:** **item 3 feito** — ver [47-TCC-inverted-slot-0x35.md](47-TCC-inverted-slot-0x35.md).
