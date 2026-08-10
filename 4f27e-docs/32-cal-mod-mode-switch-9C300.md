# 32 — Switch de modo cal_mod `0x9C300` (51 cases)

**Data:** 2026-08-07  
**Status:** ✅ Mapa case→stub→cadeia `blrl` documentado (estático)  
**Dependência:** doc 24 (`0x3FBBCC`), doc 31 (pipeline cal_mod ≠ EPC), função `cal_mod_switch_and_pipeline_9AE3C @ 0x9AE3C`

---

## Resumo Executivo

1. **FATO:** Em `0x9C300`, `lhz` lê o seletor **`0x3FBBCC`** (`lis r11,0x40` + `lhz -0x4434(r11)`); `cmplwi …,0x32` → **51** entradas (0..50); jumptable **`jpt_9C330 @ 0x9C338`**.
2. **FATO:** **35** cases (12–31, 33–36, 38–48) e o epílogo pós-cadeia apontam para o pipeline default em **`0x9CFD4/0x9CFD8`** → `blrl` **`0x88420`** (`cal_mod_lookup_to_3FC068+4`) e cadeia 3FC06x.
3. **FATO:** Cases **0–11, 32, 37, 49** têm stubs dedicados; quase todos terminam com `b 0x9CFD4` após uma cadeia de 5 `blrl` (case 49: 1 call). Worker compartilhado **`0x898B0`** aparece em todas as cadeias 0–11 / 32 / 37.
4. **FATO:** Case **50** na jumptable = dword **`0x3D800040`** (EA inválida). Case **9** chama de volta **`0x9AE3C`** (reentrada no próprio dispatcher).
5. **DESCONHECIDO:** writers estáticos de `0x3FBBCC` / gate `0x3FC3AC` (xrefs IDA vazios — só SDA). Caller externo de `0x9AE3C` → **wall estático** (doc 48).

---

## Dispatch (EA `0x9C300`)

```
9c300  stwu  r1, …
9c310  lis   r11, 0x40
9c314  lhz   r11, -0x4434(r11)   ; EA = 0x3FBBCC
9c318  cmplwi r11, 0x32          ; max case = 50
9c31c  slwi  r11, r11, 2
9c320  addis r12, r11, jpt_9C330@ha
9c324  bgt   def_9C330           ; >50 → default
9c328  lwz   r11, jpt_9C330@l(r12)
9c32c  mtctr r11
9c330  bctr
```

| Item | Valor | Citação |
|------|-------|---------|
| Seletor | `u16` **`0x3FBBCC`** | `0x9C310–0x9C314` |
| Limite | `0x32` (50) | `0x9C318` |
| JT | `0x9C338`, 51×`u32` BE | dump binário |
| Default | `0x9CFD4` → pipeline | `b` dos stubs; head `0x9CFE0+` |

**Nota (doc 24):** o mesmo `0x3FBBCC` seleciona coast decel quando `== 0x26` (38). **FATO:** case 38 → **default** `0x9CFD8` (não stub dedicado). O switch aqui **não** é o dispatcher de tabelas S25/S27; é o ramo cal_mod por mode ID.

---

## Jumptable completa (FATO — bytes)

| Case | Target dword | Stub / destino |
|------|--------------|----------------|
| 0 | `0x0009C404` | `cal_mod_mode_case_0` |
| 1 | `0x0009C468` | `cal_mod_mode_case_1` |
| 2 | `0x0009C4CC` | case 2 |
| 3 | `0x0009C530` | case 3 |
| 4 | `0x0009C594` | case 4 |
| 5 | `0x0009C5F8` | case 5 |
| 6 | `0x0009C65C` | case 6 (+ float gate) |
| 7 | `0x0009C85C` | case 7 (+ float gate) |
| 8 | `0x0009CA6C` | case 8 |
| 9 | `0x0009CAD0` | case 9 (+ float gate; reentra `0x9AE3C`) |
| 10 | `0x0009CD00` | case 10 (+ flags `0x3FC331/332`) |
| 11 | `0x0009CDE8` | case 11 (+ flags) |
| 12–31 | `0x0009CFD8` | default pipeline |
| 32 | `0x0009CF24` | case 32 |
| 33–36 | `0x0009CFD8` | default |
| 37 | `0x0009CF78` | case 37 |
| 38–48 | `0x0009CFD8` | default (incl. **0x26**) |
| 49 | `0x0009CF10` | case 49 |
| 50 | **`0x3D800040`** | **EA inválida** (dword corrompido / não-código) |

---

## Gates RAM (resolvidos via `lis 0x40` + displ)

| Símbolo operacional | EA | Uso |
|---------------------|-----|-----|
| Gate byte | **`0x3FC3AC`** | `lbz`; se `==0` salta o 1º worker (cases 0–9, 37; parte de 10/11) |
| Float cmp A | **`0x3FC1B4`** | `lfs`; `fcmpu` vs **`dbl_1882A4` = 0.25** (`0x3E800000`) — cases 6,7,9 |
| Float cmp B | **`0x3FBF64`** | 2º `fcmpu` vs 0.25 — case 6 |
| Flag | **`0x3FC331`** | entry gate cases 10/11 |
| Flag | **`0x3FC332`** | sub-gate cases 10/11 |
| Index byte (shared worker) | **`0x3FC128`** | `cal_mod_mode_worker_898B0` |
| Float table base | **`0x3FC264`** | `lfsx` indexado em `0x898B0` |

IDA: nomes de stubs/workers aplicados; labels em RAM `0x3FBxxx` falharam (segmento/item) — EAs acima são a referência.

---

## Cadeias `blrl` por case (FATO — bytes `lis`/`addi`/`mtlr`/`blrl`)

Padrão dominante (cases 0–8, 10, 32, 37):

```
[gates opcionais]
blrl worker_A          ; frequentemente gated por 0x3FC3AC!=0
blrl worker_B
blrl 0x898B0           ; SHARED — avança índice @0x3FC128 se float[idx]==0.25
blrl worker_D
blrl worker_E
b    0x9CFD4           ; entra no shared → pipeline default
```

| Case | Cadeia (ordem) |
|------|----------------|
| **0** | `0x896E0` → `0x897DC` → **`0x898B0`** → `0x9A828` → `0x89C28` |
| **1** | `0x89D6C` → `0x89E80` → **`0x898B0`** → `0x9A37C` → `0x89F40` |
| **2** | `0x8A0DC` → `0x8A19C` → **`0x898B0`** → `0x8A2A0` → `0x8A3C0` |
| **3** | `0x8A53C` → `0x8A61C` → **`0x898B0`** → `0x99E78` → `0x8A6E4` |
| **4** | `0x8A88C` → `0x8A970` → **`0x898B0`** → `0x8A9D0` → `0x8AB54` |
| **5** | `0x8AD68` → `0x8AE50` → **`0x898B0`** → `0x99984` → `0x8AF0C` |
| **6** | float `0x3FC1B4==0.25` → gate → `0x8B18C` → … → **`0x898B0`** → `0x9BC00` → `0x8B864` |
| **7** | float + gate → `0x8C3B8` → `0x8C548` → **`0x898B0`** → `0x9B608` → `0x8C868` |
| **8** | `0x8D304` → `0x8D400` → **`0x898B0`** → `0x8D6D4` → `0x8D77C` |
| **9** | float + gate → `0x8D9B4` → `0x8DB14` → **`0x898B0`** → **`0x9AE3C`** → `0x8DD90` |
| **10** | `0x3FC331!=0` + (gate/`0x3FC332`) → `0x8E6C4` → `0x8E7B0` → **`0x898B0`** → `0x8E8F8` → `0x8E970` |
| **11** | flags → `0x8F618` → `0x8F6FC` → **`0x898B0`** → `0xBBDC8` (×) + mais floats |
| **32** | `0x9019C` → `0x9061C` → **`0x898B0`** → `0x9084C` → `0x90ACC` |
| **37** | gate → `0x90ECC` → `0x90FE0` → **`0x898B0`** → `0x910EC` → `0x912EC` |
| **49** | **`0x8FE50`** apenas → `b 0x9CFD4` |

**Correção vs comentário IDA antigo:** case 49 ≠ `0x9FE50`; case 32 ≠ `0xA019C`. Bytes: `lis r12,9` + `addi` → **`0x8FE50`** / **`0x9019C`**.

---

## Default pipeline (cases 12–31, 33–36, 38–48 + epílogo)

Head observado a partir de `0x9CFD4` / `0x9CFE0`:

| Ordem | `blrl` target | Papel já nomeado |
|-------|---------------|------------------|
| 1 | `0x88420` | `cal_mod_lookup_to_3FC068+4` |
| 2 | `0x88890` | ramo 3FC06C |
| 3 | `0x889AC` | ramo 3FC064 |
| 4+ | `0x88ADC`, `0x88C14`, `0x88DD4`, … | max / pipeline → `0x3FC070` |

**Impacto:** qualquer mode ID “genérico” (incl. **0x26**) ainda passa pelo path de **threshold cal_mod**, não por worker de case 0–11.

---

## Worker compartilhado `0x898B0` (assinatura)

```
898b4  lis   r6, 0x40
898b8  addi  r6, r6, -0x3D9C   ; 0x3FC264
898bc  lis   r5, 0x40
898c0  addi  r5, r5, -0x3ED8   ; 0x3FC128
898c4  lbz   r31, 0(r5)
898cc  lfsx  f13, r6, r9       ; table[idx]
898d4  lfs   f12, dbl_1882A4   ; 0.25
898d8  fcmpu … ; se == 0.25 e idx<5, incrementa e stb de volta
```

**Interpretação objetiva:** máquina de índice 0..4 sobre floats em `0x3FC264`, avançando enquanto a célula corrente é **0.25**.

---

## IDA (aplicado 2026-08-07)

| EA | Nome |
|----|------|
| `0x9C404`…`0x9CDE8`, `0x9CF10/24/78`, `0x9CFD8` | `cal_mod_mode_case_*` / `…_default_pipeline_9CFD8` |
| `0x896E0`, `0x89C28`, `0x8A0DC`, … `0x90EC8` | `cal_mod_mode_worker_case*` |
| `0x898B0` | `cal_mod_mode_worker_898B0` |
| `0x9019C` | `cal_mod_mode_worker_case32_entry` |
| `0x8FE50` | `cal_mod_mode_worker_case49_entry` |
| `0x4A640` | `solenoid_output_group_update_cycle_0` (suffix `_0` por colisão) |

Comentários em `0x9C300`, `0x9C338`, `0x9CFD8`, `0x898B0`, cases 32/37/49, `0x9CB30`.

---

## O que falta (ROI)

1. ~~Desembrulhar `0x896E0`~~ → **feito** em [33-cal-mod-mode0-reset-lookups.md](33-cal-mod-mode0-reset-lookups.md) (reset + 1D → `0x3FC0B0+`).
2. ~~Resets 2–5 + fio `3FC070`~~ → **feito** em [35-mode-resets-and-3FC070-threshold.md](35-mode-resets-and-3FC070-threshold.md).
3. **Alto ROI estático agora:** consumidores `3FA7F6`/`1A10` — doc 42.
4. **Alto ROI vivo:** dump `0x3FC070`, `0x3FC088`, `0x3FBF6C`, slots; writer `0x3FBBCC`; case 50.

---

## Resumo Executivo BRUTAL

- **Provado:** switch em `0x9C300` indexa `0x3FBBCC` com 51 slots; 35 cases caem no pipeline `0x88420+`; 15 stubs têm cadeias `blrl` tipadas (tabela acima); case 50 é dword lixo `0x3D800040`.
- **Provado:** `0x898B0` é o elo comum das cadeias especializadas (índice @`0x3FC128` / floats @`0x3FC264` vs 0.25).
- **Provado:** mode `0x26` (coast nas tabelas de shift) **neste** switch cai no **default cal_mod**, não num case dedicado.
- **Provado (doc 33):** mode 0 = reset de fase + lookups `0x180/183xxx` → `0x3FC0B0+` — não EPC.
- **Provado (doc 34):** `0x3FC0B0` **não** alimenta `0x3FC070`; bancos paralelos.
- **Provado (doc 35):** schedules 0–5/8; `3FC070`→`3FC088`/`3FBF6C`; `0x93510` via `0x9D774`/`0x9EBCC`.
- **Próximo passo ROI:** campos irmãos do frame `0x420` — doc 42.
