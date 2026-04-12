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

| Doc | Tema |
|-----|------|
| [01-reconstruction.md](01-reconstruction.md) | Reconstrução PHF → BIN |
| [02-ida-bootstrap.md](02-ida-bootstrap.md) | IDA, boot, entrypoints |
| [03-scheduler-io.md](03-scheduler-io.md) | Tick/scheduler + IO inicial |
| [04-globals-r13.md](04-globals-r13.md) | Globais `r13` (SDA) |
| [05-solenoid-mapping.md](05-solenoid-mapping.md) | IDs de IO → hardware |
| [06-scheduler-anatomy.md](06-scheduler-anatomy.md) | Scheduler, ISR, TickContext |
| [07-io-tpu-pwm.md](07-io-tpu-pwm.md) | Tick → TPU/PWM, fila `0x15A8`, dispatch `0x15D4` |
| [08-tpu-pwm-producers.md](08-tpu-pwm-producers.md) | Produtores da fila `0x15A8` |
| [09-io-dispatch-init.md](09-io-dispatch-init.md) | Init `r13+0x15D0/0x15D4`, tabelas de ranges |
| [10-open-issues.md](10-open-issues.md) | Gargalos históricos (muitos **[RESOLVIDO]** nos docs seguintes) |
| [11-ram-block-store-clusters.md](11-ram-block-store-clusters.md) | Clusters de stores `r13+0x1500..0x3BFF` |
| [12-task3-resolution-path.md](12-task3-resolution-path.md) | TaskID=3, Engine A → PWM |
| [13-dynamic-analysis-hardware-pendencia.md](13-dynamic-analysis-hardware-pendencia.md) | Pendência física (MCU, BDM/JTAG) |
| [14-duty-command-writers-search.md](14-duty-command-writers-search.md) | Busca por writers de duty/command |
| [15-duty-writers.md](15-duty-writers.md) | Writers encontrados |
| [16-duty-values-origin.md](16-duty-values-origin.md) | Origem dos valores de duty |
| [17-duty-pipeline.md](17-duty-pipeline.md) | Pipeline de duty (completo) |
| [18-table-305CE0-search.md](18-table-305CE0-search.md) | Tabela / busca em `0x305CE0` |
| [18-uds-diag-dispatch-tx-builders.md](18-uds-diag-dispatch-tx-builders.md) | UDS/diag, dispatch, builders TX |
| [19-vle-scan-complete.md](19-vle-scan-complete.md) | Scan PPC vs VLE (conclusão 5U75) |
| [20-phf-byte31-corruption.md](20-phf-byte31-corruption.md) | Corrupção PHF byte 31, carry fix |
| [21-table-2A540-emulation.md](21-table-2A540-emulation.md) | Tabela ROM `0x2A540`, emulação / init RAM |
| [22-mini-interpreter-trace.md](22-mini-interpreter-trace.md) | Mini-interpreter `0x31C84`, trace |
| [23-channel-to-solenoid-map.md](23-channel-to-solenoid-map.md) | Canal → solenóide / TPU |
| [24-shift-schedule-tables.md](24-shift-schedule-tables.md) | Tabelas de shift schedule |
| [25-checksum-analysis.md](25-checksum-analysis.md) | Flash block checksum: estrutura, algoritmos testados, achados parciais |
| [26-patch-proposal-revised.md](26-patch-proposal-revised.md) | Proposta de patch revisada (análise mecânica cinta/torque reverso + evidência BH) |
| [27-firmware-comparison-BH-BL-CA.md](27-firmware-comparison-BH-BL-CA.md) | Comparação BH vs BL vs CA — shift schedule tables, diferenças isoladas |

Dois ficheiros usam o prefixo `18-` (tópicos distintos; escolher pelo tema na tabela).

### Nota sobre “Context Whisper”
O Context Whisper costuma exigir `repo_url`. O projeto `ford-tcm` é um repositório git na raiz; para indexar estas notas num Whisper externo, basta apontar para o remoto público (ex. GitHub) quando existir.