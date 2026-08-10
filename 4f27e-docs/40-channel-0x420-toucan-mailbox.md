# 40 — Canal `0x420` = TouCAN mailbox (não QADC)

**Data:** 2026-08-07  
**Status:** ✅ ID `0x420` decodificado até TouCAN MB; módulo A/B/C do group-1 ainda runtime  
**Dependência:** doc 39

---

## Resumo Executivo

1. **FATO:** IDs `0x400/420/440/460/480` decodificam como **group=1**, **MB index=0..4**, low5=0 (`extrwi` em `0x38284–0x3828C` / `0x37680–0x37684`).
2. **FATO:** init `toucan_modules_init_from_config @ 0x36898` grava em `0x3FAE28[i]` as bases **`0x307080` / `0x307480` / `0x307880`** = **TouCAN_A / B / C** (mapa MPC555 + `doc/MPC563_MEMORY_MAP.md`).
3. **FATO:** `channel_config_lookup_from_hw_table @ 0x38260` (caminho HW) copia **8 bytes** de  
   `TouCAN_base + 0x80 + MB_index×0x10 + 6` (`slwi`/`add`/`addi …,0x86` em `0x38420–0x3845C`) — payload do message buffer.
4. **FATO:** `0x420` ⇒ **group 1, MB 1** → fonte de `3FA7F0`/`3FA7F2` é **frame CAN**, não `lhz` RJURR.
5. **FATO (doc 41):** group1 ⇒ **TouCAN_B**; data MB1 @ `0x307496`. **DESCONHECIDO:** CAN-ID numérico.

---

## Encoding do channel ID (FATO)

```
38284  extrwi  r25, r23, 2, 20   ; group
38288  extrwi  r26, r23, 5, 22   ; mailbox index
3828c  clrlwi  r29, r23, 27      ; low 5
```

| ID | group | MB idx | low5 |
|----|-------|--------|------|
| `0x400` | 1 | 0 | 0 |
| **`0x420`** | **1** | **1** | 0 |
| `0x440` | 1 | 2 | 0 |
| `0x460` | 1 | 3 | 0 |
| `0x480` | 1 | 4 | 0 |

Todos os `0x4xx` usados em `0x4A90C` compartilham o **mesmo** módulo (`3FAE28[1]`); diferem só no mailbox.

---

## Init → bases TouCAN (FATO)

`0x368B8`: `stw r16, 0x1588(r13)` (config root).

Por entrada `i` em `*(root+0xC)`:

```
368e0  extrwi r17, cfg_byte, 2, 24   ; type
type0 → stw 0x307080 → 3FAE28[i]   ; TouCAN_A
type1 → stw 0x307480 → 3FAE28[i]   ; TouCAN_B
type2 → stw 0x307880 → 3FAE28[i]   ; TouCAN_C
```

Citação:

```
368cc  lis  r26, 0x30
368d0  ori  r26, r26, 0x7080        ; 0x307080
…
36924  lis  r10, 0x30
36928  ori  r10, r10, 0x7480        ; 0x307480
…
36944  lis  r10, 0x30
36948  ori  r10, r10, 0x7880        ; 0x307880
```

**Impacto:** group field do ID indexa `3FAE28[group]` — para `0x420`, **`*(0x3FAE2C)`**.

---

## Lookup → cópia do MB (FATO)

Chamada em `0x4A90C`: `r3=0x420`, `r4=8`, `r5=0`, `r6=stack`, `r7=0`; sucesso se **`r3==8`** (bytes copiados).

Caminho HW (`0xA(module)` bit off) em `0x3841C+`:

```
38420  slwi   r11, r26, 4           ; MB_index * 16
38424  add    r29, r24, r11         ; r24 = *(3FAE28+group*4)
38458  add    r12, r29, r22         ; r22=0
3845c  addi   r4, r12, 0x86         ; src = base + idx*16 + 0x86
… copy r4 → r27, length 8 …
38530  clrlwi r3, r31, 24           ; return len
```

Identidade:

`base + 0x80 + idx×0x10 + 6` = início dos **8 data bytes** do TouCAN MB (RM: MBs @ module+0x80, stride 0x10, data @ +6).

Para **`0x420` / MB1**:

| Módulo em `3FAE2C` | EA dos 8 data bytes |
|--------------------|---------------------|
| TouCAN_A | `0x307116` |
| TouCAN_B | `0x307496` |
| TouCAN_C | `0x307896` |

Caminho soft-queue (`0xA` bit on): usa `r13+0x158C/1590` — ainda alimentado pelo mesmo init CAN; não muda a natureza “frame CAN”.

---

## Ligação a `3FA7F0` / eixo (FATO)

```
CAN MB1 (8B) --0x38260--> stack
                 --0x4A9C4--> 3FA7F0 = ((b0&0x7F)<<8)|b1
                 --0x4AA14--> 3FA7F2 = clamp(b14)
                      --BD400--> /1023 , BBC3C --> 3FDF68 --> 3FC1BC slots
```

**HIPÓTESE (lastro `/1023` + pack 7+8):** PCM/outro ECU manda sample tipo ADC em raw counts no payload; TCM só reempacota.  
**NÃO é FATO** de canal QADC local.

---

## IDA

| EA | Nome |
|----|------|
| `0x36898` | `toucan_modules_init_from_config` |
| `0x37678` | `channel_poll_status_37678` |
| `0x38260` | `channel_config_lookup_from_hw_table` (já existia) |

---

## Resumo Executivo BRUTAL

- **Provado:** `0x420` = **TouCAN group1 / mailbox 1**; payload 8B → `3FA7F0/F2`.
- **Provado:** bases MMIO no init são **TouCAN_A/B/C**.
- **Provado:** `/1023` no TCM opera sobre dado **já chegado por CAN**.
- **Próximo ROI:** payload/logger doc 42; CAN-ID via `--can`.
