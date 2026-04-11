## 06 — Scheduler e Tabela de Tarefas (0x396D0)

### Anatomia do Scheduler (Fatos Confirmados)
O scheduler opera via interrupção do Decrementer (Tick), gerenciando uma lista de tarefas através de estruturas de dados na RAM.

#### 1. Estrutura de Dados e Acesso
- **ISR Principal (`0x396D0`)**: Ponto de entrada da interrupção.
- **Tick Context Pointer**: O ISR recebe em `r3` um ponteiro para o contexto do tick e o armazena em `0x15C0(r13)` logo no início (instrução `stw r26, 0x15C0(r13)` em `0x39E00`, onde `r26` é cópia de `r3`).
- **Indireção de Tarefas**: O acesso às tarefas é feito via dupla indireção a partir de `r13`:
  1. Carrega base: `lwz r12, 0x15C0(r13)`
  2. Carrega array: `lwz r12, 8(r12)`
  3. Indexa tarefa: `lwzx r12, r12, rIndex`
- **Helper de Manipulação (`0x39E18`)**: A função `scheduler_post_or_arm_task` utiliza essa mesma estrutura para verificar status (`+0xC`) e manipular máscaras (`0x15C8`), confirmando o layout.

#### 1.1. Loop real de dispatch (bitmask → taskEntry → call)
Existe um loop explícito (PPC “normal”, não VLE) que consome a máscara de pendências em `r13+0x15C8` e executa tarefas via ponteiro em RAM:

- **Pending mask**: `lwz r28, 0x15C8(r13)` (ex.: `0x003A370`)
- **TaskID derivado da máscara**: usa `cntlzw` + aritmética para chegar num `task_id` (em `r29`, depois `r30 = task_id << 2`)
- **TaskEntry**:
  - `tick_ctx = *(r13+0x15C0)`
  - `tasks_array = *(tick_ctx + 0x8)` (confirmado também em `scheduler_post_or_arm_task`)
  - `task_entry = *(tasks_array + (task_id<<2))` (load via `lwzx`)
- **Chamada indireta**:
  - `fn = *(task_entry + 0x4)`
  - `mtlr fn; mr r3, task_entry; blrl` (ex.: `0x003A3C4..0x003A3D0`)

Implicação: **as “tarefas” são descritores em RAM**; o scheduler **não** precisa ter `bl` direto para os handlers (por isso o IO/TPU “some” em XREFs estáticos).

#### 1.2. Layout mínimo do `TaskEntry` (evidência)
O helper `scheduler_post_or_arm_task @ 0x39E18` confirma offsets de fields dentro do `TaskEntry` (além do `fn` em `+0x4`):

- **`task_entry + 0x4`**: ponteiro de função (usado no dispatcher via `mtlr/blrl`)
- **`task_entry + 0x8`**: valor usado como “tempo/limite” (carregado e comparado no `scheduler_post_or_arm_task`) — **mas atenção**: existe também um *stride* `0xC` em outra estrutura (ver abaixo), então “+0x8” aparece em dois contextos diferentes.
- **`task_entry + 0xC`**: flag/estado “ativo” (carregado e testado; `==0` segue um caminho, `!=0` segue outro)

E existe uma estrutura paralela:
- **`r13+0x15C4`**: array indexado por `task_id<<2` onde o scheduler grava timestamps/deltas (via `stwx`) no `scheduler_post_or_arm_task`.

**Separação necessária (fato)**: `sub_30C98 @ 0x30C98` indica que `tasks_array` pode ser um array de *slots/descritores* com **stride `0xC`**, e que **o ponteiro do `task_entry` é lido em `slot+0x8`** (ou seja, `slot+0x8` ≠ `task_entry+0x8`). Isso explica o aparente conflito entre “stride 0xC” e “`task_entry+0x8` é timer”.

Implicação: ao extrair *TaskID=3*, precisamos primeiro decidir (com evidência do caminho em uso) se `tasks_array[task_id]` é:
- **ponteiro direto para `task_entry`** (array de pointers, index por `task_id<<2`), ou
- **slot `0xC` bytes** que contém `task_entry_ptr` em `+0x8`.

#### 1.2. Evidência adicional (fato): dispatch via bloco em RAM `0x003FA400`
Além do acesso via `r13+0x15C0`, existe uma rotina que materializa o mesmo padrão usando endereços absolutos na RAM:
- **`sub_30C98 @ 0x00030C98`** usa `0x003FA400` como base (carrega com `lis 0x40; addi -0x5C00`) e opera também com `0x003FA408`.
- Ela resolve um `task_id` (em `r29` no trecho abaixo) e faz **call indireto** do handler armazenado em RAM:

```asm
; ... dentro de sub_30C98 ...
lwz   r10, 0(r26)        ; r26 = 0x003FA400, root = *(0x003FA400)
lwz   r10, 8(r10)        ; tasks_array = *(root + 0x8)
mulli r11, r29, 0xC      ; stride 0xC por task_id
add   r10, r10, r11
lwz   r31, 8(r10)        ; task_entry = tasks_array[task_id].(+0x8)
lwz   r12, 4(r31)        ; fnptr = *(task_entry + 0x4)
mtlr  r12
mr    r3, r31            ; r3 = task_entry (ctx)
blrl
```

**Implicação prática**: o “ponto de verdade” para achar *TaskID=3* não é XREF — é extrair `task_entry` e ler `task_entry+0x4` (fnptr) a partir das estruturas em RAM (ou da init que popula `0x003FA400..`).

#### 2. Código Executável em `0x2621C`
O endereço `unk_2621C`, referenciado pelo ISR, contém código executável legítimo (prologue de função padrão `stwu`/`mflr`), indicando que não é apenas um dado, mas uma rotina auxiliar (possivelmente um *dispatcher* ou *callback* específico).

#### 3. Wrapper de Ativação (`0x23130`)
A função em `0x23130` atua como um wrapper que interage com o scheduler:
- Chama `scheduler_post_or_arm_task` com `r4=1` (ativar/armar?).
- Chama `scheduler_post_or_arm_task` com `r4=0` (desativar/cancelar?).
- É referenciada por `0x230d0`, sugerindo fazer parte de uma cadeia de lógica de controle maior.

### O Que Ainda Falta (Investigação em Curso)
1.  **Conexão com IO**: Ainda precisamos traçar o caminho exato de como as tarefas agendadas (via `0x15C0`) resultam na execução do driver de IO (`0x3BB10`). A hipótese de tabela de ponteiros de função é forte, mas a tabela exata precisa ser localizada.
2.  **Origem do Tick Context**: Quem chama o ISR inicialmente (passando `r3`) ou configura o vetor de interrupção? Isso revelará a localização inicial da tabela de tarefas na ROM/RAM.
3.  **Layout do TaskEntry em RAM**: o dispatcher usa `task_entry+0x4` como ponteiro de função, mas os demais campos (ex.: `+0x8`, `+0xC`) ainda precisam ser mapeados com dump do bloco em RAM (via debug/emulação ou localizar tabela de init).

### Próximos Passos
- Analisar os *callers* de `0x23130` para entender *quando* e *por que* tarefas são agendadas.
- Mapear a estrutura apontada por `0x15C0(r13)` + 0x8 para tentar identificar endereços de funções conhecidas (como `0x3BB10`) nessa tabela.
