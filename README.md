# ford-tcm

Engenharia reversa do firmware do **TCM Ford 4F27E** (estratégia `5U75-14C337-AA`).

O objetivo é reconstruir, com evidência objetiva, a lógica de boot, a inicialização de blocos em RAM e a arquitetura de despacho indireto (scheduler, IO, TPU/PWM). Análise estática é o caminho principal; dinâmica só entra quando a estática não fecha.

**Não flashar nada disto em veículo.** Pesquisa e análise. Sem lastro de bancada e sem checksum/assinatura resolvidos, um BIN “quase certo” é um módulo morto.

## Alvo


| Campo              | Valor                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| Módulo             | TCM 4F27E (separado do ECU/PCM; ver [4f27e-docs/README.md](4f27e-docs/README.md))                     |
| Estratégia         | `5U75-14C337-AA`                                                                                      |
| Artefato analisado | `samples/SILVEROAK/5U75-14C337-AA.rebuilt.aligned.bin` ([4f27e-docs/README.md](4f27e-docs/README.md)) |
| Tamanho            | `0x200000` (2 MiB)                                                                                    |
| SHA256             | `1f76041d435540cdb96b9f819b775d06e4aaf89ce615ed8ac0089d757116cd53`                                    |
| ISA no IDA         | PowerPC 32-bit big-endian, base `0x0`, segmento `ROM 0x000000..0x200000` (`r-x`)                      |
| Decode             | PPC puro neste BIN (VLE descartado; [19-vle-scan-complete.md](4f27e-docs/19-vle-scan-complete.md))    |


O BIN **não** é dump linear do PHF: concatenar records injeta marcadores no meio do código ([01-reconstruction.md](4f27e-docs/01-reconstruction.md)). O pipeline parseia records, escreve payload nos offsets absolutos e aplica shift global **+3** ([20-phf-byte31-corruption.md](4f27e-docs/20-phf-byte31-corruption.md)).

Comparações com revisões `5M5P-14C337-*` (BH/BL/CA) estão em [27-firmware-comparison-BH-BL-CA.md](4f27e-docs/27-firmware-comparison-BH-BL-CA.md). Não misturar P/N de estratégia (`5U75` vs `5M5P`) nem firmware de análise com hardware de bancada sem cruzar [4f27e-docs/README.md](4f27e-docs/README.md) e [13-dynamic-analysis-hardware-pendencia.md](4f27e-docs/13-dynamic-analysis-hardware-pendencia.md).

## SILVEROAK

No código e na documentação versionada, **SILVEROAK** aparece em **duas camadas** — não são a estratégia nem o part number do módulo:


| Camada                  | Onde                                                                                                                                          | O que é                                                                                                                                          |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Plataforma PHF**      | `phf_parser/utils.py` (`detect_platform`)                                                                                                     | String `SILVEROAK` detectada no header do ficheiro, no mesmo conjunto que `SPANISHOAK`, `BOAK`, `GOAK`. Seleciona o extrator em `phf_to_bin.py`. |
| **Campo de header**     | `phf_parser/models.py` (`PHFHeader.file_type`)                                                                                                | Valor ASCII do PHF (ex. comentário no modelo: `SILVEROAK-Siemens`). Campo distinto de `platform` e do P/N `14C337`.                              |
| **Container / records** | [01](4f27e-docs/01-reconstruction.md), [20](4f27e-docs/20-phf-byte31-corruption.md), [30](4f27e-docs/30-checksum-state-and-open-questions.md) | PHF “SILVEROAK”: records de 38 bytes, carry byte no byte 31, imagem reconstruída de 2 MiB para o alvo `5U75`.                                    |


`phf_to_bin.py` assume imagem **2 MiB** para `platform == "SILVEROAK"` (`2097152` bytes); outras plataformas Oak no mesmo parser usam tamanhos diferentes (`SPANISHOAK` 1 MiB, `BOAK`/`GOAK` 1,5 MiB).

**DESCONHECIDO neste repo:** MCU exato, mapa flash físico e significado de “Silver Oak” fora do PHF/parser — não inferir hardware só pelo rótulo.

## Método (anti-fanfic)

- **FATO** — endereço, bytes, instrução ou dump.
- **HIPÓTESE** — inferência com lastro observável, marcada como tal.
- **DESCONHECIDO** — sem evidência.

Regras: assembly e bytes mandam; XREF sozinho não fecha com `mtlr`/`blrl` ou `mtctr`/`bctr`; nome de função/struct só com assinatura comprovada.

Formato de achado: EA + snippet + interpretação + impacto + 3 bullets provados + um próximo passo de maior ROI.

## O que já está carimbado (entrada)

Âncoras dos docs 01–06; citação completa em cada ficheiro.

- **Boot:** `reset_handler @ 0x864C` → `r13 = 0x003F8F00` (`0x8654`/`0x8658`).
- **Tick:** `isr_decrementer_tick_dispatch @ 0x396D0`; tarefas via `task_entry+0x4` e `mtlr`/`blrl` (sem `bl` direto nos handlers).
- **IO por ID:** `r13+0x15D0` / `r13+0x15D4`; trampolines `0x3C16C`, `0x23F38`.
- **MMIO por faixa de ID:** `0x304000`, `0x304400`, `0x306Cxx` — ligação TPU/MIOS ainda **hipótese** ([05-solenoid-mapping.md](4f27e-docs/05-solenoid-mapping.md)).

Índice: [4f27e-docs/README.md](4f27e-docs/README.md). Ordem sugerida: [01](4f27e-docs/01-reconstruction.md) → [02](4f27e-docs/02-ida-bootstrap.md) → [03](4f27e-docs/03-scheduler-io.md) → [04](4f27e-docs/04-globals-r13.md) → [05](4f27e-docs/05-solenoid-mapping.md) → [06](4f27e-docs/06-scheduler-anatomy.md).

No IDA: segmento `ROM` com `r-x` ([02-ida-bootstrap.md](4f27e-docs/02-ida-bootstrap.md)).

## Layout versionado

```
4f27e-docs/     achados e índice da análise
phf_parser/     parser PHF lossless + PHF→BIN (SILVEROAK e outras Oak)
decompiled/     C/asm auxiliar (assembly manda)
```

Ferramenta de trabalho: IDA Pro + MCP Python. Renomear no IDB só com assinatura comprovada.

## PHF (`phf_parser/`)

Parser lossless: roundtrip PHF→modelo→PHF preserva bytes; PHF→BIN alinhado é pré-requisito da análise em IDA.

```python
from phf_parser import read_phf, phf_to_bin, write_phf

phf = read_phf("caminho/para/arquivo.phf")
print(phf.platform)          # detect_platform: SILVEROAK | SPANISHOAK | BOAK | GOAK
print(phf.header.file_type)  # campo ASCII FILE TYPE do header, se presente

phf_to_bin(phf, "saida.bin", apply_alignment_fix=True)
```

Record SILVEROAK, carry byte e correção do parser: [20-phf-byte31-corruption.md](4f27e-docs/20-phf-byte31-corruption.md).

## Patches de calibração (comportamento das trocas)

Além da RE de boot/scheduler/IO, o repo documenta **patches de calibração** nas shift schedule tables ROM — sintomas de dirigibilidade mapeados com disassembly + logging de slots RAM ([24-shift-schedule-tables.md](4f27e-docs/24-shift-schedule-tables.md), [26-patch-proposal-revised.md](4f27e-docs/26-patch-proposal-revised.md)).

**Contexto de fábrica:** comparação BH vs BL/CA/AA ([27-firmware-comparison-BH-BL-CA.md](4f27e-docs/27-firmware-comparison-BH-BL-CA.md)) — BL subiu o threshold 2→1 (Table 5) de **7 → 12 km/h** vs BH; gap **17→23** na Table 4 (1→2) existe em **todas** as revisões analisadas.

**Sintomas atacados (causa raiz → patch):**

| Sintoma | Alavanca | Doc |
|--------|----------|-----|
| 3→1 direto em coast lento | T11 (S25): 20→12 km/h | [26](4f27e-docs/26-patch-proposal-revised.md) Patch 1 |
| Preso em 1ª (trapping) | T10 (S24): 23→15 km/h | Patch 2 |
| Cascata 3→1→2 no tip-in ~20 km/h | T4 row 3 (S24): 23→18 km/h | Patch 3 |
| 3→1 em coast rápido (S25=S27=22) | `coast_decel` @ `0x182ED0`: 22→15 | Patch 4 |
| Preso em 3ª na retomada leve (~15–26 km/h TCM) | T7 (S27): rows 2–4 remapeadas | Patch 5 |
| S25/S27 inflados +5/+10 via GATE em coast | Modifiers 1D `0x185708` / `0x185750`: Y→0 | [50](4f27e-docs/50-shift-point-modifiers-185708.md) |
| 1→2 tip-in pouco perceptível | T4 rows 0–1 → 15 TCM; v6.3: breakpoint pedal 12→16% | [26](4f27e-docs/26-patch-proposal-revised.md), [51](4f27e-docs/51-v6.3-proposal-t7-e-prime-t4.md) |
| 3→2 sob carga em ladeira/alta (pós v6.2) | T7 remap E′ (S27 / Group 1) | [51](4f27e-docs/51-v6.3-proposal-t7-e-prime-t4.md) |

**Linha de builds documentada:**

- **v5** — Patches 1–5 nas tabelas ROM ([26](4f27e-docs/26-patch-proposal-revised.md)); Patches 1–3 validados em rodagem (~50 km, mesmo doc).
- **v6.2** — v5 + T4 rows 0–1 → 15 + modifiers Y→0; validado em pista 2026-08-10 ([26](4f27e-docs/26-patch-proposal-revised.md), [51](4f27e-docs/51-v6.3-proposal-t7-e-prime-t4.md)).
- **v6.3** — v6.2 + T7 E′ + eixo de pedal T4; build documentado 2026-08-20 ([51](4f27e-docs/51-v6.3-proposal-t7-e-prime-t4.md)).

Qualquer PHF patcheado exige **Block3 checksum** recalculado (CRC-16/ARC, modelo −4 / init `0xFFFF`) — [30-checksum-state-and-open-questions.md](4f27e-docs/30-checksum-state-and-open-questions.md). Não flashar sem verificar ck.

## Limites atuais

- Dinâmica em hardware: pendências em [13-dynamic-analysis-hardware-pendencia.md](4f27e-docs/13-dynamic-analysis-hardware-pendencia.md).
- QEMU “cru”: boot poll em `0x2FFFC284` ([13](4f27e-docs/13-dynamic-analysis-hardware-pendencia.md)).
- IO/TPU: callgraph indireto; procurar `bl` para `0x3BB10` ou `0x395B4` é caminho errado ([10-open-issues.md](4f27e-docs/10-open-issues.md)).



## Licença / uso

Pesquisa. Sem garantia. Não usar em veículo sem responsabilidade própria e sem fechar checksum, bootloader e hardware.