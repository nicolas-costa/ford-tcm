# 28 — UDS Services & SecurityAccess: Análise Completa

**Data:** 2026-04-19 (inicial), 2026-04-21 (atualização: falha em bootloader), 2026-06-22 (BREAKTHROUGH: L3 aceito em 10 85)  
**Status:**
- ✅ Algoritmo da APLICAÇÃO (firmware AA) reverso, implementado e validado contra vetor `0F26AD→CD931E`.
- ❌ Algoritmo NÃO funciona contra o bootloader/recovery atual (ver §8). L1 e L3 testadas, ambas rejeitadas.
- ✅ **(2026-06-22) Algoritmo L3 FUNCIONA na APLICAÇÃO AA dentro da sessão `10 85` (programming). Ver §11.**  
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

---

## 8. FATO — Algoritmo NÃO cobre estado pós-flash (bootloader/recovery)

**Data:** 2026-04-21  
**Contexto:** TCM em estado pós-flash v5 fracassado, rodando em bootloader/recovery (não em aplicação).

### Evidência direta (tcm_recovery logs, 12:13:02–12:18:06)

| Service | Request | Response | Interpretação |
|---------|---------|----------|---------------|
| `22 F186` | ActiveDiagSession | `7F 22 11` | DID padrão não implementado |
| `22 F195/F190/F18C/F100/F124` | ISO DIDs | `7F 22 11` | Nenhum DID ISO responde |
| `10 60` | Ford diag | `7F 10 22` | Rejeitado |
| `10 81` | Ford proprietary | `50 81` | **POSITIVO** |
| `10 82` | Ford proprietary | `7F 10 22` | Rejeitado |
| `10 85` | Ford proprietary | `50 85` | **POSITIVO** |
| `27 01` | RequestSeed L1 | `67 01 28 7A B4` | Seed entregue |
| `27 03` | RequestSeed L3 | `67 03 E0 7E 33` | Seed entregue |

### FATO 8.1 — Algoritmo do doc 28 rejeitado em L1 E L3

Seeds capturados e keys rejeitadas usando `tcm_recovery/security.py` (self-test contra vetor de referência AA `0F26AD → CD931E` passa):

| Nível | Seed | Key computada | Resposta do TCM |
|-------|------|---------------|-----------------|
| L3 | `E0 7E 33` | `D6 59 C4` | `7F 27 35 (InvalidKey)` |
| L1 | `28 7A B4` | `D3 26 07` | `7F 27 35 (InvalidKey)` |

**Impacto:** o algoritmo reverso de `sub_0B5E00` (aplicação AA) **não** desbloqueia o TCM no estado atual.

### FATO 8.2 — Estado atual é bootloader, não aplicação

DIDs da aplicação (`0x0100/0x0101/0x0200/0x0202/0xD100/0xD10B`) documentados na seção 4 **não foram testados neste run**, mas o padrão atual é:

- ISO-standard DIDs todos retornam `0x11`.
- Serviço `0x22` responde mas rejeita tudo.
- Sessão canônica `0x01/0x02/0x03` rejeitada por `0x22` — aplicação sempre aceita `10 01`.
- Sessões proprietárias Ford `0x81/0x85` aceitas.

Esse perfil é consistente com **bootloader isolado** (não com aplicação travada). Bootloaders Ford Silveroak possuem stack UDS própria, normalmente com algoritmo de SecurityAccess **distinto** do aplicativo.

### HIPÓTESE 8.3 — Bootloader tem função de key separada

- **HIPÓTESE:** existe uma função `security_key_compute` dentro do bootloader (região protegida, **não** incluída no PHF de aplicação).
- Lastro: duas chaves computadas via doc 28 (AA app) rejeitadas; doc 28 vetor de referência **passa** o self-test, então nossa implementação da versão-aplicação está correta.

### DESCONHECIDO 8.4

- Endereço/bytes do bootloader (não mapeado em IDA, não presente em `5U75-14C337-AA.bin`).
- Se o algoritmo do bootloader é uma variação de constantes (`S_init`, `input_magic`) ou estrutura diferente.
- Se os níveis L1/L3 do bootloader compartilham função ou são independentes.

### Contador de tentativas

**2 tentativas de SecurityAccess falhadas** neste ciclo (L3 `D6 59 C4`, L1 `D3 26 07`). Ford tipicamente permite 3 antes de `NRC 0x36 (exceededAttempts)` → `0x37 (requiredTimeDelay)`.

**Regra operacional:** não enviar mais `27 02/04 <key>` contra este TCM usando algoritmo AA. Próximo erro pode travar por minutos/horas.

### Próximo passo de maior ROI

1. **STOP** com clone ELM327 + algoritmo AA.
2. Opção A: OpenPort + FORScan Extended ou Ford IDS/SDD (algoritmo do bootloader embarcado nessas ferramentas).
3. Opção B: obter dump do bootloader Silveroak (JTAG/BDM em outro TCM-doador, ou arquivo de outra fonte) e reverter a função equivalente.

---

## 9. FATO — Corroboração externa (fórum russo, PCM Ford 2017)

**Fonte:** post comunitário (autor `mag1061`, 2017-04-10) sobre flash de PCM Ford via IDS.

### Evidência: sequência UDS canônica Ford (transcrição literal)

```
7E0 02 10 85          -> 7E8 02 50 85            ; entra em sessão programação
7E0 02 27 01          -> 7E8 05 67 01 5C 67 EB   ; seed
7E0 05 27 02 0D CE 85 -> 7E8 02 67 02            ; key OK
7E0 04 B1 00 B2 01    -> 7E8 03 7F B1 78 (x N)   ; Ford-proprietary erase (responsePending)
                      -> 7E8 03 F1 00 B2 00      ; erase done
7E0 10 09 34 00 84 00 -> 7E8 30 00 ...           ; RequestDownload @ 0x00840000
7E0 21 03 D1 C0                                  ;   length 0x0003D1C0
                      -> 7E8 03 74 00 FC         ; ready, block size 0xFC
7E0 10 FC 36 ...      -> 7E8 30 00 ...           ; TransferData loop
...
7E0 01 37             -> 7E8 03 7F 37 78 ...     ; RequestTransferExit
                      -> 7E8 01 77               ; transfer complete
```

### FATO 9.1 — A sessão correta é `0x85`, não `0x02`

Post explicitamente usa `10 85`. Bate com nossa evidência empírica (§8). Sessão ISO `0x02` não é o caminho Ford para módulos Silveroak.

### FATO 9.2 — SecurityAccess Level 1 (`27 01/02`), não Level 3

Post confirma: após `10 85`, o unlock é via `27 01 → 67 01 <seed>` → `27 02 <key> → 67 02`. Level 3 (`27 03/04`) não aparece no flow canônico de programação Ford para módulos tipo este. Nossa confusão doc 28 sobre usar L3 vem do fato de que a aplicação AA **também** implementa L3 (para outros fins, provavelmente IO control/bench), mas a flash usa **L1**.

### FATO 9.3 — Serviço `B1` é o ERASE proprietário Ford

Post: `B1 00 B2 01` dispara erase. Payload:
- `B1` = service ID
- `00 B2` = sub/selector
- `01` = segmento

Isso **é** o `B1` que doc 18 §8 identificou como Ford-proprietário em `0x0B5400` (aplicação). Bootloader tem seu próprio handler de `B1`. Por isso nossa strategy I (`31 01 FF 01 CheckProgDep`) foi rejeitada — bootloader não usa `31`; usa `B1`.

### FATO 9.4 — Algoritmo de key é POR MÓDULO

Vetor do post (PCM): seed `5C 67 EB` → key `0D CE 85`.  
Nossa implementação (algoritmo TCM app AA): mesmo seed → key `53 E0 E9`. **Mismatch.**

Prova: PCM e TCM têm algoritmos **diferentes**. Nossa implementação está correta para TCM aplicação (self-test vector `0F26AD→CD931E` passa). TCM bootloader é **outro algoritmo ainda**, não disponível para nós.

### FATO 9.5 — Estado pós-falha é "erased, awaiting flash"

Tradução literal: "Se durante a programação a sequência estrita for violada ou dados mal enviados, o módulo retorna 'vá se ferrar' e é considerado caído/tijolo **até você carregar corretamente toda a flash e seus parâmetros**."

Esse **é** o estado atual do nosso TCM. Só sai dele com flash completa e válida entregue pelo caminho correto (`10 85` → `27 01/02` → `B1 erase` → `34` → `36 ×N` → `37` → `77`).

### HIPÓTESE 9.6 — Secondary bootloader pode ser obrigatório

Post observa: "В данном случае PCM умеет себя сам стирать без загрузки secondary bootloader. Подавляющее большинство модулей такую загрузку требуют." ("Este PCM apaga a si mesmo sem carregar secondary bootloader. A esmagadora maioria dos módulos exige.")

**HIPÓTESE:** TCM 4F27E Silveroak pode exigir upload de stub "secondary bootloader" antes de `B1 erase`. ELMConfig faz isso na sessão bem-sucedida, não na fracassada. FORScan/IDS sabem.  
**DESCONHECIDO:** qual stub, de onde vem, se está embarcado no PHF ou no software.

### Consequência operacional

1. Bootloader TCM tem algoritmo de key distinto tanto da aplicação quanto do PCM.
2. Sem o algoritmo, nenhum clone ELM327 resolve.
3. Recuperação viável: OpenPort + FORScan Extended (ou Ford IDS/SDD) fazem a sequência completa incluindo secondary bootloader + key correta.

---

## 10. FATO — Power cycle de ignição é parte do protocolo de flash

**Data:** 2026-04-24  
**Fonte:** observação empírica em FORScan (versão privada, fórum) durante recuperação bem-sucedida do TCM AA via ELM327 USB clone.

### Evidência

FORScan privado **exige** ciclo de ignição OFF/ON em **dois** pontos do procedimento:
- **Antes** de iniciar o flash (após selecionar o PHF, antes de enviar qualquer comando UDS).
- **Depois** do flash completar (após `37/77`, antes de tentar reativar a sessão normal).

ELMConfig **não** solicita esses ciclos. ELMConfig falhou consistentemente no passo final ("Rebooting…") com `7F 11 80`. FORScan privado, com os mesmos PHFs e mesmo adaptador, completou com sucesso.

### FATO 10.1 — `11 01` (ECU Reset) não substitui power cycle

NRC `0x80` retornado pelo bootloader em `11 01` (ver §8) é **literalmente** "não me reseta por software, exijo power cycle". Bootloader Ford Silveroak depende de reset por hardware para:
- Re-ler flag NVRAM "novo firmware candidato"
- Recomputar checksums dos blocos recém-gravados
- Decidir se faz boot na nova aplicação ou volta ao modo recovery

### FATO 10.2 — Power cycle pré-flash é precondição para `10 85`

Sem ciclo prévio:
- State machine UDS herda contexto da última sessão diagnóstica
- Watchdog de sessão pode estar em estado inválido
- Bootloader pode rejeitar `10 85` mesmo com adaptador e payload corretos

Com ciclo prévio:
- ECU em "cold boot" determinístico
- Bootloader entra em modo "programming-receptive"
- `10 85` aceito limpo

### FATO 10.3 — Falha do ELMConfig é coerente com ausência de ciclo final

Sequência observada (reconstruída):
1. ELMConfig escreve blocos via `34/36/37` corretamente.
2. Sem ciclo, envia `11 01` para "reativar".
3. Bootloader recusa (`7F 11 80`) porque exige power cycle.
4. ELMConfig reporta erro mas a flash já foi parcialmente confirmada (writes feitos).
5. Estado: bytes na flash + flag NVRAM em "pendente" + bootloader esperando ciclo.
6. Usuário desliga ignição achando que vai resetar — o ciclo, neste momento, **comprova** o flag pendente. Bootloader tenta dar boot, falha por checksum/integridade (porque ELMConfig pode também ter falhado em escrever os checksums corretos), entra em recovery permanente.

### Impacto operacional

Qualquer ferramenta de flash para este TCM (incluindo nossa próxima tentativa com OpenPort) **precisa** instruir o operador a:
- Cycle OFF/ON antes de iniciar
- Cycle OFF/ON depois de `37/77`

Não é UX, é protocolo.

### Conexão com §9.5 ("erased, awaiting flash")

A "sequência estrita" mencionada no fórum russo **inclui** os power cycles. Sem eles, o módulo trava no estado descrito em §9.5 mesmo se cada comando UDS individual estiver correto.

---

## 11. BREAKTHROUGH — L3 aceito na APLICAÇÃO dentro de `10 85` (2026-06-22)

**Contexto:** TCM rodando AA stock (recuperado), motor parado, ignição ON. Probe via `tcm_recovery/test_l3_programming_session.py` com ELM327 USB (Windows).

### FATO 11.1 — Sequência atômica bem-sucedida

```
10 85           → 50 85            (programming session aceita pela APLICAÇÃO)
27 03           → 67 03 04 85 E5   (seed L3)
27 04 ED E3 58  → 67 04            (KEY ACEITA — autenticado)
```

Key computada por `compute_security_key([0x04,0x85,0xE5])` = `ED E3 58`, validada e aceita pelo TCM.

### FATO 11.2 — Timing do seed é crítico

Primeira tentativa falhou com `NRC 0x22 (conditionsNotCorrect)` porque havia um prompt interativo entre `27 03` e `27 04`, causando expiração do seed (janela ~2-5s). `NRC 0x22` aqui **não** é falha de algoritmo nem de pré-condição de veículo — é seed expirado. Corrigido tornando a sequência `10 85 → 27 03 → 27 04` atômica (sem pausa).

**Regra:** o flasher deve enviar a key imediatamente após receber o seed, sem qualquer I/O bloqueante no meio.

### FATO 11.3 — Implicação estratégica

A APLICAÇÃO (não o bootloader) processa `10 85` + L3. Isso significa:

1. **NÃO precisamos do algoritmo de SecurityAccess do bootloader** (§8 fica como beco documentado, não bloqueante).
2. **NÃO precisamos reverter o ELMConfig** para extrair auth.
3. O caminho de flash via Python passa pela **aplicação**, usando o algoritmo que já temos (`sub_B5E00`, doc 28 §3).

### O que ainda NÃO está provado (riscos abertos para o flasher)

| # | Pergunta | Risco | Como testar (não-destrutivo possível?) |
|---|----------|-------|----------------------------------------|
| 1 | `B1` (erase) é aceito nessa sessão pós-auth? | Alto | Parcialmente — `B1` com seletor inválido pode retornar NRC sem apagar (a confirmar) |
| 2 | `34/36/37` transfer funciona via aplicação? | Alto | Só testável com erase já feito (destrutivo) |
| 3 | O hook `blrl 0x3F901C` (doc 29) é acionado nesse path? | Médio | Requer análise IDA do handler 0x34/0xB1 da aplicação |
| 4 | Pós-flash, qual validação de boot? (Block3 CRC-16 basta?) | Médio | FATO 25.11 sugere que sim (ELMConfig provou) |
| 5 | Power cycle orquestrável via script? | Baixo | Operador faz manual entre fases |

### Próximo passo de menor risco

Antes de qualquer comando destrutivo, **mapear em IDA o handler do serviço `0x34` (RequestDownload) e `0xB1` da aplicação** (dispatcher 0xB51BC → 0x0B6B94 para 0x34, 0x0B5400 para 0xB1). Objetivo: descobrir se a aplicação faz o flash nativamente OU se ela espera o hook do secondary bootloader (0x3F901C). Isso determina se precisamos de stub ou não — sem tocar no hardware.
