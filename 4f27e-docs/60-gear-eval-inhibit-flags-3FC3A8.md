# 60 — Flags extra do `gear_zone_evaluator`: `3FC3A8` / `3FC404` / `3FD728`

**Data:** 2026-09-25  
**Status:** writers no IDA (`py_eval`); `find_bytes` `99 ?? C3 A8` falha (`stb` é `9B EC C3 A8`)  
**Dependência:** doc 24  
**IDB:** `5U75-14C337-AA.rebuilt.aligned.bin.i64`

---

## Resumo Executivo

1. **FATO:** unique `stb` SIMM `C3A8` = `0x83160` em `sub_82F34` (call dispatcher `0x9E8B8`, **antes** do evaluator `0x9E974`).
2. **FATO:** `3FC3A8≠0` **não** ignora S28. Com `speed >= S28` (`0x83804` não-`blt`), `bne 0x8383C` → `li r3, 8`. Se `3FC3A8==0` em 3ª, o fluxo cai em S27 (`0x8388C`) e **fica 3ª**. S28 sozinho não promove 3→4.
3. **FATO:** `3FC404` ← cópia de `3FD8D0` (`stb 0x80F64`, cluster `0x80E80`). `3FD728` ← `(3FD8D0≠0)` (`stb 0xAA9C8`). Unique `stb` `D8D0` definido: `0xAD26C` (=0), `0xAD28C` (=1).

---

## `3FC3A8` (FATO — enable 3→4)

`sub_82F34`:

```
82f6c  r29 = 0x3FC3A7
83054  stb r30, 0(r29)            ; 3FC3A7
8305c  cmpwi 3FC3A7, 1
83060  bne  830E8                 ; senão 3FC3A8 via 830E8+
830e0  li   r31, 1                ; se 2D 186C54(3FC1BC, speed) <= 3FC300
83158  li   r31, 0                ; 3FC3A7==0, ou speed vs 186C54-2.0
83160  stb  r31, -0x3C58(r12)     ; 0x3FC3A8
```

`3FC3A7` @ `0x83054`: 2D `BBE48` / `186C54`, eixos `3FC1BC` + `3FD493`, vs `3FC300`; `flt_186184=2.0`.

Evaluator:

```
83804  cmpw  3FD493, S28
83808  blt   83844                 ; speed < S28: sem 4ª por aqui
83810  lbz   3FC3A8
83818  bne   8383C                 ; → li r3, 8
; 3FC3A8==0 e GR=4: cai 83874 → S27 @ 8388C → 83A30 li r3, 4
```

**HIPÓTESE:** `3FC3A8` é o “arm” de 3→4 depois de S28; S27 é o stay default.

Gémeo `3FC3A7` @ `0x83868`: após `speed >= S26`, `≠0` → `0x83A30` (`li r3, 4`) = 2→3.

---

## `3FC404` / `3FD728` (FATO — skip da árvore)

```
837c8  lbz  3FC404
837d0  bne  838DC
837d8  lbz  3FD728
837e0  bne  838DC                  ; histerese float; não é cmpw dos slots
```

```
80f5c  lbz  3FD8D0
80f64  stb  → 3FC404               ; .byte; call 0x80E80 @ 0x9943C
aa9ac  lbz  3FD8D0
aa9b8  li   r3, 1  /  aa9c0 li 0
aa9c8  stb  r3, 3FD728             ; .byte; blr imediato
ad26c  stb  0, 3FD8D0              ; r4==0
ad28c  stb  1, 3FD8D0              ; r4 > byte_189280
```

Dispatcher `0x9E70C`/`0x9E71C`: se **ambos** 0 → `stb 0xFF` em S24 (`0x9E730`). Consumo distinto do evaluator.

Nome de `3FD8D0` **DESCONHECIDO** (padrão timer/fault vs `189280`).

---

## MCP / IDA

- Servidor: `project-0-ford-tcm-ida-pro-mcp`
- IDB path devolvido: `...\5U75-14C337-AA.rebuilt.aligned.bin.i64`
- `find_bytes` `99 ?? C3 A8` = 0; store real `9B EC C3 A8` @ `0x83160`

---

## Dump vivo — diferido

| EA                                   | Porquê               |
| ------------------------------------ | -------------------- |
| `0x3FC3A8` / `0x3FC3A7`              | enable 3→4 / 2→3     |
| `0x3FD8D0` / `0x3FC404` / `0x3FD728` | skip árvore + S24=FF |

---

## Resumo Executivo BRUTAL

- **Provado:** S28 **não** basta para GT=4ª. Falta `3FC3A8≠0` (`stb 0x83160`).
- **Provado:** `3FC404` e `3FD728` são o mesmo sinal `3FD8D0` (cópia vs boolean).
- **Provado:** IDA MCP neste IDB; `find_bytes` cego a `stb r31`.
- **Próximo estático:** quem chama o writer `0xAD230` de `3FD8D0` (r4), ou 2D `186C54` Y (o que arma `3FC3A8`).
