# 43 — `BD400`: destinos float do frame `0x420` (além de `3FDF68`)

**Data:** 2026-08-07  
**Status:** ✅ Mapa `stfs`/`BBC3C` do pacote `3FA7E0` no estágio gate-clear  
**Dependência:** docs 38, 42

---

## Resumo Executivo

1. **FATO:** com `*(3FA7E1)==0`, o frame CAN vira vários floats; **`3FDF68` não é o único**.
2. **FATO:** `3FA7F2` → `BBC3C(.,1)` → `3FDF68` **e** `×100/256` → `3FDF60` + `3FD52C`.
3. **FATO:** `3FA7F4` → `BBC3C(.,-1)` − `512.0` → `3FD540` + `3FDF64`.
4. **FATO:** `3FA7F6` → `BBC3C(.,0)` e o **`f1` é descartado**; só `stb 0 → 0x3FD70E`.
5. **FATO (correção):** path `3FA7F0` faz **`fsub` com `1023.0`**, não `fdiv` — doc 38/42 “/1023” no opcode estava **errado**.

---

## Gate

```
bd470  lbz  1(r30)        ; 3FA7E1
bd478  bne  BD57C         ; skip bloco F0/F2/F4/F6
```

Só o mapa abaixo roda com debounce gate clear.

---

## Tabela de emissão (FATO)

| Src pacote | Op | Destinos | Citação |
|------------|-----|----------|---------|
| `3FA7EE` | `BBC3C(.,0)` | **`0x3FE128`** | `bd438–bd44c` |
| `3FA7F0` | `lhz`→double(`0x4330\|\|u16`) **`fsub 1023.0`** →`frsp` | **`0x3FE104`** | `bd488–bd4ac` |
| `3FA7F2` (≠255) | `BBC3C(.,1)` | **`0x3FDF68`** | `bd4d8–bd4e0` |
| (mesmo `f1`) | `f1 * 100.0 / 256.0` | **`0x3FDF60`**, **`0x3FD52C`** | `bd4e4–bd508` |
| `3FA7F2` (==255) | skip BBC3C | — | `bd4b8–bd4c0` |
| `3FA7F4` | `BBC3C(.,-1)` then `− 512.0` | **`0x3FD540`**, **`0x3FDF64`** | `bd528–bd550` |
| `3FA7F6` | `BBC3C(.,0)` | **nenhum `stfs`**; `*(0x3FD70E)=0` | `bd564–bd574` |

Constantes ROM:

| EA | bits | float |
|----|------|-------|
| `0x18A410` | `0x447FC000` | **1023.0** |
| `0x18A414` | `0x42C80000` | **100.0** |
| `0x18A418` | `0x43800000` | **256.0** |
| `0x18A41C` | `0x44000000` | **512.0** |

---

## Snippets

### `3FA7F2` → eixo + escala

```
bd4d8  blrl   ; BBC3C(byte,1)
bd4e0  stfs   f1 → 0x3FDF68
bd4e8  lfs    f13, 100.0
bd4f0  fmuls  f13, f1, f13
bd4f4  lfs    f12, 256.0
bd4f8  fdivs  f31, f13, f12
bd500  stfs   f31 → 0x3FDF60
bd508  stfs   f31 → 0x3FD52C
```

**Impacto:** `3FDF68` = saída BBC3C; gémeos `3FDF60`/`3FD52C` = mesma base × **100/256**.

### `3FA7F4` → par ±512

```
bd528  lbz    r3, 0x3FA7F4
bd52c  li     r4, -1          ; exp += 1 (×2 aprox.)
bd530  blrl
bd540  fsubs  f31, f1, 512.0
bd548  stfs   → 0x3FD540
bd550  stfs   → 0x3FDF64
```

### `3FA7F6` — descarte

```
bd564  lhz    r3, 0x3FA7F6
bd568  li     r4, 0
bd56c  blrl                   ; f1 ignorado
bd574  stb    0, 0(r31)       ; r31 = 0x3FD70E
```

### Correção `3FA7F0`

```
bd4a0  fsub   f13, f13, f12   ; f12 = 1023.0  (NÃO fdiv)
bd4ac  stfs   → 0x3FE104
```

Leitores de `3FE104` existem (`lfs` @ `0x9FD5C`, `0xA2904`, …). Semântica física do valor pós-`fsub` = **DESCONHECIDO** (não assumir “0..1 ADC”).

---

## Leitores principais (amostra)

| EA | Leitores (ex.) |
|----|----------------|
| `3FDF68` | `0x81BF4` (eixo slots) |
| `3FDF60` | `0x848E8`, `0xA14D8` |
| `3FD52C` | `0x9D9B0`, `0x9FD60`, muitos |
| `3FDF64` | `0xA15A4` |
| `3FD540` | `0xA19C4` |
| `3FE104` | `0x9FD5C`, `0xA2904`, … |
| `3FE128` | (só writer achado no scan curto) |

---

## IDA

Comentários em `bd4e0`, `bd500`, `bd548`, `bd56c` atualizados via doc.

---

## Resumo Executivo BRUTAL

- **Provado:** frame `0x420` espalha para **`3FDF68` + `3FDF60`/`3FD52C` + `3FD540`/`3FDF64` + `3FE104`/`3FE128`**.
- **Provado:** `3FA7F6` é lido/`BBC3C` sem store float.
- **Corrigido:** `3FA7F0` = **`fsub 1023`**, não divisão.
- **Próximo ROI:** o que `0x81BF4` / consumidores de `3FD52C` fazem com a escala ×100/256 — liga o byte CAN ao tip-in/slots com número.
