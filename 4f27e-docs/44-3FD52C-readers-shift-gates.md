# 44 — Leitores de `0x3FD52C` / `0x3FDF60` (escala ×100/256 do frame `0x420`)

**Data:** 2026-08-07  
**Status:** ✅ Ligação estática ao dispatcher de slots e a gates de cal  
**Dependência:** docs 37, 43

---

## Resumo Executivo

1. **FATO:** `0x3FD52C` (gémeo de `0x3FDF60`) entra em `shift_table_group_dispatcher` e **condiciona** `*(0x3FD48C)=1`.
2. **FATO:** com `*(0x3FD48C)==1` e `*(0x3FBBCC)==0xB`, o dispatcher pode forçar **`stb 0xFF → 0x3FBC24`** (slot).
3. **FATO:** o mesmo float é eixo `f2` de um `cal_2d_lookup_wrapper` com `f1=0x3FE104` (path `3FA7F0−1023`).
4. **FATO:** em `cal_mod_max_064_068_06C_to_3FC070`, `3FD52C < 6.0` (com outros gates) força `3FC070 = 0.078125`.

---

## Origem (cita doc 43)

```
3FA7F2 → BBC3C(.,1) → 3FDF68
       → × 100.0 / 256.0 → 3FDF60 e 3FD52C   @ bd4e4–bd508
```

---

## Achado A — Gate no `shift_table_group_dispatcher`

**EA:** `0x9D9B0` … `0x9DA14`  
**Função:** `shift_table_group_dispatcher` (`0x9D860`)

```
9d9ac  lis   r9, 0x40
9d9b0  lfs   f11, -0x2AD4(r9)     ; 0x3FD52C
9d9b4  lis   r12, flt_1024_gate_3FD52C@ha
9d9b8  lfs   f12, ...             ; ROM 0x1866D4 = 1024.0 (bits 0x44800000)
9d9bc  fcmpu cr1, f11, f12
9d9c0  bgt   cr1, loc_9DA18       ; skip escrita da flag
…                                 ; lbz 0x3FD493 → float via 0x4330; −1000.0; cmp 0.0
…                                 ; lbz 0x3FD8D8; (r12-0x28) < 0xA
9da10  li    r12, 1
9da14  stw   r12, 0(r29)          ; r29 = 0x3FD48C (init @ 9d87c–9d888)
```

**Interpretação objetiva:**
- Init: `stw 0 → 0x3FD48C` @ `0x9D888`.
- Só escreve `1` se **todas** as condições passarem, incluindo `*(float*)0x3FD52C ≤ 1024.0`.
- Constantes: `0x1866D4=1024.0`, `0x188288=1000.0`, `0x1866F0=0.0`.

**Impacto:** o byte CAN escalado **habilita** a flag dword `0x3FD48C` usada mais abaixo no mesmo dispatcher.

---

## Achado B — Consumo da flag → slot `0x3FBC24`

**EA:** `0x9E6AC` … `0x9E734`

```
9e6ac  lwz   r12, -0x2B74(r12)    ; 0x3FD48C
9e6b0  cmpwi r12, 1
9e6b4  bne   loc_9E794            ; sai sem patch de slot
9e6b8  …
9e6bc  lhz   r12, -0x4434(r12)    ; 0x3FBBCC (mode)
9e6c0  cmpwi r12, 0xB
9e6c4  bne   loc_9E794
…                                 ; mais lbz gates
9e72c  li    r11, 0xFF
9e730  stb   r11, -0x43DC(r12)    ; 0x3FBC24 = 0xFF
```

**Interpretação objetiva:** cadeia  
`3FD52C≤1024` → `3FD48C=1` → (mode `0xB` + flags) → **`3FBC24=0xFF`**.

**HIPÓTESE (lastro: slot table docs 24/37):** `0xFF` neste slot é valor sentinela / override de threshold — **não** afirmado o nome físico do sinal CAN.

**Impacto:** fecha o elo estático **frame `0x420` → float escalado → flag → slot RAM do shift**.

---

## Achado C — 2D lookup com `3FE104` × `3FD52C`

**EA:** `0x9FD44` … `0x9FD68` em `sub_9FB44`

```
9fd44  lis/addi r12 → cal_2d_lookup_wrapper @ 0xBBE48
9fd5c  lfs   f1, -0x1EFC(r10)     ; 0x3FE104  (3FA7F0 − 1023.0)
9fd60  lfs   f2, -0x2AD4(r9)      ; 0x3FD52C
9fd64  addi  r3, … word_188768
9fd68  blrl
9fd6c  lfs   f11, -0x1F58(r12)    ; 0x3FE0A8
9fd74  fcmpu … ; se f1 > 3FE0A8 (+gates) → stb flags @ 0x3FD4D2 / 0x3FD4C8 / 0x3FD4C9
```

**Bytes @ `0x188768` (BE):**
```
00 18 86 9C | 00 18 86 5C | 00 18 86 A4 | 42 82 00 00 …
```
ptrs `0x18869C`, `0x18865C`, `0x1886A4`; dword `+0xC` = `65.0`.

**DESCONHECIDO:** layout exacto do descriptor / significado físico da superfície 2D (não forçar “throttle×load”).

**Impacto:** o mesmo pacote CAN alimenta **dois eixos** do lookup (`3FA7F0`-path e `3FA7F2`-path).

---

## Achado D — Gate em `3FC070`

**EA:** `0x88B44` … `0x88B90` em `cal_mod_max_064_068_06C_to_3FC070`

```
88b44  lfs   f13, -0x2AD4(r12)    ; 0x3FD52C
88b48  lis   … flt_6_gate_3FD52C  ; 0x1864F0 = 6.0 (0x40C00000)
88b50  fcmpu … bge → skip
… gates lbz …
88b88  lfs   f2, flt_186180       ; 0.078125
88c04  stfs  f2, -0x3F90(r12)     ; 0x3FC070
```

**Impacto:** valor escalado baixo (`< 6.0`) pode **substituir** o max habitual escrito em `0x3FC070`.

---

## Achado E — Gémeo `3FDF60` → `3FD4EC` / taxa

| EA | Ação | Citação |
|----|------|---------|
| `0x848E8` | `lfs 3FDF60` → `stfs 0x3FD4EC` | `-0x20A0` → `-0x2B14` |
| `0xA14D8` | `(3FDF60 − 3FD4EC) / f1` → `stfs 0x3FD458` | `sub_A1400` |

**Impacto:** cópia + diferença/escala (rate); consumidores adicionais de `3FD458` = **DESCONHECIDO** neste doc.

---

## Mapa de leitores `lfs`/`addi` (scan)

| Símbolo | Off SDA | Hits (amostra) |
|---------|---------|----------------|
| `3FD52C` | `-0x2AD4` | `9D9B0`, `9FD60`, `88B44`, `9C8E8`, `A19F8`, `A6C80`, … (~28) |
| `3FDF60` | `-0x20A0` | `848E8`, `A14D8`, `A1528`, `A1044` |

---

## Resumo Executivo BRUTAL

- **Provado:** `3FD52C ≤ 1024.0` é condição necessária para `*(0x3FD48C)=1` (`0x9D9B0`–`0x9DA14`; const `0x1866D4`).
- **Provado:** `3FD48C==1` + mode `0x3FBBCC==0xB` pode escrever `0xFF` em slot `0x3FBC24` (`0x9E6AC`–`0x9E730`).
- **Provado:** `3FD52C` + `3FE104` são `f2`/`f1` de `cal_2d_lookup_wrapper` com desc `0x188768` (`0x9FD5C`).
- **Próximo ROI:** feito em doc 45 (`188768` + leitores `3FD540`/`3FDF64`).
