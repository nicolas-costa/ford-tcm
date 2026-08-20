# 29 — Secondary Bootloader Hook & Implicação no Flash Protocol

**Data:** 2026-06-21
**Status:** Descoberta — explica a divergência ELMConfig vs FORScan
**Dependência:** Firmware AA (IDB com funções nomeadas)
**Relaciona-se a:** doc 25 (checksums), doc 28 (UDS SecurityAccess)

---

## Resumo Executivo

1. **FATO:** O validator do bootloader (`sub_6284` @ 0x6284) executa `blrl 0x3F901C` quando o CRC-32 verificado bate com o esperado. Isso é **execução de código arbitrário em RAM** por design — não é vulnerabilidade, é a infraestrutura oficial do **secondary bootloader** (stub) que o tool de flash uploadа.
2. **FATO:** `sub_5E00` é o handler que escreve chunks do upload UDS para `0x3F9000 + offset`. Junto com `sub_6380` (validate trigger), forma o mecanismo completo para uploadr e executar o stub.
3. **CONSEQUÊNCIA:** A lógica de erase/write/verify da flash **não está no firmware do TCM**. Está dentro do **stub** que o flash tool uploadа. ELMConfig e FORScan carregam stubs **diferentes**, com regras de validação diferentes.
4. **NOVA INTERPRETAÇÃO** (subscreve seções §8 e §9.6 do doc 28): a diferença operacional entre ELMConfig (aceita patched) e FORScan (rejeita patched) está no **stub embarcado em cada tool**, não em comandos UDS extras enviados pelo TCM.

---

## 1. Layout do Validator (sub_6284 @ 0x6284)

### Disassembly (trecho crítico)

```
6284  stwu      r1, -0x18(r1)
6298  addi      r30, r30, -0x294       ; r30 = 0x3FFD6C (state)
629c  lhz       r11, 0(r30)
62a0  rlwinm    r11, r11, 0,26,26      ; check bit 0x20 (validator armado)
62a4  cmpwi     r11, 0
62a8  beq       loc_636C               ; not armed → return

62b0  addi      r29, r29, -0x2A4       ; r29 = 0x3FFD5C (current pos)
62b4  lwz       r31, 0(r29)            ; pos
62bc  lwz       r10, -0x2A0(r10)       ; end (0x3FFD60)
62c0  subf      r3, r31, r10           ; remaining = end - pos
62c4  cmplwi    r3, 0x100
62c8  ble       loc_62F8               ; remaining ≤ 256 → final chunk

; --- intermediate chunks: process 256 bytes ---
62d0  addi      r30, r30, -0x29C       ; r30 = 0x3FFD64 (CRC accumulator)
62d4  lwz       r5, 0(r30)             ; load accumulated CRC
62d8  addi      r3, r31, 0             ; data = pos
62dc  li        r4, 0x100              ; len = 256
62e0  bl        sub_77B4               ; CRC-32/MPEG-2
62e4  stw       r3, 0(r30)             ; save accumulated CRC
62e8  lwz       r9, 0(r29)
62ec  addi      r9, r9, 0x100
62f0  stw       r9, 0(r29)             ; pos += 256
62f4  b         loc_636C               ; defer next chunk

; --- final chunk: process remaining bytes + compare ---
62fc  addi      r29, r29, -0x29C       ; r29 = 0x3FFD64
6300  addi      r4, r3, 1              ; len = remaining + 1 (end inclusive)
6304  lwz       r5, 0(r29)             ; load CRC
6308  addi      r3, r31, 0
630c  bl        sub_77B4
6310  addi      r31, r3, 0             ; final CRC
6314  stw       r31, 0(r29)
6318  lwz       r9, -0x298(r9)         ; expected CRC (0x3FFD68)
6320  cmplw     r9, r31                ; compare
6324  bne       loc_6340               ; mismatch → 0x92

; --- CRC MATCH: execute code at 0x3F901C ---
6328  lis       r31, 0x40
632c  addi      r31, r31, -0x6FE4      ; r31 = 0x3F901C
6330  mtlr      r31                    ; LR ← 0x3F901C
6334  blrl                             ; <<<<< ARBITRARY CODE EXECUTION
6338  li        r31, 0xA0              ; response: success
633c  b         loc_6344

6340  li        r31, 0x92              ; response: CRC mismatch
6344  lis       r12, 0x40
6348  li        r11, 1
634c  sth       r11, -0x192(r12)
6350  stb       r31, -0x292(r10)       ; 0x3FFD6E = response code
6358  lhz       r9, 0(r30)
635c  rlwinm    r31, r9, 0,27,25       ; clear validator armed bit
6364  sth       r12, 0(r30)
6368  bl        sub_5CCC               ; cleanup
```

### Estados do validator

| State bit (0x3FFD6C) | Significado |
|---|---|
| `0x200` | Sessão de programação ativa (set por `10 85`) |
| `0x10` | Pré-condição cumprida (set por `sub_5E00` após primeiro upload OK) |
| `0x20` | Validator armado (set por `sub_6380` antes de chamar `sub_6284`) |
| `0x8000` | Validator em progresso (set por `sub_6380`) |

### Response codes (`MEMORY[0x3FFD6E]`)

| Valor | Hex | Causa |
|---|---|---|
| 0x81 | -127 | Sessão de programação não ativa |
| 0x90 | -112 | Pré-condição faltando (bit 0x10) |
| 0x91 | -111 | Module ID mismatch (`0x3F9014` ≠ `0xBA00`) |
| 0x92 | -110 | **CRC-32 mismatch** |
| 0xA0 | -96 | **Sucesso (stub executou)** |
| 0xB7 | -73 | Range inválido (end < start) ou overflow |

---

## 2. Layout da Struct em RAM 0x3F9000

Inferido por `sub_6380` (CRC validator setup) — lê offsets do struct e copia para mirror state em 0x3FFD5C+.

```c
struct flash_tool_descriptor {
    uint32_t crc_seed;           // +0x00 → 0x3FFD64 (CRC accumulator init)
    uint32_t crc_expected;       // +0x04 → 0x3FFD68 (target CRC)
    uint32_t _unused_0x08;       // +0x08 (não lido por sub_6380)
    uint32_t start_addr;         // +0x0C → 0x3FFD5C (region start)
    uint32_t end_addr;           // +0x10 → 0x3FFD60 (region end, INCLUSIVE)
    uint8_t  module_id[6];       // +0x14 → comparado com bytes em 0xBA00
    uint8_t  _padding[2];        // +0x1A
    uint8_t  stub_code[N];       // +0x1C → EXECUTADO se CRC bate
} __attribute__((aligned(4)));
```

### Bytes de referência em 0xBA00

```
0xB9FC: 4E 42 30 02                    ; "NB0\x02" (header?)
0xBA00: 22 00 46 54 33 30 30 FF        ; \x22\x00 + "FT300" + 0xFF
0xBA08: 46 54 33 35 30 30 4B 43        ; "FT3500KC"
0xBA10: 58 58 58 58 2D 2D 2D 2D        ; "XXXX----" (placeholder)
```

**O sub_75EC compara 6 bytes a partir de `0xBA00`**:
```
22 00 46 54 33 30  →  \x22\x00 "FT30"
```

Tools que querem flashar precisam enviar exatamente estes 6 bytes em `0x3F9014`. ELMConfig e FORScan enviam — ambos passam essa checagem.

### Comportamento de `sub_75EC` (memcmp variant)

| Retorno | Significado |
|---|---|
| `-1` | **MATCH** (todos os bytes iguais) |
| `>=0` | Offset do primeiro byte diferente |

Note que é o INVERSO de `memcmp` padrão. `sub_6380` confere `if (sub_75EC(...) != -1) → mismatch path`.

---

## 3. Upload Mechanism (sub_5E00 @ 0x5E00)

```c
sub_5E00():
    // requer sessão de programação ativa
    if ((MEMORY[0x3FFD6C] & 0x200) == 0) {
        response = 0x81;
        goto store_response;
    }

    // dest = 0x3F9000 + offset_field
    base = 0x3F9000;
    offset = MEMORY[0x3FFD6F];
    if (offset >= 0xFFC07000) {
        v0 = -1;  // overflow guard
    } else {
        v0 = offset + base;
    }

    // length = MEMORY[0x3FFE6E] - 5 (UDS length - header)
    chunk_len = MEMORY[0x3FFE6E] - 5;
    end = v0 + chunk_len;

    // bounds check: end < 0x3FF765 (~10KB acima de 0x3F9000)
    if (end >= 0x3FF765) {
        response = 0xB7;  // overflow
    } else {
        sub_7518(v0, 0x3FFEF3, chunk_len);  // memcpy from UDS buffer
        MEMORY[0x3FFD6C] |= 0x10;            // set "data uploaded" bit
        response = 0xA0;                      // OK
    }

store_response:
    MEMORY[0x3FFD6E] = response;
    return 1;
```

### Buffer limits

- Base: `0x3F9000`
- Topo: `0x3FF765` (~26KB úteis para o stub)
- Origem dos bytes: `0x3FFEF3` (UDS receive buffer + 5)

### Pipeline de upload

```
Tool envia UDS [service_id] [offset_hi] [offset_mid] [offset_lo] [data...]
                                                                  ↑
                                            chunks de até ~26KB no total
sub_5E00 lê offset do byte 1-3, copia data[] para 0x3F9000+offset
Tool repete N vezes com offsets contínuos até cobrir todo o stub
```

---

## 4. Modelo Completo do Flash Protocol Ford Silveroak

```
┌─ TOOL ─────────────────────────────────────────┐  ┌─ TCM ─────────────────────────┐
│                                                │  │                                │
│ 1. 10 85                              ────────►│  │ → 50 85 (programming session) │
│                                                │  │ → set bit 0x200 em 0x3FFD6C   │
│                                                │  │                                │
│ 2. 27 01                              ────────►│  │ → 67 01 <seed>                │
│    compute key(seed, BL_secret)                │  │                                │
│    27 02 <key>                        ────────►│  │ → 67 02 (auth ok)              │
│                                                │  │                                │
│ 3. UPLOAD STUB (loop N vezes):                 │  │ sub_5E00 escreve em RAM        │
│    [svc] [off_h] [off_m] [off_l] data ────────►│  │ → 0x3F9000 + off               │
│                                       ────────│  │                                │
│ 4. WRITE DESCRIPTOR FIELDS:                    │  │ (mesmo mecanismo)              │
│    seed, expected_crc, start, end,             │  │                                │
│    module_id "\x22\x00FT30"                    │  │                                │
│                                                │  │                                │
│ 5. TRIGGER VALIDATE                   ────────►│  │ sub_6380:                      │
│    [svc]                                       │  │   → verify module_id           │
│                                                │  │   → call sub_6284              │
│                                                │  │     → CRC-32 over [start,end]  │
│                                                │  │     → compare with expected    │
│                                                │  │     → IF MATCH: blrl 0x3F901C  │
│                                                │  │                                │
│                                                │  │ ═════════ STUB RODANDO ═══════ │
│                                                │  │ (código do TOOL agora controla │
│                                                │  │  o MPC555. Tudo daqui em       │
│                                                │  │  diante é stub ↔ tool, não     │
│                                                │  │  bootloader ↔ tool)            │
│                                                │  │                                │
│ 6. STUB-SPECIFIC PROTOCOL (opaco)              │  │                                │
│    erase via SIU/flash controller              │  │                                │
│    receive flash data via UDS wrapper          │  │                                │
│    write to flash sectors                      │  │                                │
│    final verify (LENIENT em ELMConfig,         │  │                                │
│      STRICT em FORScan ?)                      │  │                                │
│    set NVRAM flag "new app valid"              │  │                                │
│    triggers reset                              │  │                                │
│                                                │  │                                │
└────────────────────────────────────────────────┘  └────────────────────────────────┘
```

---

## 5. Reconciliação com Observações Anteriores

### vs §9.6 do doc 28 (HIPÓTESE secondary bootloader)

> "TCM 4F27E Silveroak pode exigir upload de stub 'secondary bootloader' antes de `B1 erase`. ELMConfig faz isso na sessão bem-sucedida, não na fracassada."

**Confirmado.** Não é hipótese; é fato arquitetural. O `blrl 0x3F901C` exige stub. Sem stub, `sub_6284` retorna 0x92 e o flash não progride.

### vs FATO 25.11 (Block3 checksum correto basta)

> "v3_old PHF (BL-based) que rodou 50km via ELMConfig tinha checksum Master e Block2 inalterados (incorretos)... bootloader não valida Master/Block2 CRC-16."

**Confirmado.** O CRC-16 dos blocks não é checado pelo bootloader nativo. É o **stub do tool** que pode (ou não) checar. ELMConfig's stub não checa. FORScan's stub provavelmente checa OU checa o CRC-32/MPEG-2 sobre um range (via mecanismo similar a `sub_6284`, mas aplicado pós-flash).

### vs FATO 25.14 (mesmo PHF, comportamento diferente)

> "O `v3_old` PHF que bootou via ELMConfig falhou em boot via FORScan."

**Explicado.** A diferença não está no PHF nem no bootloader do TCM. Está no **stub** que cada tool uploadа. Mesmo PHF, stubs diferentes → resultados diferentes.

### vs FATO 25.16 (sub_6380 e sub_5E00 sem callers)

> "sub_6380 e sub_5E00 têm zero callers diretos, sugerindo invocação via UDS dispatch table."

**Confirmado e refinado.** São handlers UDS chamados via tabela de dispatch. Os service IDs específicos ainda não foram identificados, mas a função de cada um agora está clara:
- `sub_5E00` → handler do serviço de upload (provavelmente `0xA0`, com base no response code retornado)
- `sub_6380` → handler do serviço de trigger validate (provavelmente `0xA1`)

---

## 6. Implicação Crítica para o Flasher Próprio

### O que precisamos para flashar via Python J2534

| Componente | Status | Fonte |
|---|---|---|
| Sequência UDS pré-stub | ✅ Conhecida | Doc 28 §9 + fórum russo |
| Algoritmo SecurityAccess do bootloader | ❌ Desconhecido | Boot block não está no PHF |
| **Stub binário (PowerPC executável)** | ❌ Desconhecido | Embarcado em ELMConfig/FORScan |
| Protocolo stub-tool (pós-execução) | ❌ Desconhecido | Definido pelo autor do stub |
| Endereços flash + sectors MPC555 | ✅ Documentado | Datasheet MPC555 |

**Sem o stub, nenhum flasher próprio funciona.** Mesmo com bootloader auth resolvido, o passo `blrl 0x3F901C` precisa pular para código válido. Sem código válido em RAM, o `blrl` salta para `0xFF FF FF FF` (RAM não inicializada) → exception handler → travamento.

### Caminhos para obter o stub

| Caminho | Custo | Risco | Reversibilidade |
|---|---|---|---|
| **A. Capturar via sniff** (Portmon + ELMConfig flash AA) | 1.5h + risco brick recuperável | Médio (brick recuperável via FORScan) | Stub captura é bit-perfect |
| **B. Static reverse do binário ELMConfig** | 1h-1semana (dependendo do packer) | Zero hardware | Pode estar criptografado/comprimido |
| **C. Dynamic analysis do ELMConfig** | 4-8h | Zero hardware | Memory dump após decryption runtime |
| **D. Escrever stub do zero** | 1-3 semanas | Zero hardware | Requer documentar formato flash MPC555 |
| **E. Static reverse do FORScan** | Similar a B | Zero hardware | Stub provavelmente estrito → pode não ajudar |

---

## 7. Próximos Passos Prioritários

### Imediato

1. **Identificar packer do ELMConfig** (Detect It Easy / CFF Explorer / PEiD).
2. Se packer trivial (UPX, etc.) → unpack → procurar blob de bytes PowerPC.
3. Se packer não-trivial → tentar **dynamic analysis**:
   - Rodar ELMConfig em sandbox (Sandboxie ou Windows VM)
   - Iniciar flash de AA stock até passar do `10 85` + `27 02`
   - Suspender processo, dump de memória
   - Buscar por padrões: instruções PowerPC válidas, strings `"\x22\x00FT30"`, código que referencia `0x3F900X`

### Médio prazo

1. Identificar boundaries do stub no dump (start = primeira instrução PowerPC válida; end = próximo dado/padding).
2. Disassemblar o stub (carregar como PowerPC em IDA).
3. Reverso do protocolo stub↔tool para entender quais comandos UDS são proxy'ados, quais são absorvidos pelo stub.

### Documentação relacionada

- Doc 25 — checksums (CRC-16/ARC, GF(2) algebra, file_checksum mistery)
- Doc 28 — SecurityAccess (algoritmo da aplicação, falha em bootloader)
- Doc 29 (este) — secondary bootloader hook

---

## 8. Padrões para Identificação do Stub em Dump de Memória

### Bytes PowerPC característicos

| Padrão | Instrução | Frequência típica |
|---|---|---|
| `4E 80 00 20` | `blr` (return) | 1-3 por função |
| `48 00 ?? ??` | `b` short branch | Comum |
| `38 ?? ?? ??` | `addi` / `li` | Muito comum |
| `7C ?? ?? ??` | Operações com 3 regs | Comum |
| `3C ?? ?? ??` | `lis` (load upper) | Comum |
| `94 21 FF ??` | `stwu r1, -N(r1)` (prologue) | 1 por função |

### Strings e constantes que devem estar no stub

| String/Constante | Razão |
|---|---|
| `0x3F9000` ou `0xFFC07000` (RAM) | Stub conhece seu próprio endereço |
| `0x40000000` (lis 0x40 base) | Para acessar RAM/MMIO |
| `0x2F000000-0x2F0FFFFF` (SIU/flash control) | Para erase/write flash |
| `0x3F8F00` (SDA base) | Para r13 references |
| `"\x22\x00FT30"` | Module ID se o stub também checa |

### Tamanho esperado

- Buffer disponível: `0x3FF765 - 0x3F901C` ≈ **26 KB**
- Stub típico de Ford SBC: 4-16 KB

---

## 10. Confirmação via APLICAÇÃO — handlers 0x34/0x36/B1 (2026-06-22)

Após o breakthrough de auth L3 na aplicação (doc 28 §11), mapeamos os handlers de
flash da APLICAÇÃO (dispatcher `sub_B3E98` @ 0xB3E98) para responder: **a aplicação
faz flash nativo ou delega ao stub?**

### FATO 10.1 — `0x34` RequestDownload só aceita destino em RAM

`uds_34_request_download` @ 0xB6B94 valida o endereço de destino contra uma tabela
de 6 boundaries em ROM `0x18A154`:

| Índice | Valor | Papel |
|--------|-------|-------|
| [0] | `0x003FCAFF` | range1 low |
| [1] | `0x003FD334` | range1 high |
| [2] | `0x003FFFFF` | range2 (RAM top) |
| [3] | `0x003FCB34` | — |
| [4] | `0x003FD333` | — |
| [5] | `0x00180000` | — |

Tracejando a lógica de comparação (`cmplw`/`blt` em 0xB6BFC-0xB6C2C), o único range
que resulta em ACEITE é **`[0x3FCAFF, 0x3FD334)` — RAM, ~2 KB (0x835 bytes)**.
Endereços de flash (< 0x3FCB34) caem no caminho de REJEIÇÃO com `NRC 0x31
(requestOutOfRange)`. Destino aceito é gravado em `0x3FDC70`.

### FATO 10.2 — `0x36` TransferData faz cópia byte-a-byte para RAM, SEM programação de flash

`uds_36_transfer_data` @ 0xB6DAC:
```c
v2 = (_BYTE *)MEMORY[0x3FDC70];   // dest (RAM, de 0x34)
...
*v2++ = result[v4 + 1];           // cópia direta byte a byte
++MEMORY[0x3FDC70];               // avança dest
```
- **NÃO** há sequência de programação CMF (sem unlock, sem program-word, sem poll de status).
- **NÃO** há cálculo de checksum.
- Contador em `0x3FDC6E` decrementado por byte.

Cópia direta `*v2++ = byte` **só funciona em RAM**. Flash (interna ou externa)
exige máquina de estado de programação. Logo: `0x34/0x36` da aplicação **carrega
dados em RAM, não programa flash**.

### FATO 10.3 — `B1` é dispatcher de sub-comandos

O handler `B1` (inline em `sub_B3E98` @ 0xB5400) chama via `blrl` a rotina @ 0xB6690,
que parseia os bytes do comando B1 e despacha via `sub_BA740`, mantendo contadores
em `0x3FDAC8`/`0x3FDACB`. É um dispatcher de sub-comandos proprietários Ford, não
um erase monolítico.

### CONCLUSÃO 10.4 — A aplicação NÃO faz flash nativo; precisa de um flash driver em RAM

O padrão é o **clássico fluxo de reprogramação UDS automotivo**:

```
10 85                  → programming session (APLICAÇÃO aceita)
27 03/04               → auth L3 (algoritmo que JÁ TEMOS, validado on-target)
34 (dest=0x3FCAFF RAM) → RequestDownload do FLASH DRIVER para RAM
36 ×N                  → TransferData: copia o flash driver (~2KB) para RAM
31/B1 (trigger)        → executa o flash driver em RAM
   ↓
   [FLASH DRIVER agora roda em RAM e faz o trabalho real:]
   - erase de setores da flash EXTERNA (firmware é 3.5MB >> 448KB internos do MPC555)
   - recebe dados de flash via UDS (proxy pelo driver)
   - programa a flash externa
   - verifica
11 01 / power cycle    → reset, boot da nova aplicação
```

Conecta diretamente com o hook `blrl 0x3F901C` (§1): é o MESMO mecanismo de
"download código para RAM e executa". A aplicação expõe a primitiva de download
para RAM; o **flash driver (stub)** faz a programação.

### CONSEQUÊNCIA 10.5 — O ingrediente faltante é o FLASH DRIVER (stub), não a auth

Estado do flasher Python:

| Componente | Status |
|---|---|
| Sessão `10 85` | ✅ Aplicação aceita (on-target) |
| SecurityAccess L3 | ✅ Algoritmo validado on-target (`04 85 E5 → ED E3 58`) |
| Download para RAM (`34/36`) | ✅ Mecanismo mapeado, destino RAM `0x3FCAFF` |
| **Flash driver (stub em RAM)** | ❌ **NÃO temos** — faz o erase/program da flash externa |
| Trigger de execução do driver | ⚠️ Provável `31` ou `B1`; falta identificar sub-função exata |
| Protocolo driver↔tool pós-execução | ❌ Definido pelo autor do driver |

**O stub é específico do chip de flash EXTERNA da placa do TCM.** Fontes possíveis:
1. `frw.dat` do ELMConfig (criptografado, 9.5 MB) — provável conter o driver
2. Sniff do ELMConfig durante flash (captura o driver nos frames `36`)
3. Escrever do zero (requer part number do chip de flash externa do TCM)

### FATO 10.6 — Reconciliação: por que ELMConfig (sem stub TCM bundled aparente) funciona

ELMConfig não tem VBF de SBL para TCM em `data/` (só BCM/IPC), mas tem `frw.dat`
criptografado de 9.5 MB. O flash driver do TCM quase certamente está lá dentro,
decriptado em runtime e enviado via `34/36`. Isso explica por que ELMConfig
consegue flashear o TCM sem um arquivo SBL visível.

---

## 9. Estado de Confiança

| Afirmação | Confiança | Evidência |
|---|---|---|
| `sub_6284` faz `blrl 0x3F901C` em CRC match | 100% | Disassembly direto |
| Layout da struct 0x3F9000 | 95% | Inferência forte de `sub_6380` |
| `sub_5E00` faz upload chunks | 90% | Pattern match com `memcpy` para 0x3F9000+offset |
| Stub é diferente entre ELMConfig e FORScan | 70% | Única hipótese consistente com observações |
| Stub está embarcado nos binários | 85% | Tools standalone, sem network fetch durante flash |
| Service IDs (0xA0=upload, 0xA1=trigger) | 50% | Inferência por response code; precisa de sniff/dynamic para confirmar |
