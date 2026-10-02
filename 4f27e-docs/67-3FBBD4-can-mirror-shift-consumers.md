# 67 — `3FBBD4`: espelho de sinal de CAN consumido pelo ponto de troca

Cross-ref: docs [38](38-BBC3C-exponent-to-3FDF68.md), [40](40-channel-0x420-toucan-mailbox.md),
[42](42-can-0x420-payload-and-logger.md), [43](43-BD400-float-fanout-from-0x420.md),
[44](44-3FD52C-readers-shift-gates.md).

## Objetivo
Fechar o item "writer de `3FC3A9`" (negativo) e, no caminho, mapear uma entrada **não-tabela**
que influencia o ponto de troca: o escalar `0x3FBBD4`.

## FATO — cadeia de origem
- `0x3FA7F0` (u16) = payload da mensagem CAN `0x420` (TouCAN B / MB1). Único leitor SDA: `0xBD488`
  (`lhz r11, -0x5810(r11)`). Sem writer SDA → preenchido pela camada I/O (CAN), docs 40–42.
- `0xBD4AC` `stfs f13 -> 0x3FE104`, com `f13 = (float)*(0x3FA7F0) - 1023.0` (`flt_18A410`).
  Store único em `0x3FE104`. (doc 43 já corrige a leitura "fdiv" → é `fsub 1023.0`.)
- `sub_81238` (case 7 do jumptable `0x94454`, task periódico, **sem caller direto**):
  - `0x81250` `f31 = *(0x3FE104)`
  - `0x81258` `stfs f31 -> 0x3FBBD4`   ← **espelho A**
  - `0x81260` `stfs f31 -> 0x3FBDA0`   ← espelho B
  - A seguir deriva razões/derivada/integrador (`0x3FD450`, `0x3FC24C..58`).

## FATO — consumidores de `0x3FBBD4` (disp `0xBBD4`, todos `lfs`)
| EA        | Função                                   | Papel na troca                                  |
|-----------|-------------------------------------------|-------------------------------------------------|
| `0x85358` | `gear_trans_gate_3FC388`                  | gate de transição de marcha                     |
| `0x873D8` | `shift_slot_eval_with_mode_switch`        | avaliação de slot c/ troca de modo              |
| `0x87C1C` | `shift_slot_eval_with_mode_switch`        | idem (segundo uso)                              |
| `0x9E914` | `shift_table_group_dispatcher`            | dispatcher de grupo de tabela                   |
| `0x9F190` | `shift_point_2d_eval_from_cal`            | **avaliação 2D do ponto de troca**              |
| `0x99164` | `sub_99150`                               | debounce/latch (gating interno)                 |
Demais leitores (`0x8828C`, `0x88AFC`, `0x8B3C4`, `0x8C63C`, `0x8DBE0`, `0x90890`,
`0x91130`, `0x94968`, `0x94DD0`, `0x94F3C`) são `cal_mod_*` workers (modificadores de pressão/mod).

## FATO — writer de `3FC3A9` NÃO existe por SDA nem r13
Varredura completa `0x8000..0xC0000`: zero `stb/sth/stw` com disp `0xC3A9` (SDA `lis 0x40`) ou
`0x34A9` (r13=`0x3F8F00`); zero store largo cobrindo o byte (`sth/stw` em `3FC3A6..A8`); IDA sem
xref. Único site que monta ponteiro para o bloco `3FC3A0..B0` é `sub_99150` @ `0x991D0`
(`addi r5, -0x3C5A → 0x3FC3A6`), e ele escreve **`3FC3A6`/`3FC3B4`**, não `3FC3A9`.
→ Writer de `3FC3A9` é **escrita indireta/VLE**. DESCONHECIDO; não fechado.

## FATO — confirmação viva (log parado 2026-10-01, `tcm_road_20261001_214504.csv`)
- `*(0x3FAE2C) = 0x307480` ao vivo ⇒ confirma TouCAN_B (doc 41 era HIPÓTESE).
- MMIO `0x307492/96` = **NRC** ao vivo ⇒ ID numérico segue pendente de estática.
- Em idle (`THR=0`): `F_3FBBD4 ≈ F_3FE104 ≈ F0(3FA7F0)` ~750–800 ⇒ espelho vivo confirmado;
  `sub_81238` roda.
- Blips de acelerador em P/N: `THR 0→7` ⇒ `F0 732→1735`, `F_3FBBD4` até ~1883, `3FD52C 0→92`.
  **Correlação positiva inequívoca**: o sinal sobe com o acelerador e propaga a `3FD52C`
  (gates de troca, doc 44).

## CORREÇÃO de FATO — "fsub 1023.0" estava ERRADO
`0xBD4AC` usa `lis 0x4330` + `fsub flt_18A410` = **truque int→float (magic 2^52)**, não bias −1023.
Ao vivo `FE104 ≈ F0` (não `F0−1023`). Portanto `0x3FE104 = float(raw 0x3FA7F0)`, sem offset.
Divergência `F0` vs `FE104/FBBD4` nos blips = **artefato de amostragem** (campos lidos em instantes
distintos no loop ~2.8 s), não divergência real.

## HIPÓTESE (lastro vivo)
`0x420` = sinal do PCM. Dado que em idle (`THR=0`) o sinal **não** é zero (~760 counts, offset de
marcha lenta) e sobe monotonicamente com o pedal, a HIPÓTESE pende para **torque/carga do motor**,
não posição de throttle. Unidade física (Nm / % carga) e byte do frame: DESCONHECIDO (payload MMIO
não respondeu; só valor pós-processado em RAM).

## Impacto na troca
Existe entrada **de rede (CAN)**, viva, que polariza o ponto de troca 2D (`0x9F190`) e o gate
(`0x85358`) — além das tabelas throttle×VSS. Se o sinal `0x420` oscilar/degradar, o ponto de
troca se desloca sem mudança de calibração.

## Resumo executivo
- PROVADO: `CAN 0x420 → 0x3FA7F0 → float (sem offset) → 0x3FE104 → sub_81238 → 0x3FBBD4`, lido por
  6 funções de troca incluindo o avaliador 2D `0x9F190` e o gate `0x85358`.
- PROVADO AO VIVO: o sinal sobe com o acelerador (`THR 0→7` ⇒ raw `732→1735`) e propaga a `3FD52C`
  (gates de troca). É entrada de carga/torque, não throttle puro (offset de idle ~760).
- CORRIGIDO: anotação "fsub 1023" era o magic int→float, não bias −1023.
- PROVADO (negativo): `3FC3A9` não tem writer SDA/r13/largo — escrita indireta/VLE, segue aberto.
- PROVADO: `sub_99150` lateja `3FC3A6`/`3FC3B4` por debounce temporal, gated por `0x3FBBD4`.
- PRÓXIMO PASSO (maior ROI): decodificar o ID numérico do `0x420` via descriptor estático
  (`r13+0x6B7C`, doc 41) — MMIO `0x307492` dá NRC ao vivo.
