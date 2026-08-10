# 50 — Shift point modifiers 1D (`0x185708` / `0x185750`)

**Data:** 2026-08-09  
**Status:** ✅ Path estático + live (coast/GATE) fechados; patch v6 zera Y  
**Dependência:** docs 24 (slots), 44 (GATE `3FD48C`), logs `tcm_road_20260809_*`

---

## Resumo Executivo

1. **FATO:** S25=17/22 em coast com MODE=0 **não** vem de T5 nem de `coast_decel` escrevendo S25. Vem de `T5(12) + Y`, Y de tabela 1D `0x185708`.
2. **FATO:** A função no dispatcher só faz lookup + `fadds` sob GATE; os valores 5/10 estão na **cal ROM**, não como immediates do add.
3. **FATO:** Irmão espelho `0x185750` sob o mesmo GATE alimenta o path do S27.
4. **FATO:** Só esses dois footers usam a curva Y=10/5 @ eixos negativos; ~50 outros 1D existem em `0x185xxx` (papéis não inventariados).

---

## Formato (igual outras 1D Ford)

| Peça | S25 modifier | S27 modifier |
|------|--------------|--------------|
| Footer | `0x185708` → ptr `0x1856C8` | `0x185750` → ptr `0x185710` |
| Pares | `(Y, eixo)` float BE | idêntico (espelho) |
| Lookup | `cal_1d_lookup_trampoline` | idem |

Curva stock (Y @ eixo), antes do patch v6:

| Y | eixos |
|---|--------|
| 10 | −9, −8, −7, −3, −3 |
| 5 | −3, 0 (, + terminator) |

---

## Código (dispatcher)

```
0x9DBFC  lfs f1, 0(r28)          ; eixo @ 0x3FD464
0x9DC04  addi r3, … 0x5708      ; footer 0x185708
0x9DC08  blrl                   ; Y → f25
0x9DC10  lwz  r12, 0(r29)       ; GATE @ 0x3FD48C
0x9DC14  cmpwi r12, 1
         …
0x9DC54  fadds f31, f29, f25    ; f29 = T5 lookup (12)
```

Irmão: `0x9DAE0` → `0x185750` (mesma condição GATE).

Store: float em `0x3FD4A4` → `stb` S25 @ `0x9E6A4` (path blend / G5=0).

---

## Efeito no avaliador

`speed >= S25` → elegível 2ª; senão 1ª (`0x838C8`).  
Em 3ª: primeiro S27 (ficar/sair); depois S25 (2ª vs 1ª).

Com GATE e Y=5/10:

| | TCM | ≈ vel (TCM+3) |
|--|-----|----------------|
| T5 só | 12 | 15 |
| +5 | 17 | 20 |
| +10 | 22 | 25 |

Live: pacote 19/17 e 24/22 com `GATE=1`, `thr≈0` → bounce 2→1 ~19–22 vel e 3→1 quando S27 também alto.

---

## Patch v6

Y → `0.0` em todos os pontos das duas tabelas (`scripts/build_v6_modifier.py`).  
Código intacto; GATE ainda arma, soma zero.

---

## Vizinhos / DESCONHECIDO

Scan `0x185000–0x186200`: ~50 footers 1D. Ex.: `0x1856C0` (curva tipo RPM) — **outro** papel.  
Inventário completo de gates/modifiers fora deste par = follow-up; **não** refuta o patch deste sintoma.

---

## Artefatos

- Bin/PHF: `firmwares/5U75-14C337-AA_v6.2.{bin,PHF}`
- Logs: `tcm_road_20260809_142825.csv`, `tcm_road_20260809_150045.csv`
