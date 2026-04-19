# 28 — UDS Services & SecurityAccess: Análise Completa

**Data:** 2026-04-19  
**Status:** ✅ Algoritmo de SecurityAccess reverso e implementado. Aguardando validação on-target.  
**Dependência:** Firmware AA (IDB com funções nomeadas)

---

## Resumo Executivo

1. **FATO:** O dispatcher UDS está em `0x0B51BC`. Compara `r5` (service ID) e despacha via `blrl` indireto. Serviços mapeados: 0x27, 0x28, 0x2F, 0x34, 0x36, 0x37, 0x3E, 0x85, 0xA0, 0xA1, 0xB1.
2. **FATO:** SecurityAccess (0x27) usa state machine em RAM `0x3FDC51` (state: 0=fresh, 1=seed_sent, 2=authenticated). Seed armazenado em RAM `0x3FDC58`.
3. **FATO:** Algoritmo de key = LFSR 24-bit com 5 taps XOR, 2 rounds de 32 iterações. Constantes: `S_init=0x00C541A9`, input\_magic=`0x45444F49` ("EDOI"). Implementado e validado contra disassembly IDA.
4. **Próximo passo:** Testar unlock live via ELM327 → se positivo, logging de RAM shift slots em tempo real.

---

## 1. UDS Service Dispatcher

**Endereço:** `0x0B51BC` (dentro de função maior, não é o entry point)

O dispatcher recebe o service ID em `r5` e o sub-function em `0x1A(r1)`. Sequência de comparações:

| Service ID | Nome | Handler | Observação |
|-----------|------|---------|------------|
| `0x27` | SecurityAccess | `0x0B5F60` (`uds_security_access_handler`) | Sub 0x03=seed, 0x04=key |
| `0x28` | ? | `0x0B709C` | Não investigado |
| `0x2F` | IOControlByIdentifier | `0x0B6128` | Sub 0xE9 apenas |
| `0x34` | RequestDownload | `0x0B6B94` | Flash programming |
| `0x36` | TransferData | `0x0B6DAC` | Flash programming |
| `0x37` | RequestTransferExit | `0x0B701C` | Flash programming |
| `0x3E` | TesterPresent | inline `0x0B5394` | — |
| `0x85` | Ford proprietary | inline `0x0B52E4` | Lê RAM `0x40DA9E` |
| `0xA0` | Ford proprietary | `0x0B535C` | — |
| `0xA1` | Ford proprietary | `0x0B5378` | — |
| `0xB1` | Ford proprietary | `0x0B5400` | — |

**Evidência (dispatcher):**
```
0B51BC: cmpwi   r5, 0x27
0B51C0: bne     0x0B51F4
0B51C4: lbz     r31, 0x1A(r1)    ; sub-function
0B51C8: cmpwi   r31, 0x3         ; requestSeed?
0B51CC: beq     0x0B51D8
0B51D0: cmpwi   r31, 0x4         ; sendKey?
0B51D4: bne     0x0B51F4
0B51D8: lis     r12, sub_B5F60@ha
0B51DC: addi    r12, r12, sub_B5F60@l
0B51E0: mtlr    r12
0B51E4: addi    r3, r1, 0x18     ; request buffer
0B51E8: addi    r4, r1, 0x10     ; response buffer
0B51EC: blrl
```

---

## 2. SecurityAccess Handler (`uds_security_access_handler` @ 0x0B5F60)

### State Machine

RAM `0x3FDC51` (1 byte):
- **State 0** (fresh): aceita sub=0x03 (requestSeed). Gera seed, envia, transita para state 1.
- **State 1** (seed\_sent): aceita sub=0x04 (sendKey). Compara key recebida com esperada.
  - Match → state 2, resposta positiva `67 04`.
  - Mismatch → state 0, NRC `0x35` (invalidKey).
- **State 2** (authenticated): se sub=0x03, retorna seed zero (já autenticado).

### Seed Generation

1. Chama `security_seed_generate` (`sub_BD1D4`) → retorna 32-bit em `r3`.
2. Extrai 3 bytes (MSB) do retorno: `seed[0]` = byte0, `seed[1]` = byte1, `seed[2]` = byte2.
3. Armazena em RAM `0x3FDC58` como: `seed[0] | (seed[1] << 8) | (seed[2] << 16)`.
4. Resposta UDS: `67 03 seed[0] seed[1] seed[2]`.

**Evidência (armazenamento do seed):**
```
; IDA disassembly @ 0xB5FE4-0xB5FF8:
b5fe4  slwi      r9, r28, 8         ; r9 = seed[1] << 8
b5fe8  or        r9, r30, r9        ; r9 = seed[0] | (seed[1] << 8)
b5fec  slwi      r12, r27, 16       ; r12 = seed[2] << 16
b5ff4  or        r9, r9, r12        ; r9 = seed[0] | (s1<<8) | (s2<<16)
b5ff8  stw       r9, -0x23A8(r10)   ; *(0x3FDC58) = r9
```

### Key Verification

1. Extrai 3-byte key do request: `key_recv = (k0 << 16) | (k1 << 8) | k2`.
2. Chama `security_key_compute` (`sub_B5E00`) → retorna 24-bit expected key em `r3`.
3. Compara: `cmplw r27, r28` (received vs expected).

---

## 3. Key Computation Algorithm (`security_key_compute` @ 0x0B5E00)

### Constantes

| Valor | Uso |
|-------|-----|
| `0x00C541A9` | Estado inicial do LFSR (S) |
| `0x44000000` | OR'd com stored seed para input[0] |
| `0x45444F49` | Input[1] fixo (ASCII "EDOI") |

### Estrutura

```
S = 0x00C541A9                              ; 32-bit state register
inputs = [stored_seed | 0x44000000,         ; round 0
          0x45444F49]                        ; round 1

for each input_word in inputs:
    for bit = 0..31:
        feedback = (input_word & 1) XOR (S & 1)
        S = (feedback << 23) | (S >> 1)

        ; 5 XOR taps on specific bit positions of S:
        S.byte1.bit4 ^= S.byte1.bit7       ; tap 1
        S.byte2.bit7 ^= S.byte1.bit7       ; tap 2 (reads updated byte1)
        S.byte2.bit4 ^= S.byte1.bit7       ; tap 3
        S.byte3.bit5 ^= S.byte1.bit7       ; tap 4
        S.byte3.bit3 ^= S.byte1.bit7       ; tap 5

        input_word >>= 1

; Final bit shuffle:
key = shuffle(S)  ; rlwinm-based bit extraction and OR
```

### Byte Layout de S (big-endian em stack)

- `byte0` = MSB = `(S >> 24) & 0xFF` — stack+0x08
- `byte1` = `(S >> 16) & 0xFF` — stack+0x09 (source de bit7 para todos os taps)
- `byte2` = `(S >> 8) & 0xFF` — stack+0x0A
- `byte3` = LSB = `S & 0xFF` — stack+0x0B (feedback source)

### Final Shuffle

Instrução IDA → operação:

| Instr | Operação |
|-------|----------|
| `rlwinm r11, r3, 12, 8, 15` | Bits 20..27 de S → posição 8..15 |
| `rlwinm r10, r3, 0, 16, 19` | Bits 16..19 de S (mask 0xF000) |
| `rlwinm r12, r3, 20, 20, 23` | Bits 0..3 de S → posição 20..23 |
| `clrlslwi r10, r3, 28, 4` | Bits 28..31 de S → shift left 4 |
| `extrwi r12, r3, 4, 12` | Bits 12..15 de S → posição 28..31 |
| `or r3, r11, r12` | Combina todos |

---

## 4. Resultados do Probe UDS (On-Target, 2026-04-19)

TCM target: `5U75-14C337-AA` (firmware BL flasheado), ELM327 v1.5 clone, CAN 500kbps.

### Serviços Testados

| Service | Resultado | NRC |
|---------|-----------|-----|
| 0x10 (Session) | REJEITADO | 0x22 (conditionsNotCorrect) |
| 0x19 (ReadDTC) | REJEITADO | 0x11 (serviceNotSupported) |
| 0x22 (ReadDID) | 6 DIDs OK | — |
| 0x23 (ReadMem) | BLOQUEADO | 0x31 (requestOutOfRange) |
| 0x27 level 0x03 | **SEED OK** | — |
| 0x27 level 0x01 | REJEITADO | 0x11 |
| 0x3E (Tester) | NO DATA | — |

### DIDs Encontrados (0x22)

| DID | Bytes | Valor (parado) | Tipo provável |
|-----|-------|-----------------|---------------|
| 0x0100 | 1 | 0x03 | Estático (config) |
| 0x0101 | 2 | 0x0014 (=20) | Estático (temp? subiu 19→20 entre runs) |
| 0x0200 | 1 | 0x00 | Estático (não mudou dirigindo) |
| 0x0202 | 1 | 0x00 | Estático (não mudou dirigindo) |
| 0xD100 | 1 | 0x81 | Estático (status byte) |
| 0xD10B | 1 | ~164 (oscila) | Sensor analógico (bateria?) |

**FATO:** Nenhum DID reagiu a mudanças físicas (velocidade, marcha, throttle, seletor P/R/N/D). São dados de configuração, não telemetria live.

### Seed Capturado

```
27 03 → 67 03 0F 26 AD
```

Seed: `0F 26 AD` (3 bytes). Key computada: `CD 93 1E`.

---

## 5. Implementação Python

Script: `scripts/tcm_slot_logger.py`

Função `compute_security_key(seed)`:
- Input: lista de 3 bytes (seed do TCM)
- Output: lista de 3 bytes (key para enviar)
- Validado contra disassembly IDA instrução por instrução

Fluxo do script:
1. Init ELM327 (CAN 500kbps, header 7E1, filtro 7E9)
2. `27 03` → recebe seed
3. `compute_security_key(seed)` → calcula key
4. `27 04 <key>` → desbloqueia
5. `23 14 <addr> <size>` → lê RAM
6. Logging contínuo (slots, gear, speed, flag, input float) → CSV

---

## 6. Funções IDA Nomeadas

| Endereço | Nome IDA | Papel |
|----------|----------|-------|
| `0x0B5E00` | `security_key_compute` | LFSR key computation |
| `0x0B5F60` | `uds_security_access_handler` | Handler 0x27 (state machine + seed + key verify) |
| `0x0BD1D4` | `security_seed_generate` | Gerador de seed (retorna 32-bit) |

---

## 7. RAM Addresses (SecurityAccess)

| Endereço | Tamanho | Papel |
|----------|---------|-------|
| `0x3FDC51` | 1 byte | Security state (0/1/2) |
| `0x3FDC58` | 4 bytes | Stored seed: `s0 \| (s1<<8) \| (s2<<16)` |
| `0x3FDC5C` | 4 bytes | Stored key (após auth bem-sucedida) |
| `0x3FDC50` | 1 byte | IOControl checksum byte (service 0x2F) |
