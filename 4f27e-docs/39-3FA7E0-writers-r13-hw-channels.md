# 39 — Writers de `0x3FA7E0`: `r13` SDA + canais HW `0x4A90C`

**Data:** 2026-08-07  
**Status:** ✅ Origem do pacote de entrada mapeada (falso negativo do scan `lis 0x40`)  
**Dependência:** docs 37–38

---

## Resumo Executivo

1. **FATO:** scans só com base `0x40` / disp `-0x58xx` **não** encontram writers — o pacote é escrito via **`r13+0x18Ex`** (`r13 = 0x3F8F00` ⇒ `0x3F8F00+0x18E0 = 0x3FA7E0`).
2. **FATO:** `veh_pkt_fill_from_hw_channels_4A90C @ 0x4A90C` puxa frames via `loc_37678` + `channel_config_lookup_from_hw_table @ 0x38260` (IDs **`0x400` / `0x420` / `0x440` / …**) e grava campos de dados (`3FA7EE`, **`3FA7F0`**, **`3FA7F2`**, …).
3. **FATO:** `veh_pkt_gate_debounce_434D4 @ 0x434D4` grava gates `3FA7E0/E1/E2/…` a partir de flags `r13+0x1859…` + contadores `r13+0x1868…`.
4. **FATO:** wrapper `0x4A8C0` chama **`4A90C` → `434D4` → `C0644`** (este último chega a `BD400` → `3FDF68`).

---

## Armadilha de addressing (FATO)

| Forma | Exemplo | Cobre `3FA7E0`? |
|-------|---------|-----------------|
| `lis r,0x40` / `-0x5820` | `BD418` | **só leitura** em `BD400` |
| `disp(r13)` | `sth r4, 0x18F0(r13)` @ `0x4A9C4` | **escrita** |

Opcode `stb` = primary **38** (não 37). Scans que omitam op 38 perdem os gates.

---

## Pipeline (FATO)

```
0x4A8C0  veh_pkt_update_then_C0644
           ├─ bl 0x4A90C   fill from HW channels
           ├─ bl 0x434D4   gate debounce → 3FA7E0+
           └─ bl 0xC0644   … → 0xBD400 → BBC3C → 0x3FDF68
```

Citação epílogo caller:

```
4a8cc  bl   sub_4A90C     ; fill
4a8d0  bl   loc_434D4     ; gates
4a8d4  bl   sub_C0644     ; consume (incl. BD400)
```

---

## Fill HW — `0x4A90C` (FATO)

Padrão repetido por canal:

```
addi  r4, r13, 0x1626      ; scratch
li    r3, <channel_id>     ; 0x400 / 0x420 / 0x440 / 0x460 / 0x480 …
bl    loc_37678            ; fetch into table @ r13+0x1626 path
…
bl    channel_config_lookup_from_hw_table  ; r3=id, r4=8, r6=stack buf
cmpwi ret, 8
bne   skip
; unpack bytes from stack → r13+0x18Ex
```

### Campos críticos para o eixo de slots

| EA | r13 off | Writer | Origem (assembly) |
|----|---------|--------|-------------------|
| `0x3FA7EE` | `+0x18EE` | `stb` `0x4A958` | canal **`0x400`**, byte do lookup |
| **`0x3FA7F0`** | `+0x18F0` | `sth` **`0x4A9C4`** | canal **`0x420`**: `((b0&0x7F)<<8)\|b1` |
| **`0x3FA7F2`** | `+0x18F2` | `stb` **`0x4AA14`** | canal **`0x420`** byte `0xE(r1)`; se `≥0xC8` e `≠0xFF` ⇒ força **`0xC8`** |
| `0x3FA7F4` | `+0x18F4` | `stb` `0x4AA1C` | mesmo frame, `0xF(r1)` |
| `0x3FA7F6` | `+0x18F6` | `sth` `0x4A9F0` | canal `0x420` (2º u16 packed) |
| `0x3FA7F8`…`808` | `+0x18F8…` | `0x4AA94`… | canal **`0x440`** unpack |

Citação montagem `3FA7F0` (`0x420`):

```
4a9a0  lbz   r3, 8(r1)
4a9b8  clrlwi r10, r3, 25        ; low 7 bits
4a9bc  slwi  r10, r10, 8
4a9b4  lbz   r12, 9(r1)
4a9c0  add   r4, r10, r12
4a9c4  sth   r4, 0x18F0(r13)     ; → 0x3FA7F0
```

Citação `3FA7F2` (gap que IDA tinha como `.byte`; bytes `98 6D 18 F2`):

```
4a9f4  lbz    r3, 0xE(r1)
4a9f8  cmpwi  r3, 0xC8
4a9fc  blt    keep
4aa00  cmpwi  r3, 0xFF
4aa04  bne    force_C8
keep:
4aa14  stb    r3, 0x18F2(r13)    ; → 0x3FA7F2 (≠255 → BBC3C→3FDF68)
```

**Impacto:** o raw **/1023** em `BD400` é este `u16` montado do canal **`0x420`** — não um `lhz` direto de RJURR. O valor ainda é **≤0x7FFF** pelo mask de 7 bits no high byte (domínio “10-bit-ish” / word de resultado empacotado).

---

## Gates — `0x434D4` (FATO)

Cada gate: se flag `r13+0x1859+i` == 0 → inicia debounce (flag=1, counter=0, **escreve 0** no byte do pacote); senão incrementa counter até limiar e então **escreve 1**.

| Pacote | Writer | Flag / counter |
|--------|--------|----------------|
| `0x3FA7E0` | `0x43514` | `0x1859` / `0x1868` limiar 1 |
| `0x3FA7E1` | `0x43558` | `0x185A` / `0x186A` limiar 1 |
| `0x3FA7E2` | `0x4359C` | `0x185B` / `0x186C` limiar 1 |
| … | … | outros `0x18E3…EC` |

Flags `0x1859/185A` também são **zeradas** no sucesso do fill (`0x4A960`, `0x4AA24`) — amarra fill HW ↔ debounce.

---

## Mapa consumidor `BD400` (FATO — leitura)

Base `r30 = 0x3FA7E0`:

| Off | EA | Uso em `BD400` |
|-----|-----|----------------|
| +0 | `3FA7E0` | enable |
| +1 | `3FA7E1` | gate estágio 2 |
| +2 | `3FA7E2` | gate estágio 3 |
| +0xE | `3FA7EE` | `BBC3C(.,0)` → `3FE128` |
| +0x10 | `3FA7F0` | `/1023` → `3FE104` |
| +0x12 | `3FA7F2` | `BBC3C(.,1)` → **`3FDF68`** se ≠255 |
| +0x14… | `3FA7F4…` | mais `BBC3C` / cópias |

---

## HIPÓTESE / DESCONHECIDO

- **FATO (doc 40):** `0x420` = TouCAN group1 / mailbox 1; 8B copiados do MB.
- **FATO (doc 41):** TouCAN_B MB1 @ `0x307496`. **DESCONHECIDO:** CAN-ID; semântica payload.

---

## IDA

| EA | Nome |
|----|------|
| `0x4A8C0` | `veh_pkt_update_then_C0644` |
| `0x4A90C` | `veh_pkt_fill_from_hw_channels_4A90C` |
| `0x434D4` | `veh_pkt_gate_debounce_434D4` |

---

## Resumo Executivo BRUTAL

- **Provado:** writers existem — **`r13+0x18Ex`**, não `lis 0x40`.
- **Provado:** `3FA7F0`/`3FA7F2` ← canal HW **`0x420`** em `0x4A90C`; gates ← `0x434D4`.
- **Provado:** ordem `fill → gates → C0644/BD400`.
- **Próximo ROI:** CAN-ID MB1 — docs 40–41.
