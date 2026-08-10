# 48 — Caller externo de `0x9AE3C` (item 5) — wall estático

**Data:** 2026-08-08  
**Status:** 🔴 Esgotado em análise estática — sem caller externo no binário  
**Dependência:** docs 32, 35–36; ROI lista item 5

---

## Resumo Executivo

1. **FATO:** `XrefsTo(0x9AE3C)` / `callers` IDA = **só** a reentrada do case 9 (`0x9CB24`–`0x9CB30`).
2. **FATO:** Scan do binário 2 MB: **0** `bl`/`b`, **0** dword BE/LE `0x9AE3C`/`+4`/`+8`, **0** `lis+ori`, **1** `lis+addi+mtlr+blrl` (= case 9).
3. **FATO:** O cluster irmão `0x4B390 → bl 0xC06EC → blrl 0x9EBD0` também é **órfão** no topo (`4B390` sem xrefs) — mesmo padrão de despacho em RAM.
4. **DESCONHECIDO:** qual task/fnptr em RAM aponta a `0x9AE3C`; exige dump vivo / BP.

---

## Achado A — Único construct estático

**EA:** `0x9CB24` (dentro de `cal_mod_switch_and_pipeline_9AE3C`, case 9)

```
9cb24  lis    r10, 9AE3C@ha
9cb28  addi   r10, r10, 9AE3C@l
9cb2c  mtlr   r10
9cb30  blrl                 ; reentra a própria função
```

**Impacto:** não é caller externo; é recursão/reentrada do switch.

---

## Achado B — Scans negativos (FATO, bin `5U75-14C337-AA.from_phf.bin`)

| Teste | Alvo | Hits |
|-------|------|-----:|
| dword BE | `0x9AE3C`, `0x9AE40`, `0x9AE44` | **0** |
| dword LE | `0x9AE3C` | **0** |
| `bl`/`b` relative/absolute | → `0x9AE3C`/`40`/`44` | **0** |
| `lis`+`ori` | → família `0x9AE0x` | **0** |
| `lis`+`addi`+`mtlr`+`blrl` | → `0x9AE3C` | **1** (`0x9CB24`) |
| tagged `v<<2`, `v^~0`, `v^0x80000000` | = `0x9AE3C` | **0** |
| ptrs ROM em `0x9AE00–0x9AF00` | qualquer | **0** |
| ptrs corpo `0x9AE3C–0x9D120` fora da jumptable interna | — | só JT cases `0x9C338+` |

Ptrs no corpo = **jumptable** `0x9C300` (cases), não callers.

---

## Achado C — Cluster órfão paralelo (contexto)

| Elo | Como é alcançado | Caller externo estático |
|-----|------------------|-------------------------|
| `0x9AE3C` | só case 9 self | **nenhum** |
| `0x9EBD0` (mirror entry+4) | `lis/addi/blrl` @ `0xC06FC` | wrapper `0xC06EC` |
| `0xC06EC` | `bl` @ `0x4B3AC` | wrapper `0x4B390` |
| `0x4B390` | — | **nenhum** (0 xrefs) |

**FATO:** mesmo o caminho “completo” até o mirror (`4B390→C06EC→9EBD0`) **não tem raiz estática**.  
**HIPÓTESE (lastro: padrão task/`blrl` do TCM, docs 09/12):** instalador grava fnptr em RAM (task table / lista `0x3FA400` / análogo) em runtime.

**Impacto:** item 5 não é anomalia isolada de `0x9AE3C` — é o mesmo mecanismo que esconde `0x4B390` / `0x9D774`.

---

## Achado D — Entrypoints IDA

Único entrypoint reportado pelo MCP: `0x864C` (`sub_0`). **Não** referencia `0x9AE3C`.

---

## O que **não** fazer a seguir (ROI)

- Mais scans de literais/`bl` no flash → **ROI negativo** (já exaustivo).
- Assumir que `0x1845E8` / 1D / TCC duty chamam `0x9AE3C` → **falsificado** pelos scans.

## O que **faz** sentido (vivo)

1. BP em `0x9AE3C` / `0x9AE40` no ECU → ler LR / callstack.  
2. Dump RAM de task tables (`0x3FA400` slots, listas SDA) à procura de dword `0x0009AE3C` ou `0x0009AE40`.  
3. BP em instaladores conhecidos (`0x31594`, `0x30C98`) e filtrar writes de fnptr na faixa `0x9A000–0xA0000`.

---

## Resumo Executivo BRUTAL

- **Provado:** caller externo de `0x9AE3C` **não existe** no flash como `bl`, ptr ou `lis/addi` (salvo self case 9).
- **Provado:** cluster `4B390`/`C06EC`/`9EBD0` é o mesmo tipo de órfão.
- **Provado:** item 5 estático = **wall**.
- **Próximo ROI:** item **4** (diff BH/BL/CA) **ou** BP/dump vivo de fnptr — não mais IDA em `0x9AE3C`.
