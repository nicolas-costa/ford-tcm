# 45 — Descriptor `0x188768` + leitores `3FD540` / `3FDF64`

**Data:** 2026-08-07  
**Status:** ✅ Formato 1D + fan-out `3FA7F4` mapeados; alinhamento count/ptr do 1D = paradoxo aberto  
**Dependência:** docs 43, 44

---

## Resumo Executivo

1. **FATO:** `cal_1d_lookup_trampoline` @ `0xBBDC8` lê `count = lbz 0(r3)`, `data = lwz 4(r3)`, stride **8** `(breakpoint, value)`, input em `f5`.
2. **FATO:** ROM empacota `[count:u8][pad3][data_ptr:u32]` (ex.: `0x184B64`/`0x188400`/`0x188658`); call sites passam o endereço do **campo ptr** (count em `−4`).
3. **FATO:** `0x3FD540` / `0x3FDF64` (path `3FA7F4`) têm poucos leitores: seletor @ `0x84878`, gate @ `0xA19C4`, 1D @ `0xA15A4` → `0x3FD4E8`.
4. **DESCONHECIDO:** como o 1D obtém `count` correto se `r3` aponta ao ptr (byte0=0x00) — paradoxo vs slots live que consomem estes lookups.

---

## Achado A — Algoritmo 1D (bytes @ `0xBBDC8`)

**EA:** `0xBBDC4`–`0xBBE40` (entry útil: `frsp f5,f1` @ `0xBBDC4`; symbol IDA @ `0xBBDC8`)

```
bbdc4  frsp   f5, f1
bbdc8  lwz    r4, 4(r3)          ; data ptr
bbdcc  lbz    r11, 0(r3)         ; count
bbdd0  clrlslwi r11, r11, 24, 3  ; count * 8
bbdd4  add    r11, r4, r11
bbdd8  addi   r3, r11, -8        ; last pair
…      busca + interpolação linear → f1
```

**Layout esperado por este código:**

| Off | Campo |
|-----|--------|
| `+0` | `u8` count |
| `+4` | `u32` BE ptr para pares float `(bp, val)` |

**Exemplo ROM (shift T4):**

```
184B64  0B 00 00 00     count=11
184B68  00 18 4B 10     data=0x184B10
```

Call @ `0x9E220`–`0x9E228`: `lis/addi r3 → 0x184B68` (**ptr**, não count).

**Impacto:** formato 1D está fechado; o **alinhamento call↔hdr** não está.

---

## Achado B — Descriptor `0x188768` (2D wrapper args)

**Caller:** `sub_9FB44` @ `0x9FD5C` — `f1=0x3FE104`, `f2=0x3FD52C`, `r3=0x188768` → `cal_2d_lookup_wrapper`.

**Bytes @ `0x188768`:**

| Off | Valor | Nota |
|-----|-------|------|
| `+0` | `0x18869C` | ptr |
| `+4` | `0x18865C` | ptr (campo ptr do hdr 1D abaixo) |
| `+8` | `0x1886A4` | cai no meio de floats `45.0…` |
| `+C` | `65.0` | `0x42820000` |

**Hdr 1D adjacente @ `0x188658`:**

```
188658  07 00 00 00     count=7
18865C  00 18 86 24     data=0x188624
```

**Pares @ `0x188624` (FATO, 6 pares limpos):**

| i | bp | val |
|---|-----|------|
| 0 | 0.0 | 150.0 |
| 1 | 1.0 | 300.0 |
| 2 | 2.0 | 400.0 |
| 3 | 3.0 | 600.0 |
| 4 | 4.0 | 800.0 |
| 5 | 5.0 | 1024.0 |

(`count=7` mas só 48B limpos antes do hdr — par 6 colide com a word `count`.)

**Wrapper 2D:** `lwz r3,4(desc)` / `lwz r3,8(desc)` → 1D em cada eixo; depois `BBEC8` com o mesmo `desc`.

**DESCONHECIDO:** dims/`data` efectivos em `BBEC8` para este desc (`lbz 0/1` sobre `0x188768` → `0x00`,`0x18`; `lwz +0xC` → `65.0`) — não é um header 2D clássico nx/ny/data.

**Impacto:** eixos CAN entram no wrapper; superfície Z / dims = aberto.

---

## Achado C — Leitores `0x3FD540` (path `3FA7F4`)

**Writer (doc 43):** `BBC3C(3FA7F4,−1) − 512.0` → `3FD540` + `3FDF64` @ `0xBD548`/`0xBD550`.

### C1 — Seletor / rewrite @ `0x84878`

```
84878  addi  r29, … -0x2AC0     ; r29 = 0x3FD540
8487c  lbz   … byte_186781
       0 → lfs f1, 0(r29)       ; usa valor BD400
       1 → lfs f1, 0x3FD458
       2 → lfs f1, 0x3FBD8C
       else → (0x3FBD8C * flt_1882F0) / const
848e0  stfs  f1, 0(r29)         ; reescreve 0x3FD540
```

**Impacto:** `3FD540` pode ser **substituído** após o fan-out CAN, conforme cal `0x186781`.

### C2 — Gate @ `0xA19C4`

```
a19c4  lfs   f13, -0x2AC0(r12)  ; 0x3FD540
a19cc  lfs   f12, flt_18896C    ; bits 0xC2C80000 = -100.0
a19d0  fcmpu ; bge → skip
…      gates + lfs 0x3FD52C
a1a10  stb   1 → flags (0x3FD518 / 0x3FD51B / 0x3FD52B)
```

**Impacto:** `3FD540 < -100.0` (com gates) arma flags na região `3FD51x` — mesmo bloco que também olha `3FD52C`.

---

## Achado D — Leitor `0x3FDF64` → `0x3FD4E8`

**EA:** `0xA15A4` em `sub_A1400`

```
a15a4  lfs   f1, -0x209C(r10)   ; 0x3FDF64
a15a8  addi  r3, …              ; r3 = 0x188404
a15ac  blrl                     ; cal_1d
a15b4  stfs  f31, 0(r29)        ; r29 = 0x3FD4E8
```

**ROM @ `0x188400`:**

```
188400  0A 00 00 00     count=10
188404  00 18 83 B4     data=0x1883B4
```

**Pares @ `0x1883B4` (FATO):** breakpoint repetido `≈0.0996` (`0x3DCC0001`); values `50,100,200,250,300,350,400,800,1024` (+ par final colide com hdr).

**DESCONHECIDO:** semântica física (porque o bp é constante); se o 1D com `r3=0x188404` usa count=10 correctamente (paradoxo do Achado A).

**Impacto:** gémeo `3FDF64` alimenta float em **`0x3FD4E8`** via 1D.

---

## Mapa curto

```
3FA7F4 → BBC3C−512 → 3FD540 / 3FDF64
                         │
         ┌───────────────┼────────────────┐
         ▼               ▼                ▼
   selector 84878   gate A19C4      1D A15A4
   (rewrite 540)    (flags 3FD51x)   → 3FD4E8
```

---

## Resumo Executivo BRUTAL

- **Provado:** 1D = `count@0` + `ptr@4` + pares×8 (`0xBBDC8`).
- **Provado:** `3FD540` é lido/reescrito em `0x84878` e gated em `0xA19C4` (`< -100.0`).
- **Provado:** `3FDF64` → 1D(`0x188404`) → `stfs 0x3FD4E8` (`0xA15A4`).
- **Próximo ROI:** resolver paradoxo **r3=&ptr vs count@r3** (harness/QEMU step em `0xBBDC8` com `r3=0x184B68`) **ou** seguir flags `0x3FD518`/`0x3FD4E8` no tip-in.
