# 68 — Jumptable `cal_mod` `0x9C300` indexado por `3FBBCC`

**Data:** 2026-10-01
**Método:** leitura/decodificação direta do `.bin` (`5U75-14C337-AA.from_phf.bin`), PPC32 BE,
load base 0 (IDA MCP offline no momento — ver nota). Decoder: `scripts/ppc_peek.py`.
Cross-ref: docs [63](63-ratios-scale-3FBBCC-shift-type.md), [64](64-fcmpu-is-schedule-not-clutch-sync.md),
[67](67-3FBBD4-can-mirror-shift-consumers.md).

## FATO — dispatcher
```
0009C310  lis   r11, 0x40
0009C314  lhz   r11, -0x4434(r11)   ; r11 = *(u16)0x3FBBCC   (shift type)
0009C318  cmplwi r11, 0x32          ; compara com 0x32 (50)
0009C31C  rlwinm r11, r11, 2,0,29   ; r11 = idx*4
0009C320  addis r12, r11, 0xA       ; r12 = idx*4 + 0xA0000
0009C324  bc    (bgt) 0x9CFD4       ; se 3FBBCC > 0x32 -> default/return
0009C328  lwz   r11, -0x3CC8(r12)   ; r11 = tabela[idx]  (base 0x9C338)
0009C32C  mtctr r11
0009C330  bctr                      ; salto indireto
```
Tabela de 32 bits em **`0x9C338`** (alvos absolutos), 51 slots (`idx 0..0x32`).

## FATO — distribuição dos alvos
- **35 de 51** slots apontam para **`0x9CFD8`** = epílogo/`return` (**sem ação de cal_mod**).
- Handlers dedicados existem para os índices **baixos** (`0x00..0x0B` = os pares de troca
  1..0xC, doc 63) e para alguns especiais (`0x20`, `0x25`, `0x31`).
- `0x26` (coast, provado vivo doc 24) cai no **return** aqui ⇒ o comportamento coast de `0x26`
  **não** está neste dispatcher; está no leitor coast-vs-normal `0x872B4` (doc 64).
- Handlers `0x9C404`/`0x9C468`/`0x9CF78` começam com `lbz 0x3FC3AC` + branch.

## FATO/ANOMALIA — slot `idx 0x32`
- `tabela[0x32]` (em `0x9C400`) = **`0x3D800040`**, que **não é endereço de código válido**
  (`0x3D800040` está fora da flash `0..0x1FFFFF` e fora da RAM `~0x3F8xxxx`).
- O guard é `bgt 0x32` (estritamente **maior** que `0x32`), logo **`idx == 0x32` NÃO cai no
  default**; indexa o slot malformado e faria `bctr → 0x3D800040` (memória não mapeada).
- `0x32` é um valor **produzível** de `3FBBCC` (`li r5,0x32 @ 0x86AB8`, visto no encoder).

## HIPÓTESE (landmine — NÃO provado em produção)
Se `3FBBCC == 0x32` alcançar este dispatcher, o `bctr` salta para endereço inválido ⇒
exception/reset. Isso **poderia** explicar morte intermitente, mas:
- **DESCONHECIDO:** se o caminho produtor de `0x32` (`sub_86654`/encoder) chega a este dispatcher
  antes de `3FBBCC` ser clampado/sobrescrito.
- **DESCONHECIDO:** se `0x32` ocorre em operação real.
Firmware stock roda há anos ⇒ provavelmente `0x32` é inalcançável aqui (clamp a montante ou
consumido por outro leitor). Confirmar reachability **exige IDA** (xref dos callers de `0x9C300`
+ análise do fluxo que seta `0x32`).

## Nota — base da tabela (±4) a confirmar no IDA
Os handlers lêem `r12=0x400000` via `lis r12,0x40` imediatamente antes do corpo (ex. `0x9C400`),
mas o dispatcher deixa `r12=idx*4+0xA0000`. Isso sugere que o alinhamento exato índice→handler
(e portanto a semântica por-índice fina) precisa da análise do IDA para fechar sem ambiguidade.
O **mapa estrutural** (quantos/quais índices são no-op vs ativos, e a anomalia de `0x32`) é
robusto a esse ±4.

## ATUALIZAÇÃO IDA (2026-10-01, MCP de volta) — off-by-one CONFIRMADO, mas DORMENTE
- `ida_nalt.get_switch_info(0x9C330)`: base `jpt_9C330=0x9C338`, **`ncases=50`** (índices `0..0x31`),
  `defjump=0x9CFD4`, `lowcase=0`. ⇒ a tabela tem **50 entradas**; `0x9C400` já é código de handler
  (`lis r12,0x40`), não slot.
- Guard `cmplwi 0x32 ; bgt default` admite `idx==0x32` (=50), que é **1 além** da tabela ⇒
  `bctr → *(0x9C400)=0x3D800040` (não mapeado). **Off-by-one real** (deveria ser `bge 0x32`).
- Encoder (`0x86A88`): `3FBBCC=0x32` quando `GR(0x3FC106)==alvo r4` e (`r3==0` ou `3FC332≠0`),
  i.e., **"segurando marcha" (estado estacionário)** — condição COMUM; `sth @0x86BB0` confirmado.
- **RECONCILIAÇÃO:** se `0x32` fosse lido por este dispatcher em cruzeiro, haveria crash contínuo.
  Como o stock roda, o dispatcher `0x9AE3C` **não executa com `3FBBCC==0x32`** — coerente com o
  **doc 48** (`0x9AE3C` órfão, sem raiz estática, execução não comprovada / possivelmente morta).
- **VEREDITO:** defeito latente **DORMENTE**. Severidade prática rebaixada de HIGH → **LOW/MEDIUM**.
  **Não** é explicação credível para o stall enquanto `0x9AE3C` não for provado vivo.
- **ÚNICA forma de fechar:** BP vivo em `0x9C314`/`0x9AE3C` (lê LR/execução) ou log de `3FBBCC`
  dirigindo. Scans estáticos aqui estão esgotados (doc 48).

## Resumo Executivo BRUTAL
- PROVADO: `0x9C300` despacha por `3FBBCC` (0..0x32); **35/51 índices = no-op** (return). O efeito
  cal_mod de `3FBBCC` concentra-se nos tipos baixos (pares de troca) + `0x20/0x25/0x31`.
- PROVADO: `0x26` (coast) é **no-op** neste dispatcher — coast vive em `0x872B4`.
- ANOMALIA: `tabela[0x32] = 0x3D800040` (endereço inválido) com guard que **admite** `0x32`;
  `0x32` é produzível. Landmine latente, **reachability não provada**.
- PRÓXIMO PASSO (maior ROI): com IDA de volta, (a) xref callers de `0x9C300` e (b) rastrear se o
  `0x32` do encoder chega aqui — para confirmar/descartar o landmine. Alternativa viva: logar
  `3FBBCC` em uso e ver se alguma vez assume `0x32`.
