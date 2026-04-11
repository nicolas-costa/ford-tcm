## 12 — Resolução do TaskID=3: Caminho Completo (Integração Final)

### Resumo Executivo (Brutal)
Com as descobertas dos agentes, o caminho para resolver TaskID=3 está **quase completo**. O gargalo não era falta de XREF - era init via dispatch indireto. Agora temos:

- **`sub_30C98 @ 0x30C98`**: consumidor do root em `0x003FA400` e dispatcher `slot → task_entry → fnptr → blrl`
- **`iterate_slots_3FA400_and_update_3FA404 @ 0x31698`**: confirma iteração por `count` e manutenção de estado em `0x003FA404`
- **Tabela `0x0002A540`**: descreve init de RAM incluindo `0x003FA400..0x003FCB00` (fato por dump raw)
- **O elo que falta**: quem seta `*(0x003FA400)` (root pointer) e inicializa os arrays (`root+8`, `root+0x10`, `0x3FA408`, `0x3FA404`)

**Fato:** Não há mais "misticismo" - é mecanismo de dispatch indireto padrão do firmware.

---

### Evidências Integradas (Agentes 1 + 2)

#### 1) Agente 1: Não Há Init PPC Direto do Bloco RAM
**Conclusão Chave:** Os únicos writers PPC no bloco `0x003FA400..0x003FCB00` são:
- `0x3C088`: Alloc/zero do `+0x15D4` (buffer dinâmico)
- `0x3A7F8`: Clear/teardown do `+0x15D0` (root pointer)
- Dois writes suspeitos (`0x23CBC`, `0x3911C`) incompatíveis com modelo se fossem PPC reais

**Impacto:** Init do bloco vem de **mecanismo indireto**, não stores PPC diretos.

#### 2) Agente 2: 4 Engines de Dispatch Indireto + Tabela Candidata

**Engines Identificadas:**
- **Engine A (0x43F84)**: state machine baseada em `off_2A458` que faz call indireto via `*(ctx+4)`.
  - **Fato:** call indireto (`mtlr; blrl`) → “callers” via `bl` somem.
  - **Hipótese (a confirmar):** esse pipeline participa do boot/config e pode disparar alguma etapa que termina em `*(0x003FA400)=root_ptr`.

- **Engine B (0x32934)**: Callback loop FIFO puro
- **Engine C (0x33310)**: Timebase/tick callback loop
- **Engine D (0x327C0)**: Callback gate ligado a `0x163C(r13)` - **diretamente conectado ao mini-interpreter**

**Descoberta Chave (Update Agente 1):** sub_30C98 é consumidor direto da estrutura populada:
- Trata `0x003FA400` como **ponteiro global para struct raiz**
- Faz indirect-call via `task_entry+0x4` (exatamente o padrão TaskID=3!)
- Itera slots usando `count = *( *(0x3FA400) + 2 )`

**Tabela Candidata do Mini-Interpreter:**
- **Bloco 0x2A6F4**: Sequências coerentes com opcodes do `sub_31C84`:
  - `0x2A6F4: 0x00000001, 0x00000001, 0x37000000, ...`
  - `0x2A710: 0x00000002, 0x00000001, ...`
  - `0x2A72C: 0x00000003, 0x00000001, ...`
  - `0x2A764: 0x00000004, 0x00000001, ...`

---

### Caminho Completo: Engine A → TaskTable → TaskID=3

#### Passo 1: Engine A Popula o Bloco RAM
**O que é (fato, PPC):**
- `sub_30C98 @ 0x30C98` **consome** `0x003FA400` como ponteiro global para uma “raiz” em RAM.
  - `root = *(0x3FA400)` (via `lwz r10, 0(r26)` com `r26=0x3FA400`)
  - `slots = *(root + 0x8)` (via `lwz r10, 8(r10)`)
  - stride explícito: **`slot = slots + (slot_id * 0xC)`** (`mulli r11, r29, 0xC` em `0x30E4C`)
  - `task_entry = *(slot + 0x8)` (`lwz r31, 8(r10)` em `0x30E58`)
  - call indireto: **`fnptr = *(task_entry + 0x4); mtlr fnptr; r3=task_entry; blrl`** (`0x30E64..0x30E70`)
- `iterate_slots_3FA400_and_update_3FA404 @ 0x31698` confirma o modelo:
  - `root = *(0x3FA400)`
  - `count = *(root + 2)` (byte) e iteração por índice
  - mantém estado em `0x3FA404` (inclui `stw` em `0(0x3FA404)` + `stb 0` em `+2` por-slot)

**O que ainda é hipótese:**
- *Quem* e *quando* popula `*(0x003FA400)` (root pointer) **após** a fase de init de RAM descrita por `0x2A540`.
- se isso acontece via **VLE / boot-stage / mini-interpreter**, o PPC “limpo” não vai mostrar `stw 0x1500(r13)` (de fato: 0 hits).

**Ponte observável (fato) ROM → consumo do bloco:**
- Existe uma rotina `tasktable_or_slot_init_from_2A744_and_3FA400 @ 0x31594` que referencia **`unk_2A744`** e toca `0x003FA400`.
  - **Importante:** o disasm PPC atual só prova o *touch*/loop (a parte “chama 0x30EC4/0x3099C” ainda precisa ser validada por bytes/VLE — não vou cravar como fato).

#### Passo 2: TaskTable Entry para 0x395B4
**Onde:** Dentro do bloco `0x003FA400..` (coberto pela tabela `0x2A540`)
**Como localizar:** Uma vez que o bloco é populado pelo Engine A, procurar por:
- Ponteiro `fnptr = 0x395B4` (tpu_pwm_queue_build_and_schedule_task3)
- Offset adjacente com `ctx` pointer (passado como `r3` para o builder)

#### Passo 3: ctx Pointer da Fila PWM
**O que é:** Ponteiro para estrutura com:
- `count` em `+0x0` (u32)
- `entries` em `+0x4` (ponteiro para array de entries stride 0x10)
- Cada entry: `id`, `mode`, `flags`, **`duty_command`** em `+0x4`

---

### Próximos Passos Imediatos

#### Fase 2A: Validar Engine A → Bloco RAM
1. **Não perseguir `0x44460` como “aplicador”**: com os últimos findings, ele não tem callers diretos e não se comporta como iterador de tabela.
2. Focar no que falta: **identificar quem seta `*(0x003FA400)`** e monta `root+8/root+0x10` (provável VLE/boot-stage/mini-interpreter).
3. Só depois: dump/parsing do layout em RAM e caça do `fnptr==0x395B4` no TaskID=3.

#### Fase 2B: Localizar TaskTable Entry
1. Com bloco populado identificado, fazer dump/parsing estático
2. Procurar por `0x395B4` como fnptr em estrutura de TaskEntry
3. Extrair ctx pointer adjacente

#### Fase 2C: Conectar com Producers PWM
1. Com ctx pointer em mãos, rastrear writers do `queue->entries[i]`
2. Focar em `entry+0x4` (raw duty/command)
3. Mapear para hardware (EPC/TCC/shift solenoids)

---

### Por Que Isso Resolve o Problema Original

**Antes:** "Como chegar em EPC/TCC/shift sem fanfic?"
- Não conseguíamos porque TaskID=3 não tinha bl direto
- r13+0x15D0 não tinha init PPC visível

**Agora:** Caminho completo identificado
- Dispatcher está provado (`sub_30C98`: `slot*0xC → *(+8)=task_entry → *(+4)=fnptr → blrl`)
- TaskTable (ou “slots table”) mora no bloco sob `root = *(0x3FA400)`
- Producers da fila PWM ficam acessíveis uma vez localizado o ctx

**Métrica de Sucesso:** TaskID=3 → ctx → primeiro producer identificado com evidência concreta.
