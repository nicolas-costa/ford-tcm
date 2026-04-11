## 10 — Open issues (o que está travando e por quê)

---

### 11) UDS/diag: `svc 0x3B` faz branch para `0xFE02BF28` (fora do segmento `ROM`) — **FATO** e bloqueio

#### 11.1) FATO (branch fora de segmento)
No `uds_svc_3B_handler_entry`:
- **EA:** `0x0001BF14..0x0001BF1C`
- **Assembly:**
  - `0x0001BF14: li r12, 0`
  - `0x0001BF18: stw r12, 0x7044(r13)`
  - `0x0001BF1C: b 0xFE02BF28`
- **Bytes do branch:** `0x0001BF1C = 4A 01 00 0C` (word `0x4A01000C`)

#### 11.2) FATO (segmentos carregados no IDA)
- `ROM`: `0x00000000..0x00200000`
- `ROM18`: `0x01854000..0x01856000`

`0xFE02BF28` está fora de qualquer segmento → não dá para disassemblar/seguir CFG desse alvo no IDB atual.

#### 11.3) Impacto no objetivo (por que isso trava)
- Sem resolver o alvo `0xFE02BF28`, não dá para provar estaticamente se o `svc 0x3B`:
  - retorna ao dispatcher/state machine (epílogo comum), ou
  - transiciona para outra fase/dispatcher externo.

Isso bloqueia fechar a cadeia “`svc 0x3B → estado (6D40=2) → builder TX (0x459B0)`” como sequência temporal no mesmo caminho.

#### 11.4) Próximo passo (ROI máximo)
1. **Criar o segmento-espelho no IDA:** executar o script `scripts/ida_add_mirror_segment_fe000000.py` (File → Script file...). O script cria o segmento `ROM_mirror_FE` em `0xFE000000..0xFE030000` com o mesmo conteúdo do ROM (alias virtual).
2. **Re-analisar o alvo:** ir para `0xFE02BF28`, aplicar Edit → Code (C) para disassemblar e, se necessário, rodar análise automática. Decidir se o fluxo é epílogo comum (retorno ao dispatcher) ou dispatcher externo.

---

### 10) QEMU (`-M bamboo -cpu 440-xilinx`): **FATO** — quem gera os acessos `0x4808xxxx` (registrador + instrução)

#### 10.1) FATO (endereços inválidos observados)
- O `qemu.log` reporta leituras inválidas em sequência em uma janela contígua que cruza `0x48080000` (ex.: `Invalid read at addr 0x4807FFFC`, `0x48080000`, `0x48080004`, …).

#### 10.2) FATO (instrução que faz a leitura e registrador-base)
Trecho executado em loop:
- **EA:** `0x00008FD0..0x00008FE0`
- **Bytes (BE):** `1D 88 00 14  7C C4 62 14  80 E6 00 04  60 00 00 00  41 81 FF E0`
- **Assembly:**
  - `0x00008FD0: mulli r12, r8, 0x14`
  - `0x00008FD4: add   r6,  r4, r12`
  - `0x00008FD8: lwz   r7,  4(r6)`  ← **leitura que depende de `r6`**
  - `0x00008FDC: nop`
  - `0x00008FE0: bgt   0x8FC0`

#### 10.3) FATO (dump de registradores no instante do `lwz r7,4(r6)`)
Em um run com `qemu-system-ppc ... -singlestep -d cpu,in_asm,guest_errors`:
- **NIP:** `0x00008FD8` (PC no `lwz r7, 4(r6)`)
- **GPRs relevantes:**
  - `r4 = 0x4800864F`
  - `r8 = 0x00000E43`
  - `r12 = 0x00011D3C` (**confere** com `r8*0x14`)
  - `r6 = 0x4801A38B` (resultado do `add r6,r4,r12`)
- **Endereço efetivo lido pelo `lwz`:** `EA = r6 + 4 = 0x4801A38F` (já fora de qualquer RAM/ROM mapeada no nosso modelo ⇒ rejeitado pelo QEMU).

#### 10.4) FATO (por que isso é suspeito: `r4` é word de instrução)
O valor de `r4 = 0x4800864F` bate exatamente com o word em low-memory:
- **EA:** `0x00000004`
- **Bytes (BE):** `48 00 86 4F` = `bla 0x864C`

#### 10.5) Impacto no objetivo
- Não é “sensores funcionando”: é **um loop fazendo loads usando um base pointer que é igual a word de branch**.
- O sintoma `0x4808xxxx` é explicado mecanicamente por `r6` caminhando (com `r8` crescendo) e o `lwz` varrendo uma região `0x480xxxxx`.

#### 10.6) Próximo passo (ROI máximo)
- Capturar **onde `r4` recebe `0x4800864F`** (EA + bytes + instrução) e decidir se:
  - é **corrupção de dados** (ex.: carregou de `0x00000004` por bug/patch anterior), ou
  - é **ponteiro/tagging/janela** não modelada (menos provável aqui porque o valor coincide com opcode de branch).

### Resumo brutalmente honesto
Tem dois gargalos que estão **objetivamente** travando a ligação “duty → EPC/TCC/shift” sem virar fanfic:
- **`r13+0x15D0` não tem init visível** em PPC “normal” neste BIN (só *clear*).
- **`tpu_pwm_queue_build_and_schedule_task3 @ 0x395B4` não tem `bl` direto**, então o caminho pra achar “quem chama” não é XREF — é **tabela/dispatch do scheduler** e/ou VLE.

---

### 12) [Débito técnico] PowerPC 405: branch relativo `b` com destino incorreto
**FATO:** Em 0x181E8, `b 0x18298` (bytes `48 00 00 2c`) faz o QEMU/405 desviar para **0x18214**, não 0x18298.
**Workaround:** Usar `ba 0x18298` (branch absoluto).
**Próximo passo:** Consultar manual MPC405 para semântica do branch relativo.

---

### 1) `r13+0x15D0` (IO dispatch root): init ausente em PPC
**O que é (fato):**
- `r13+0x15D0` é usado como *root pointer* (ex.: `lwz r12, 0x15D0(r13)` seguido de `lwz r12, 4(r12)`).
- existe um teardown explícito que zera o root:
  - `0x0003A7F8: stw r12, 0x15D0(r13)` com `r12=0`.
- varredura do BIN por `stw rX, 0x15D0(r13)` dá **1 ocorrência** (o clear).
- varredura do BIN por `addi rX, r13, 0x15D0` dá **0 ocorrências**.

**O que deveria ser (pra facilitar reverse):**
- um init explícito (store ou `addi`+`stw`) ou uma rotina de copy/reloc fácil de seguir.

**Hipóteses restantes (ordem de plausibilidade):**
- **pré-init fora desta imagem**: boot ROM / estágio anterior entra com RAM populada e o firmware assume.
- **init em VLE**: o IDB está em decode mixed (PPC+VLE); init pode estar em instruções compactas que não aparecem no nosso scan PPC-only.
- **init por store indexado** (`stwx`/loop) sem `stw disp(r13)` óbvio (ainda não achamos um writer).
 - **(importante)**: a tabela de ranges `0x2A540` existe e cobre o bloco onde cai `0x15D0`, mas **ainda não temos o consumidor/aplicador provado** em PPC “direto” (sem xref/`lis/addi` explícito) — isso reforça VLE/indireto.

**Impacto direto:**
Sem o valor inicial de `0x15D0`, fica impossível “dump/parsing” estático da tabela `ID → handler/ctx` com confiança.

**Evidência nova relevante (fato):**
- Encontramos execução real de tasks via tabela em RAM com `fnptr` em `task_entry+0x4` (call indireto `mtlr; blrl`) em **`sub_30C98 @ 0x00030C98`**, usando o bloco RAM **`0x003FA400`**.
- Isso é crítico porque **`0x003FA4D0` (=`r13+0x15D0`) mora no mesmo bloco**: a rotina (ou init) que popula `0x003FA400..` é candidata forte a também inicializar o root de IO dispatch.

**Armadilha nova (fato, mas suspeita):**
- Existe uma instrução **PPC** em `0x00023CBC` codificada como `stb r19, 0x15D0(r13)` (word `0x9A6D15D0`).
  - Se isso for *realmente* PPC (não VLE), é **incompatível** com `0x15D0` ser um ponteiro usado por `lwz r12, 0x15D0(r13)` em outros paths: um `stb` corromperia o root pointer.
  - Conclusão prática: **não use esse write como “init do 15D0”** até validar se essa região está em VLE/misdecode (ou se `r13` foi repurposed — até agora não achamos writes para `r13` nesse trecho).

---

### 1.1) Padrão clássico de firmware **data-driven** (e por que PPC-only esgotou)
Isso merece ficar explícito, porque é o ponto onde a investigação muda de marcha.

**O que é (fato, com números):**
- Foi feito um scan **PPC-only** de stores no bloco `r13+0x1500..0x3BFF` (que contém `r13+0x15D0 = 0x003FA4D0`):
  - **696 stores** no total
  - agrupados em **127 clusters** por proximidade de PC
- Mesmo assim, `r13+0x15D0` aparece em PPC “claro” de forma extremamente limitada:
  - **1 clear** (`0x3A7F8: stw 0, 0x15D0(r13)`)
  - **1 write “impossível”** (`0x23CBC: stb …, 0x15D0(r13)`) que, se executado como PPC real, **corrompe** um campo que é tratado como ponteiro em outros paths
- `r13+0x15AC` (ponteiro temp da fila PWM) tem um problema análogo:
  - `0x395B4` escreve `stw r3, 0x15AC(r13)` (ponteiro)
  - existe um `0x3911C: sth r10, 0x15AC(r13)` (word `0xB14D15AC`) que, se executado como PPC real, **corromperia** o ponteiro

**Conclusão operacional (o que isso *significa*):**
- Isso é o padrão clássico de firmware **data-driven**: parte do init “de verdade” do bloco RAM (incluindo `r13+0x15D0`) **não aparece** como stores PPC óbvios.
- **Update crítico (FATO):** o *root* do TaskTable (`*(0x003FA400)`) **tem writer PPC direto**:
  - `0x00030220: lis r12, 0x40` (bytes `3D 80 00 40`)
  - `0x00030224: stw r31, -0x5C00(r12)` ⇒ `*(0x003FA400)=r31` (bytes `93 EC A4 00`)
  - isso ocorre dentro de `init_roots_write_3FA400_from_r3` (antigo `sub_2FFFC`), e `r31` recebe o `arg0` (`0x0003000C: addi r31, r3, 0`).
- A origem mais provável é:
  - **VLE** (instruções compactas não capturadas pelo scan PPC-only), e/ou
  - **estágio anterior / boot ROM**, e/ou
  - **loops por store indexado** (`stwx` / memcpy/memset por tabela) que não aparecem como `stw disp(r13)`

**Impacto direto na estratégia:**
- Continuar “PPC-only + XREF por ponteiro cru” aqui tende a gerar ruído.
- O próximo passo produtivo é:
  - localizar **quem chama** `init_roots_write_3FA400_from_r3` e **qual ponteiro entra em `r3`** (isso determina o root real do TaskTable),
  - e em paralelo, continuar a análise do aplicador da tabela `0x2A540` (porque ele ainda pode ser responsável pelo *fill* e por outros roots no bloco).

**Referência (documentado):**
- veja `11-ram-block-store-clusters.md` para os clusters críticos e o mapa top-20.

---

### 2) `tpu_pwm_queue_build_and_schedule_task3 @ 0x395B4`: sem `bl` direto
**O que é (fato):**
- não existe `bl` direto para `0x395B4` no BIN (scan de branches PPC).
- dentro dela, o final chama `scheduler_post_or_arm_task` com **TaskID = 3** e publica `queue` em `r13+0x15A8`.

**O que deveria ser:**
- call sites diretos (ou tabela de function pointers facilmente localizada).

**Implicação prática:**
Pra achar o “produtor do duty/command”, o alvo correto é:
- recuperar o **TaskTable entry** do scheduler que aponta para `0x395B4`,
- recuperar o **ctx ptr** passado em `r3` (isso é o `queue`),
- daí sim achar writers no `queue->entries[i]`.

---

### 3) Pitfall recém-descoberto: ponteiros “tagged” (top-byte) em tabelas ROM
**O que é (fato):**
- Em `off_2A458` (usado por `sub_4410C @ 0x4410C`) existe pelo menos um word no formato `0xTT02A500` (ex.: **`0x7F02A500`**).
- O código que consome (`sub_4410C`) **não mascara** o valor (não faz `& 0x00FFFFFF`): ele usa o word como ponteiro “cru”.
- Portanto, o mais provável é: **top-byte não é só “tag lógica”**, e sim parte do **espaço de endereçamento** em runtime (ex.: `0x7Fxxxxxx`, `0x6Fxxxxxx`, `0x51xxxxxx` como janelas/bases), e o low-24 é apenas o offset dentro dessa janela.
- O alvo low-24 (`0x02A500`) contém um bloco coerente de dados de configuração (ex.: `0x02A500: 0002A4F0 0002A4E4 00010000 ...`), então não parece ruído aleatório.
**Evidência adicional (fato, mais forte):**
- Dentro do próprio bloco em `0x02A500`, a tabela em `0x02A4F0` contém opcodes/words com top-byte != 0:
  - `0x51390000` (tag `0x51`, low24 `0x390000`)
  - `0x6F0440C4` (tag `0x6F`, low24 `0x0440C4` → aponta para `sub_440C4 @ 0x440C4`)
  - `0x7C000000` (tag `0x7C`, low24 `0x000000`)
  - `0xB6000000` (tag `0xB6`, low24 `0x000000`)
- Isso reforça que **não é um caso isolado**: existe um “mini-VM/bytecode” ou esquema de ponteiros/opcodes com tag no top-byte.

**Por que isso importa (impacto direto):**
- Explica por que “buscar `u32 == 0x000395B4`” ou “buscar ponteiros por valor exato” **pode falhar**: a ROM pode armazenar referências **tagged/comprimidas**, não endereços crus.

---

### 4) Outro componente relevante (atualizado): "mini-interpreter"/dispatcher que configura ponteiros em SDA (`0x1638/0x163C`)
Foi identificado um interpretador simples de entries em memória:
- **`sub_31C84 @ 0x31C84`** lê um opcode em `*(entry+0x0)` e executa ações.
- Opcodes observados (pelo assembly):
  - **`1`**: `stw *(entry+0x8), 0x1638(r13)` → publica um ponteiro-base em SDA
  - **`3`**: `stw (result+8), 0x166C(r13)` (via `sub_327BC`)
  - **`4`**: `mtctr *(entry+0x8)` e preenche `*(entry+0x10)` com `0xFF` por `ctr` iterações (memset-like)
  - **(outros)**: escreve em `0x163C(r13)` (ponteiro de callback/contexto) e aciona helpers

**Por que isso importa AGORA (com updates dos agentes):**
- `sub_31FC4` e `sub_327C0` usam **`0x1638(r13)`** e **`0x163C(r13)`** para navegar tabelas/descritores e fazer chamadas indiretas.
- Isso é exatamente o padrão "tabela em RAM + call indireto" que impede XREF clássico — e pode ser o caminho de init que eventualmente popula o bloco `0x003FA400..` (scheduler/IO).
- **Confirmação:** Agente 1 provou que **não há init PPC direto** do bloco RAM; Agente 2 mostrou que tagged pointers são janelas de endereço. Logo, o init vem deste dispatcher indireto.
- **Update Final (Agente 2):** 4 engines de dispatch indireto identificadas + candidato forte de tabela em 0x2A6F4 com opcodes 1/3/4. Engine A (0x43F84) conecta diretamente com init do bloco RAM via sub_44460.

**Resolução dos Gargalos (Status Final):**
- 🔄 **r13+0x15D0**: ainda sem writer init provado (além do clear). Continua sendo gargalo real.
- ✅ **`*(0x003FA400)` (TaskTable root)**: writer PPC provado em `0x00030224` (ver acima). Falta: callsite/arg0.
- ✅ **TaskID=3 @ 0x395B4**: caminho e consumidores do TaskTable mapeados; faltam os detalhes do init completo do bloco em runtime (incluindo roots auxiliares).
- 🔄 **Próximo:** capturar/derivar o **arg0** real passado a `init_roots_write_3FA400_from_r3` (o valor que vira o root) e então seguir `root->...` até os producers PWM.

---

### 5) Descoberta crítica: `0x1648/0x164C` são **cursor/lista de callbacks**; o primeiro callback (`0x32840`) contém **words “raw”/hazards** (quebra QEMU sem patch)
Isso explica **objetivamente** por que o boot “morre” cedo no QEMU: ele entra num loop que chama um fnptr cuja execução depende de instruções/words que o modelo atual não tolera sem contorno.

**FATO (init do cursor/lista):**
- Existe uma rotina **PPC** que constrói o endereço **`0x0040B154`**, escreve um fnptr inicial e publica esse endereço em `r13+0x1648`:
  - `0x00031BE4: lis r3,0x40` (word `0x3C600040`)
  - `0x00031BEC: addi r3,r3,0xB154` ⇒ `r3=0x0040B154` (word `0x3863B154`)
  - `0x00031BF0: addi r9,r9,0x2840` com `lis r9,0x3` ⇒ `r9=0x00032840` (words `0x3D200003` + `0x39292840`)
  - `0x00031BF4: stw r9,0(r3)` ⇒ `*(0x0040B154)=0x00032840` (word `0x91230000`)
  - `0x00031C60: stw r3,0x1648(r13)` ⇒ `*(r13+0x1648)=0x0040B154` (word `0x906D1648`)

**FATO (runner do cursor/lista):**
- Existe um loop **PPC** que consome `r13+0x1648` e chama `*(cursor)` via `mtlr; blrl`:
  - `0x0003294C: lwz r3,0x1648(r13)` (word `0x806D1648`)
  - `0x00032950: stw r3,0x164C(r13)` (word `0x906D164C`)
  - `0x00032954: addi r10,r3,4; 0x00032958: stw r10,0x1648(r13)` (words `0x39430004`, `0x914D1648`)
  - `0x00032960: lwz r9,0x164C(r13); 0x00032964: lwz r9,0(r9); 0x00032968: mtlr r9; 0x0003296C: blrl`

**FATO (por que QEMU quebra aqui):**
- O primeiro fnptr gravado na lista é `0x00032840` (ver init acima).
- Os bytes do entrypoint **começam com PPC válido** (ex.: `0x00032840: 94 21 FF F0` = `stwu r1,-0x10(r1)`), mas o bloco contém **words “raw”** embutidos que exigem patch no harness QEMU:
  - `0x000328DC`: word `0x00FFC010` (bytes `00 FF C0 10`)
  - `0x000328FC`: word `0x178CB154` (bytes `17 8C B1 54`)
  - Evidência prática: `scripts/qemu_e500_run_callback_32840_patch_and_dump_list.sh` faz NOP nesses pontos (e outros) para conseguir progredir e observar side-effects.

**Impacto no objetivo:**
- O “callsite real” do init do bloco (`0x003FA400` writer em `0x00030224`) **pode estar atrás desse callback** (ou ele pode popular listas que incluem o writer). Sem contornar os hazards internos do `0x32840`, o QEMU tende a nunca chegar no path que escreve `*(0x003FA400)` em modo “orgânico”.

**Próximo passo (ROI máximo):**
- Extrair/decodificar a semântica do callback `0x00032840` (ou contornar via patch controlado) para ver **quais callbacks adicionais ele instala na lista em `0x0040B154`** e se/onde aparece o `init_roots_write_3FA400_from_r3` (`0x2FFFC` / `0x30224`).
- Evidência dinâmica atual (com harness fabricado+patchado): `scripts/qemu_e500_run_callback_32840_patch_and_dump_list.sh` mostrou `LIST @0x0040B154` mantendo apenas `0x00032840` em `0x40B154` e `0x40B158..` zerados (não observou `0x2FFFC` nesse cenário).

---

### 6) Evidência objetiva: o callback `0x32840` depende de roots SDA ainda sem init (especialmente `0x1644`)
Isso não é opinião: dá pra provar só com bytes PPC-aligned.

**FATO (leituras SDA dentro de `0x00032840..0x00032934`):**
- `0x00032850: lwz r12, 0x1664(r13)` (word `0x818D1664`)
- `0x00032878: lwz r31, 0x166C(r13)` (word `0x83ED166C`)
- `0x00032898: lwz r31, 0x1644(r13)` (word `0x83ED1644`)
- `0x000328CC: lwz r12, 0x1638(r13)` (word `0x818D1638`)
- `0x000328E8: lwz r10, 0x1648(r13)` (word `0x814D1648`)
- `0x00032904: lwz r12, 0x1638(r13)` (word `0x818D1638`)

**FATO (escritas SDA no mesmo bloco):**
- `0x000328B8: stw r12, 0x164C(r13)` (word `0x918D164C`)
- `0x000328C4: stw r12, 0x1660(r13)` (word `0x918D1660`)
- `0x00032900: stw r12, 0x1648(r13)` (word `0x918D1648`)

**FATO (gargalo exato):**
- Scan PPC-only por `stw ?, 0x1644(r13)` retornou **0 writers**.\n  ⇒ o `0x1644` vem de **VLE / store indexado / estágio anterior**.

**Impacto no objetivo:**
- Sem descobrir o init do `0x1644`, qualquer tentativa de executar o callback “como no hardware” no QEMU vai falhar cedo (porque ele lê `0x1644` e segue uma cadeia de ponteiros/calls).

---

### 6.1) Consumidores de `0x1638(r13)` e callers de `dispatch_via_1638_slot60` (atualização)
**FATO (único writer PPC de `0x1638`):**
- Scan em `.ida-mcp/stores_to_r13_1400_1700.json`: **único** `stw ?, 0x1638(r13)` em **`0x31CE0`** (função `mini_interpreter_publish_sda_roots` / `sub_31C84`).

**FATO (uso sem máscara):**
- Em `dispatch_via_1638_slot60` @ `0x31FD8`: `lwz r12, 0x1638(r13)`; em seguida `lwz r12, 0x60(r12)`. O valor é usado **como ponteiro direto** (sem AND/resolução de tag). Se `0x1638 = 0x37000000`, o acesso seria a `[0x37000060]` (inválido em PPC puro).

**FATO (callers de `0x31FC4`):**
- Busca no BIN por `bl` cujo alvo é `0x31FC4`: **dois** callers:
  - **`0x4A448`** (em `sub_4A3B4`): imediatamente antes, `stw r4, 0x1608(r13)`; depois `bl dispatch_via_1638_slot60`.
  - **`0x4B498`** (em `sub_4B474`): tail call `b dispatch_via_1638_slot60`; antes chama `nullsub_5`, `loc_257EC`, `loc_32348`.

**Interpretação objetiva:**
- Quando `0x4A448` ou `0x4B498` executam, `0x1638(r13)` **já deve** ser um ponteiro válido (não tagged `0x37000000`). O único writer PPC é `0x31CE0`; logo o valor em `0x1638` vem de uma **execução anterior** do mini-interpreter com uma tabela cuja entrada de opcode 1 tem `*(entry+8)` = ponteiro real (ex.: `0x003FAxxx`), não `0x37000000`.
- **Não há** “resolver” PPC que converta tagged `0x37000000` em ponteiro antes do uso; os consumidores usam o valor como base direta.

**Próximo passo de ROI:**
- Identificar **qual(is) tabela(s)** do mini-interpreter são executadas **antes** de `0x4A448`/`0x4B498` no path de boot e se alguma tem em `entry+8` um ponteiro RAM válido (ex.: `0x003FAxxx`). Isso explicaria o valor em `0x1638` quando `dispatch_via_1638_slot60` é chamado. O init de `0x1644` continua **DESCONHECIDO** (sem writer PPC).

**FATO (tabela candidata com ponteiro RAM em entry+8):**
- Scan no BIN (ROM 0x0..0x30000) por estruturas tipo tabela do mini-interpreter: **word em +0 = 1** (opcode 1) e **word em +8 em range 0x3F8000..0x400000** (RAM) → **uma única hit: EA `0x267E8`**.
- Dump em `0x267E8`: `0x00000001`, `0x00000002`, **`0x003FB16E`** (entry+8), `0x00000011`, `0x00000000`, `0x260267E8`, …
- **Interpretação:** Se o mini-interpreter for invocado com **r3 = 0x267E8**, a ação do opcode 1 será **`stw 0x003FB16E, 0x1638(r13)`** → valor em `0x1638` seria um **ponteiro RAM válido**, não tagged.
- O único literal `0x267E8` no BIN não aparece como word; em `0x267FC` aparece **`0x260267E8`** (tag 0x26 + offset 0x267E8), autorreferência da própria tabela. Logo o acesso a essa tabela é **indireto** (tagged pointer ou via `0x3688(r13)` / outro base). **DESCONHECIDO:** quem de fato chama o mini-interpreter com r3 = 0x267E8 no boot.

**FATO (harness QEMU):** O script **`scripts/qemu_e500_call_31c84_table_267e8.sh`** invoca `0x31C84` com **r3 = 0x267E8** (tabela em ROM). Após ~80 steps: **`*(r13+0x1638) = 0x003FB16E`** (dump em `0x003FA538`). Isso prova que a tabela em **0x267E8** é suficiente para popular **0x1638(r13)** com ponteiro RAM válido, compatível com o uso em `dispatch_via_1638_slot60`.

### 6.2) Slot SDA `0x3688(r13)` — leituras vs único writer PPC

**FATO (scan PPC no BIN):**
- **`lwz ?, 0x3688(r13)`** em: **`0x48F48`**, **`0x490C8`**, **`0x49C20`**, **`0x49D98`**, **`0x49FB8`**, **`0x4B4EC`** (words `818D3688` / `810D3688` / `834D3688` / `83CD3688` / `838D3688` conforme RT).
- **`stw ?, 0x3688(r13)`** — **uma única** ocorrência: **`0x49390`** (`912D3688`).
- Imediatamente antes: **`0x4938C`**: `39 20 00 00` = **`addi r9, r0, 0`** (`li r9, 0`).

**Interpretação objetiva:** O único store PPC direto em **`0x3688(r13)`** **zera** o slot (`r9 = 0`), não publica ponteiro para **`0x267E8`** nem base RAM. Os consumidores em **`0x4B4EC`** (`sub_4B4D8`) e vizinhos esperam um ponteiro não-nulo para usar **`base+0x1554`** / **`base+0xAA8`** — logo, se em HW o slot for não-nulo, a promoção é **fora** deste `stw` PPC ou exige **outro mecanismo** (VLE, `stwx`, cópia de RAM, estágio não mapeado no scan D-form).

**DESCONHECIDO:** segundo writer não-D-form ou ordem real boot vs. clear em **`0x49360..0x49390`**.

---

### 7) QEMU (e500) não chega no init “de verdade” sem bypass agressivo: MMIO + self-loops bloqueiam o caminho
**FATO (MMIO polling loop):**
- O reset entra em `init_immr_mmio_window_30xx @ 0x00008138`, que faz loop em leituras/escritas MMIO:
  - `0x00008160: lis r3,0x30`
  - `0x00008168: lwz r0, -0x3D7C(r3)` ⇒ EA `0x2FFFC284`
  - `0x00008170: stw r0, -0x3D7C(r3)` ⇒ EA `0x2FFFC284`
  - `0x00008190: sth r11, 0x6800(r3)` ⇒ EA `0x30006800`
- Em QEMU, isso não tem hardware por trás → o loop impede progresso até o subsistema de init/dispatch.

**FATO (decodificação do loop “ready” — bytes no BIN `5U75-14C337-AA.rebuilt.aligned.bin`):**
- Trecho em `0x00008174..0x00008184` (PPC32, BE):
  - `0x00008174: 3c 60 00 30`  `lis   r3, 0x30`
  - `0x00008178: 81 63 c2 84`  `lwz   r11, -0x3D7C(r3)`  ⇒ EA `0x2FFFC284`
  - `0x0000817C: a3 6b 87 fe`  `lhz   r27, -0x77F2(r11)` (depende de `r11`)
  - `0x00008180: 2c 0b 00 00`  `cmpwi r11, 0`
  - `0x00008184: 41 82 ff f0`  `beq   0x00008174`
- Interpretação objetiva: o firmware **poll** até o word em `0x2FFFC284` ficar **!= 0**. Sem dispositivo mapeado, `lwz` tende a retornar `0` e o loop não termina.

**FATO (semântica operacional do loop):**
- Se algum hardware/periférico fizer com que a leitura em `0x2FFFC284` retorne **não-zero**, o branch `beq 0x00008174` **não** é tomado e o firmware **continua** o fluxo de inicialização.
- Se a leitura permanecer em `0x00000000`, o firmware fica preso em polling infinito nesse ponto.
  - **DESCONHECIDO**: qual periférico real alimenta `0x2FFFC284` (sem datasheet/IDCODE/memory map do MCU, não dá para afirmar).

**FATO (stub mínimo “ready” via patch de instrução, usado nos harnesses QEMU):**
- Forçar `r11 != 0` no ponto do poll e remover o `lhz` dependente:
  - `0x00008178: 81 63 c2 84` (lwz r11, -0x3D7C(r3)) → `39 60 00 01` (li r11, 1)
  - `0x0000817C: a3 6b 87 fe` (lhz r27, -0x77F2(r11)) → `60 00 00 00` (nop)

**Impacto no objetivo (QEMU):**
- Esse loop é um **bloqueio de boot**: sem “ready”, QEMU não chega no init/dispatch do scheduler/IO.
- O patch acima é um **bypass mínimo e verificável** para permitir progressão e coleta de PCs/efeitos, até modelarmos MMIO/IMMR corretamente.

---

### 8) QEMU `-cpu 405`: **FATO** — corrupção de stack/LR causa retorno para vetores low-memory (`0x80/0xA0/0xBC`)
Este bloco não é “narrativa”: é **efeito mecânico** de instruções que escrevem em `r1` (SP) e/ou não restauram o `LR` corretamente no caminho executado pelo harness.

#### 8.1) Evidência objetiva (EA + bytes + instrução)
**FATO (clobber de `r1`):**
- **EA:** `0x00007E5C`
- **Bytes (BE):** `77 81 00 28`
- **Instr (PPC32):** `andis. r1, r28, 0x28`
- **Interpretação objetiva:** escreve em `r1` (stack pointer) ⇒ corrompe frame/slots usados para restaurar `r0/LR`.

**FATO (epílogo “quebrado” para LR):**
- **EA:** `0x00007F5C`
- **Bytes (BE):** `85 01 00 1C`
- **Instr:** `lwzu r8, 0x1C(r1)`
- **Interpretação objetiva:** atualiza `r1` e carrega em `r8`; **não** restaura `r0` salvo em `0x1C(r1)`.
- Em seguida, o epílogo executa:
  - `0x00007F60: 7C 08 03 A6` `mtlr r0` ⇒ `LR` recebe lixo se `r0` não foi recarregado.

#### 8.2) Evidência dinâmica (trace QEMU)
**FATO:** após `blr` em epílogos, o PC cai em vetores low-memory quando `LR` está inválido.
- Exemplo observado no trace: execução em `0x00000080` (vetor redirecionado pelo harness) após `blr`.

#### 8.3) Correção mínima aplicada no harness (reprodutível)
**FATO (patches no `scripts/qemu_patch_loop.py`):**
- `0x00007E5C`: NOP (remove `andis. r1, r28, 0x28`)
- `0x00007F5C`: `lwz r0, 0x1C(r1)` (bytes `80 01 00 1C`) para restaurar `r0` salvo
- `0x00007F64`: NOP (remove drift `addi r1,r1,0x18`)

#### 8.4) Progresso objetivo após correção (novo range alcançado)
**FATO:** após os patches acima, a execução alcançou e executou init em `0x00008BB4..0x00008C50` (escritas em `r13+0x6Fxx`), ex.:
- `0x00008BC0: stw r3, 0x6F98(r13)`
- `0x00008BE4: stw r9, 0x6FC0(r13)`
- `0x00008BF4: stw r12, 0x6FC8(r13)`
- `0x00008C18: stw r10, 0x6F74(r13)`
- `0x00008C40: bl 0x9B34` (retorna)
- `0x00008C50: blr`

**FATO:** nesse caminho o harness detectou e NOPou bloqueios específicos de decode/SPR:
- `invalid_opcode`: `0x00008BBC`, `0x00008BDC`, `0x00008BFC`
- `invalid_spr`: `0x00008BF8`

#### 8.5) Próximo passo (ROI máximo)
- Capturar o **primeiro bloqueio pós-`0x00008C50`** com **EA + bytes + snippet** (opcode/SPR/MMIO). Isso define o próximo stub/patch mínimo sem fanfic.

---

### 9) QEMU `-cpu 405`: **FATO** — segfault do host (rc=-11) ao atingir `0x00008EC0..0x00008EC4` (não é exceção do guest)
Este é um gargalo qualitativamente diferente: **o QEMU cai** (processo morre com `SIGSEGV`, rc `-11`) **sem imprimir** `invalid_opcode/invalid_spr` no log.

#### 9.1) Evidência objetiva (últimas instruções antes do crash)
**FATO (trace QEMU, último bloco `IN:` no `qemu.log`):**
- `0x00008EC0: 2c 03 00 00`  `cmpwi r3, 0`
- `0x00008EC4: 48 00 8e de`  `ba 0x8EDC` *(patch do harness; o crash ocorre imediatamente após esta instrução)*

**FATO (quando `0x8EB8` é NOP para fall-through, antes do patch do branch):**
- `0x00008EBC: a8 60 00 01`  `lha r3, 1(0)` *(acesso com base `0`, inválido; foi NOPado no harness)*
- Mesmo após NOP em `0x8EBC`, o QEMU continuou morrendo imediatamente após `0x8EC4`.

#### 9.2) Evidência objetiva (bytes do trecho em ROM)
**FATO (bytes @ `0x00008EC0..0x00008EDC`, PPC32 BE):**
- `0x00008EC0`: `2c 03 00 00 40 82 00 18 38 60 00 00 81 6d 6f 94 61 6b 00 40 91 6d 6f 94 48 00 00 08 ...`
- `0x00008EDC`: word observado como `0x0A600001` (IDA não decodificou nesse endereço; no harness foi NOPado por precaução).

#### 9.3) Interpretação objetiva
- **FATO:** o crash é **do host** (QEMU), não um “trap/Program Exception” do guest.
- **FATO:** o harness não consegue “auto-patchar” esse caso porque não há `invalid_opcode`/`invalid_spr` reportado pelo QEMU antes do processo morrer.

#### 9.4) Próximo passo (ROI máximo)
- Rodar o QEMU **sob gdb** ou em uma build mais nova (ou com `-d in_asm,exec,cpu` + core dump) para capturar **PC exato** do segfault no host e correlacionar com a transição `0x8EC4 -> 0x8EC8/0x8EDC`.
- Alternativa pragmática para continuar exploração: **bypass** do bloco inteiro (branch dirigido para um “safe path”) até que o bug do QEMU seja entendido/corrigido.

**FATO (próximo gargalo após o “ready stub” no QEMU, cpu=405):**
- Ao aplicar o bypass do loop (`0x8178/0x817C`), a execução progride até `system_init_early @ 0x00008204`, onde QEMU encontra instruções não decodificadas nesse modelo:
  - `0x0000821C`: word `0xE2E30004` (no log QEMU aparece como `.long` e dispara `invalid/unsupported opcode`).
- O harness automático (`scripts/qemu_patch_loop.py`) confirma a cadeia:
  - iter 1: patch `0x0000811C` (word `0x7B210010`)
  - iter 2: patch `0x0000821C` (word `0xE2E30004`)
  - iter 3: patch `0x0000867C` (`invalid_form`)
- Interpretação objetiva: depois do “ready”, o próximo bloqueio não é polling MMIO, e sim **ISA/CPU-model mismatch** (instruções não suportadas pelo QEMU `-cpu 405`) e/ou **mix PPC/VLE/SPE** no caminho de boot.

**FATO (tentativa de “bater Qorivva/e200” via QEMU):**
- `qemu-system-ppc` **tem** CPU models `e200/e200z6/e500` disponíveis (`qemu-system-ppc -cpu help`), mas:
  - `-M none -cpu e200/e500`: o core inicia com `pc=0x0`, porém o GDB não consegue ler memória em `0x0` (`Cannot access memory at address 0x0`) ⇒ o setup não é funcional para executar o firmware nesse modo.
  - `-M ppce500 -cpu e200z6`: o QEMU aborta com assert (`qdev_get_gpio_in_named`), indicando incompatibilidade de CPU com a máquina.
  - `-M ppce500 -cpu e500`: o core reset **não** começa em `0x0`, e sim em `0x00F00000` (ROM da máquina). Para entrar no nosso BIN carregado em `0x0`, foi necessário um **reset-stub** em `0x00F00000` (`ba 0x0`, bytes `48 00 00 02`).
- Mesmo após entrar no nosso BIN com `-M ppce500 -cpu e500`, os mesmos gargalos de instruções não decodificadas aparecem (ex.: word `0xE2E30004`), ou seja: “mudar para e500/e200” **não elimina** o problema de ISA/mix do boot nesse harness.

**FATO (self-loop no boot):**
- No reset handler `0x0000864C`, existe `0x00008688: b loc_8688` (loop infinito).
- Mesmo quando você “pula” o MMIO (`0x00008670` NOP) e “quebra” o self-loop (`0x00008688 -> 0x48000004`), pode ocorrer retorno ao reset (`pc=0x0000864C`, `lr=0x0000867C`) — evidência via `scripts/qemu_e500_probe_reach_8684_and_traps.sh`.

**Impacto no objetivo:**
- Explica objetivamente por que watchpoints/breakpoints para `0x31BE4` (init da lista), `0x32840` (callback), `0x2FFFC/0x30224` (writer do root) **não disparam** em runs “orgânicos” no QEMU.

**Scripts/harnesses relevantes (reprodutíveis):**
- `scripts/qemu_e500_watch_list_root_organic_boot.sh`: watchpoints em `0x0040B158` e `0x003FA400` durante boot com patches.
- `scripts/qemu_e500_probe_reach_8684_and_traps.sh`: prova se o fluxo alcança/volta do `0x8684/0x8204`.
- `scripts/qemu_e500_watch_callback_list_and_root.sh`: runner+callback fabricado com watchpoints.



