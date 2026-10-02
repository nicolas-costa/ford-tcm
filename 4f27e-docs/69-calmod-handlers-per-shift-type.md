# 69 — Handlers do cal_mod por tipo de troca (o que cada `3FBBCC` modifica)

**Data:** 2026-10-01
**Método:** IDA MCP (switch_info + decode). Cross-ref: docs
[63](63-ratios-scale-3FBBCC-shift-type.md), [67](67-3FBBD4-can-mirror-shift-consumers.md),
[68](68-calmod-jumptable-9C300-3FBBCC.md), [44](44-3FD52C-readers-shift-gates.md).

## FATO — estrutura
Dispatcher `0x9C300` (dentro de `cal_mod_switch_and_pipeline_9AE3C`) indexa `3FBBCC` →
**15 handlers ativos**; demais índices = no-op (`0x9CFD8`, return). Cada handler é um **seletor
fino**: lê flags de gate e faz **tail-call (`mtlr;blrl`) para uma CASCATA de workers** na faixa
`0x88xxx–0x90xxx`. Comuns a todos: `0x898B0` (helper de estado) e `0xBBDC8` (interpolação, sem stores).

## FATO — mapa idx(=`3FBBCC`) → tipo de troca → head do cascade
Pares de bitmask vêm do encoder (doc 63; bitmask `{1,2,4,8}`, "1=1ª" NÃO provado).

| idx | par (from→to) | handler | head worker |
|----:|---------------|---------|-------------|
| 0x00 | estado/holding | 0x9C404 | 0x896E0 |
| 0x01 | 1→2 | 0x9C468 | 0x89D6C |
| 0x02 | 1→4 | 0x9C4CC | 0x8A0DC |
| 0x03 | 1→8 | 0x9C530 | 0x8A53C |
| 0x04 | 2→4 | 0x9C594 | 0x8A88C |
| 0x05 | 2→8 | 0x9C5F8 | 0x8AD68 |
| 0x06 | 4→8 | 0x9C65C | 0x8B18C |
| 0x07 | 8→4 | 0x9C85C | 0x8C3B8 |
| 0x08 | 8→2 | 0x9CA6C | 0x8D304 |
| 0x09 | 8→1 | 0x9CAD0 | 0x8D9B4 |
| 0x0A | 4→2 | 0x9CD00 | 0x8E6C4 |
| 0x0B | 4→1 | 0x9CDE8 | 0x8F618 |
| 0x20 | especial | 0x9CF24 | 0x9061C |
| 0x25 | especial | 0x9CF78 | 0x90ECC |
| 0x31 | especial | 0x9CF10 | (stub addi/mtctr) |
| 0x0C=2→1 e 0x26=coast | — | **no-op** aqui (coast vive em `0x872B4`) |

## FATO — o que os workers ESCREVEM
- Comum `0x898B0`: bytes de estado `3FC128/3FC129/3FC12B`.
- Per-tipo (ex. `0x896E0`, `0x8C3B8`): preenchem um **bloco de 18 floats `0x3FC264..0x3FC2A8`**
  (perfil de pressão/mod da troca) + escalares `3FBF94`,`3FC100`,`3FBF50`,`3FBD1C`,`3FC310`,
  `3FBCFC`,`3FBCD4` e bytes `3FC394`,`3FC35F`,`3FC330`,`3FC3F2`.
- ⇒ **cada tipo de troca grava um perfil diferente no mesmo bloco `3FC264..3FC2A8`.**

## FATO — flags de gate por handler (amostra exposta)
- idx 0x06: `3FC3AC,3FBF64,3FC3D8,3FC361,3FC1F8,3FC1F0,3FC23C,3FC200,3FC3C1`.
- **idx 0x07 (8→4): lê `3FD52C` (sinal de CARGA do CAN, doc 67) + `3FC190` (gémeo, doc 58)** além do
  eixo de razão `3FC1F0/3FC23C`. ⇒ o downshift 8→4 é modulado pelo sinal de rede.
- idx 0x09: `3FBD6C` (eixo de peso) + `3FC1F8`.
- idx 0x0A/0x0B: `3FC332` (flag do ramo `0xC`/`0x32`) + `3FBD6C`.

## FATO — saída do cluster (rastreada 2026-10-01)
Varredura global por base `lis 0x40` provou:
- **Bloco `0x3FC264..0x3FC2A8` é scratch INTRA-cluster**: escrito e lido só dentro de
  `0x89xxx–0x90xxx` + dispatcher `0x9AE3C` (acesso por `addi r,r12,0xc264/0xc27c/0xc294` ⇒ três
  sub-arrays de 6 floats). Nenhum leitor externo. (Os "externos" `sub_B71B8/sub_B94B8/0x9c848`
  eram FALSO POSITIVO: `flt_BC2A4` = ponteiro de função ROM `0xBC2A4` via `lis 0xC`, não `0x3FC2A4`.)
- Os escalares `3FBF50/3FBD1C/3FC310/3FBCFC/3FBCD4/3FBF94/3FC100` também são consumidos só
  dentro do cluster + `0x9AE3C` (externos a `3FC100` = rotinas de init que zeram).
- **A saída real do cal_mod são os bytes de estado `3FC128/3FC129/3FC12B`** (gravados pelo worker
  comum e por cada per-tipo). Leitores EXTERNOS = o próprio caminho de troca:
  - `gear_commit_3FC104 @0x83E04` lê `3FC129` ⇒ **commit de marcha**.
  - `shift_slot_eval_with_mode_switch @0x872B4` lê `3FC129` ⇒ **avaliador de slot de troca**.
  - `sub_86BC0 @0x86BC0` lê `3FC128/129`; `sub_91E3C` lê `3FC128/12B` (11×) e `sub_949D4`
    lê `3FC128/129` ⇒ estágios de saída/solenoide.
- **Desacoplado do EPC/pressão (doc 53):** o writer EPC `0xB2944` lê seu estado de
  `0x3FD9EC/F4/F0/F8/FC` + `0x3FA7A8` — NÃO lê nada do cal_mod. São subsistemas separados.

## FATO — semântica dos bytes de estado `3FC128/129/12A/12B/12C` (2026-10-01)
Varredura global (base `lis 0x40`, r13-rel, indexado): **70 stores, todos `li 0` ou `li 1`,
todos no cluster cal_mod**. Nenhum store externo, nenhum RMW/incremento. ⇒ **domínio real = {0,1}**
(latches booleanas), apesar de alguns leitores conterem limiar (`>3`,`<=4`) — ver nota de vestígio.

- São um **array de bytes adjacentes** (`3FC128,129,12A,12B,12C`) = latches one-shot de **sub-fase
  (fill/ramp)** por elemento da troca. Zerados no início de cada worker; setados `=1` uma vez quando
  um sub-passo dispara. Dentro do array, uns servem de **gate de ENTRADA** (`==1` exigido) e outros
  de **latch de SAÍDA** (set `=1`).
- Condição de set (prova, `case7 @0x8C680` / `case6 @0x8B408`):
  ```
  if ( 3FBD84 < lim                       # acumulador global
    && 3FBBD4 < (3FC1F8 + 9562.5)         # <== MIRROR DO CAN (doc 67) abaixo de limiar
    && <slot do mod-array> == 0.25        # slot ainda no default
    && 3FC12A/3FC12C == 1 )               # gate de entrada (byte adjacente)
  { 3FBD84 += 3FBC1C; 3FC129/12B = 1; <slot> += 3FBC1C; }
  ```
  ⇒ o latch de sub-fase **depende do sinal de carga do CAN** (`3FBBD4`) — mais um elo CAN→troca.
- Leitores (saída do cluster): `gear_commit_3FC104 @0x83E04` lê `3FC129`;
  `shift_slot_eval_with_mode_switch @0x872B4` lê `3FC129` (ramo tipo 10);
  `sub_86BC0` usa `3FC128/129` (gating tipos 7/8/10); `sub_91E3C` lê `3FC128/12B` (estágio de saída).
- **NOTA de vestígio:** as comparações `3FC129 > 3`, `3FC128 <= 2`, `3FC129 <= 4` nos leitores são
  efetivamente constantes no stock (bytes nunca passam de 1). Lógica de contador desenhada mas
  **dormente** — o stock só dirige latches 0/1.

## DESCONHECIDO
- Rótulo humano de `0x20/0x25/0x31`.
- Qual elemento físico (embreagem/banda) cada byte do array `3FC128..12C` representa.

## Resumo Executivo BRUTAL
- PROVADO: cada tipo de troca tem um cascade próprio de workers; o **perfil de 18 floats
  `0x3FC264..3FC2A8` é scratch INTERNO** (não é a saída cross-cluster).
- PROVADO: **a influência do cal_mod na troca sai pelos bytes `3FC128/129/12B`**, lidos por
  `gear_commit_3FC104 (0x83E04)` e `shift_slot_eval_with_mode_switch (0x872B4)` — fecha
  "tipo de troca → decisão de marcha/slot".
- PROVADO: o downshift **8→4 (idx7)** é modulado pelo **sinal de carga do CAN** (`3FD52C`, doc 67);
  `2→1` (0xC) e `coast` (0x26) = no-op aqui.
- PROVADO: cal_mod é **desacoplado do EPC/pressão** (`0xB2944` usa `0x3FD9xx`, não o cal_mod).
- PRÓXIMO ROI: decodificar os 3 bits de `3FC128/129/12B` (significado p/ commit/slot-eval).
