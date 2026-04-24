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