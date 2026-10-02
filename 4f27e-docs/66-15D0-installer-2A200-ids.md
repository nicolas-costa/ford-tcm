# 66 — `15D0` tem installer; blob ROM 11 IDs = universo 7ch, não SSA extra

Escopo: parede IO (doc 65). Sem dump. Sem PHF.

## Correcção ao doc 09 (FATO)

Doc 09: um único `stw …, 0x15D0(r13)` (clear `0x3A7F8`). **Falso agora.**

```
3C01C  stwu  (sub_3C01C / io_15D0_install_root_and_init_channels)
3C038  addi  r28, r3, 0
3C03C  stw   r28, 0x15D0(r13)     ; 0x938D15D0
3C048  lbz   r3, 0(r28)           ; count
3C054  lwz   r29, 4(r28)          ; entries*
; conta ids >= 0x64 → aloca 15D4
; loop idx=0..count-1:
;   id = entries[idx*16 + 0]
;   id < 0x64  → io_channel_init_from_15D0_table + tpu_pwm_callback_register(0x23F3C)
;   0x64 ≤ id < 0x97 → pwm_duty_writer_staging_builder (MIOS 0x305CE0)
;   id ≥ 0x97 → bl 0x23C98 (3C120 0x4BFE7B79)
```

`add_func 0x3C01C`–`0x3C16C`. Teardown: `0x3A674`–`0x3A810`, `stw 0` @ `0x3A7F8` após percorrer os mesmos ids (TPU `sub_34444` / MIOS `0x305CE0`).

**Callers:** XREF / `bl` / dword `0x0003C01C` / `addi` SIMM `C01C` com `lis 4`: **zero**. `r3` chega por `blrl`/tabela tagged.

## Blob ROM de 11 descritores (FATO)

Em `0x2A1F8`:

```
2A1F8  0B 00 00 00  00 02 A2 04     ; count=11, ptr=0x2A204
2A200  64 0A 01 00  00 00 FF FF …  ; id 0x64
```

Se o installer usa `*(root+4)==0x2A204`, o primeiro `lbzx` cai 4 bytes dentro do recorde `0x64` (byte `0x00`). O layout **útil** alinhado a 16 B começa em **`0x2A200`**:

| idx  | EA            | `entry[0]` (id)    | classe no installer     |
| ---- | ------------- | ------------------ | ----------------------- |
| 0–2  | `2A200/10/20` | `0x64, 0x65, 0x66` | MIOS (`≥0x64`, `<0x97`) |
| 3–10 | `2A230…2A2A0` | `0x00 … 0x07`      | TPU (`<0x64`)           |

`entry[1]=0x0A` em todos; `entry[2]=1` nos MIOS, `0x0A` nos TPU; `lhz +4` no recorde alinhado a `2A200` é `0` (os `FFFF` estão em +6/+7).

Isto casa com o laço 7ch (`io_id` 0–7 + 3 canais MIOS), **não** com um segundo banco SSA/SSB.

Nenhum `lis`/`addi`/`ori`/`u32` no range `0x10000`–`0xC0000` carrega `0x2A1F8` / `0x2A200`. O blob está no BIN; o **call** que o passa a `3C01C` não é PPC D-form.

## `io_set_float` (FATO, fechado)

`0x3BFCC`: `entries = *(15D0)+4`, `class = entries[r3*16]`, ramo `233C4` / `23748` / `23A5C`. Sem tagged `0x??03BFCC` no BIN. Callers `bl` = só 7ch + `25244` (doc 65).

## HIPÓTESE

`0x2A1F8` é o root que `3C01C` recebe em runtime (count 11). O ptr `2A204` vs dados em `2A200` é **off-by-4** se interpretado à letra — ou o primeiro byte útil é padding. Sem o `r3` do caller, não fechar.

Shift solenoids **não** aparecem como ids extra neste blob.

## DESCONHECIDO

- Quem põe `r3` em `3C01C` (2A540 op `0x27` / mini-interpreter / VLE).
- Se existe **outro** root 15D0 (segunda tabela) nunca instalado neste scan.

## Resumo executivo

- **Provado:** installer `3C03C`; teardown `3A7F8`; 11 ids ROM `0x64–66` + `0–7`.
- **Não** é o caminho novo das shift solenoids.
- **Provado:** `15D0` não nasce só NULL — há publish em PPC; o doc 09 estava incompleto.

**Próximo passo (ROI):** consumidor da tabela `0x2A540` entry `003FA400..003FCB00 op=0x27` — se copia/reloca `2A1F8` e chama `3C01C`; senão scan VLE/`31C84` por `2A1F8`.
