# 37 — Eixo dos slots `0x3FC1BC`: writer, `0x3FDF68`, cauda do dispatcher

**Data:** 2026-08-07  
**Status:** ✅ Cadeia estática `dispatcher → 0x81B4C → 3FC1BC` fechada  
**Dependência:** docs 24, 36

---

## Resumo Executivo

1. **FATO:** `shift_table_group_dispatcher` no epílogo (`0x9E7D0+`) chama em sequência helpers; o que arma o eixo é **`blrl → 0x81B4C`** (`shift_slot_axis_3FC1BC_update`).
2. **FATO:** `0x81B4C…0x81C64` escreve **`0x3FC1B8`** depois **`0x3FC1BC`** (único `stfs` deste último no binário).
3. **FATO:** fontes possíveis de `f2` antes do store: **`0.25`**, **`100.0`** (`0x18829C`), ou **`*(0x3FDF68)`**; gate **`0x3FC37A`** pode forçar `100.0` em `3FC1BC`.
4. **FATO:** `0x3FDF68` tem um único writer: **`0xBD4E0`** dentro de `veh_signal_to_3FDF68_block @ 0xBD400`, chamado de **`0xC0664`** (mesmo cluster que `0xC06FC → 0x9EBD0`).
5. **FATO (3FBF6C):** uso = working float **interno** a `0x93510` (+ `0xB2ACxx`); **não** entra nesta cadeia de eixo/slots.

---

## Call chain (FATO)

```
sub_C06EC @ 0xC0640+
  blrl 0xBD400          ; @ 0xC066C  → pode stfs 0x3FDF68 @ 0xBD4E0
  …
  blrl 0x9EBD0          ; mirror cal_mod + 0x93510

… (outro path / mesmo tick) …

shift_table_group_dispatcher epílogo:
  9e7d0  blrl 0x81798   ; shift_post_dispatcher_flags_81794+4
  9e7e0  blrl 0x81A5C   ; helper floats
  9e800  blrl 0x81B4C   ; ★ shift_slot_axis_3FC1BC_update
  9e810  blrl 0x81C6C   ; seguinte
  9e824  lfs  0x3FC1B8  ; usa eixo logo após update
```

Citação: `0x9E7CC–0x9E824`.

---

## Lógica `0x81B4C` → `0x3FC1BC` (FATO)

```
81b4c  entry (via blrl; sem stwu próprio)
81b88  lbz  speed? 0x3FD493          ; mesmo byte de speed do doc 24
81b90  lbz  cal 0x186779             ; ROM byte (valor stock = 0)
81b94  cmpw …
81ba4  stb  flag 0x3FC35E

; --- monta f2 para 3FC1B8 ---
81bac  lfs  0x3FBC64
81bb4  b… → se ramo A:
81bbc    lfs  0.25 (0x1882A4) → jump store
         senão:
81bc8    lfs  5.0 (0x186648), 20.0 (0x185FC8); fadds/fcmpu
81be0    b… → 100.0 (0x18829C)  OU  *(0x3FDF68)
81bfc  stfs f2 → 0x3FC1B8

; --- 3FC1BC ---
81c04  lbz  0x3FC37A
81c0c  beq  skip          ; se gate==0 mantém f2
81c14  lfs  100.0         ; se gate!=0 força 100.0
81c20  stfs f2 → 0x3FC1BC

81c60  stb  flag 0x3FC3E8
81c64  blr
```

| EA | Papel |
|----|-------|
| `0x3FC1B8` | eixo “irmão” (também lido @ `0x9E824`) |
| `0x3FC1BC` | eixo 1D dos `stb` de slot (`r30` @ `0x9E1A4`) |
| `0x3FDF68` | alternativa a `100.0` na montagem de `3FC1B8` |
| `0x3FC37A` | se ≠0 → `3FC1BC := 100.0` |
| `0x3FD493` | speed byte (doc 24) |

**Interpretação objetiva:** o eixo dos thresholds de marcha é um float **normalizado em torno de 0.25 / ~100**, com override por sinal em `0x3FDF68` e gate `0x3FC37A` — **não** o fator cal_mod `0x3FC070`.

**HIPÓTESE (lastro 100.0 / 0.25):** domínio tipo % (throttle/load) ou escala fixa de lookup; confirmar com log de `0x3FC1BC` vs pedal/carga.

---

## Origem `0x3FDF68` (FATO)

```
0xC0664  addi → 0xBD400
0xC066C  blrl
  BD400  veh_signal_to_3FDF68_block
    blrl 0xBBC3C  (helper)
    BD4E0  stfs f1 → 0x3FDF68     ; único writer
    também stfs → 0x3FDF60 / 0x3FDF64 / 0x3FD52C …
```

**DESCONHECIDO:** significado físico exato do retorno de `0xBBC3C` (sensor/escala).  
**FATO:** esse valor só entra nos slots **se** o ramo de `0x81B4C` escolher `lfs 0x3FDF68` em vez de `100.0`/`0.25`.

---

## `0x3FBF6C` — fechamento curto (FATO)

| Onde | Papel |
|------|-------|
| `0x93510` @ `0x9369C+`, `0x93900+`, `0x93A30+` | acumulador do fator pós-`3FC070` + lookups internos |
| `0xB2AC4+` | outro consumidor |
| `0x9D860` | **não lê** |

Não há aresta para `0x3FC1BC` / slots.

---

## IDA (2026-08-07)

| EA | Nome |
|----|------|
| `0x81B4C` | `shift_slot_axis_3FC1BC_update` |
| `0x81794` | `shift_post_dispatcher_flags_81794` |
| `0xBD400` | `veh_signal_to_3FDF68_block` |

---

## Resumo Executivo BRUTAL

- **Provado:** slots ← `3FC1BC` ← **`0x81B4C`** ← epílogo **`0x9E800`** do dispatcher.
- **Provado:** `3FDF68` ← **`0xBD4E0`** ← **`0xC0664`** (cluster com mirror threshold).
- **Provado:** `3FC070`/`3FBF6C` continuam fora desta aresta.
- **Próximo ROI:** CAN-ID @ `0x307492` — doc 41.
