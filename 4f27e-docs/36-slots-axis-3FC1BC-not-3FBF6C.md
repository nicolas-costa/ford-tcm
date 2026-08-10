# 36 — `3FBF6C` ↛ slots; eixo real `0x3FC1BC`; órfãos do sequenciador

**Data:** 2026-08-07  
**Status:** ✅ Ponte `3FC070/3FBF6C` → `0x3FBC24–29` **falsificada**; eixo dos slots identificado  
**Dependência:** docs 24, 35

---

## Resumo Executivo

1. **FATO:** `shift_table_group_dispatcher @ 0x9D860` **não lê** `0x3FBF6C`, `0x3FC088` nem `0x3FC070` (scan SDA `0x9D860…0x9EC60`).
2. **FATO:** escritas dos slots (`stb` @ `0x9E1D4+`) usam eixo **`lfs 0(r30)` com `r30 = 0x3FC1BC`**, não o fator cal_mod.
3. **FATO:** único `stfs` para `0x3FC1BC` no binário = **`0x81C20`** (valor `100.0` de `0x18829C` ou `*(0x3FDF68)`).
4. **FATO:** `0x94E74` não toca slots nem `3FBF6C` (só flags, ex. `stb` → `0x3FD400`-ish / `0x3FC3EC`).
5. **FATO:** `0x9D774` — **zero** `lis`/`addi`, **zero** branch, **zero** dword `00 09 D7 74` no flash. Sem referência estática.

---

## Dataflow corrigido (FATO)

```
cal_mod max → 0x3FC070
       │
       ▼
0x93510: escala → 0x3FC088 / 0x3FBF6C (+ 0x183DE0)
       │
       ✕  NÃO lido por 0x9D860
       │
       └── consumidores: corpo de 0x93510; também 0xB2ACxx (outro bloco)

0x81C20: stfs → 0x3FC1BC   (100.0 ou RAM 0x3FDF68)
       │
       ▼
0x9D860 / 0x9E1A4+: r30 := 0x3FC1BC
       │
       ▼
cal_1d_lookup(tabelas 0x184Bxx…) ; fctiwz ; stb → 0x3FBC24–29
       │
       ▼
gear_zone_evaluator @ 0x83484 (doc 24)
```

Citação slot write (Group1):

```
9e1a4  … r30 := 0x3FC1BC …
9e1e4  lfs   f1, 0(r30)
9e1ec  addi  r3, … 0x184BC8
9e1f0  blrl  ; cal_1d_lookup
9e1f4  fctiwz
9e208  stb   → 0x3FBC25
9e23c  stb   → 0x3FBC24
```

Citação eixo:

```
81bf4  lfs   f2, …          ; 0x3FDF68  OU
81be8  lfs   f2, 0x18829C   ; 100.0
81bfc  stfs  f2 → 0x3FC1B8
81c20  stfs  f2 → 0x3FC1BC
```

---

## O que `0x94E74` faz (FATO)

Chamado **depois** de `0x93510` nos sequenciadores. Head:

- `blrl 0x949D8`
- compara floats RAM vs cal (`0x185D48+`)
- `stb` flag em `0x3FD400` (`-0x2C00`) e `0x3FC3EC`
- **sem** `stfs`/`stb` em `0x3FBC24–29` nem load de `0x3FBF6C`

**Interpretação objetiva:** pós-processamento / enable de caminho, não preenchimento de threshold km/h.

---

## Órfãos estáticos (FATO)

| EA | Refs `lis`/`addi` | Branches | Dword no flash |
|----|-------------------|----------|----------------|
| `0x9D774` sequencer | **0** | **0** | **0** |
| `0x9D860` dispatcher | só self `0x9DE90` | **0** | — |
| `0x9EBCC` mirror | entry+4 ← **`0xC06FC`** | — | — |
| `0x9AE3C` cal_mod | ← `0x9CB28` (self) | — | — |
| `0xC06EC` | **0** | — | — |

**HIPÓTESE (lastro):** o grafo “vivo” de threshold+slots entra por mecanismos não-literais (tabela em RAM, tagged ptr, `bctr`), igual outros despachos do TCM. O único fio estático completo até `0x93510` continua sendo **`0xC06EC → 0x9EBD0`**.

**Impacto:** marcar `0x9D774` como **sem prova de reachability estática**; não assumir que roda em toda tip-in.

---

## `0x3FBF6C` — onde realmente aparece

| Região | Uso |
|--------|-----|
| `0x93510` | working float do fator (múltiplos `lfs`/`stfs`) |
| `0xB29F8+` | `lfs` em bloco separado (não dispatcher de slots) |

**DESCONHECIDO:** efeito final do fator cal_mod em marcha (coast handler? outro comparador?) — **não** é o eixo dos bytes S24–S29.

---

## IDA

- Tentativa de materializar código em `0x81C20` falhou (região ainda `.byte` no IDB) — EA e bytes confirmados no BIN.
- Nomes úteis já existentes: `shift_table_group_dispatcher`, `shift_threshold_compute_with_mode`.

Comentário operacional: `0x3FC1BC` = **eixo 1D dos shift slots** (frequente `100.0`).

---

## Resumo Executivo BRUTAL

- **Provado:** slots `0x3FBC24–29` bebem **`0x3FC1BC`**, não `0x3FC070`/`0x3FBF6C`.
- **Provado:** `3FC070`→`3FBF6C` é banco paralelo (como mode modulators vs max).
- **Provado:** `0x9D774` sem nenhuma referência no flash — reachability estática **nula**.
- **Próximo ROI:** ver doc 37 — cadeia writer fechada; desembrulhar `0xBBC3C` (fonte de `3FDF68`).
