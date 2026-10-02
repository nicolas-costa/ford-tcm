# 70 — Sinal de carga do CAN (`0x3FBBD4`) → modificadores de pressão

**Data:** 2026-10-01
**Método:** IDA MCP (decompile + varredura de leitores). Fecha a opção B.
Cross-ref: [67](67-3FBBD4-can-mirror-shift-consumers.md) (origem do sinal),
[69](69-calmod-handlers-per-shift-type.md) (latches de fase), [53](53-epc-command-writer-0B2944.md) (EPC).

## FATO — origem do sinal (recap doc 67)
`0x3FBBD4` = mirror vivo de `0x3FE104`, escrito por `sub_81238 @0x81258`, originado da
msg CAN `0x420` via RAM `0x3FA7F0`. É um sinal de **carga/torque** da rede. `0x3FD52C` é um
segundo sinal CAN-derivado que acompanha.

## FATO — leitores de `0x3FBBD4` no cluster cal_mod (base `lis 0x40`, disp `0xBBD4`)
| EA worker | função | uso do sinal |
|-----------|--------|--------------|
| 0x8B18C | `cal_mod_mode_worker_case6` (4→8) | gate de fill-ramp |
| 0x8C3B8 | `cal_mod_mode_worker_case7` (8→4) | gate de fill-ramp |
| 0x8DB10 | `sub_8DB10` | gate de fill-ramp |
| 0x88234 | `cal_mod_pre_gate_3FC008_3FC00C` | gate do pré-shift |
| 0x88AD8 | `cal_mod_max_064_068_06C_to_3FC070` | cap de pressão |
| 0x90848 | `sub_90848` | **ramo morto no stock** |

(fora do cluster também leem: `gear_trans_gate_3FC388 @0x85358`, `shift_slot_eval @0x873D8/87C1C`,
`shift_table_group_dispatcher @0x9E914`, `shift_point_2d_eval_from_cal @0x9F190`, etc. — doc 67.)

## FATO — como cada um modula pressão

### 1) Fill-ramp (case6 / case7 / sub_8DB10)
```
if ( 3FBD84 < lim                       # acumulador global de fill
  && 3FBBD4 < (3FC1F8 + 9562.5)         # <== CARGA abaixo de limiar dinâmico
  && <slot mod-array> == 0.25           # slot ainda no default
  && 3FC12A/3FC12C == 1 )               # gate de entrada (byte adjacente)
{ 3FBD84 += 3FBC1C; <latch fase> = 1; <slot> += 3FBC1C; }
```
⇒ A **carga do CAN GATEIA o avanço da rampa de enchimento**: se a carga excede
`3FC1F8 + 9562.5`, a rampa é **segurada** (fase não avança). Carga pesada atrasa/segura o fill.

### 2) Pré-shift gate (`cal_mod_pre_gate_3FC008_3FC00C @0x88234`)
```
if ( 3FBBF4 >= 134.0 && (3FC34C||3FC3D2||3FC37C)
  && 3FBBD4 >= 1.4 && 3FC23C >= 1.4 )  # <== CARGA presente exigida
{ ...ramp de 3FC008/3FC00C via 3FBC1C... }
else { 3FC00C = 0.25; 3FC008 = 0.25; } # sem carga -> default
```
⇒ **Sem carga (`3FBBD4 < 1.4`) o gate pré-troca não roda** — pressões `3FC008/3FC00C`
ficam no default `0.25`.

### 3) Cap de pressão (`cal_mod_max_064_068_06C_to_3FC070 @0x88AD8`)
```
if ( 3FBBD4 < 1200.0 && !3FD493 && 3FD464 < 4.59
  && 3FD52C < 6.0 && !3FD741 && !3FC3F4 && !3FD8D0 )
{ 3FC070 = 0.078125; }                 # <== carga leve -> teto reduzido
else { 3FC070 = max(3FC064,3FC068,3FC06C); }
```
⇒ **Carga leve (`3FBBD4 < 1200` + `3FD52C < 6.0` + gates)** força o teto de pressão
`3FC070` a `0.078` em vez do máximo das três fontes. Os DOIS sinais CAN atuam juntos aqui.

### 4) `sub_90848` — uso morto no stock
`if (3FC128 >= 3u && (3FBD70>112.5 || 3FBBD4>-75.0 || !3FC373)) 3FBF94 += 3FBC1C;`
`3FC128` é latch {0,1} (doc 69) ⇒ `>= 3` nunca verdadeiro ⇒ **ramo dormente**. O resto da
função calcula `3FC0A0/0A4/0A8/0AC` por tabelas, sem usar `3FBBD4`.

## HIPÓTESE
- `3FC1F8` é uma base de pressão/torque de referência (limiar dinâmico do fill escala com ela).
  Não confirmado o produtor de `3FC1F8` nesta rodada.

## DESCONHECIDO
- Unidade física de `3FBBD4` (sem live/DBC). Doc 67 observou raw 732→1735 com acelerador 0→7.

## Resumo Executivo BRUTAL
- PROVADO: o sinal de carga do CAN (`0x3FBBD4`) modula pressão em **3 pontos reais**:
  (1) **gateia a rampa de fill** da troca (`< 3FC1F8+9562.5`), (2) **habilita o gate pré-shift**
  (`>= 1.4`, senão default), (3) **reduz o teto de pressão** `3FC070` em carga leve (junto com `3FD52C`).
- PROVADO: `3FBBD4` + `3FD52C` agem **juntos** no cap de pressão `0x88AD8`.
- PROVADO: o uso em `sub_90848` é **dead code** no stock (gate `3FC128>=3`, byte {0,1}).
- PROVADO: estes modificadores são do **cluster cal_mod** (pressões `3FC008/00C/070`, fill-ramp),
  distintos do writer EPC final `0xB2944` (doc 53), que lê `0x3FD9xx`.
- PRÓXIMO ROI: rastrear o produtor de `3FC1F8` (base do limiar de fill) e confirmar se `3FC070`/
  `3FC008` alimentam a cadeia que chega ao EPC.
