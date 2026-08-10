# 30 — Checksum / Boot-Gate: Estado Consolidado

> **Propósito:** documento único, auto-contido e *Gemini-ready* para iniciar uma
> investigação focada em checksums. Consolida o que está **CONFIRMADO**, lista o
> que está **REFUTADO** (para não reperseguir becos sem saída) e registra a solução
> da antiga irreprodutibilidade dos checksums armazenados.
>
> Substitui, como referência de trabalho, as conclusões dispersas e contraditórias
> do `25-checksum-analysis.md` (mantido apenas como histórico). Onde houver conflito,
> **este doc prevalece.**
>
> **Última atualização:** 2026-08-02.

---

## 0. Contexto de hardware / plataforma

- **Arquitetura:** PowerPC (família MPC5xx). Confirmado por desmontagem (`stwu`,
  `mflr`, `lbz`, `clrlwi`, `srawi`, `blr`, big-endian).
- **Imagem lógica:** 2 MB (`0x200000`). Os endereços dos descritores são endereços
  runtime. Para os bytes gravados pelo PHF, a visão consumida pela engine CRC equivale
  a `BIN[endereço-4]`; assumir `offset BIN == endereço runtime` produziu os checksums
  falsos. Prova cruzada em AA/BL/CA: §1.5.
- **Container de flash:** `.PHF` (SILVEROAK). `phf_parser/` faz `phf↔bin`. Round-trip
  do stock é **byte-perfect** (confirmado nesta e em sessões anteriores).
- **TCM sob teste é NATIVO AA** (`5U75-14C337-AA`). O stock que o FORScan grava é AA.
  Isto é crítico e mudou toda a interpretação (ver §3).

---

## 1. CONFIRMADO

### 1.1 O algoritmo É CRC-16/ARC — rotina `crc16_arc_update` (`0x1639C`)

Decompilação (IDA) da rotina central:

```c
int __fastcall crc16_arc_update(unsigned __int8 *a1, int a2, int a3) {
  // a1 = ptr dados, a2 = length, a3 = CRC state (init/seed)
  for ( ; a2; --a2 ) {
    LOWORD(v3) = *a1;
    for (v4 = 0; v4 < 8; ++v4) {
      if ( ((a3 ^ v3) & 1) != 0 )
        a3 = (a3 >> 1) ^ 0xA001;   // poly refletido 0xA001 == ARC/IBM
      else
        a3 = a3 >> 1;
      v3 = v3 >> 1;
    }
    ++a1;
  }
  return (unsigned __int16)a3;
}
```

- **Poly = 0xA001** (CRC-16/ARC, reflexivo, LSB-first).
- **O seed (`init`) é passado como argumento (`a3`)** — não é fixo no código.
- Wrapper `block_crc_update_range` (`0x1632C`) chama
  `crc16_arc_update(ptr, len, previous_crc)`.

### 1.2 As tabelas descritoras — estrutura real

Duas tabelas de descritores em flash:

- `0x0042C` — tabela pequena (**Block0 e Block1 apenas**).
- `0x1047C` — tabela grande (Block0, Block1, Block2, Block3, Master `@0x1F0440`).

**Registros em `0x1047C`** (cada um termina em `FFFFFFFF`):

```
rec[0]: 0x0000B700 0x0000B708 0x000162F8 0x0001632C 0x0001635C 0x0000000A
rec[1]: 0x00010400 0x00010408 0x000162F8 0x0001632C 0x0001635C 0x0000000A
rec[2]: 0x0002FC00 0x0002FC08 0x000162F8 0x0001632C 0x0001635C 0x00000028
rec[3]: 0x00180010 0x00180018 0x000162F8 0x0001632C 0x0001635C 0x0000000A
rec[4]: 0x001F0440 0x001F0448 0x000162F8 0x0001632C 0x0001635C 0x0000000A
```

Campos por registro: `[addr_descritor][addr_descritor+8][ptr_ler=0x162F8][ptr_crc=0x1632C][ptr_cmp=0x1635C][count/flag]`.
`block_crc_load_init` (`0x162F8`), `block_crc_update_range` (`0x1632C`) e
`block_crc_compare_expected` (`0x1635C`) são os callbacks. A engine genérica
`block_crc_engine_tick` (`0x16DE8`) chama-os por registro e preserva o acumulador
entre ranges.

**Descritor em cada `store addr`** tem o formato:

```
[ck:2][count:2][ (start:4, end:4) × count ][FFFFFFFF]
```

Exemplo — Block3 `@0x180010` (BL stock): `64 90 | 00 07 | 00180100 0018FFFF | 00190000 ...`
→ ck=`0x6490`, count=7 ranges, 1ª range `0x180100..0x18FFFF`. As ranges batem
**exatamente** com `BLOCKS[...]["ranges"]` de `scripts/build_patched_firmware.py`.
**As ranges estão corretas.**

### 1.3 O portão de boot `sub_1640C` NÃO recomputa CRC de dados

`sub_1938C → sub_16CD0 → sub_1640C`. `sub_1640C` (decompilado) compara uma
**identidade de 4 bytes** = `*(_DWORD*)descritor` = `[ck:2][count:2]` (primeiro dword
do header do bloco) contra:
- uma referência em flash (`v13[11] + 12*v10`, ou `record+8`), **e**
- uma cópia em **NVM/EEPROM** via `sub_168FC(...)`.

`sub_1640C` **nunca chama** `sub_1632C`/`sub_1639C`. Ou seja: **no boot, o gate
compara identidade + NVM; não há recomputação de CRC dos dados dentro dele.**

`sub_168FC` é o driver NVM (usa `sub_1D358`/`sub_1D63C`/`sub_1D424`/`sub_1D7A4`).
Tem modos compare/write (flags `a4`: `&2`, `&4`, `&0x20`) e um magic
`0x536C7535`-ish em `+28740`. Aparenta lógica **"trust-on-flash"** (grava a
identidade na NVM sob condições).

### 1.4 CRC-32 é código morto para boot

`sub_77B4` (CRC-32/MPEG-2, poly `0x04C11DB7`), `sub_6284`/`sub_6380` (struct
`0x3F9000`): **não estão no caminho de boot**. (Ver REFUTADO §2.)

### 1.5 A irreprodutibilidade foi resolvida: o stream runtime está deslocado −4

**FATO — engine localizada e reconstruída:**

- `block_crc_engine_tick` (`0x16DE8`) inicializa cada registro pelo callback em
  `record+8`, percorre os pares `(start,end)` em `record+4`, chama o callback CRC em
  `record+12` e finaliza pelo callback em `record+16`.
- `block_crc_load_init` (`0x162F8`) lê `u16[runtime_header+2]`.
- `block_crc_compare_expected` (`0x1635C`) compara o acumulador com
  `u16[runtime_header+4]`.
- Na imagem transmitida pelo PHF, `runtime_addr` corresponde a `BIN[runtime_addr-4]`.
  Logo, para Block3: init=`BIN[0x18000E]=0xFFFF` e target=
  `BIN[0x180010]=stored_ck`.

Fórmula reproduzida:

```
stored_ck = CRC16_ARC(
    concat(BIN[start-4 : end-4+1] para cada range),
    init=0xFFFF
)
```

Validação independente em três stocks:

| Firmware | Block2 calculado/gravado | Block3 calculado/gravado |
|----------|---------------------------|---------------------------|
| AA | `0x26A5 / 0x26A5` | `0x73A1 / 0x73A1` |
| BL | `0x804A / 0x804A` | `0x6490 / 0x6490` |
| CA | `0xFD2A / 0xFD2A` | `0x7510 / 0x7510` |

Para AA floats-only v3:

```
modelo antigo, sem shift: delta=0x0CD8 → 0x73A1 XOR 0x0CD8 = 0x7F79 (ERRADO)
modelo runtime, shift -4: delta=0x7C7F → 0x73A1 XOR 0x7C7F = 0x0FDE (CORRETO)
```

O valor `0x7F79` foi rejeitado porque não é o CRC consumido pela ECU.

---

## 2. REFUTADO — NÃO reperseguir

| # | Hipótese antiga | Como foi refutada |
|---|-----------------|-------------------|
| R1 | "Expected CRC-32 vem via UDS (struct `0x3F9000`)" — FATO 25.15 | Captura UDS do ELMConfig (FATO 25.18): **não há** `31 RoutineControl` nem setup de `0x3F9000` nem envio de CRC-32. Protocolo é UDS comum (`10 85`,`27 01/02`,`34/36/37`,`11 01`). |
| R2 | "A ferramenta de flash é a variável" (ELMConfig mágico) — FATO 25.14 | FATO 25.18: ELMConfig e FORScan produzem o **mesmo** resultado (`14 → 7F 14 11` = bootloader ativo, app não bootou). |
| R3 | "Gate = flash CRC + máscara dominante" — FATO 25.22 | FATO 25.23 + §1.3: `sub_1640C` compara identidade+NVM, não recomputa CRC. |
| R4 | "Só o Block3 ck pode mudar; Master/Block2 quebram o boot" | **`AA_patched_v3` com Master/Block2/Block3 TODOS recalculados (all-ck) BOOTOU** (2026-07-01). Refuta HIPÓTESE 25.12 e a leitura de FATO 25.11. |
| R5 | "AA_patched_v3 não boota" — FATO 25.10 | Bootou em 2026-07-01 (FORScan/OpenPort). |
| R6 | "A base errada (BL vs AA) é a causa única do não-boot" | Parcial: a base **importa** (TCM é AA), mas não explica falhas do MESMO arquivo (ver §3/§4). |
| R7 | "floats-only isola a hipótese NVM" — FATO 25.24 | O `floats-only` e o padflip **falharam por erro de teste**: mudaram dados do Block3 **sem** atualizar o Block3 ck. Não provam gate novo. |
| R8 | "O método delta-XOR do patcher recalcula o ck correto" | Refutado por §1.5: a linearidade é válida, mas o patcher alimentava bytes nos offsets BIN diretos. A engine usa o stream runtime deslocado −4. Para AA v3, `0x7F79` é errado e `0x0FDE` é o CRC correto. |

---

## 3. A virada: a BASE importa, mas não é a história toda

- TCM é **nativo AA**. Patch em base **AA** bootou (`AA_patched_v3`, all-ck, FORScan).
- Patch em base **BL** só bootou via ELMConfig (BL v3_old rodou 50km) — nunca via FORScan.
- Isso valida a intuição "o firmware base importa" — **porém** ver §4.

### 3.1 Matriz empírica de boot (consolidada)

| Firmware | Estilo ck | Ferramenta | Bootou? |
|----------|-----------|-----------|---------|
| AA stock | — | FORScan / ELMConfig | ✅ |
| BL stock | — | ELMConfig | ✅ (histórico) |
| BL v3_old (só Block3 ck) | só Block3 | **ELMConfig** | ✅ rodou 50km |
| BL v3_old (mesmo PHF) | só Block3 | **FORScan** | ❌ |
| BL v3_corrected (all-ck) | all-ck | qualquer | ❌ |
| **AA_patched_v3 (all-ck)** | all-ck | FORScan/OpenPort | ✅ **(2026-07-01)** |
| **AA_patched_v5 (all-ck)** | all-ck | FORScan/OpenPort | ❌ (2026-07-01) |
| **AA_patched_v3 (RE-flash)** | all-ck | FORScan/OpenPort | ❌ **(mesmo arquivo que bootou!)** |
| floats-only (BL, Block3 ck stale) | — | FORScan | ❌ (erro de teste) |
| padflip (BL, Block3 ck stale) | — | FORScan | ❌ (erro de teste) |
| AA floats-only v3 (`0x73A1` stale) | Block3 ck stock | FORScan/OpenPort | ❌ (CRC calculado=`0x0FDE`) |
| AA floats-only v3 (`0x7F79`) | Block3 ck antigo/incorreto | FORScan/OpenPort | ❌ (CRC calculado=`0x0FDE`) |

---

## 4. 🚩 O sinal mais forte: falha NÃO-DETERMINÍSTICA

Sequência real de 2026-07-01 (mesma ferramenta FORScan/OpenPort, mesmos ciclos de ignição):

```
stock → padflip (falha) → AA_v3 (SUCESSO) → AA_v5 (falha) → AA_v3 (FALHA)
```

- O **mesmo** `AA_patched_v3.PHF` **bootou** e, mais tarde, **falhou**.

> ⚠️ **CORREÇÃO (2026-08-02, ver §7.5):** a conclusão original desta seção — "resultado
> diferente para bytes idênticos ⇒ causa física" — está **mal-fundamentada**. O boot
> gate **escreve NVM durante a validação** (modo 3, `sub_168FC(...,4,0x24)`), então um
> sistema **determinístico-COM-ESTADO** também aceita e depois rejeita os mesmos bytes
> conforme a NVM muta. A hipótese mais forte hoje é **mutação/corrupção de estado
> NVM**, não tensão. Ver §7.5.

- **Hipótese secundária (não provada): queda de tensão da bateria** ao longo de ~5
  gravações + ciclos de ignição. Se o stock recupera 100%, esta prioridade cai.

**Sintoma de gravação (FORScan/OpenPort):** ~95% "arquivo carregado", stall ~20s
(PRNDL aparece no painel — **transitório, não é boot**), pede ciclo de ignição (~15s).
Na falha, o app não sobe pós-reset, o FORScan não confirma e **entra em loop** pedindo
ignição; usuário **cancela** (deixa a sessão não-finalizada).

> **Implicação para a sessão de checksum:** antes de atribuir qualquer falha a
> checksum, é obrigatório **eliminar a variável tensão** — gravar com fonte/carregador
> estável ≥13.5V e **ler os DTCs** (ainda não lidos) buscando códigos de tensão de
> programação. Sem isso, os dados de boot ficam contaminados.

---

## 5. MECANISMO RESOLVIDO E PONTO AINDA DESCONHECIDO

### 5.1 O CRC de Block2/Block3 agora é reproduzível

O antigo “seed diferente por bloco” era artefato de alimentar o CRC com offsets BIN
diretos. A engine usa:

1. init `0xFFFF`;
2. ranges inclusivas em ordem;
3. acumulador contínuo entre ranges;
4. bytes em `BIN[start-4:end-4+1]`;
5. comparação final contra o `stored_ck`.

Isto fecha byte por byte em AA, BL e CA (§1.5).

> ⚠️ **CAVEAT (verificado 2026-08-02) — o modelo `-4/init=0xFFFF` vale para Block1/2/3,
> NÃO para Block0 nem Master.** Verificação independente (AA e BL):
>
> | Bloco | calc (`-4`,`0xFFFF`) | stored | resultado |
> |-------|----------------------|--------|-----------|
> | Block1 | = stored | = stored | ✅ |
> | Block2 | = stored | = stored | ✅ |
> | Block3 | = stored | = stored | ✅ |
> | Block0 | `0xFFFF` | `0x3B67` | ❌ |
> | Master | ≠ stored | ≠ stored | ❌ |
>
> - **Block0**: `start=0x000000` → `start-4` é índice negativo; o slice vira vazio
>   (CRC=init=`0xFFFF`). O primeiro bloco precisa de tratamento especial (clamp) ou usa
>   esquema distinto. **Não é crítico** (Block0 nunca é patcheado).
> - **Master**: não reproduz com `-4/0xFFFF` (esquema diferente). **Não bloqueia boot** —
>   o gate não valida Master (`AA_v3` bootou com Master recalculado).
>
> ⚠️ **Armadilha futura:** a generalização "`-4` para todos os blocos" é **falsa**. Se um
> patch futuro tocar Block0, o modelo atual escreveria um ck inválido silenciosamente.
> O patcher só está provado correto para patches contidos no **Block3**.

### 5.2 Relação com o boot gate

`block_crc_engine_tick` seta as máscaras consultadas por `validate_boot_blocks`
(`0x1938C`) via `block_crc_status_query` (`0x1707C`). Em `0x19498`, selector 2 consulta
o bit de CRC aprovado. Em `0x1B1C4`, uma máscara final fora de
`{0x10,0x0C,0x1C}` gera NRC `0x22`.

`block_identity_dispatch` (`0x1640C`) continua sendo um segundo gate: compara o
primeiro dword `[ck:2][count:2]` com referências e pode persistir quatro bytes via
`nvm_compare_or_write` (`0x168FC`).

### 5.3 DESCONHECIDO remanescente

A origem inicial do slot primário de referência de identidade (`root+0x2C`) ainda não
está provada. O código prova quem compara e quem escreve os slots NVM, mas não prova
quem fornece o primeiro valor após programação. Um firmware com CRC correto ainda é
necessário para isolar esse segundo gate.

---

## 6. Resumo executivo (para começar a sessão)

- **Algoritmo confirmado:** CRC-16/ARC (`crc16_arc_update @0x1639C`, poly `0xA001`).
- **Stream confirmado para Block2/Block3:** ranges inclusivas, acumulador contínuo,
  init `0xFFFF`, leitura em offsets BIN deslocados −4.
- **AA v3 correto:** Block3 `0x73A1 → 0x0FDE`; `0x7F79` está provadamente errado.
- **Boot gate híbrido:** a engine CRC seta máscaras consumidas por
  `validate_boot_blocks @0x1938C`; `block_identity_dispatch @0x1640C` compara a
  identidade de quatro bytes com referências/NVM.
- **Aviso crítico (revisado 2026-08-02):** as falhas de 2026-07-01 são
  **determinísticas-com-estado**, não necessariamente físicas — o boot gate **escreve
  NVM durante a validação** (§7.5), então o mesmo arquivo pode bootar e depois falhar
  conforme a NVM muta. Hipótese nº1 = **estado NVM**; tensão = secundária/não provada.
- **Metadados PHF (FILE CHECKSUM / CAL ID) estão stale** nos patches (fórmulas
  verificadas, §7.1/§7.2) — corrigir por higiene, MAS **não são fatais ao boot**
  (`AA_v3` bootou com ambos stale, §7.3).

---

## 7. Achados da sessão GPT-sol (2026-08-02) — auditados aqui

> Origem: sessão paralela no Cursor com "GPT sol". Os itens abaixo foram
> **re-verificados independentemente** neste ambiente (marcados ✅) ou registrados
> como lead a confirmar (⚠️).

### 7.1 ✅ VERIFICADO — FILE CHECKSUM do header PHF tem fórmula fechada

Campo ASCII do header: `FILE CHECKSUM > 0x....`. Relação confirmada nos **4 stocks**:

```
FILE_CHECKSUM = (sum(bytes do .bin lógico 2MB) - 0x03B2) mod 0x10000
```

| FW | sum(bin) | FILE CHECKSUM (header) | (sum − 0x03B2) |
|----|----------|------------------------|----------------|
| AA | 0x0DE8 | 0x0A36 | 0x0A36 ✅ |
| BL | 0x39EF | 0x363D | 0x363D ✅ |
| CA | 0x3536 | 0x3184 | 0x3184 ✅ |
| BH | 0x44C7 | 0x4115 | 0x4115 ✅ |

`bin_to_phf.py` foi atualizado em 2026-08-02 e agora recalcula esse campo por padrão.

### 7.2 ✅ VERIFICADO — CAL ID suffix = Master ck

`CAL ID > 20462;<XXXX>`, onde `<XXXX> = u16be[0x02045E]` (= Master ck). Confirmado nos
4 stocks (`D8BF/FCF5/DFB3/F7F9`). PHFs "all-ck" (que mudam o Master ck) têm CAL ID stale.

### 7.3 ⚠️ CONTRAPONTO CRÍTICO — metadados stale NÃO são fatais ao boot (PROVADO)

`AA_patched_v3` **bootou** (2026-07-01) com **FILE CHECKSUM stale** (0x0A36 armazenado
vs ~0x0609 real) **E** CAL ID stale (header `D8BF` vs Master real `B97E`). Portanto o
FORScan **não rejeita fatalmente** por esses campos — ou eles não são o portão de boot.
São **higiene** (devem ser corrigidos no gerador PHF), **não** a causa provada do
não-boot. Não priorizar como bloqueador.

### 7.4 ✅ RESOLVIDO — semântica do header no callback e deslocamento runtime

As funções `0x162F8`, `0x1635C` e `0x16DE8` foram definidas e decompiladas. A leitura
literal `runtime_header+2/+4` estava correta, mas a premissa
`runtime address == BIN offset` estava errada. O PHF apresenta os bytes à engine com
deslocamento −4. Para Block3:

- `runtime_header+2` → `BIN[ck_off-2]` = `0xFFFF` (init);
- `runtime_header+4` → `BIN[ck_off]` = checksum armazenado;
- ranges runtime → bytes `BIN[start-4:end-4+1]`.

Isto reproduz os checksums stock em AA/BL/CA e produz `0x0FDE` para AA v3.

### 7.5 ✅ CONCEDIDO — o §4 ("físico") estava mal-fundamentado

O boot gate **modifica NVM durante a validação**: modo 3 (`sub_1938C @0x194E0`, guard
`0x5365` → `sub_16CD0` → `sub_1640C` a1=3 → `sub_168FC(..., 4, 0x24)` = blank-check +
write + commit via `sub_1D424`/`sub_1D7A4`/`sub_1D358`). Logo, um sistema
**determinístico-COM-ESTADO** aceita e depois rejeita os MESMOS bytes conforme o estado
inicial da NVM muta. **"Mesmo arquivo falhou depois" NÃO prova causa física.**
Evidência de estado variável no log ELMConfig: `B1 00 B2 AA` (erase) → `NRC 0x22`, e
após ciclo o mesmo comando conclui positivo — antes do 1º TransferData.

**Hipóteses de falha recente, reordenadas:**
1. **Checksum Block3 incorreto — CONFIRMADO:** `0x73A1` stale e `0x7F79` calculado pelo
   modelo sem shift não casam com o resultado runtime `0x0FDE`.
2. **Estado NVM/identidade — ainda aberto:** existe e é mutável, mas os testes anteriores
   nunca chegaram com CRC Block3 correto; portanto não isolam esse gate.
3. ~~Tensão/elétrico~~ — **ELIMINADA (2026-08-02).** Ver §7.8.

### 7.8 ✅ DECISIVO — tensão eliminada; o gate é 100% dependente de conteúdo/estado

**FATO (confirmado pelo usuário, 2026-08-02):** o **stock NUNCA falha** ao gravar/bootar
— nem tarde numa sessão de múltiplos flashes.

- Tensão de bateria **não discrimina conteúdo de arquivo**. Se fosse tensão, o stock
  gravado tarde na sessão também falharia às vezes. Não falha. **Tensão está morta.**
- Logo, a falha do patched é **determinística e dependente de conteúdo/estado**, não física.

**Por que o stock é à prova de balas:** a identidade do stock (`[ck:2][count:2]` por
bloco) **é igual à âncora de fábrica/as-built gravada na NVM**. O gate compara flash×NVM
e **sempre casa** → boota sempre.

**Por que o patched é instável:** a identidade patcheada **≠** âncora NVM. Para bootar,
o gate precisa **comitar a nova identidade na NVM** (write do modo 3), e esse caminho é
**one-shot/frágil**: quando o slot NVM já contém uma identidade não-stock, um novo
patched com identidade diferente **não recasa**, e um write parcial/falho pode corromper
o slot. Isso explica exatamente **`AA_v3` bootar uma vez e o reflash falhar**.

**Correção estratégica:** preservar `0x73A1` enquanto os dados mudam deixa o CRC stale
e é rejeitado pela engine. O próximo experimento deve gravar o checksum Block3 correto
`0x0FDE`; só depois é válido concluir algo sobre a referência NVM.

> ⚠️ **Cuidado operacional:** cada flash pode **mutar a NVM**. Antes de qualquer
> experimento, **recuperar para stock** (re-ancora a NVM), e então fazer o teste §7.6
> como **um único flash limpo**. Não encadear tentativas patched (cada uma degrada o
> estado).

### 7.6 Testes executados e próximo isolamento correto

1. AA + 13 bytes floats v3 + Block3 stock `0x73A1`: falhou. CRC runtime calculado
   posteriormente=`0x0FDE`; portanto o teste tinha checksum stale.
2. Mesmo conteúdo + Block3 `0x7F79`: falhou. Esse valor veio do delta sobre offsets BIN
   sem shift; também não é o CRC runtime.
3. Próximo teste controlado: AA + 13 bytes floats v3 + Block3 `0x0FDE`, Master/Block2
   preservados, CAL ID `D8BF`, FILE CHECKSUM `0x05DF`.

### 7.7 Ações de higiene recomendadas (independentes do enigma)

1. Implementar o cálculo de **FILE CHECKSUM** (fórmula §7.1) em `bin_to_phf.py`
   (`update_header_checksum`).
2. Atualizar o **CAL ID** suffix para o Master ck real do bin patcheado.
3. Não confiar no self-test do patcher (é circular, §2 R8 / §5).
