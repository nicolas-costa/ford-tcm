# 20 — Diagnóstico e Correção: Formato de Record SILVEROAK PHF

**Data:** 2026-03-22  
**Status:** ✅ CORRIGIDO. Parser reescrito, binário regenerado.  
**Firmware:** 5U75-14C337-AA.rebuilt.aligned.bin

---

## Resumo Executivo

O parser SILVEROAK em `phf_parser/phf_to_bin.py` tratava os 38 bytes de cada data record como 6 bytes de header + 32 bytes de payload. Na realidade, o formato usa um **carry byte** onde o byte 31 de cada chunk de 32 bytes é transportado no campo [5] do **próximo** record. O byte [37] do record é checksum/metadata, NÃO firmware data.

1. **FATO:** 65.248 bytes (de 65.536 posições byte-31) estavam corrompidos no binário extraído
2. **FATO:** Parser corrigido. mflr: 741→850 (+109), mtlr: 697→786 (+89), stwu: 851→985 (+134)
3. **FATO:** Tabela de vetores restaurada — todas as entradas agora são `b <target>` (0x48xxxxxx)

---

## Formato Real do Record SILVEROAK

```
Record N (38 bytes):
  [0:2]   marker   0x3A 0x20
  [2:4]   offset   big-endian u16 — destino dentro do bloco de 64 KB
  [4]     tag_hi   sempre 0x00
  [5]     carry    byte 31 do chunk do record ANTERIOR
  [6:37]  data     bytes 0–30 do chunk deste record (31 bytes)
  [37]    csum     checksum/metadata — NÃO é dado do firmware
```

**Carry cross-block:** o primeiro data record do bloco N+1 carrega o byte 31 do último record do bloco N.

### Reconstrução correta de cada chunk de 32 bytes:
```
chunk[0:31]  = record_N.data[6:37]    (31 bytes)
chunk[31]    = record_{N+1}.carry[5]  (1 byte, do próximo record)
```

---

## Evidência da Descoberta

### 1. Prova nos 4 endereços corrompidos conhecidos

| Endereço | Antes (corrompido) | payload[31] | next_tag_lo | Corrigido |
|----------|-------------------|-------------|-------------|-----------|
| 0x009D5C | 0x**59**0802A6 | 0x59 | **0x7C** | 0x**7C**0802A6 (mflr r0) ✓ |
| 0x015EDC | 0x**5B**0802A6 | 0x5B | **0x7C** | 0x**7C**0802A6 (mflr r0) ✓ |
| 0x015FDC | 0x**5B**0803A6 | 0x5B | **0x7C** | 0x**7C**0803A6 (mtlr r0) ✓ |
| 0x01629C | 0x**25**21FFF8 | 0x25 | **0x94** | 0x**94**21FFF8 (stwu r1,-8(r1)) ✓ |

### 2. Tabela de vetores restaurada

```
Antes:                          Depois:
0x0018: 0x60000000              0x0018: 0x60000000
0x001C: 0x38000022  ← lixo     0x001C: 0x48000022  ← b 0x22  ✓
0x003C: 0xD40087D2  ← lixo     0x003C: 0x480087D2  ← b 0x87D2 ✓
```

### 3. Impacto quantitativo

| Métrica | Antes | Depois | Delta |
|---------|-------|--------|-------|
| mflr r0 (4-byte aligned) | 741 | 850 | +109 |
| mtlr r0 (4-byte aligned) | 697 | 786 | +89 |
| stwu r1 (4-byte aligned) | 851 | 985 | +134 |
| Bytes corrigidos no total | — | — | **65.248** |

---

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `firmwares/5U75-14C337-AA.from_phf.bin` | Binário extraído CORRIGIDO |
| `firmwares/5U75-14C337-AA.from_phf.OLD.bin` | Backup do binário com bug |
| `samples/SILVEROAK/5U75-14C337-AA.rebuilt.aligned.bin` | Binário para IDA CORRIGIDO |
| `samples/SILVEROAK/5U75-14C337-AA.rebuilt.aligned.OLD.bin` | Backup do IDA binary |

---

## Próximo Passo

Recarregar `5U75-14C337-AA.rebuilt.aligned.bin` no IDA Pro e re-analisar. As 73 "instruções impossíveis" devem desaparecer.

---

**FIM DO DOCUMENTO**
