## 4f27e-docs (mapeamentos e achados)

Este diretório contém um **snapshot humano** do que foi confirmado até agora na análise do Ford TCM (`5U75-14C337-AA`).

### O que foi “carimbado” (fato)

- **IDB/arquivo analisado**: `samples/SILVEROAK/5U75-14C337-AA.rebuilt.aligned.bin`
- **Tamanho**: `0x200000` (2 MiB)
- **Base**: `0x0`
- **SHA256**: `1f76041d435540cdb96b9f819b775d06e4aaf89ce615ed8ac0089d757116cd53`
- **Segmento**: `ROM 0x000000..0x200000` com permissão `r-x`
- **Arquitetura no IDA**: PowerPC big-endian 32-bit; para o `5U75` corrigido, o trabalho recente assume **PPC como linha principal** (ver [19-vle-scan-complete.md](19-vle-scan-complete.md))

### Contexto de arquitetura do veículo (update do operador — 2026-01-08)

**FATO (fornecido pelo operador):**

- O **TCM não é integrado ao ECU/PCM**: são **módulos individuais**.
- O TCM **ainda não foi removido fisicamente** (“ainda não tive tempo para arrancar o TCM”).
- Será necessário **remover o TCM** e **reinstalar a ECU/PCM** no veículo para voltar a operar enquanto o módulo estiver em bancada.

**FATO (fornecido pelo operador; contexto 2026-01-08):**

- Os identificadores **`ESU-411` / “Visteon”** foram coletados via diagnóstico e estavam sendo usados como referência de módulo. Esse ponto ficou **pendente** até inspeção física do TCU/TCM.

### Update de bancada (update do operador — 2026-01-09)

**FATO (fornecido pelo operador):**

- O módulo em bancada e aberto é **somente TCU/TCM** (controle de câmbio).
- A **ECU/PCM** do veículo é **Visteon ESU-411** (módulo separado do TCU/TCM).

**FATO (fornecido pelo operador; identificação externa do TCU/TCM em foto):**

- **Fornecedor**: Continental (Siemens VDO Continental)
- **Hardware P/N**: `5WP22350BI-K`
- **Ford P/N (módulo)**: `5M5P-12B565-BL`
- **SW/Strategy (módulo)**: `5M5P-14C337-BL`
- **Aplicação**: `1.8/2.0`
- **S/N**: `93510173`

**FATO (fornecido pelo operador; identificação de ICs em foto):**

- **Processador/SoC (marking)**: `A2C00023028` (`UQMZFM0926`)
- **Memória (marking)**: Spansion `925MB467`
- **Memória (marking adicional, fornecido pelo operador)**: `s29cd016jomqfm11`

**FATO (fornecido pelo operador; evidência visual no encapsulamento):**

- O MCU possui **logo Freescale** impressa.

**HIPÓTESE (fornecida pelo operador; origem: Gemini; pendente de confirmação objetiva):**

- O core do MCU seria **PowerPC e200z4** ou **e200z6** (PowerPC 32-bit).
- O MCU seria da linha **NXP/Freescale Qorivva**.

**DESCONHECIDO (até evidência objetiva):**

- Modelo exato do MCU (família/PN do fabricante), IDCODE, e se a hipótese e200z4/e200z6 procede.

**NOTA (escopo deste diretório):**

- Este `4f27e-docs/` é um snapshot focado na análise do firmware **`5U75-14C337-AA`**.
- A identificação física acima refere-se ao módulo **`5M5P-12B565-BL` / `5M5P-14C337-BL`** (família 5M5P), útil para evitar confusão de módulos (TCU vs ECU/PCM) e guiar a etapa de bancada.

### Índice (todos os `.md` desta pasta)

| Doc                                                                                                | Tema                                                                                                                                                                                                                |
| -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [01-reconstruction.md](01-reconstruction.md)                                                       | Reconstrução PHF → BIN                                                                                                                                                                                              |
| [02-ida-bootstrap.md](02-ida-bootstrap.md)                                                         | IDA, boot, entrypoints                                                                                                                                                                                              |
| [03-scheduler-io.md](03-scheduler-io.md)                                                           | Tick/scheduler + IO inicial                                                                                                                                                                                         |
| [04-globals-r13.md](04-globals-r13.md)                                                             | Globais `r13` (SDA)                                                                                                                                                                                                 |
| [05-solenoid-mapping.md](05-solenoid-mapping.md)                                                   | IDs de IO → hardware                                                                                                                                                                                                |
| [06-scheduler-anatomy.md](06-scheduler-anatomy.md)                                                 | Scheduler, ISR, TickContext                                                                                                                                                                                         |
| [07-io-tpu-pwm.md](07-io-tpu-pwm.md)                                                               | Tick → TPU/PWM, fila `0x15A8`, dispatch `0x15D4`                                                                                                                                                                    |
| [08-tpu-pwm-producers.md](08-tpu-pwm-producers.md)                                                 | Produtores da fila `0x15A8`                                                                                                                                                                                         |
| [09-io-dispatch-init.md](09-io-dispatch-init.md)                                                   | Init `r13+0x15D0/0x15D4`, tabelas de ranges                                                                                                                                                                         |
| [10-open-issues.md](10-open-issues.md)                                                             | Gargalos históricos (muitos **[RESOLVIDO]** nos docs seguintes)                                                                                                                                                     |
| [11-ram-block-store-clusters.md](11-ram-block-store-clusters.md)                                   | Clusters de stores `r13+0x1500..0x3BFF`                                                                                                                                                                             |
| [12-task3-resolution-path.md](12-task3-resolution-path.md)                                         | TaskID=3, Engine A → PWM                                                                                                                                                                                            |
| [13-dynamic-analysis-hardware-pendencia.md](13-dynamic-analysis-hardware-pendencia.md)             | Pendência física (MCU, BDM/JTAG)                                                                                                                                                                                    |
| [14-duty-command-writers-search.md](14-duty-command-writers-search.md)                             | Busca por writers de duty/command                                                                                                                                                                                   |
| [15-duty-writers.md](15-duty-writers.md)                                                           | Writers encontrados                                                                                                                                                                                                 |
| [16-duty-values-origin.md](16-duty-values-origin.md)                                               | Origem dos valores de duty                                                                                                                                                                                          |
| [17-duty-pipeline.md](17-duty-pipeline.md)                                                         | Pipeline de duty (completo)                                                                                                                                                                                         |
| [18-table-305CE0-search.md](18-table-305CE0-search.md)                                             | Tabela / busca em `0x305CE0`                                                                                                                                                                                        |
| [18-uds-diag-dispatch-tx-builders.md](18-uds-diag-dispatch-tx-builders.md)                         | UDS/diag, dispatch, builders TX                                                                                                                                                                                     |
| [19-vle-scan-complete.md](19-vle-scan-complete.md)                                                 | Scan PPC vs VLE (conclusão 5U75)                                                                                                                                                                                    |
| [20-phf-byte31-corruption.md](20-phf-byte31-corruption.md)                                         | Corrupção PHF byte 31, carry fix                                                                                                                                                                                    |
| [21-table-2A540-emulation.md](21-table-2A540-emulation.md)                                         | Tabela ROM `0x2A540`, emulação / init RAM                                                                                                                                                                           |
| [22-mini-interpreter-trace.md](22-mini-interpreter-trace.md)                                       | Mini-interpreter `0x31C84`, trace                                                                                                                                                                                   |
| [23-channel-to-solenoid-map.md](23-channel-to-solenoid-map.md)                                     | Canal → solenóide / TPU                                                                                                                                                                                             |
| [24-shift-schedule-tables.md](24-shift-schedule-tables.md)                                         | Tabelas T4–T13 + slots. **2026-10:** causa `0x182ED0` revogada; S25 coast = T5+Y (`185708`, doc 50); v6.2 no doc 26                                                                                                 |
| [25-checksum-analysis.md](25-checksum-analysis.md)                                                 | Flash block checksum: estrutura, algoritmos testados, achados parciais                                                                                                                                              |
| [26-patch-proposal-revised.md](26-patch-proposal-revised.md)                                       | Proposta de patch revisada (análise mecânica cinta/torque reverso + evidência BH)                                                                                                                                   |
| [27-firmware-comparison-BH-BL-CA.md](27-firmware-comparison-BH-BL-CA.md)                           | Comparação BH vs BL vs CA — shift schedule tables, diferenças isoladas                                                                                                                                              |
| [31-pressure-tables-located.md](31-pressure-tables-located.md)                                     | Tabelas `0x181xxx` ≠ EPC; rastro invertido duty→QADC/RJURR                                                                                                                                                          |
| [32-cal-mod-mode-switch-9C300.md](32-cal-mod-mode-switch-9C300.md)                                 | Switch modo cal_mod `0x9C300` (51 cases, cadeias `blrl`)                                                                                                                                                            |
| [33-cal-mod-mode0-reset-lookups.md](33-cal-mod-mode0-reset-lookups.md)                             | Mode 0: reset estado + 1D ROM → `0x3FC0B0+`                                                                                                                                                                         |
| [34-cal-mod-parallel-banks-3FC0B0.md](34-cal-mod-parallel-banks-3FC0B0.md)                         | `3FC0B0` ↛ `3FC070`; bancos paralelos; diff mode0/1                                                                                                                                                                 |
| [35-mode-resets-and-3FC070-threshold.md](35-mode-resets-and-3FC070-threshold.md)                   | Schedules mode 0–5/8; `3FC070`→`3FC088`/`3FBF6C`; sequenciadores                                                                                                                                                    |
| [36-slots-axis-3FC1BC-not-3FBF6C.md](36-slots-axis-3FC1BC-not-3FBF6C.md)                           | Slots usam `3FC1BC`, não `3FBF6C`; `9D774` sem refs                                                                                                                                                                 |
| [37-slot-axis-3FC1BC-writer-chain.md](37-slot-axis-3FC1BC-writer-chain.md)                         | Writer `0x81B4C`; `3FDF68`←`0xBD400`; cauda dispatcher                                                                                                                                                              |
| [38-BBC3C-exponent-to-3FDF68.md](38-BBC3C-exponent-to-3FDF68.md)                                   | `BBC3C` re-exp; `3FDF68`; raw `3FA7F0`/1023                                                                                                                                                                         |
| [39-3FA7E0-writers-r13-hw-channels.md](39-3FA7E0-writers-r13-hw-channels.md)                       | Writers `r13+0x18Ex`; canais HW `0x420`→`3FA7F0/F2`                                                                                                                                                                 |
| [40-channel-0x420-toucan-mailbox.md](40-channel-0x420-toucan-mailbox.md)                           | `0x420`=TouCAN MB1; payload CAN→`3FA7F0`                                                                                                                                                                            |
| [41-toucan-B-MB1-module.md](41-toucan-B-MB1-module.md)                                             | `0x420`→TouCAN_B; data `0x307496`; ID pendente                                                                                                                                                                      |
| [42-can-0x420-payload-and-logger.md](42-can-0x420-payload-and-logger.md)                           | Payload 8B; `tcm_road_logger --can`                                                                                                                                                                                 |
| [43-BD400-float-fanout-from-0x420.md](43-BD400-float-fanout-from-0x420.md)                         | Fan-out floats `3FDF60/64/68`, `3FD52C/540`; corrige fsub1023                                                                                                                                                       |
| [44-3FD52C-readers-shift-gates.md](44-3FD52C-readers-shift-gates.md)                               | `3FD52C`→flag`3FD48C`→slot`3FBC24`; 2D c/ `3FE104`                                                                                                                                                                  |
| [45-desc-188768-and-3FD540-readers.md](45-desc-188768-and-3FD540-readers.md)                       | Formato 1D; `3FD540`/`3FDF64`→`3FD4E8`; paradoxo count/ptr                                                                                                                                                          |
| [46-cal-1d-consumers-inventory.md](46-cal-1d-consumers-inventory.md)                               | Item 2: 406 sites / 124 funcs; famílias; handoff TCC `0x1845E8`                                                                                                                                                     |
| [47-TCC-inverted-slot-0x35.md](47-TCC-inverted-slot-0x35.md)                                       | Item 3: TCC/SSE idx5 duty→QADC `0x10`; ≠ mapa `0x1845E8`                                                                                                                                                            |
| [48-caller-9AE3C-static-wall.md](48-caller-9AE3C-static-wall.md)                                   | Item 5: 0 caller externo no bin; só case9; cluster órfão                                                                                                                                                            |
| [49-diff-BH-BL-CA-181xxx-threshold-mod.md](49-diff-BH-BL-CA-181xxx-threshold-mod.md)               | Item 4: BL≡CA≡AA; cal_mod→3FC070 idêntico BH; delta H_THRESH→3FC0B0/B4                                                                                                                                              |
| [50-shift-point-modifiers-185708.md](50-shift-point-modifiers-185708.md)                           | Modifiers 1D `185708`/`185750`; GATE→S25/S27; patch v6 Y→0                                                                                                                                                          |
| [51-v6.3-proposal-t7-e-prime-t4.md](51-v6.3-proposal-t7-e-prime-t4.md)                             | **Proposta v6.3** T7 E′ + T4 throttle — aguardando OK                                                                                                                                                               |
| [52-idx0-is-pressure-solenoid-road-2026-09-07.md](52-idx0-is-pressure-solenoid-road-2026-09-07.md) | **Rua:** idx0 = solenóide de pressão (não SSA); shift solenoids fora da struct `0x3FA6C4`; tranco = pressão baixa                                                                                                   |
| [53-epc-command-writer-0B2944.md](53-epc-command-writer-0B2944.md)                                 | **Writer do setpoint EPC:** `sth @0x0B2CAC` em `func 0x0B2944` (absoluto, store único); `C8 = cmd*10`; amostra SILVEROAK está em branco                                                                             |
| [54-weight-axes-3FCDA8-3FBD6C.md](54-weight-axes-3FCDA8-3FBD6C.md)                                 | Eixos de peso `3FCDA8`/`3FBD6C`; aditivo AA (~−1 / −7 WOT); dump vivo diferido                                                                                                                                      |
| [55-dispatcher-1d-inventory.md](55-dispatcher-1d-inventory.md)                                     | 42 lookups `0x9D860`; S28=`FF` se `3FC34C==0`; `184F28` piso 76; Group3 `1826F8`                                                                                                                                    |
| [56-3FC34C-onehot-writer.md](56-3FC34C-onehot-writer.md)                                           | Writer `3FC34C`: `sub_8251C` one-hot `r31==0x10`; call `0x9E888`                                                                                                                                                    |
| [57-r31-0x10-3FC34C-chain.md](57-r31-0x10-3FC34C-chain.md)                                         | `r31==0x10`: `3FBBB0`/`3FD79D`/`3FDA6A` morto/`3FBF54==0.25`; packer `0xB38C4` morto                                                                                                                                |
| [58-twin-829E8-3FC190-3FBE84-dead.md](58-twin-829E8-3FC190-3FBE84-dead.md)                         | Gémeo `0x829E8`→`3FC190`/`3FC34E`; `3FC18C` sem `lfs`; `3FBE84=1` morto (`18A8C0=0`)                                                                                                                                |
| [59-fmadds-3FC1A4-sub-91E3C.md](59-fmadds-3FC1A4-sub-91E3C.md)                                     | OR `{3FC34E,8,4}` slewa `3FC1A4`→`3FC3D0`; `3FC210` sem `lfs` externo — gémeo sem impacto 1D                                                                                                                        |
| [60-gear-eval-inhibit-flags-3FC3A8.md](60-gear-eval-inhibit-flags-3FC3A8.md)                       | `3FC3A8` enable 3→4 (S28 não basta); `3FC404`/`3FD728` ← `3FD8D0`; writer `sub_82F34`                                                                                                                               |
| [61-gt-to-gr-pipeline-83AE0-83E04-84774.md](61-gt-to-gr-pipeline-83AE0-83E04-84774.md)             | GT `3FC239`→`3FC238`→`3FC104`→GR `3FC106`; writers `0x83AE0`/`0x83E04`/`0x84774`                                                                                                                                    |
| [62-trans-flags-3FC3Bx-not-solenoid.md](62-trans-flags-3FC3Bx-not-solenoid.md)                     | `3FC3Bx` = flags 105→106; `84FCC` razões `185F80`; sem TPU/`15D0`                                                                                                                                                   |
| [63-ratios-scale-3FBBCC-shift-type.md](63-ratios-scale-3FBBCC-shift-type.md)                       | `3FC1F0=3FC1F8*r_to/r_from`; único `sth 3FBBCC` = `0x86BB0`; encoder 1..0xC                                                                                                                                         |
| [64-fcmpu-is-schedule-not-clutch-sync.md](64-fcmpu-is-schedule-not-clutch-sync.md)                 | `fcmpu` = GT/slots; `3FC1F8` congela se `3FBBCC≠0`; zero SIMM GR→`15D0`                                                                                                                                             |
| [65-io-wall-no-gr-to-tpu.md](65-io-wall-no-gr-to-tpu.md)                                           | Parede: zero `lis 0x30` no ROM de troca; TPU PRAM só 7ch; `0x395B4` sem `bl`                                                                                                                                        |
| [66-15D0-installer-2A200-ids.md](66-15D0-installer-2A200-ids.md)                                   | `3C03C` instala `15D0`; blob 11 ids `0x64–66`+`0–7` @ `2A200`; não é SSA extra                                                                                                                                      |
| [67-3FBBD4-can-mirror-shift-consumers.md](67-3FBBD4-can-mirror-shift-consumers.md)                 | `CAN 0x420→3FA7F0→3FE104→3FBBD4` lido por 6 funcs de troca (2D `9F190`, gate `85358`); confirmado vivo = carga/torque; `fsub 1023` era magic int→float                                                              |
| [68-calmod-jumptable-9C300-3FBBCC.md](68-calmod-jumptable-9C300-3FBBCC.md)                         | Jumptable `0x9C300` por `3FBBCC` (ncases=50); off-by-one `bgt 0x32` → `idx 0x32` lê fora da tabela (`0x3D800040`); CONFIRMADO IDA mas **dormente** (reader `0x9AE3C` órfão, doc 48); não explica stall sem BP vivo  |
| [69-calmod-handlers-per-shift-type.md](69-calmod-handlers-per-shift-type.md)                       | 15 handlers ativos; cada tipo de troca → cascade de workers → perfil de 18 floats `3FC264..3FC2A8`; **idx7 (8→4) usa carga do CAN `3FD52C`**; `2→1`/coast = no-op aqui; bytes `3FC128..12C` = latches de fase {0,1} |
| [70-can-load-3FBBD4-pressure-modifiers.md](70-can-load-3FBBD4-pressure-modifiers.md)               | Sinal de carga CAN `3FBBD4` modula pressão em 3 pontos: gate de fill-ramp (`<3FC1F8+9562.5`), gate pré-shift `3FC008/00C` (`>=1.4`), cap `3FC070` (carga leve, com `3FD52C`); `sub_90848` = dead code               |
| [71-coast-0x26-slot-eval-872B4.md](71-coast-0x26-slot-eval-872B4.md)                               | Tipo `0x26` (flag `3FC3AA`): no-op no cal_mod; em `0x872B4` grava `3FBC14 = 1D(0x181908)×2D(0x187514, peso, carga CAN)` vs normal `1D(0x184218)×3FC148`; também delay-gate `0x86470` e `sub_949D4`                  |
| [72-lookup-descriptor-off-by-4.md](72-lookup-descriptor-off-by-4.md)                               | Call do 1D cai em `0xBBDC8` (`lbz` count no ptr = 0); count real e pares estão em `addr−4`. Header 6×4 do coast está em `0x187510`, o call passa `0x187514`. `0x182ED0=22.0` não é o grid                           |
| [73-1d-lookup-f5-and-no-addi.md](73-1d-lookup-f5-and-no-addi.md)                                   | Não há `addi r3,-4`. Call `0x9DC08` (`r3=0x185708`) faz `lwz *(r3+4)=0xC2C80000` e compara `f5` do lookup anterior; a curva Y=10 está inline em `0x18570C`                                                          |

Dois ficheiros usam o prefixo `18-` (tópicos distintos; escolher pelo tema na tabela).

### Nota sobre “Context Whisper”

O Context Whisper costuma exigir `repo_url`. O projeto `ford-tcm` é um repositório git na raiz; para indexar estas notas num Whisper externo, basta apontar para o remoto público (ex. GitHub) quando existir.
