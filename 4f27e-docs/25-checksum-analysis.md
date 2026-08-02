# 25 — Flash Block Checksum: Análise Completa

**Data:** 2026-04-13 (atualizado)  
**Status:** ✅ **RESOLVIDO** — Algoritmo identificado: CRC-16/ARC (poly=0xA001). Validado em 4 firmwares × 4 blocks (16/16 matches).  
**Dependência:** Binários AA, BL, CA, BH convertidos (doc 20)

---

## Resumo Executivo

1. **FATO:** Algoritmo = **CRC-16/ARC** (poly=0xA001, LSB-first, reflected). Função no firmware: `crc16_arc_poly_a001` @ 0x6548.
2. **FATO:** Validado em 16/16 combinações (4 firmwares × 4 blocks), com ranges COMPLETOS extraídos dos headers.
3. **FATO:** O init value é **variável** (não fixo), determinado em runtime. MAS não é necessário conhecê-lo: a propriedade de linearidade do CRC permite recalcular checksums após patches usando `new_cksum = old_cksum XOR CRC(delta_buf, 0)`.
4. **FATO:** O valor xorout também é variável (0x0000 ou 0xFFFF), mas a fórmula delta funciona independentemente.

---

## Algoritmo Identificado

### CRC-16/ARC (poly=0xA001)

```
Implementação no firmware: sub_6548 / crc16_arc_poly_a001
Parâmetros PPC:
  r3 = ponteiro para dados
  r4 = comprimento em bytes
  r5 = CRC inicial
Retorno:
  r3 = CRC-16 computado

Algoritmo: LSB-first, bit-by-bit
  for each byte:
    crc ^= byte
    for 8 bits:
      if (crc & 1): crc = (crc >> 1) ^ 0xA001
      else: crc >>= 1
```

### Wrapper: `crc16_wrapper` @ 0x64D4

Entry point 0x64D8 (referenciado no descriptor table):

- r3=data, r4=init, r5=length → rearranges → chama crc16_arc(r3=data, r4=len, r5=init)

### Recálculo via Linearidade (SEM NECESSIDADE DE INIT)

```
Para cada byte modificado no range do bloco:
  1. delta_buf = buffer de zeros do tamanho total dos ranges do bloco
  2. Para cada posição p modificada: delta_buf[p] = old_byte[p] XOR new_byte[p]
  3. delta = CRC16_ARC(delta_buf, init=0)
  4. new_checksum = old_checksum XOR delta
```

**Prova:** Validado com modificações simples e multi-byte no Block0 do firmware AA.

---

## Block Headers — Estrutura Completa

### Formato

```
[00 00 FF FF] [CK CK] [TT TT] [START1(4)] [END1(4)] [START2(4)] [END2(4)] ... [FF FF FF FF]
```

- `0000 FFFF` = marcador de block válido
- `CK CK` = 16-bit checksum (CRC-16/ARC do conteúdo dos ranges)
- `TT TT` = tipo do block
- Ranges: pares (start, end) inclusivos, terminados por 0xFFFFFFFF

### Tabela Completa de Blocks (AA firmware)


| Block        | Header EA | Marker   | Checksum | Type   | Ranges    | Total Data      |
| ------------ | --------- | -------- | -------- | ------ | --------- | --------------- |
| 0 (boot)     | 0xB6FC    | 0000FFFF | 0x3B67   | 0x0001 | 1 range   | 41,272 bytes    |
| 1 (code)     | 0x103FC   | 0000FFFF | 0x2562   | 0x0002 | 2 ranges  | 63,694 bytes    |
| 3 (code+cal) | 0x2FBFC   | 0000FFFF | 0x26A5   | 0x0013 | 19 ranges | 1,223,964 bytes |
| Master (cal) | 0x18000C  | 0000FFFF | 0x73A1   | 0x0007 | 7 ranges  | 454,272 bytes   |


### Ranges Detalhados

**Block0** (1 range):

- 0x000000 - 0x00A137

**Block1** (2 ranges):

- 0x010010 - 0x010311
- 0x010480 - 0x01FA4B

**Block3** (19 ranges):

- 0x020400 - 0x02FA67
- 0x030000 - 0x03FFFF
- 0x040000 - 0x04B6B3
- 0x080000 - 0x0FFFFF (8 ranges contíguos de 64KB: 0x08-0x0F)
- 0x100000 - 0x17FFFF (8 ranges contíguos de 64KB: 0x10-0x17)

**Master** (7 ranges):

- 0x180100 - 0x18FFFF
- 0x190000 - 0x1AFFFF (2 ranges contíguos)
- 0x1A0000 - 0x1BFFFF (2 ranges contíguos)
- 0x1C0000 - 0x1DFFFF (2 ranges contíguos)
- 0x1E0000 - 0x1EEF7F

### Checksums por Firmware


| Block  | AA     | BL     | CA     | BH     |
| ------ | ------ | ------ | ------ | ------ |
| Block0 | 0x3B67 | 0x3B67 | 0x3B67 | 0x1912 |
| Block1 | 0x2562 | 0x2562 | 0x2562 | 0x91A1 |
| Block3 | 0x26A5 | 0x804A | 0xFD2A | 0x80FF |
| Master | 0x73A1 | 0x6490 | 0x7510 | 0x5BC4 |


Block0/1 são idênticos entre AA/BL/CA (mesmo código). BH é plataforma diferente (Siemens vs Continental).

---

## Descriptor Table @ 0x042C

Entries de 28 bytes (7 × uint32 big-endian):


| Field | Entry 0 (Block0) | Entry 1 (Block1) | Descrição                                    |
| ----- | ---------------- | ---------------- | -------------------------------------------- |
| [0]   | 0x0000B700       | 0x00010400       | Header address (após marker 0000FFFF)        |
| [1]   | 0x0000B708       | 0x00010408       | Range data start in header                   |
| [2]   | 0x000064A4       | 0x000064A4       | `sub_64A4` — init: lê TYPE, armazena em RAM  |
| [3]   | 0x000064D8       | 0x000064D8       | `crc16_wrapper` entry — computa CRC          |
| [4]   | 0x00006508       | 0x00006508       | `sub_6508` — verify: compara CRC vs expected |
| [5]   | 0x0000000A       | 0x0000000A       | Constante (block count? stride?)             |
| [6]   | 0xFFFFFFFF       | 0xFFFFFFFF       | Sentinel                                     |


---

## CRC-32 no Firmware (separado do checksum de blocks)

### Função `sub_77B4` (CRC-32/MPEG-2, tabela shifted)

Usado pelo validador `loc_6284` para verificação CRC-32 de integridade. **NÃO** é o algoritmo dos block headers 16-bit.

- Poly: 0x04C11DB7 (MSB-first)
- Tabela: 0x77FC (shifted +1: entry[0] da tabela = entry[1] do standard)
- Validador: processa chunks de 256 bytes, compara resultado com esperado em RAM 0x3FFD68

---

## UDS Flash Handlers (confirmação: ECU NÃO computa block checksums)


| Função                         | EA      | Serviço | Comportamento                                                      |
| ------------------------------ | ------- | ------- | ------------------------------------------------------------------ |
| `uds_34_request_download`      | 0xB6B94 | 0x34    | Valida endereço destino, configura sessão                          |
| `uds_36_transfer_data`         | 0xB6DAC | 0x36    | Byte-copy do buffer UDS para flash. **ZERO** checksum computation. |
| `uds_37_request_transfer_exit` | 0xB701C | 0x37    | State management. **ZERO** checksum computation.                   |


**FATO:** Os 16-bit block checksums são pré-computados pela flash tool (ELMConfig), não pela ECU.

---

## ELMConfig (ferramenta de flash)

- VB6 P-code (bytecode interpretado por MSVBVM60.DLL)
- Protegido por packer customizado (seções .UPX0/.UPX1 + cifragem .text)
- Usa `diCryptoSys.dll` (AES para decifrar `frw.dat`, CRC-32 para integridade VBF)
- Pode conter **strings** no executável (ex. texto sobre checksum) — isso **não** implica controle visível na GUI. Na prática, o operador vê em geral opções de **tamanho de bloco** e algo do tipo **não apagar/zerar a memória antes de flashear**; não há, na interface comum, um interruptor explícito “não recalcular checksum” documentado de forma confiável.
- Conhece firmwares TCM: strings `"5M5P-14C337-A"`, `"5M5P-14C337-B"`, `"5M5P-14C337-C"`
- Aceita formatos: PHF, HEX, BIN

**FATO:** Análise dinâmica via Wine confirmou unpacking bem-sucedido e GUI funcional.

**Implicação para patches:** o BIN/PHF gravado no TCM tem de levar **já** os 16-bit block checksums corretos no header de cada região; **não** contar com o ELMConfig para “arrumar” isso de forma previsível só pela interface.

---

## Histórico de Algoritmos Testados

14+ algoritmos testados antes da solução (todos falharam por ranges incompletos):


| #    | Algoritmo                                                                                            | Resultado              |
| ---- | ---------------------------------------------------------------------------------------------------- | ---------------------- |
| 1-14 | sum16, ~sum16, CRC-16/CCITT, CRC-16/IBM, CRC-32/MPEG-2, Fletcher-16, XOR-16, Adler-16, RFC1071, etc. | FAIL (ranges parciais) |
| 15   | CRC-16/ARC brute-force (range parcial: só 1º range por block)                                        | FAIL                   |
| 16   | CRC-16/ARC brute-force (todos os ranges do header)                                                   | **16/16 MATCH**        |


**Root cause dos falsos negativos:** Block3 tem 19 ranges (1.2MB) e Master tem 7 ranges (454KB). Testes anteriores usavam apenas o 1º range de cada block.

---

## 🔬 Validação On-Target (2026-05-07) — Patches v5 NÃO bootam mesmo com checksums corretos

**Contexto:** OpenPort + FORScan privado flashou v3 e v5; nenhum boota. AA stock boota direto.

### FATO V.1 — Checksums dos 5 blocks no v5 estão corretos via linearidade

Validação executada (delta vs BL stock):

| Block  | BL ck    | v5 ck    | esperado (BL XOR delta_crc) | resultado |
|--------|----------|----------|------------------------------|-----------|
| Block0 | 0x3B67   | 0x3B67   | 0x3B67                       | **MATCH** (sem patches) |
| Block1 | 0x2562   | 0x2562   | 0x2562                       | **MATCH** (sem patches) |
| Block2 | 0x804A   | 0x96C0   | 0x96C0 (delta_crc=0x168A)    | **MATCH** |
| Block3 | 0x6490   | 0x59A5   | 0x59A5 (delta_crc=0x3D35)    | **MATCH** |
| Master | 0xFCF5   | 0xFCFA   | 0xFCFA (delta_crc=0x000F)    | **MATCH** |

5/5 batem. Algoritmo CRC-16/ARC + linearidade confirmados em PATCH real, não só em validação artificial.

### FATO V.2 — Pipeline PHF é byte-perfect

Round-trip BL.PHF → BIN → PHF reproduz BL.PHF byte a byte. Carry byte-31 (doc 20) está correto. v5.bin → v5.PHF preserva tudo.

### FATO V.3 — Block0 e Block1 estão idênticos entre BL e v5

Patches v5 só tocaram em ranges dentro de Block2 (0 byte) e Block3 (23 bytes) + 5 bytes de checksum em headers. **Block0 e Block1 permanecem idênticos.** O descriptor table @ `0x042C` só tem **2 entries** (Block0 e Block1).

### Implicação direta

Se o validador do bootloader usa apenas as 2 entries do descriptor table @ 0x042C, ele valida **apenas Block0/Block1**, que estão **inalterados** em v5. Então o bootloader deveria aceitar.

**Mas o TCM não boota com v5.**

Logo, **existe outra camada de validação** que ainda não está documentada e que estamos quebrando. Candidatos:

1. **CRC-32 (`sub_77B4` @ 0x77B4) chamado por validador `sub_6284` @ 0x6284.** Validador opera incremental em chunks de 256 bytes, mantém estado em RAM `0x3FFD5C..0x3FFD6C`, compara CRC-32 acumulado contra valor esperado em RAM `0x3FFD68`. RAM inicializada de algum offset em flash que ainda não localizamos.
2. **Tabela de descriptors adicional** que enumera Block2/3/Master para validação. Não encontrada em scan de 0x042C+. Pode estar em outro endereço.
3. **Assinatura/hash extra** sobre cabeçalhos ou metadata.
4. **Validação aplicacional** (não bootloader): aplicação inicia mas se mata num check, deixando o sistema sem PRNDL.

### DESCONHECIDO

- Endereço em flash de onde RAM `0x3FFD5C..0x3FFD6C` é populada.
- Range coberto pelo CRC-32 incremental.
- Se o CRC-32 é bootloader-time ou runtime de aplicação.
- Se há descriptor adicional para Block2/3/Master.

### Próximo passo de maior ROI

1. **Localizar fonte em flash do RAM 0x3FFD5C-0x3FFD6C** (init/copy loop). Endereço de origem revela onde está o "expected CRC-32".
2. **Capturar UDS log de uma flashagem AA→AA bem-sucedida** (idempotente, baixo risco). Os bytes que o FORScan envia são exatamente o que o módulo espera; comparar com o que enviaria para v5 mostra que campos extras estão sendo modificados.
3. **Bissecção de patches**: aplicar patches 1, 2, 3, 4, 5 individualmente em cima de BL stock e flashear cada um. O primeiro que falhar identifica qual patch quebra a validação extra.

---

## 🔍 Atualização (2026-05-07 madrugada) — Pipeline reproduzível + bug v3/AA_patched

**Contexto:** v3 também falha no FORScan privado, embora tenha rodado 50 km via ELMConfig.

### FATO 25.1 — `5M5P-14C337-BL_patched.bin` (v3 antigo) tem Master ck inválido

Verificação direta:

| Block  | BL ck | v3 antigo ck | esperado (linearidade) | resultado |
|--------|-------|--------------|------------------------|-----------|
| Block3 | 0x6490 | 0x6848 | 0x6848 | MATCH |
| Block2 | 0x804A | 0x804A | 0x804A (sem patches em Block2) | MATCH |
| Master | 0xFCF5 | 0xFCF5 | 0xA4B3 (com Block3 ck delta) | **MISMATCH** |

`5U75-14C337-AA_patched.bin` apresenta o mesmo padrão. **Bug do pipeline antigo:** Block3 ck atualizado, Master ck deixado inalterado. ELMConfig recalculava silenciosamente durante o flash, o que mascarou o bug por meses. FORScan privado **não** recalcula → expõe.

### FATO 25.2 — Pipeline correto implementado em `scripts/build_patched_firmware.py`

Script único reproduzível que:

1. Aplica patches em Block3 (área de calibração).
2. Recomputa Block3 ck via linearidade (self-contained).
3. Resolve dependência circular Master ↔ Block2 como sistema linear sobre GF(2)^16:
   - `(I XOR L_M∘L_B2)·ΔM = K_M_const`
   - Gauss elimination produz 2 soluções (kernel 1-dim).
   - Heurística: escolher par (M, B2) com **menor distância de Hamming** vs (Master_old, Block2_old). Mesma escolha do brute-force original.

### FATO 25.3 — Self-test reproduz v5 byte-perfect

Aplicando patches 1-5 em BL stock via novo pipeline:

| Block  | velho ck | novo ck (calculado) | v5.bin (referência) |
|--------|----------|---------------------|---------------------|
| Block0 | 0x3B67 | 0x3B67 | 0x3B67 |
| Block1 | 0x2562 | 0x2562 | 0x2562 |
| Block3 | 0x6490 | 0x59A5 | 0x59A5 |
| Master | 0xFCF5 | 0xFCFA | 0xFCFA |
| Block2 | 0x804A | 0x96C0 | 0x96C0 |

**0 byte diffs** entre output do script e v5.bin existente. Pipeline confirmado.

### FATO 25.4 — v3 corrigido gerado

`firmwares/5M5P-14C337-BL_patched_v3_corrected.bin` + `.PHF`, com:

| Block  | BL ck | v3_corrected ck |
|--------|-------|-----------------|
| Block3 | 0x6490 | 0x6848 |
| Master | 0xFCF5 | 0x9D34 |
| Block2 | 0x804A | 0x335A |

Diff vs v3 antigo: apenas 4 bytes (Master ck + Block2 ck). PHF round-trip valida.

### Pendências

- Flashar v3_corrected.PHF para confirmar que correção do Master/Block2 resolve o caso v3.
- Se v3_corrected bootar: caso v5 isolado em patches 4 ou 5 (bissecção).
- Se v3_corrected também falhar: validação adicional além do CRC-16/ARC. Investigar `sub_77B4`/`sub_6284` CRC-32.

---

## 🚨 Atualização (2026-05-07 manhã) — v3_corrected também não bootou. Causa: BASELINE ERRADA.

**Contexto:** v3_corrected (BL stock + patches 1-3 com checksums corretos) não boota.

### FATO 25.5 — TCM atual está rodando AA, não BL

Cenário corrente: FORScan baixou e gravou **AA stock** durante a recuperação do bricked TCM. Estamos flasheando **BL_patched** em cima.

### FATO 25.6 — AA e BL têm metadados de identificação diferentes

Região `0x020200-0x02045E` (entre fim de Block1 e início de Master) contém strings de identificação **fora** de qualquer block checksum:

| Offset    | Conteúdo (AA)         | Conteúdo (BL)         |
|-----------|----------------------|----------------------|
| 0x020200  | `5U75-14C337-AA`     | `5M5P-14C337-BL`     |
| 0x020228  | `5U75-12B565-AA`     | `5M5P-12B565-BL`     |
| 0x020260  | `Copyright Ford Motor Co. 2010` | `...2008` |
| 0x020410  | `GKOWALCZ` (autor)   | `ALAZOS` (autor)     |
| 0x020450  | hash 0xD8BF          | hash 0xFCF5          |

### HIPÓTESE 25.7 — Validador adicional verifica consistência metadata vs bootloader/EEPROM

O bootloader (ou aplicação no startup) provavelmente compara strategy/calibration ID embarcado em flash contra valor esperado (em EEPROM persistente, RAM cache, ou ambos).
Quando flasheamos BL_patched sobre AA:
- Bytes em ranges de bloco viram BL.
- Metadata em `0x020200-0x0203FF` pode (ou não) ser flasheado dependendo do que o PHF contém — round-trip mostra que a região está no PHF.
- Se PHF flashear, metadata vira BL; se EEPROM/cache esperar AA → mismatch → halt.
- Se PHF não flashear, metadata fica AA mas blocos são BL → também mismatch.

Não-flashar versus flashar: ambos falham. Fica claro que **a única coisa que combina é flashar AA-based**.

### FATO 25.8 — Patches 1-5 transferem byte-perfect para AA

Verificação dos 23 offsets de patch (T11/T10/T4/coast_decel/T7) em AA vs BL:

| Patch    | Offset    | BL valor    | AA valor    | resultado |
|----------|-----------|-------------|-------------|-----------|
| T11 7×   | 0x184DB0  | 41 A0 00 00 | 41 A0 00 00 | IDÊNTICOS |
| T10 5×   | 0x184D50  | 41 B8 00 00 | 41 B8 00 00 | IDÊNTICOS |
| T4 1×    | 0x184B28  | 41 B8 00 00 | 41 B8 00 00 | IDÊNTICOS |
| Coast 7× | 0x182ED0  | 41 B0 00 00 | 41 B0 00 00 | IDÊNTICOS |
| T7 3×    | 0x184C40  | 41 60/98/C8 | 41 60/98/C8 | IDÊNTICOS |

**Tabelas de calibração nos pontos de patch são literalmente os mesmos bytes em AA e BL.** Patch addresses são portáveis. Aplicar os mesmos 13 bytes (v3) ou 23 bytes (v5) sobre AA produz exatamente o mesmo efeito comportamental que sobre BL — sem trocar identidade do firmware.

### FATO 25.9 — `5U75-14C337-AA_patched_v3.PHF` gerado e validado

| Block  | AA ck | AA_patched_v3 ck |
|--------|-------|------------------|
| Block3 | 0x73A1 | 0x7F79 |
| Master | 0xD8BF | 0xB97E |
| Block2 | 0x26A5 | 0x95B5 |

PHF round-trip: 0 diffs. Strategy ID `5U75-14C337-AA` preservado.

### FATO 25.10 — AA_patched_v3 também NÃO bootou. Hipótese baseline-mismatch falsa.

**Resultado experimental:** flashar `5U75-14C337-AA_patched_v3.PHF` (com strategy ID idêntico, todos 5 ck recalculados) também resultou em TCM sem PRNDL. Mismatch de identidade não é a causa.

### FATO 25.13 — AA_patched_v3_elmconfigStyle NÃO bootou. Master/Block2 ck NÃO é a variável.

Flashar `5U75-14C337-AA_patched_v3_elmconfigStyle.PHF` (Master+Block2 ck preservados como AA stock, só Block3 ck atualizado, fingerprint idêntico ao V3 antigo) **TAMBÉM falhou via FORScan/OpenPort**. Resultado: TCM sem PRNDL.

### 🔥 FATO 25.14 — Mesmo PHF: ELMConfig boota, FORScan não boota

O usuário confirmou que o PHF V3 antigo (`5M5P-14C337-BL_patched.PHF`, abril 13) flasheado por **FORScan/OpenPort também falhou**. Esse é o mesmo arquivo byte-perfect que rodou 50km via ELMConfig.

**Conclusão direta:** A ferramenta de flash é a variável determinante, não os bytes do PHF.

| Cenário          | ELMConfig | FORScan/OpenPort |
|------------------|-----------|-------------------|
| AA stock         | ✓ boota   | ✓ boota           |
| V3 (mesmo PHF)   | **✓ rodou 50km** | ❌ não boota |
| V5               | ❌ brick  | ❌ não boota      |

### Investigação IDA do validador CRC-32 (sub_6284 / sub_6380)

Decompilação confirma:
- **`sub_77B4`** — CRC-32/MPEG-2 (poly=0x04C11DB7, MSB-first), tabela em 0x77FC.
- **`sub_6284`** — Validador iterativo que processa range em chunks de 256 bytes.
  - RAM 0x3FFD5C: pos atual
  - RAM 0x3FFD60: end address
  - RAM 0x3FFD64: CRC acumulado
  - RAM 0x3FFD68: CRC esperado
  - Match → grava 0xA0 em RAM 0x3FFD6E.
  - Fail → grava 0x92 em RAM 0x3FFD6E.
- **`sub_6380`** — Setup do validador. Lê struct em RAM `0x3F9000`:
  - 0x3F9000: init CRC → 0x3FFD64
  - 0x3F9004: expected CRC → 0x3FFD68
  - 0x3F900C: range start → 0x3FFD5C
  - 0x3F9010: range end → 0x3FFD60
  - 0x3F9014: 6 bytes ID, comparado com ROM `0xBA00` ("FT300" / Ford Transmission 300).
  - Após match do module ID, dispara `loc_6284` (validador).

### FATO 25.15 — Struct 0x3F9000 é POPULADO via UDS, não vem de flash

`sub_5E00` (chamado durante UDS Transfer) faz `memcpy(0x3F9000+offset, 0x3FF833, len)`. O **expected CRC-32 vem do tool de flash via UDS**, não está hardcoded em flash.

Implicação: ELMConfig e FORScan podem enviar valores diferentes pra esse struct. Se um envia o CRC esperado correto e o outro não, isso explica a diferença.

### FATO 25.16 — `sub_6380` e `sub_5E00` não têm xrefs diretos

IDA não encontra callers via `bl/b/bla/ba`. Só podem ser invocados via dispatch table de UDS Routine Control (serviço `0x31`), provavelmente `routine ID = 0xFF01` (CheckProgrammingDependencies) ou similar.

### FATO 25.17 — file_checksum no PHF NÃO é atualizado em patches

`bin_to_phf.py` linha 130-141: parâmetro `update_header_checksum=True` mas docstring confirma "not yet implemented — header is copied verbatim from template".

| PHF          | file_checksum | cal_id          |
|--------------|---------------|-----------------|
| AA stock     | 0x0A36        | 20462;D8BF (= AA Master ck) |
| BL stock     | 0x363D        | 20462;FCF5 (= BL Master ck) |
| v3 antigo    | 0x363D (= BL) | 20462;FCF5 (= BL) |
| v3 corrected | 0x363D (= BL) | 20462;FCF5 (= BL, embora BIN tenha 0x9D34) |

Ambos campos ficam **stale** em PHFs patched. ELMConfig não valida; FORScan pode validar. Tentativa simples: gerar variant com file_checksum/cal_id atualizado e testar.

### Próxima ação concreta

**Capturar log UDS do FORScan privado** durante:
- Flash A: AA stock (boota) — comportamento esperado
- Flash B: V3 antigo (não boota) — comportamento problemático

Diferença entre os dois identifica o comando UDS que falha. Sem isso continuamos chutando hipóteses.

### 🔥 FATO 25.11 — V3 antigo (que rodou 50km via ELMConfig) tem **Master ck e Block2 ck NÃO atualizados** (= BL stock)

Diff de checksums entre as variantes V3:

| ck | BL stock | **v3 OLD (rodou 50km!)** | v3_corrected (não boota) |
|----|----------|--------------------------|--------------------------|
| Block0 | 0x3B67   | 0x3B67       | 0x3B67       |
| Block1 | 0x2562   | 0x2562       | 0x2562       |
| Master | **0xFCF5** | **0xFCF5 (= BL stock)** | 0x9D34 (recalculado) |
| Block2 | **0x804A** | **0x804A (= BL stock)** | 0x335A (recalculado) |
| Block3 | 0x6490   | **0x6848 (atualizado)** | 0x6848 (atualizado) |

Diff v3_old vs v3_corrected = **APENAS 4 bytes**: Master ck (0x02045E) e Block2 ck (0x02FC00). Patches/Block3 ck idênticos.

ELMConfig **não atualizou** Master/Block2 ck. Esse firmware **passou pelo bootloader e rodou 50km**. Conclusão direta:

- O bootloader **NÃO valida Master ck nem Block2 ck**.
- O bootloader provavelmente só valida Block0/Block1 (consistente com o descriptor table @ 0x042C).
- Block3 ck **tem que** estar atualizado (caso contrário não boota — comportamento de validação).

### HIPÓTESE 25.12 — App rejeita Master ck "novo" (que não bate com factory baseline)

Possível mecanismo: a aplicação lê Master ck @ 0x02045E como identificador de versão de calibração e compara contra valor armazenado em EEPROM (gravado em factory programming) ou contra constante hardcoded em código.

- v3_old com Master=0xFCF5 (BL stock conhecido) → app aceita.
- v3_corrected com Master=0x9D34 (valor "novo") → app rejeita.
- AA_patched_v3 com Master=0xB97E (valor "novo") → app rejeita.

Predição: AA_patched_v3 **com Master/Block2 ck preservados em AA stock** (ELMConfig style) deve bootar.

### Próximo experimento — `AA_patched_v3_elmconfigStyle.PHF`

Gerado: `firmwares/5U75-14C337-AA_patched_v3_elmconfigStyle.PHF`

| ck     | valor               | nota |
|--------|---------------------|------|
| Block0 | 0x3B67              | unchanged |
| Block1 | 0x2562              | unchanged |
| Master | **0xD8BF**          | **NÃO atualizado** (= AA stock) |
| Block2 | **0x26A5**          | **NÃO atualizado** (= AA stock) |
| Block3 | **0x7F79**          | atualizado (delta dos patches) |

Total: 15 bytes diff vs AA stock (13 patches + 2 Block3 ck).

Também gerado: `firmwares/5U75-14C337-AA_patched_v5_elmconfigStyle.PHF` (Block3 ck = 0x4E94).

---

## 🔥 Atualização (2026-06-22) — Captura UDS do ELMConfig + 2ª tabela de validação

**Contexto:** sniff serial transparente (bridge PTY/Python entre Wine→ELMConfig e ELM327 @115200) capturou o protocolo COMPLETO de flash do ELMConfig, byte a byte. Artefatos em `tcm_recovery/`:
- `elmconfig_uds_raw_*.log` (captura serial crua)
- `uds_transcript_v3_flash_FULL.txt` (UDS decodificado)
- `decode_uds.py` (decoder ISO-TP→UDS)

### 🔥 FATO 25.18 — O protocolo do ELMConfig é UDS COMUM. NÃO há comando mágico.

Sequência completa capturada (flash de `v3_corrected`, CAN ISO-15765, 7E1/7DF):

```
10 85            → 50 85         DiagnosticSessionControl (programming) OK
27 01            → 67 01 28 7A B4    SecurityAccess L1 requestSeed (SEED ESTÁTICO)
27 02 E5 0A 7A   → 67 02         SecurityAccess L1 sendKey OK (key 3 bytes)
B1 00 B2 AA      → 7F B1 78 (×~40) → 50 B1 00 B2   erase (~10s, EXIGE ciclo de ignição)
34 00 02 00 00 00 1E 00 00 → 74 01 01   RequestDownload size=0x1E0000, bloco=257B
36 ... (257B)    → 76           TransferData × 7680
37               → 77           RequestTransferExit OK
11 01            → 51 01        ECUReset (hardReset) OK
14 FF 00         → 7F 14 11     ClearDTC serviceNotSupported  ← app NÃO bootou
```

**Implicações decisivas:**
1. **NÃO existe** `31 RoutineControl`, **NÃO existe** setup do struct `0x3F9000`, **NÃO existe** envio de CRC-32 via UDS. A HIPÓTESE central do doc (FATO 25.15: "expected CRC-32 vem via UDS") está **REFUTADA**. ELMConfig não envia nada disso.
2. **Security é Nível 1** (`27 01/02`), seed estático `28 7A B4` → key `E5 0A 7A`. Algoritmo L1 ≠ L3 (nosso `compute_security_key` dá `D3 26 07` p/ esse seed). O TCM "bricado" responde via **bootloader** (L1).
3. `14 ClearDTC → serviceNotSupported` após reset = **bootloader ativo, app não bootou**. Mesmo resultado do FORScan. **A ferramenta NÃO é a variável** (refuta interpretação de FATO 25.14 sobre "ELMConfig mágico").

### 🔥 FATO 25.19 — Existe uma SEGUNDA tabela de validação CRC-16/ARC @ 0x1047C

Além da tabela @ 0x042C (só Block0/Block1), há uma 2ª tabela @ **0x1047C** com 5 entries (28 bytes cada) cobrindo **Block0, Block1, Block3, Master e 0x1F0440**, usando funções próprias:
- `0x162F8` (init), `0x1632C` (compute wrapper → `sub_1639C`), `0x1635C` (verify)
- `sub_1639C` = **CRC-16/ARC** (poly 0xA001), 2ª cópia do algoritmo

| Entry | Header (CK ea) | field5 |
|-------|----------------|--------|
| Block0 | 0xB700 | 0x0A |
| Block1 | 0x10400 | 0x0A |
| Block3 | 0x2FC00 | **0x28** |
| Master | 0x180010 | 0x0A |
| 0x1F0440 | 0x1F0440 | 0x0A |

Driver da tabela em ~`0x1640C` (usa globais r13-relativos `0x7040`). Esta validação cobre a área de calibração (Block3/Master) — explica por que Block3 ck precisa estar correto.

### FATO 25.20 — CRC-32 (sub_6284/6380/77B4) é código MORTO p/ boot

Varredura `py_eval` da imagem 0..0x200000: endereços `0x6284` e `0x6380` **não são referenciados em lugar nenhum** (nem dados nem código). `0x6508`/`0x64A4`/`0x64D8` só aparecem nas 2 entries da tabela @0x042C. Logo o validador CRC-32 não participa do boot.

### FATO 25.21 — Os "patches" são floats IEEE-754 (limiares de troca), benignos

Ex.: `0x182ED0` = `41 B0 00 00` = **22.0** (v3) → `41 70 00 00` = **15.0** (v5). `0x184C40` = `14.0`→`26.0`. São calibrações de velocidade de troca; não são código, não crasham a app.

### CONCLUSÃO ATUALIZADA — o portão de boot é provavelmente ESTADO (EEPROM), não checksum

Com checksums consistentes (FATO 25.3) e ambas as tabelas de validação cobertas, e dado que **bytes idênticos deram resultado diferente ao longo do tempo** (v3 bootou via ELMConfig há meses; mesmo v3 não boota mais por nenhuma ferramenta), a causa mais provável é **estado persistente em EEPROM/NVM**: a app no startup compara identidade/calibração da flash contra valor gravado em EEPROM (as-built/factory). Após muitas regravações, o estado divergiu e nenhum patched casa mais.

**Próximo passo de maior ROI:** localizar no IDA a leitura de EEPROM/NVM no startup da app e a comparação que gateia operação normal (PRNDL). Alternativa pragmática: o objetivo de comportamento de troca já é atingível via config "adaptive/sport mode" do ELMConfig, sem regravação.

---

## 🔥🔥 FATO 25.22 (2026-06-22) — O PORTÃO DE BOOT FOI LOCALIZADO. É flash CRC/identidade + máscara NVM.

Análise IDA (IDB `5U75-14C337-AA.rebuilt.aligned.bin.i64`) subiu a cadeia de chamadas a partir do validador CRC-16 até a decisão de boot. O portão está na rotina de validação do **bootloader** em `0x1AFC4` (rotulada `uds_svc_11_handler`, mas é a state-machine de validação pós-reset).

### A decisão exata (gate)

```c
// 0x1AFC4 (bootloader, executa no reset/pós-flash)
v3 = sub_1938C(28, 2);            // valida conjunto de blocos máscara 0x1C = {2,3,4}
if (v3 == -1) { ...contador de falha, NRC... }
else {
    v6 = sub_16CF4() | v3;        // OR com máscara persistida em NVM/RAM-espelho
    if (v6 != 16 && v6 != 12 && v6 != 28)   // {0x10, 0x0C, 0x1C}
        *(base + 27983) = 34;     // 34 = 0x22 = conditionsNotCorrect  → app NÃO marcada válida → SEM PRNDL
}
```

**As únicas máscaras de blocos válidos aceitas são `0x0C` (blocos 2+3), `0x10` (bloco 4) e `0x1C` (blocos 2+3+4).** Qualquer outra → `0x22 conditionsNotCorrect`. Esse é **exatamente** o erro de campo ("Conditions not correct" / falha no `14 ClearDTC` pós-reset).

### Cadeia de validação por bloco (`sub_1938C` → `sub_16CD0` → `sub_1640C`)

Para cada bloco da máscara, `sub_1640C(modo, blocoBit)` faz:
- **modo 2** (identidade primária, `descritor[idx].field0`): se `*bloco != esperado` → **JUMPOUT (falha dura)**.
- **modo 1** (identidade vs `descritor[idx]+8`): se casa, **seta o bit de válido** (`0x40000000`) e adiciona o bloco a `v6`.
- **modo 3/4** (CRC-16/ARC completo via `sub_168FC`): protegido pelo **guard word `0x5365`** em `base+28740`. Modo 3 chega a **regravar/atualizar o CRC** (self-heal) quando `v2 == 0x18000000`, gravando status `0x35`/`0xCA`.

Flags do status word por bloco (`v2`, reportado via callback `BT+52`): `0x08000000` presença, `0x10000000`, `0x40000000` identidade-OK; "tudo OK" = `0xF8000000`.

### A máscara persistida (`sub_16CF4` → `sub_1707C` → `sub_17080`)

`sub_17080` é accessor sobre 4 máscaras de bits em RAM (offsets r13 ~`28832..28848`), **espelhadas de NVM**:
- caso 1 → máscara "identidade/válido" (`+28836`); caso 2 → `+28844`; caso 3 → `+28840`; caso 4 → `+28848`; caso 5/6 → clear/set bits.

Gravadas/lidas via driver de registro NVM por id de 16 bits: `sub_1D358(id, modo)` (abre p/ escrita / commit), `sub_1D8F8(id, &val)` (escreve), `sub_1D670` (dirty mask). `sub_16B30`/`sub_16BD4` gravam/leem o guard `0x5365` na NVM.

### Conclusão (refina FATO 25.21 / conclusão anterior)

O portão é **híbrido**: `v6 = (CRC/identidade da flash recém-validada) | (máscara persistida em NVM)`. Reconcilia as duas teorias:
1. **Lado flash (corrigível por patcher):** se o bloco patcheado tem **CRC-16/ARC ou identidade divergente**, não entra na máscara → `v6` sai de {0x0C,0x10,0x1C} → `0x22`. **Hipótese dominante e acionável.**
2. **Lado NVM (explica a deriva temporal):** a máscara persistida entra por OR. Após muitas regravações, o bit persistido pode ter sido limpo (`sub_17080` caso 5).

### Estratégia de patch DEFINIDA

Para um patched bootar, o patcher TEM que, para cada bloco modificado:
1. Recalcular **CRC-16/ARC** (poly 0xA001) do bloco e gravar no **trailer/descritor** comparado pelo modo 3/4.
2. Atualizar **ambas** as tabelas: `0x042C` (Block0/1) **e** `0x1047C` (Block0/1/Block3/Master/0x1F0440) — FATO 25.19. Block3 usa `field5=0x28`.
3. Manter **palavras de identidade** (modo 1 e 2) intactas — não tocar nos primeiros dwords dos blocos nem em `descritor[idx]+0/+8`.
4. Garantir que o conjunto feche em **`0x1C`** (blocos 2+3+4). Não depender do self-heal (modo 3) nem da máscara NVM.

**Não** tratar "EEPROM divergiu" como causa única: maior ROI é CRC-16+identidade corretos em flash. Se mesmo assim `v6` não fechar, o bit NVM persistido foi limpo e precisa de reescrita (restauração as-built por FORScan).

---

## 🔥🔥🔥 FATO 25.23 (2026-06-22) — O BOOT GATE É COMPARAÇÃO FLASH×NVM, NÃO CHECKSUM. O patcher é irrelevante pro boot.

Auditoria do patcher (`scripts/build_patched_firmware.py`) + RE do validador real, com verificação independente em Python sobre os `.bin`. **Refuta a parte "lado flash dominante" do FATO 25.22.**

### Prova 1 — o esquema de checksum NÃO é CRC-16/ARC sobre as ranges

Decodifiquei a tabela `0x1047C` (entries de 28 bytes) e os headers que ela aponta (`0xB700/0x10400/0x2FC00/0x180010`). Formato do header: `[+0 u16 CRC][+2 u16 nRanges][ranges (u32 start,u32 end)×N][FFFFFFFF]`. As ranges batem 1:1 com `BLOCKS` do patcher.

Mas ao computar CRC-16/ARC independente (`sub_1639C` = ARC poly 0xA001, confirmado) sobre essas ranges, **nenhum seed/target reproduz os valores de fábrica** (testado em 2 imagens stock conhecidas-boas, `5M5P-BL` e `5U75 from_phf`):
- seed exigido por bloco p/ casar `+0`: B0=0x1E9E, B1=0x05A4, B2=0x7267, B3=0x9935 → **todos diferentes**.
- `verify` (`sub_1635C`) compara o acumulador contra `header+4`, que são **metadados de endereço** (B1=0x01, B2=0x02, B3=0x18=`0x180000>>16`), não um CRC; e semeia o acumulador com `header+2` (nº de ranges).

Conclusão: o valor em `header+0` **não é** um CRC-16/ARC linear das ranges de dados → o método delta-XOR do patcher (`new_ck = old_ck XOR crc16_arc(delta,0)`) opera sobre um modelo **inválido**. O self-test do patcher (reconstrói v5 byte-a-byte) é **circular** — valida contra um v5 gerado pela própria lógica, não contra algo que o firmware aceita. Não prova nada sobre aceitação.

### Prova 2 — o validador do boot gate lê NVM e compara, não calcula CRC

`sub_1938C → sub_16CD0 → sub_1640C` (modos 3/4) chama **`sub_168FC`**, que **não é CRC**:
- chama `sub_1D358`/`sub_1D7A4`/`sub_1D424`/`sub_1D63C`/`sub_1D670` = driver de registro **NVM/EEPROM** (id de 16 bits, `v23`);
- usa o guard `0x536C2535` (`v5+28740`);
- faz loop de **comparação byte-a-byte** entre ponteiro de flash (`a1`) e buffer (`*v7`);
- `a4&0x20` → `sub_1D424` (compara flash×NVM); `a4&0x04` → `sub_1D358(id,0)` (commit NVM).

`sub_167AC` mapeia faixa de flash → descritor (tabela `BT+40`, entries de 16 bytes) com campos de id de registro NVM. Os modos de identidade (`sub_1640C` modos 1/2) comparam o **1º dword do bloco** contra valores do descritor.

**Portanto o portão de boot valida comparando a identidade/calibração da flash contra uma cópia gravada na NVM** (referência escrita na última programação "autorizada"), e não contra um CRC interno da flash. A tabela CRC `0x1047C` (driver `0x7070`) é um **scanner de integridade secundário**, provavelmente não bloqueante de boot.

### Por que casa com TODOS os sintomas
- Patched falha no boot mesmo com checksums "corrigidos": os checksums não são o portão; a calibração patcheada **não casa com a referência NVM** → bloco reprova modo 3/4 → máscara sai de {0x0C,0x10,0x1C} → **NRC 0x22** (visto em campo).
- "v3 bootou via ELM há meses, agora não": em alguma programação o caminho de **commit NVM** (`sub_168FC` `a4=5`, sob guard `0x5365`/sessão/segurança) gravou a referência; reflashes posteriores dessincronizaram.

### VEREDITO sobre o patcher
`build_patched_firmware.py` está **matematicamente correto para o que se propõe** (recalcula 5 checksums de bloco CRC-16/ARC com solve GF(2) da dependência circular Master↔Block2), porém **isso é IRRELEVANTE para o boot**. Nenhuma correção de checksum fará um patched bootar, porque o gate é identidade flash×NVM. Mexer só na flash não resolve.

### Caminhos reais (em ordem de ROI)
1. **Pragmático (sem reflash):** obter o comportamento de troca via config "adaptive/sport" do ELMConfig. Zero risco de brick. **Recomendado.**
2. **Recuperar o carro:** restaurar firmware stock + **as-built/NVM via FORScan** (reescreve a referência NVM coerente com a flash).
3. **Fazer patched bootar (alto risco/esforço):** forçar o caminho de **commit NVM** durante a programação — exige sessão+segurança e disparar o ramo `sub_168FC(a4 com bit 0x04)` sob o guard `0x5365`, provavelmente via `RoutineControl 0x31` específico (que o ELMConfig capturado NÃO envia). Requer mapear `sub_1D7A4`/`sub_1D424` e o id de registro `v23` por bloco. Só vale se (1) e (2) não atenderem.

---

## 🔥🔥🔥 FATO 25.24 (2026-06-22) — O PATCHER PODE ESTAR QUEBRANDO O BOOT AO "CORRIGIR" O CHECKSUM

### Prova: o método de checksum do patcher é inválido

Teste de linearidade entre 3 firmwares de fábrica válidos (BL/BH/CA), mesmo layout de ranges:
`stored_A XOR stored_B  ≠  crc16_arc(dataA XOR dataB, 0)` para **Block1, Block2, Block3 e Master**.
O valor em `header+0` **não** é um CRC-16/ARC linear das ranges de dados → o `new_ck = old_ck XOR crc16_arc(delta,0)` do `build_patched_firmware.py` grava **valores errados**. (Bateria de algoritmos×formatos de entrada também não reproduziu o esquema offline.)

### A identidade de boot é 4 bytes e mora no header do bloco

`sub_1640C` (modos 3/4) chama `sub_168FC(ptr, v9, **4**, ...)` → compara **apenas 4 bytes** (`*v9`, o 1º dword do bloco) contra a referência NVM (mapeada por endereço via `sub_167AC`, tabela `BT+40` com id de registro em `+12/+14`). A entry do Block3 na tabela `0x1047C` aponta para **`0x180010`** (o header `[CRC|count]`), não para os dados em `0x180100`.

Logo, `*v9 (Block3)` = `0x64900007` (stock). O patcher altera o CRC `0x6490→0x6848` → identidade vira `0x68480007` → **diverge da referência NVM** → bloco reprova → máscara fora de {0x0C,0x10,0x1C} → **NRC 0x22**.

**Os floats de calibração (0x182ED0.., 0x184B28..) ficam nos DADOS do Block3 e NÃO tocam nenhum dword de identidade.** Quem quebra o boot é a "correção" de checksum do patcher no header, não o patch em si.

### Experimento decisivo (próximo flash): `floats-only`, headers intactos

`scripts/build_floats_only.py` aplica só os floats e **deixa todos os headers/checksums byte-a-byte como stock**. Resultado: v3 difere do stock em **13 bytes**, v5 em **23 bytes**, todos em dados do Block3; `0xB700/0x10400/0x2FC00/0x180010/0x02045E` inalterados.

Predição diagnóstica:
- **Se bootar** → confirmado: as edições de checksum do patcher quebravam a identidade×NVM. Método de patch válido passa a ser "floats-only" (sem mexer em checksum).
- **Se NÃO bootar** → o portão não é a identidade do header; é check NVM/dados mais profundo → vai pro item 2/3 (commit NVM) ou encerra a via de flash.

Artefatos: `firmwares/5M5P-14C337-BL_floatsonly_v3.bin`, `..._floatsonly_v5.bin`.

---

## 🔥🔥🔥 FATO 25.25 (2026-08-02) — O CRC FOI REPRODUZIDO; O ERRO ERA UM SHIFT RUNTIME DE −4

> **Esta seção corrige as conclusões de 25.23/25.24.** O documento consolidado
> `30-checksum-state-and-open-questions.md` prevalece.

### EA e cadeia comprovada

- `block_crc_load_init @0x162F8`: carrega o init de `runtime_header+2`.
- `block_crc_update_range @0x1632C` → `crc16_arc_update @0x1639C`: atualiza
  CRC-16/ARC, poly `0xA001`, preservando o acumulador entre ranges.
- `block_crc_compare_expected @0x1635C`: compara o acumulador com
  `runtime_header+4`.
- `block_crc_engine_tick @0x16DE8`: percorre records/ranges e publica o bit de
  aprovação em `r13+0x70AC`.
- `validate_boot_blocks @0x1938C`, `0x19498`: consome esse bit.
- `uds_svc_11_handler @0x1B1C4`: máscara inválida gera NRC `0x22`.

### FATO — tradução de endereços

A engine não lê os offsets lógicos do BIN diretamente. Para os blocos transmitidos
pelo PHF:

```
byte runtime no endereço A = BIN[A-4]
```

Consequência para Block3:

```
init   = BIN[0x180010-2] = 0xFFFF
target = BIN[0x180010]   = stored_ck
dados  = BIN[start-4 : end-4+1], ranges inclusivas e em ordem
```

### Prova cruzada em três firmwares stock

| Firmware | Block2 calculado/gravado | Block3 calculado/gravado |
|----------|---------------------------|---------------------------|
| AA | `0x26A5 / 0x26A5` | `0x73A1 / 0x73A1` |
| BL | `0x804A / 0x804A` | `0x6490 / 0x6490` |
| CA | `0xFD2A / 0xFD2A` | `0x7510 / 0x7510` |

### Impacto direto no AA v3

```
modelo antigo, sem shift:
  delta=0x0CD8
  0x73A1 XOR 0x0CD8 = 0x7F79  ← ERRADO

modelo runtime correto, shift -4:
  delta=0x7C7F
  0x73A1 XOR 0x7C7F = 0x0FDE  ← CORRETO
```

Os dois flashes anteriores não isolaram NVM:

- floats-only com `0x73A1` falhou porque o checksum ficou stale;
- variante `0x7F79` falhou porque o patcher calculou sobre o stream errado.

### Próximo experimento

AA stock restaurado → AA v3 com 13 bytes de floats + Block3 `0x0FDE`, mantendo
Master `0xD8BF`, Block2 `0x26A5`, CAL ID `D8BF` e FILE CHECKSUM `0x05DF`.