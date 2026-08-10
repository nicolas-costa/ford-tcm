# 42 — Payload CAN canal `0x420` (8B) + logger `--can`

**Data:** 2026-08-07  
**Status:** ✅ Layout dos 8 bytes documentado; CAN-ID numérico continua DESCONHECIDO (vivo)  
**Dependência:** docs 39–41

---

## Resumo Executivo

1. **FATO:** `tcm_road_logger.py --can` lê `0x307492`/`0x307496` + RAM `3FAE2C`/`3FA7F0`/`3FA7F2`/`3FDF68`.
2. **FATO:** unpack `0x4A9A0–0x4AA24` mapeia os 8 bytes do MB1 → campos SDA (incl. `3FA7F0`/`3FA7F2`).
3. **FATO:** bytes **2–3** do frame **não** são consumidos neste unpack.
4. **DESCONHECIDO:** CAN-ID — config root sem `bl` estático; ROI vivo `0x307492`.

---

## Logger (FATO)

```text
python3 -u scripts/tcm_road_logger.py <PORT> <BAUD> --can
python3 -u scripts/tcm_road_logger.py <PORT> <BAUD> --full --can
```

| Coluna CSV | EA | Nota |
|------------|-----|------|
| `MB1_ID_U16` | `0x307492` | MMIO — pode NRC |
| `CAN_ID_STD` | derivado | `(u16>>5)&0x7FF` |
| `MB1_DATA0_3_HEX` | `0x307496` | 4 dos 8 data bytes |
| `AE2C_HEX` | `0x3FAE2C` | ptr módulo (espera `0x307480`) |
| `PKT_3FA7F0` | `0x3FA7F0` | raw packed |
| `PKT_3FA7F2` | `0x3FA7F2` | gate BBC3C |
| `AXIS_3FDF68` | `0x3FDF68` | float eixo |

---

## Layout dos 8 bytes (FATO — `0x4A9A0+`)

Buffer em `8(r1)` após `channel_config_lookup(..., len=8)`:

| Off | Assembly | Destino | Interpretação objetiva |
|-----|----------|---------|------------------------|
| 0 | `lbz 8(r1)`; bit7→bool; `clrlwi …,25`\|`9(r1)` | `r13+0x1A10`; **`0x3FA7F0`** | flag + u16 `((b0&0x7F)<<8)\|b1` |
| 1 | low byte | (parte de `3FA7F0`) | |
| 2–3 | — | **não lidos** | |
| 4 | bit7→bool; bits0–6\|`5` | `r13+0x1A12`; **`0x3FA7F6`** | 2º u16 packed igual |
| 5 | low byte | (parte de `3FA7F6`) | |
| 6 | clamp `0xC8`/`0xFF` | **`0x3FA7F2`** | → `BBC3C` → `3FDF68` |
| 7 | `stb` | **`0x3FA7F4`** | 2º byte pós-eixo |

Citação montagem `3FA7F0`:

```
4a9a0  lbz    r3, 8(r1)           ; b0
4a9b8  clrlwi r10, r3, 25         ; b0 & 0x7F
4a9bc  slwi   r10, r10, 8
4a9b4  lbz    r12, 9(r1)          ; b1
4a9c0  add    r4, r10, r12
4a9c4  sth    r4, 0x18F0(r13)     ; 3FA7F0
```

Após sucesso: `stb 0 → 0x185A(r13)` (libera debounce do gate `3FA7E1`).

---

## CAN-ID (status)

| Tentativa | Resultado |
|-----------|-----------|
| `bl` → `0xDA8` / `0x13C10` | 0 hits |
| Heurística desc MB1→ID obj | falso positivos (código/`0x7c0802a6`) |
| Dump vivo `0x307492` | **adiado** (logger pronto) |

---

## Kick/clear relacionado (FATO)

`veh_pkt_gates_clear_and_ch_kick_433E4 @ 0x433E4`:

- `bl sub_372E4(0)` e `bl sub_372E4(0x400)` — reset soft-ctx TouCAN por group
- série `sub_38D18(0x80/A0/C0/E0/5A0…)`
- zera `r13+0x1858…0x1864` (flags de debounce do pacote)

---

## Consumidores dos campos irmãos (FATO — scan)

| Campo | Writers | Readers (D-form) |
|-------|---------|------------------|
| `3FA7F4` | `0x4AA1C` | **`0xBD528`** (`BBC3C` r4=-1) |
| `3FA7F6` | `0x4A9F0` | **`0xBD564`** (`BBC3C` r4=0) |
| `r13+0x1A10` | `0x4A9B0` | **0** no scan SDA/`0x40` |
| `r13+0x1A12` | `0x4A9D8` | **0** no scan SDA/`0x40` |

**Impacto:** o mesmo frame alimenta **três** entradas `BBC3C` em `BD400` (`3FA7F2`, `3FA7F4`, `3FA7F6` path). Flags `1A10/1A12` parecem one-shot / sem leitor D-form óbvio (**DESCONHECIDO** uso).

---

## Resumo Executivo BRUTAL

- **Logger:** `--can` cobre MMIO MB1 + cadeia RAM.
- **Provado:** frame 8B → dois u16 packed (off 0–1 e 4–5) + bytes 6–7; off 2–3 mortos neste path.
- **Provado:** `3FA7F4`/`3FA7F6` só voltam a ser lidos em `BD400`.
- **Aberto:** CAN-ID (só vivo / config ainda opaca).
- **Próximo ROI:** ver doc 43 — fan-out completo; seguir leitores de `3FD52C` / escala ×100/256.
