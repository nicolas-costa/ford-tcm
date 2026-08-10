# 41 — `0x420` → TouCAN_B MB1; ID ainda em config

**Data:** 2026-08-07  
**Status:** ✅ Módulo = TouCAN_B; ID numérico ainda DESCONHECIDO (config indireta)  
**Dependência:** doc 40

---

## Resumo Executivo

1. **FATO:** selectors de baixo nível mapeiam **`extrwi group == 0` → `0x307080` (TouCAN_A)** e **`group != 0` → `0x307480` (TouCAN_B)** — sem TouCAN_C nesses paths.
2. **FATO:** canal **`0x420`** tem **group=1** ⇒ cai no ramo **TouCAN_B**.
3. **FATO:** data bytes do MB1 em TouCAN_B = **`0x307496`** (`0x307480+0x80+0x10+6`).
4. **FATO:** ID do MB é programado em `base+MB×16+0x82` (+`0x84` se extended) a partir de objeto config (`0x13EF4` / `0x13F24` / `0x37078`).
5. **DESCONHECIDO:** valor numérico do CAN-ID (root de config não referenciado por `bl` direto no scan).

---

## Group → módulo (FATO — múltiplos sites)

Padrão invariante:

```
extrwi  rG, r3, 2, 20     ; group do channel ID
cmpwi   rG, 0
beq     TouCAN_A          ; lis/ori 0x307080
b       TouCAN_B          ; lis/ori 0x307480
```

| EA | Contexto |
|----|----------|
| `0xE0C–E24` | init soft-ctx / freeze |
| `0x1110–112C` | shutdown/clear helper |
| `0x1190–11AC` | twin |
| `0x14E4–1514` | decode channel ID → base+MB |
| `0x13C78–13C90` | bring-up por type byte |
| `0x416D4–416EC` | loop **só `r4=0..1`** (A então B) |

Citação `0x14E4` (mesmo encoding de `0x38284`):

```
14e4  extrwi  r6, r3, 2, 20      ; group
14e8  extrwi  r3, r3, 5, 22      ; MB index
…
1508  cmpwi   r6, 0
150c  beq     loc_151C           ; A
1510  lis/ori r3, 0x307480       ; B
```

**Impacto:** `0x420` (group1, MB1) ⇒ **TouCAN_B mailbox 1**.

TouCAN_C (`0x307880`) só aparece no switch de **type** em `toucan_modules_init_from_config` (`0x36948`); os drivers early **não** indexam C por group.

---

## EA concreto do payload (FATO)

| Campo | EA |
|-------|-----|
| TouCAN_B base | `0x307480` |
| MB1 control | `0x307480+0x80+0x10` = `0x307490` |
| MB1 ID reg | `0x307492` (`+0x82`) |
| **MB1 data[0..7]** | **`0x307496`** (`+0x86`) |

É desta região que `channel_config_lookup` copia 8B quando o path HW está ativo (`addi …,0x86` @ `0x3845C` com `r24=*(3FAE2C)`).

**HIPÓTESE (lastro group→B + init type1→B):** `*(0x3FAE2C) = 0x307480` após boot.  
**Confirmação viva:** UDS/`0x23` ou probe de `0x3FAE2C` / `0x307496`.

---

## Programação do CAN-ID (FATO — mecanismo)

Bring-up (`0x13ED4+`) e twin em `0x37058+`:

**Standard ID:**

```
13f18  lwz    r11, 0(r31)        ; ID object
13f1c  srwi   r11, r11, 3
13f20  slwi   r11, r11, 5
13f24  sth    r11, 0x82(r6)      ; r6 = base + MB*16
13f2c  sth    0, 0x84(r6)
```

**Extended ID:** pack em `0x82`/`0x84` (`0x13EF4` / `0x37078`).

`r31` / `r29` vêm de `*(mailbox_desc+4)` — descriptor na tabela apontada pelo config root (`r13+0x6B7C` ← `stw r27` @ `0xDBC`).

**Recuperação do ID (vivo):** ler `*(u16*)0x307492`; para standard,  
`can_id ≈ (val >> 5) & 0x7FF` (RTR/IDE nos bits baixos conforme RM TouCAN).

---

## Cadeia atualizada

```
TouCAN_B MB1 @ 0x307496 (8B)
    → channel_config_lookup (id 0x420)
    → 3FA7F0 / 3FA7F2
    → BD400 / BBC3C
    → 3FDF68 → 3FC1BC → slots
```

---

## IDA

| EA | Nota |
|----|------|
| `0x14E4` | decode channel→TouCAN base (comentar) |
| `0x13EF4` / `0x13F24` | write MB ID regs |
| `0x307496` | alvo data MB1 B (comment em lookup) |

---

## Resumo Executivo BRUTAL

- **Provado:** `0x420` = **TouCAN_B / mailbox 1**; data @ **`0x307496`**.
- **Provado:** drivers early são **só A/B**; group1 ⇒ B.
- **Aberto:** CAN-ID numérico (config root sem `bl` estático achado).
- **Logger:** `tcm_road_logger.py --can` lê `0x307492`/`0x307496` + RAM `3FAE2C`/`3FA7F0`/`3FA7F2`/`3FDF68` (MMIO pode NRC).
- **Próximo ROI:** consumidores `0x1A10`/`3FA7F6`/`3FA7F4` — doc 42. CAN-ID = vivo `--can`.
