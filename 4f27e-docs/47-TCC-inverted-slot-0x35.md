# 47 — TCC invertido (slot `0x35` / idx5) — mesmo método do EPC

**Data:** 2026-08-08  
**Status:** ✅ Item 3 — rastro duty→QADC fechado estaticamente (espelho do EPC)  
**Dependência:** docs 23, 31; ROI lista item 3

---

## Resumo Executivo

1. **FATO:** Canal PWM ~33 Hz = **idx5** na tabela `0x252F4`: bytes `10 06 00 06` — lógico **`0x10`**, io=`6`, ordinal=`6`.
2. **FATO:** Duty sai pelo **mesmo** pipeline dos 7 canais: `prepare @ 0x42674` → `qadc_read(0x10)` → `ramp @ 0x41DFC` → `sth +0xE` → `io_set` — duty RAM **`0x3FA736`**.
3. **FATO:** setpoint `+4` vem de `r13+0x18C2` (`0x3FA7C2`); **zero writers** no binário → default init `period×10` = **300** (`0x18A2A8[ord6]=30`).
4. **FATO:** cal no path = ganhos de slew (`0x18A1EC`/`208`/…) — **não** `0x1845E8` nem mapas 1D de “pressão TCC”.
5. **DESCONHECIDO vivo:** RJURR exacto para `0x10` (simulação doc 31: start **21**); off-by-4 do init QADC afecta este canal como o EPC.

**Nome:** doc 31 chama **SSE**; doc 23/ROI chamam **TCC** — mesmo slot físico `0x35` / TPU_B ch0. Aqui: **TCC/SSE idx5**.

---

## Identidade do canal (FATO)

ROM `0x252F4` (stride 4), idx5 @ `0x25308`:

```
25308  10 06 00 06
```

| Campo | Valor |
|-------|-------|
| hw / lógico QADC | **`0x10`** |
| io_id | `6` |
| flags | `0` |
| ordinal (byte3) | **`6`** |
| struct | `0x3FA6C4 + 5×0x14` = **`0x3FA728`** |
| duty `+0xE` | **`0x3FA736`** |
| sense filtrado `+0x2` | **`0x3FA72A`** (via `0x426BC` EMA) |
| cmd setpoint SDA | `r13+0x18C2` → **`0x3FA7C2`** |
| período init | `lhz 0x18A2A8 + 2×6` = **`0x001E` (30)** → `×10` = **300** (~33 Hz) |

Citação período: bytes `0x18A2A8`: `… 00 0A 00 1E 00 14` — índice 5=`10` (EPC×10→100), índice 6=`30` (TCC×10→300).

---

## Pipeline (idêntico ao EPC, idx diferente)

```
solenoid_outputs_prepare_cycle_from_252F4 @ 0x42674
  loop r28=7:
    lbzu r3, 252F4[i]           ; idx5 → r3=0x10
    bl   qadc_read_result_by_logical_ch @ 0x35CD0
    EMA → *(r13+0x17C6 + i×0x14)  ; idx5 → 0x3FA72A

solenoid_outputs_update_7ch @ 0x42584
  r30=idx; r31=0x3FA6C4+idx×0x14
  bl solenoid_duty_ramp_calculate(r3=idx, r4=struct) @ 0x41DFC
  sth r3, 0xE(r31)              ; idx5 → 0x3FA736
  bl io_set_float_by_id (io from 252F5)
```

**Entrada variável do ramp:** `lhz 0(r4)` = sense (ADC); `lhz 4(r4)` = alvo.  
**Sem** `bl` a `cal_1d` / `0x1845E8` neste caminho.

---

## Cal no ramp (não é mapa de lockup)

Mesmas tabelas do EPC (`0x41DFC`), indexadas por `ordinal<<1` / `ordinal<<2`:

| ROM | Papel |
|-----|--------|
| `0x18A208`, `0x18A1EC`, `0x18A1FA` | ganhos slew |
| `0x18A244`, `0x18A27E` | clamp duty |
| `0x18A254`, `0x18A28C` | clamp acumulador `+8` |
| `0x18A2A8` | período base |

Para ordinal 6: `0x18A208 + 12` → halfword **`0x0032`**.

---

## Setpoint `+4` / `0x18C2`

| Item | Evidência |
|------|-----------|
| Scan stores `0x18B8–0x18C4(r13)` | **0 hits** (mesmo resultado doc 31) |
| `solenoid_apply_period_targets_from_18B8 @ 0x41190` | lê cmds → `+4`; caller externo órfão |
| Default | `period×10` = **300** |

**Conclusão:** alvo de ramp TCC/SSE estático = **300**; variação de duty, se houver, vem do **ADC `0x10`**, não de tabela schedule `0x1845E8`.

---

## Relação com item 2 / `0x1845E8`

| Path | Usa `0x1845E8`? |
|------|-----------------|
| Duty TCC `0x3FA736` | **Não** |
| Call `0x915D8` (doc 46) | **Sim** — eixo `0x3FC1F0`; família schedule/shift-adj |

**FATO:** “Table 7 TCC” do doc 27 **não** alimenta o solenóide `0x35` no path de duty.

---

## Off-by-4 QADC (partilhado com EPC)

Init passa `r3=0x2A6CC` em vez de header `0x2A6C8` (doc 31).  
**Impacto:** softctx `*(r13+0x155C)` / mapeamento RJURR para **`0x10` e `0x11`** ficam sob a mesma anomalia até prova viva.

**HIPÓTESE (doc 31):** RJURR start lógico `0x10` = **21** → `0x304E80+42` = **`0x304EAA`**.

---

## Logger

`scripts/tcm_road_logger.py --tcc` lê:

| EA | Campo |
|----|--------|
| `0x3FA736` | duty |
| `0x3FA72A` | sense filtrado |
| `0x3FA7C2` | cmd setpoint |

---

## Resumo Executivo BRUTAL

- **Provado:** TCC/SSE idx5 = mesmo laço ADC+slew que o EPC; duty **`0x3FA736`**; lógico **`0x10`**.
- **Provado:** sem writers de pedido em `0x18C2`; default alvo **300**.
- **Provado:** `0x1845E8` ≠ path de duty do slot `0x35`.
- **Próximo ROI:** item **4** (diff BH/BL/CA `0x181xxx`) **ou** dump vivo `--tcc` + `0x155C`/RJURR `0x10`.
