# 19 — VLE Scan + Diagnóstico de Corrupção PHF — RESULTADOS

**Data:** 2026-03-22 (atualizado 2026-03-22)  
**Status:** ✅ VLE DESCARTADO — firmware é PPC puro. Bug no parser PHF identificado.  
**Firmware:** 5U75-14C337-AA.rebuilt.aligned.bin

---

## Resumo Executivo BRUTAL

### O que está PROVADO (3 bullets)

1. **NÃO EXISTE VLE neste firmware.** O registrador `vle` no IDA (ID=32) aceita configuração, mas VLE=1 produz decode errado em TODAS as regiões testadas (0x10000, 0x44460, 0x47000, 0x9D58, 0x2FFFC). Zero prologos VLE (`e_stwu r1` = `0x1821xxxx`) encontrados. Zero `e_bl` com targets válidos. As "1831 se_blr" reportadas anteriormente são `0x0004` em dados (calibração/tabelas), não código VLE. O binário é **100% PPC**.
2. **73 instruções "impossíveis" em funções analisadas são ARTEFATOS do parser PHF→BIN:**
  - 100% (73/73) estão no byte 31 (último byte) do payload de 32 bytes no formato de registro PHF (posição verificada com a rotação de alinhamento +3).
  - Incluem: `rlmi` (29x), `dozi` (35x), `fnmadd.` (2x), `xxsel` (4x), `xscmpeqdp` (3x).
  - Bytes 1-3 de cada instrução estão CORRETOS; apenas byte 0 está corrompido.
  - Exemplo verificado: `mflr r0` (0x7C0802A6) reconstruído como 0x590802A6 (`rlmi`) — últimos 3 bytes `0802A6` intactos.
  - As 11 `subfic` (opcode 8) previamente categorizadas como impossíveis são **PPC válido**.
3. **ZERO stores D-form para os 3 alvos críticos** (scan mantém-se válido):
  - `*(0x3FA400)`: 1 único writer em 0x30224.
  - `r13+0x15D0`, `0x305CE0`, `r13+0x1644`: ZERO writers D-form PPC.
  - Cadeia completa de init indireta mapeada (inalterada do scan original).

### Próximo passo de maior ROI

**Corrigir o parser PHF** (byte 31 dos records). Depois: **Emulador offline da tabela 0x2A540** (Task 2). Handlers no range 0x47000-0x48300 são PPC (não VLE como reportado anteriormente).

---

## Fatos Detalhados

### 1. Estado do IDB


| Métrica     | Valor                     |
| ----------- | ------------------------- |
| Processador | PPC (sem VLE)             |
| T register  | -1 (inexistente)          |
| ROM         | 0x0-0x200000 (2MB)        |
| ROM18       | 0x1854000-0x1856000 (8KB) |
| CODE        | 156,708 bytes (7.5%)      |
| DATA        | 2,920 bytes (0.1%)        |
| UNDEFINED   | 1,937,524 bytes (92.4%)   |


### 2. Scan de Stores D-form — Resultados Completos

#### Método

Scan raw de bytes em todo o ROM (step=2 para compatibilidade VLE):

- Pattern: `byte1 & 0x1F = base_reg`, `bytes[2:3] = displacement`
- Cobertura: 0x0-0x200000 (ROM) + 0x1854000-0x1856000 (ROM18)
- Inclui TODOS os opcodes (PPC e VLE)

#### Resultados por alvo


| Alvo           | Disp   | Base | Stores                   | Loads | Notas                                 |
| -------------- | ------ | ---- | ------------------------ | ----- | ------------------------------------- |
| r13+0x15D0     | 0x15D0 | r13  | 2 (stb@23CBC, stw@3A7F8) | 29    | stb é 1 byte — não escreve ptr válido |
| r13+0x15D4     | 0x15D4 | r13  | 1 (stw@3C088)            | 25    | O alloc+publish já documentado        |
| r13+0x1638     | 0x1638 | r13  | 1 (stw@31CE0)            | 27    | Mini-interpreter opcode 1             |
| r13+0x163C     | 0x163C | r13  | 2                        | 9     | Mini-interpreter opcode 2 + clear     |
| r13+0x1644     | 0x1644 | r13  | 0                        | 1     | ZERO writers PPC!                     |
| r13+0x166C     | 0x166C | r13  | 2                        | 3     | Mini-interpreter opcode 3 + clear     |
| r13+0x1698     | 0x1698 | r13  | 1                        | 1     | Callback ptr                          |
| r13+0x164C     | 0x164C | r13  | 8                        | 5     | Dispatch cursor (runtime)             |
| *(base+0xA400) | 0xA400 | any  | 1 (stw@30224)            | 0     | O ÚNICO writer do root ptr            |
| *(base+0xA544) | 0xA544 | any  | 0                        | 0     | ZERO writers para 0x3FA544            |
| *(base+0xA4D0) | 0xA4D0 | any  | 0                        | 0     | ZERO writers para 0x3FA4D0            |


#### Stores indexados (stwx): 34 instâncias no ROM

Impossível determinar destino sem contexto dinâmico. Concentrados em 0x054B0, 0x16D98, 0x21980, 0x23B04, 0x320AC, 0x32B74, 0x337xx, 0x339xx, 0x34AA8, 0x369xx, 0x39Exx, 0x3ABxx, 0x3AExx, 0x3AFxx, 0x3B1xx, 0x3B3xx, 0x3BCxx, 0x3BExx, 0x3BFxx, 0x48040, 0xB5Bxx.

#### Block stores (stswi): 59 instâncias no ROM

Todas com pattern `stswi r7, r11, N` (N=4,6,8,16). Destino = *(r11). Usados extensivamente pelo init table processor.

### 3. Tabela ROM 0x2A540 — Estrutura

Primeiras 5 entries são formato simples `[start, end, op, arg]` (16 bytes):


| #   | Start    | End      | Op   | Arg  | Significado                               |
| --- | -------- | -------- | ---- | ---- | ----------------------------------------- |
| 0   | 0x3F8000 | 0x3F8F00 | 0x04 | 0x00 | memset(0x3F8000, 0x00, 0xF00)             |
| 1   | 0x3F9500 | 0x3F9D00 | 0x04 | 0xB6 | memset(0x3F9500, 0xB6, 0x800)             |
| 2   | 0x3F9D00 | 0x3FA400 | 0x04 | 0x00 | memset(0x3F9D00, 0x00, 0x700)             |
| 3   | 0x3FA400 | 0x3FCB00 | 0x04 | 0x27 | **memset(0x3FA400, 0x27, 0x2700)**        |
| 4   | 0x3FCB00 | 0x400000 | 0x14 | 0x00 | op=20 (diferente!) para 0x3FCB00-0x400000 |


Entries 5+ mudam de formato — auto-referenciante com "top-byte tags":

- Referências internas ao próprio table offset (0x2A544, 0x2A59C, etc.)
- Valores 0xFFFFFFF8 (possível sentinel/link)
- Endereços ROM como 0x4873C, 0x48794, 0x48818 etc. (provavelmente function pointers nos handlers)
- Entries 90+93: cobrem range completo 0x3F8000-0x3FFFFF com op=1 e op=0

### 4. Handlers do Init Table (0x47000-0x48300)

Jump table em 0x46FB8, indexada pela dispatch em ROM18 (0x18544BC):

```asm
18544BC: slwi  r11, r11, 2        # index * 4
18544C0: addis r12, r11, 4        # + 0x40000
18544C8: lwz   r11, 0x6FB8(r12)   # load handler address
18544CC: mtctr r11
18544D0: bctr                      # indirect jump
```

Handlers identificados (endereços via jump table):

- 0x47048 (entry 0), 0x4711C (2), 0x47298 (3), **0x473C0** (4=fill), 0x473F0 (5), **0x47578** (6), 0x47630 (7), 0x476FC (8), 0x47750 (11), 0x4783C (12), 0x47874 (13), etc.
- **0x482F4**: handler default/fallthrough — escreve em 0x3FC518 e 0x3FA430, NÃO em 0x3FA400.

Handler region contém:

- Código VLE+PPC mixed (não decodificável com processador "PPC")
- `stmw r20, 0(r26)` @ 0x47F9C — store múltiplo (48 bytes) para destino dinâmico
- `stmw r28, 0x35C6(r13)` @ 0x482DC, 0x483FC — stores para SDA +0x35C6

### 5. `init_roots_write_3FA400_from_r3 @ 0x2FFFC`

**FATO:** Esta função escreve `*(0x3FA400) = r3` (argumento 1) no FINAL da execução:

```asm
30220: lis   r12, 0x40       # r12 = 0x400000
30224: stw   r31, -0x5C00(r12) # *(0x3FA400) = r31 = r3
```

Antes disso, inicializa campos:

- `*(0x3FA404)` via alloc call (0x2621C)
- `*(0x3FA40C)` via alloc call (0x2621C)
- Loop que popula slot entries

**Chamada indireta:** r3 = `*(r13+0x1644)` carregado em 0x328A4, chamado via dispatch loop em 0x31E00.

### 6. Mini-interpreter `@ 0x31C84`

Switch sobre opcode em entry[0]:

- **Opcode 1**: `stw entry[8], 0x1638(r13)` — seta root do sistema de dispatch
- **Opcode 2**: `stw (entry+8), 0x163C(r13)` 
- **Opcode 3**: `stw (entry+8), 0x166C(r13)`
- **Opcode 4**: memset loop com 0xFF
- **Opcode 5**: call sub_327BC
- **Loop**: avança cursor por entries linkadas

**NÃO popula r13+0x15D0 nem r13+0x1644.**

### 7. 0x305CE0 — 6 referências totais


| Endereço | Tipo                | Contexto                   |
| -------- | ------------------- | -------------------------- |
| 0x23784  | ori r10 (undefined) | Duty writer area           |
| 0x23870  | ori r8 (decoded)    | Duty value reader          |
| 0x3A5D4  | ori r11 (undefined) | Scheduler/IO area          |
| 0x3A6E8  | ori r10 (decoded)   | IO dispatch                |
| 0x3AB00  | ori r10 (undefined) | IO update                  |
| 0x1FFFFC | ori r10 (data)      | End of ROM, false positive |


**TODOS são readers.** Nenhum store para a tabela via qualquer mecanismo D-form.

---

## Conclusão Operacional

O scan VLE está COMPLETO. Os 3 alvos críticos (0x3FA400, r13+0x15D0, 0x305CE0) **não têm writers D-form além dos já documentados**. A inicialização acontece EXCLUSIVAMENTE via:

1. **Fill da tabela 0x2A540** (op=4 com byte 0x27) para o range 0x3FA400-0x3FCB00
2. **Handlers VLE+PPC mixed** (0x47000-0x48300) que modificam bytes individuais pós-fill
3. **Stores indexados (stwx) ou block stores (stswi/stmw)** cujo destino é computado em runtime
4. **Cadeia de indirect dispatch** que culmina em `init_roots_write_3FA400_from_r3` escrevendo `*(0x3FA400) = config_struct_ptr`

**Para resolver os valores finais, é MANDATÓRIO emular a tabela 0x2A540 (Task 2).**

---

**FIM DO DOCUMENTO**