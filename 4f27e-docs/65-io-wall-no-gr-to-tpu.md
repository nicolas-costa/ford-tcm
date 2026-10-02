# 65 — Parede IO: TPU/`15A8` não lê GR por SIMM nem `r13`

Escopo: ligar `3FC106`/`3FBBCC` a `15D0`/`15A8`/`0x304xxx`. Sem dump. Sem PHF.

## Resultado (FATO)

Não há ponte estático **GR/GT/`3FBBCC` → TPU** neste firmware pelos encodings varridos.

## 1) MMIO `0x30xxxx` no domínio de troca (FATO)

Scan `lis imm∈{0x3040,0x3041,0x3044,0x305F,0x3060}` em `0x80000`–`0xC0000`: **zero**.  
Scan `lis r, 0x30` no mesmo range: **zero**.

`lis r, 0x30` existe em `0x20000`–`0x50000` (TPU/MIOS/QADC). Ex.: `task3_secondary_entry @ 0x41600`:

```
41600  lis r4, 0x30
41604  lhz r11, 0x70A0(r4)     ; 0x3070A0
4161C  lhz r0,  0x7080(r3)
41624  sth r0,  0x7080(r3)     ; bit insrwi
41634  sth … 0x7480            ; 0x307480
```

Isto arma um bit de módulo, **não** um padrão SSA/SSB por marcha.

## 2) SDA `r13+off` ≠ `3FCxxx` de marcha (FATO)

`r13 = 0x3F8F00` (doc 04). Então `3FC106 = r13+0x3206`, `3FBBCC = r13+0x2CCC`, `3FC239 = r13+0x3339`.

Scan `disp(r13)` nesses offsets em `0x10000`–`0xC0000`: **zero** `lbz`/`stb`/`lhz`.  
O pipeline de marcha usa só `lis 0x40` + SIMM (docs 61–63).

## 3) Writers TPU/`15D0` fechados (FATO)

`bl` LK=1 para:

| dest                                        | callers                                              |
| ------------------------------------------- | ---------------------------------------------------- |
| `io_set_float @ 0x3BFCC`                    | `25284/94` (`sub_25244`), `421DC`, `425F8/614` (7ch) |
| `io_write @ 0x3C16C`                        | só `252BC/D4` (`sub_25244`)                          |
| `tpu_channel_write_pram2 @ 0x3C4D0`         | `bl 42220` (init 7ch); `b 42138` (state machine 7ch) |
| `tpu_pwm_queue_build @ 0x395B4`             | **nenhum `bl`**                                      |
| `pwm_duty_writer_staging_builder @ 0x23820` | `3C0F8` (dentro de `io_set_float`)                   |

`stw 0x15A8(r13)`: só `39598` (zera) e `3968C` (publica). Sem dword ROM `0x000395B4`.

`sub_25244`: escala período (`cmpwi 0x2710`) e chama `io_set`/`io_write`. Caller: `solenoid_apply_period_targets_from_18B8 @ 0x41190` ← `sub_4B390 @ 0x4B3B0` (tabela `18A224`, **não** GR).

## 4) 7ch não é o path de shift (já doc 52; reconfirmado)

`solenoid_outputs_update_7ch @ 0x42584`: `lbzx` IDs em `252F5`, `sth 0xE(r31)` duty, `bl io_set_float`. `r31 = r13+0x17C4 + idx×0x14`.

`prepare_cycle @ 0x42674`: 7× `qadc_read` → média no struct. Sem `lbz 3FC106`.

`task3_slot_alloc @ 0x31594`: aloca IDs via `2A744` / `3FA400`; `blrl 0x30EC4` / `0x3099C`. **Não** chama `0x395B4` (o diagrama do doc 21 está errado neste elo).

## 5) `shift_state_machine_transition @ 0xB1130` (FATO)

`0xB1130`–`0xB1B08`. SIMM `C106`/`C239`/`BBCC`: ausentes. Stores: cluster `3FD8xx` (`-0x27E9`=`3FD817`, etc.). `blrl 0xB98C8` com `r3=3FCCC4`. XREF IDA vazio (indireto). Não é o writer TPU.

## HIPÓTESE

Shift ON/OFF/PWM ou (a) usa **`blrl`** para `0x3BFCC` com o endereço em RAM/tabela tagged (doc 10), ou (b) outro bloco MMIO sem `lis 0x30` no range de troca, ou (c) o comando está no 7ch e o log de rua do doc 52 mede o campo errado. (a) e (b) não têm evidência positiva aqui. (c) contradiz D1–D5=0 em todas as marchas.

## DESCONHECIDO

- Conteúdo runtime de `*(r13+0x15D0)` (lista de io_id).
- Quem preenche `queue` passado a `0x395B4` (task table tagged).
- Encoding GPIO se existir sem `lis 0x2FC0` (scan `2FC0/2FD0/7E00`: zero em `0x10000`–`0xC0000`).

## Resumo executivo

- GR não é lido por `r13` nem escrito para `0x304xxx` no ROM de scheduling.
- O único writer TPU PRAM nomeado é o laço 7ch — o mesmo que o doc 52 tirou das shift solenoids.
- `0x395B4` continua sem `bl` e sem ponteiro `u32` cru.

**Próximo passo (ROI):** dump/`py_eval` da tabela em `*(0x3F8F00+0x15D0)` (init ROM) — lista de IDs — e scan de **bytes** `3B FCC` packed em interpretadores (`0x31C84`), não mais SIMM `C106`.
