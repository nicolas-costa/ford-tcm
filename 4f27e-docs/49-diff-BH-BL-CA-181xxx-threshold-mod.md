# 49 — Diff BH/BL/CA em `0x181xxx` (modulador de threshold)

**Data:** 2026-08-08  
**Status:** ✅ Item 4 da lista ROI — fechado com evidência de bytes  
**Dependência:** docs 27 (shift −0x648), 31 (≠ EPC), 34 (bancos `3FC0B0`), 46 (famílias 1D)  
**Bins:** `5M5P-14C337-BH/BL/CA.bin`, `5U75-14C337-AA.from_phf.bin` (todos 2 MiB)

---

## Resumo Executivo

1. **FATO:** Em `[0x181000, 0x182000)` — **BL ≡ CA ≡ AA** (0 bytes diferem). O delta “versão” nesta janela **não** existe entre BL/CA/AA.
2. **FATO:** Tabelas do pipeline `cal_mod_lookup_to_3FC068/06C/064` (`0x181200`, `0x181278`, `0x181460`, `0x181518`, `0x1816C8`/`1710`/`1758`/`17A0`, `0x1813B8`) são **byte-idênticas** BH↔BL após alinhamento `BH = BL − 0x648`.
3. **FATO:** O que muda BH→BL/CA nesta região é o banco **H_THRESH** (`0x1810F0` / `130` / `170` e vizinhos), consumido por código que grava **`0x3FC0B0` / `0x3FC0B4`** — banco **paralelo** (doc 34), **não** o path `→0x3FC070`.
4. **Próximo ROI (maior):** validação viva de `0x3FC070` vs `0x3FC0B0/B4` sob o mesmo manobra; estático ROI numerado **1–5 encerrado**.

---

## Método

| Passo | Ação | Resultado |
|-------|------|-----------|
| 1 | XOR byte a byte `BL` vs `AA`/`CA` em `0x181000–0x182000` | **0** diffs |
| 2 | Fingerprint 16 B de chunks BL → BH em `0x180000–0x183000` | delta dominante **−0x648** (120/173 hits) — igual doc 27 |
| 3 | Parse descritores 1D `[count][0][0][0][ptr]` (doc 45); comparar **blobs de dados** em `ptr` vs `ptr−0x648` | evita falso “delta float” em palavras-ponteiro |
| 4 | Confirmar consumers via `lis r3,0x18` + `addi imm` no AA | sites `0x884C0`, `0x888EC`, … e H_THRESH `0x8CD4C`/`8EFE4`/`8FC0C` |

**FATO (armadilha):** comparar `BH[ea]` com `BL[ea]` sem −0x648 produz lixo (floats “impossíveis”). Comparar palavras `0x0018xxxx` alinhadas mostra relocação exacta `ptr_BH = ptr_BL − 0x648`.

---

## Identidade BL / CA / AA

| Intervalo | BL vs AA | BL vs CA |
|-----------|---------:|---------:|
| `0x181000–0x182000` | 0 | 0 |
| `0x182000–0x184000` | 0 | **50** (ver § CA abaixo) |
| `0x180000–0x181000` | 2 (`0x180010–11`) | 2 |

---

## Pipeline `cal_mod` → `3FC06x` / `3FC070` — sem retune BH→BL

### Consumers (assembly)

```
884b8  lis   r3, 0x18
884c0  addi  r3, r3, 0x1200   ; 0x181200
884c4  blrl                   ; → stfs 0x3FC068  (cal_mod_lookup_to_3FC068)

888e4  lis   r3, 0x18
888ec  addi  r3, r3, 0x16C8   ; 0x1816C8
888f0  blrl                   ; cal_mod_lookup_to_3FC06C
; idem 0x181710 @ 0x88920, 0x181758 @ 0x88954, 0x1817A0 @ 0x88988

88a44  addi  r3, r3, 0x1460   ; 0x181460  (cal_mod_lookup_to_3FC064)
```

Bytes em `0x884B8`: `3C 60 00 18 … 38 63 12 00 4E 80 00 21`.

### Dados (após −0x648)

| ptr_site (BL/AA) | count | data @ | BH data @ | Diff BH↔BL |
|------------------|------:|--------|-----------|------------|
| `0x181200` | 8 | `0x1811C0` | `0x180B78` | **0** |
| `0x181278` | 6 | `0x181248` | `0x180C00` | **0** |
| `0x181460` | 6 | `0x181430` | `0x180DE8` | **0** |
| `0x181518` | 8 | `0x1814D8` | `0x180E90` | **0** |
| `0x1816C8` | 8 | `0x181688` | `0x181040` | **0** |
| `0x181710` | 8 | `0x1816D0` | `0x181088` | **0** |
| `0x181758` | 8 | `0x181718` | `0x1810D0` | **0** |
| `0x1817A0` | 8 | `0x181760` | `0x181118` | **0** |
| `0x1813B8` | 11 | `0x181360` | `0x180D18` | **0** |

Exemplo `0x1816C8` (pares raw `(f0,f1)`):

`(400,0) (400,0) (400,40) (400,100) (500,150) (600,255) (600,255) (600,0)` — idêntico em BH alinhado.

**Impacto:** qualquer patch “de threshold” nos mapas que alimentam `0x3FC070` via este pipeline **não** explica diferença de comportamento BH vs BL atribuível a `0x181xxx` nestas tabelas — **não há delta**.

---

## O que **difere** BH → BL: banco H_THRESH → `3FC0B0/B4`

### Descritores alinhados (c=7, delta hdr = −0x648)

| BL hdr | BL data | BH hdr | BH data | Estado |
|--------|---------|--------|---------|--------|
| `0x1810EC` | `0x1810B8` | `0x180AA4` | `0x180A70` | **cal diferente**, estrutura ok |
| `0x18112C` | `0x1810F8` | `0x180AE4` | `0x180AB0` | **cal diferente**, estrutura ok |
| `0x18116C` | `0x181138` | `0x180B24` | `0x180AF0` | **cal diferente**, estrutura ok |
| `0x18102C`/`06C`/`0AC` e anteriores da escada 975 | — | — | — | layout BH **não** 1:1 sob −0x648 (inserções); ver nota |

### Pares (amostra) — `0x1810F0` / data `0x1810B8`

| i | BL `(f0,f1)` | BH `(f0,f1)` |
|--:|-------------:|-------------:|
| 0 | (0, 0) | (150, 0) |
| 1 | (0, 975) | (150, 50) |
| 2 | (0, 1950) | (200, 100) |
| 3 | (0, 2925) | (300, 140) |
| 4 | (0, 3900) | (450, 250) |
| 5 | (0, 9562.5) | (600, 510) |

BL: eixo `f0` todo zero + escada `975…9562.5` em `f1`. BH: curva `(eixo, valor)` preenchida.  
**DESCONHECIDO:** unidade física de `f0`/`f1` (não afirmado).

Bytes hdr BL `0x1810EC`: `07 00 00 00 00 18 10 B8`.

### Consumers (assembly) — stores no banco paralelo

```
8cd44  lis   r3, 0x18
8cd48  lfs   f1, -0x2C10(r10)
8cd4c  addi  r3, r3, 0x10F0   ; 0x1810F0
8cd50  blrl                   ; sub_8CD24

8efe0  lfs   f1, -0x2C10(r10)
8efe4  addi  r3, r3, 0x1130   ; 0x181130
8efe8  blrl
8f030  stfs  f31, 0(r29)      ; r29 = 0x3FC0B4   (sub_8EFA8)

8fc08  lfs   f1, -0x2C10(r10)
8fc0c  addi  r3, r3, 0x1170   ; 0x181170
8fc10  blrl
8fc50  stfs  f31, 0(r30)      ; r30 = 0x3FC0B0   (sub_8FBD0)
```

**FATO (doc 34):** `0x3FC0B0` / `0x3FC0B4` **não** são lidos pelo pipeline default `0x8841C–0x88E00` que alimenta `0x3FC070`.

**HIPÓTESE (lastro: store + doc 34):** retune BH→BL nestas tabelas afecta o **banco paralelo mode-0/aux**, não o modulador principal de threshold.

**Nota layout:** 9 ocorrências BL da sequência `(0,975)(0,1950)…`; **0** ocorrências dessa sequência exacta em BH. Três slots finais alinham por −0x648; os anteriores exigem matching estrutural (descritores BH em `0x180924+`) — não forçar pares desalinhados como “delta de cal”.

---

## CA vs BL fora de `0x181xxx` (contexto)

Única ilha relevante em `0x182000–0x184000`: descritor **`0x18249C`** → data **`0x182448`**, count=11.

| i | BL | CA |
|--:|----|----|
| 0 | (2.117, 0.1) | (2.06, 0.1) |
| 1 | (1.99, 0.201) | (1.90, 0.2) |
| … | … | … |
| 9 | (1.0, 1.0) | (0.99, 1.0) |

**FATO:** 50 bytes diferem; região família **K_COAST_182** (doc 46).  
**DESCONHECIDO:** consumer directo (0 XREF IDA no ptr; típico `lis`/`addi` — não rastreado neste item).  
**Fora do escopo estrito `0x181xxx`**, mas documentado para não confundir com threshold-mod.

---

## Contagem alinhada `0x181000–0x182000` (BH vs BL, −0x648)

| Classe | Words (≈) | Significado |
|--------|----------:|-------------|
| Relocação de ponteiro `0x0018xxxx` | 58 | `ptr−0x648` — **não** é cal |
| Float com \|Δ\| > 1e−3 | 67 | quase todo no banco H_THRESH / layout head |
| Outros | 3 | ruído / parcial |
| **Total bytes** | **309** | |

61 descritores 1D em `0x181000–0x182000`: **55** data-idênticos alinhados, **6** com data diferente (família H_THRESH / head).

---

## O que isto **não** é

| Afirmação | Veredicto |
|-----------|-----------|
| `0x181xxx` = mapas EPC | **FALSIFICADO** (doc 31); este diff **não** reabre |
| BH retunou `cal_mod→3FC070` via `0x1816C8` etc. | **FALSIFICADO** — dados idênticos |
| Diff schedule 2→1 (7 vs 12 km/h) está em `0x181xxx` | **FALSIFICADO** — isso é Table 5 em `0x184xxx` (doc 27) |

---

## Resumo Executivo BRUTAL

- **Provado:** BL/CA/AA idênticos em `0x181000–0x182000` (0 B).
- **Provado:** mapas `cal_mod` → `3FC068/06C/064` idênticos BH↔BL (citas `0x1816C8`/`0x888EC`, blobs 0 diff).
- **Provado:** deltas BH reais nesta janela → H_THRESH `0x1810F0/130/170` → stores `0x3FC0B4`/`0x3FC0B0` (`0x8F030`/`0x8FC50`), paralelo ao `3FC070`.
- **Próximo passo ROI:** dump vivo `3FC070` vs `3FC0B0/B4` + CAN/`--tcc`; lista estática ROI 1–5 **completa**.
