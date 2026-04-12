# 25 — Flash Block Checksum: Análise e Achados Parciais

**Data:** 2026-03-22  
**Status:** 🔶 Estrutura dos block headers mapeada. Algoritmo exato **NÃO identificado**. CRC-32 encontrado no firmware mas não bate com valores armazenados.  
**Dependência:** Binários AA e BL convertidos (doc 20)

---

## Resumo Executivo

1. **FATO:** 4 block headers encontrados no binário, todos com marcador `0000 FFFF` seguido de 2 bytes de checksum + 2 bytes de tipo + range descriptors (start/end address pairs).
2. **FATO:** Função CRC-32 identificada em `sub_77B4` (ROM @ 0x77B4), polinômio 0x04C11DB7 (CRC-32/MPEG-2), tabela de lookup em 0x77F8 (256 entries). Usada pelo validador em `loc_6284`.
3. **FATO:** 14+ algoritmos testados (sum16, ~sum16+1, CRC-16 CCITT/IBM, CRC-32 padrão/firmware table/chained, Fletcher-16, XOR-16, Adler-16, Internet Checksum RFC 1071, byte sum, 32→16 fold). **Nenhum match** em nenhuma combinação de range.
4. **Próximo passo:** Testar flash com ELMConfig (que provavelmente recalcula checksums) usando firmware cobaia (AA). Alternativa: consultar pcmhacking.net para algoritmo específico Ford/Continental.

---

## Block Headers Encontrados

### Estrutura comum

```
[FF FF FF FF]*N  [00 00 FF FF]  [CK CK] [TT TT]  [START1] [END1]  [START2] [END2]
```

- `0000 FFFF` = marcador de block válido (flash programada)
- `CK CK` = 2 bytes de checksum (varia com dados)
- `TT TT` = 2 bytes de tipo/número (constante entre AA e BL)
- `START/END` = endereços 32-bit dos ranges cobertos

### Tabela de Blocks

| Block | Header EA | Checksum AA | Checksum BL | Tipo | Range 1 | Range 2 |
|-------|-----------|-------------|-------------|------|---------|---------|
| 0 (boot) | 0x00B700 | 0x3B67 | 0x3B67 | 0x0001 | 0x000000-0x00A137 | — (0xFFFFFFFF) |
| 1 (code) | 0x010400 | 0x2562 | 0x2562 | 0x0002 | 0x010010-0x010311 | 0x010480-0x01FA4B |
| 2 (code/data) | 0x02FC00 | 0x26A5 | 0x804A | 0x0013 | 0x020400-0x02FA67 | 0x030000-0x03FFFF |
| 3 (calibração) | 0x180010 | 0x73A1 | 0x6490 | 0x0007 | 0x180100-0x18FFFF | 0x190000-0x19FFFF |

**Observação:** Blocks 0 e 1 são idênticos entre AA e BL (mesmo código). Blocks 2 e 3 diferem (calibração e part numbers).

### Master Checksum

| EA | Checksum AA | Checksum BL | Const | Range 1 | Range 2 | Count |
|----|-------------|-------------|-------|---------|---------|-------|
| 0x02045E | 0xD8BF | 0xFCF5 | 0x4D10 | 0x020460-0x17FFFE | 0x180000-0x1EFFFE | 2 |

O master checksum cobre AMBOS os ranges de código e calibração.

---

## CRC-32 no Firmware

### Função `sub_77B4` (ROM @ 0x77B4)

```
Parâmetros PPC:
  r3 = ponteiro para dados
  r4 = comprimento em bytes
  r5 = CRC inicial (passado pelo chamador)
Retorno:
  r3 = CRC-32 computado

Algoritmo: MSB-first, shift-left, lookup table
  loop:
    index = ((CRC >> 24) ^ byte) & 0xFF
    CRC = (CRC << 8) ^ TABLE[index]
```

### Tabela de Lookup

- **Endereço:** 0x77F8 (256 entries × 4 bytes = 1024 bytes)
- **Polinômio:** 0x04C11DB7 (CRC-32 standard / MPEG-2)
- **Nota:** O código referencia `0x77FC` (entry[1]), não `0x77F8` (entry[0] = 0). Entry[0] da tabela padrão (0x00000000) está em 0x77F8, que o IDA marcou como fim da função anterior. O código pula entry[0] — implicação: quando `index = 0`, o lookup retorna `0x04C11DB7` (polinômio) em vez de `0x00000000` (identidade). Isso altera fundamentalmente o CRC computado vs. CRC-32/MPEG-2 padrão.

### Validador `loc_6284` (ROM @ 0x6284)

```
Variáveis em RAM:
  0x3FFD5C = posição atual dos dados
  0x3FFD60 = endereço final dos dados
  0x3FFD64 = CRC acumulador (atualizado a cada 256 bytes)
  0x3FFD68 = CRC esperado (para comparação final)

Fluxo:
  1. Processa dados em chunks de 256 bytes via sub_77B4
  2. Chunk final: length = (end - current) + 1 (range é inclusivo)
  3. Compara CRC computado vs esperado em 0x3FFD68
  4. Match → sucesso (0xA0) → jump para código em RAM 0x3F901C
  5. Mismatch → falha (0x92) → sinaliza erro
```

### Setup `sub_6380` (ROM @ 0x6380)

```
Popula variáveis do validador a partir de estrutura em RAM 0x3F9000:
  *(0x3FFD5C) = *(0x3F900C)   → start address
  *(0x3FFD60) = *(0x3F9010)   → end address
  *(0x3FFD64) = *(0x3F9000)   → CRC inicial
  *(0x3FFD68) = *(0x3F9004)   → CRC esperado

Antes de iniciar, compara string @ ROM 0xBA00 ("FT300") com *(0x3F9014)
para validar que o bloco é do módulo correto.
```

**DESCONHECIDO:** Quem popula a estrutura em 0x3F9000. Provavelmente código de boot que escaneia os block headers, ou valores injetados pela ferramenta de programação via UDS.

---

## Algoritmos Testados (Nenhum Match)

| # | Algoritmo | Init/Variação | Ranges Testados |
|---|-----------|--------------|-----------------|
| 1 | sum16 (big-endian words) | — | R1, R2, R1+R2, full block, excl header |
| 2 | ~sum16+1 (2's complement) | — | Idem |
| 3 | sum8 (byte sum) mod 16 | — | Idem |
| 4 | CRC-16/CCITT | init=0xFFFF, 0x0000 | R1, R2, R1+R2, header+data |
| 5 | CRC-16/IBM | init=0x0000 | Idem |
| 6 | CRC-32/MPEG-2 (standard table) | init=0xFFFFFFFF, 0x0 | Idem, + chained blocks |
| 7 | CRC-32 (firmware table @ 0x77FC) | init=0xFFFFFFFF, 0x0, block values | Idem |
| 8 | CRC-32 chained (output→input) | Forward + reverse order | Todos os 4 blocks |
| 9 | Fletcher-16 | — | R1+R2, R1 |
| 10 | XOR-16 | — | R1+R2, R1 |
| 11 | Adler-16 | — | R1+R2 |
| 12 | Internet Checksum (RFC 1071) | — | R1+R2, header+data |
| 13 | 32-bit sum → 16-bit fold | lo16, hi16, fold, complement | R1+R2 |
| 14 | Zero-sum (sum incl. checksum = const?) | — | Full block, multiple ranges |

Nenhum algoritmo produziu o valor `0x73A1` (AA) ou `0x6490` (BL) para QUALQUER combinação de range.

---

## Comparação AA vs BL

### Diff Global

- **Total de bytes diferentes:** 329 / 2,097,152 (0.02%)
- **Regiões contíguas diferentes:** 106

### Categorias de Diferenças

| Categoria | Offsets | Descrição |
|-----------|---------|-----------|
| Part numbers | 0x020200-0x020260 | `5U75-14C337-AA` → `5M5P-14C337-BL`, engenheiro `GKOWALCZ` → `ALAZOS` |
| Checksums | 0x02045E, 0x02FC00, 0x180010 | 2 bytes cada (ver tabela de blocks acima) |
| Cal ID | 0x180010 | Checksum do bloco de calibração |
| Tabela Aux A | 0x185330 (12 pairs) | Provável TCC lockup schedule — BL tem primeiros 5 rows zerados |
| Tabela Aux B | 0x185400 (12 pairs) | Provável speed limiter — BL tem primeiros 7 rows zerados |

### Itens 100% Idênticos entre AA e BL

- **10 shift schedule tables** (0x184B10-0x184EC4) — TODAS idênticas
- **Gear ratios** (0x189700) — idênticos
- **Torque converter curve** (0x18AD10) — idêntica
- **Todo o código** (blocks 0 e 1) — idêntico

---

## Opções para Prosseguir

| Opção | Risco | Descrição |
|-------|-------|-----------|
| **A. Confiar no ELMConfig** | Baixo | A maioria das ferramentas Ford recalcula checksums automaticamente durante flash |
| **B. Testar no cobaia (AA)** | Baixo | Modificar 1 byte, flashear via ELMConfig, ler de volta e verificar se checksum foi corrigido |
| **C. Bypass no firmware** | Alto | Patchar `bne` em 0x6324 para `b` (forçar sucesso). Problema: está no boot block (Block 0), que tem seu próprio checksum |
| **D. Consultar comunidade** | — | pcmhacking.net, FORScan forum, UCDS wiki têm threads sobre Ford checksums |

**Recomendação:** Opção B (testar com cobaia) antes de qualquer alteração no BL.
