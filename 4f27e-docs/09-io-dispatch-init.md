## 09 — Init dos globais `r13+0x15D0/0x15D4` (IO dispatch)

### Resumo brutalmente honesto
O “problema” de extrair a tabela de IO (`r13+0x15D0`) não é falta de XREF: é **inicialização via dados/boot tables**, não via `stw` óbvio em função bem nomeada.

Nesta rodada a gente saiu do “acho que é RAM” e chegou em evidência concreta:
- `r13+0x15D4` **é alocado** em runtime e zerado.
- `r13+0x15D0` tem pelo menos um path que **zera** (desregistra) o root — e isso explica porque “às vezes” ele some.
- existem **tabelas de init de RAM** em ROM (com ranges incluindo o bloco onde cai `r13+0x15D0`).

---

### Evidências (fato)

#### 1) `r13+0x15D4` é alocado em runtime
Em `0x0003C084`:
- `li r4, 0`
- `bl loc_26218` (alocador/alloc-like)
- **`stw r3, 0x15D4(r13)` @ `0x0003C088`** (publica ponteiro)
- `slwi r4, r31, 3` (size = `count * 8`)
- `lwz r3, 0x15D4(r13)`
- `li r5, 0`
- `bl sub_2610C` (memset/zero)

Conclusão: `0x15D4` não é “constante em ROM”: é **buffer alocado** (provável tabela de words/bitfields por ID >= `0x64`).

#### 2) `r13+0x15D0` é zerado (teardown/desregistro)
Em `0x0003A7F8`:
- `li r12, 0`
- **`stw r12, 0x15D0(r13)`** (zera root)

O que não aparece (e isso é o ponto): **não existe init simétrico em PPC “normal”**.
- varredura do BIN por opcode (`stw rX, 0x15D0(r13)`) retorna **exatamente 1 hit**: o *clear* em `0x3A7F8`.
- varredura por “address-take” (`addi rX, r13, 0x15D0`) retorna **0 hits**.

Isso empurra a hipótese para:
- **pré-init fora desta imagem** (boot ROM / estágio anterior que já entra com RAM populada), ou
- **init em VLE** (o IDB está em *mixed decode* PPC+VLE), ou
- init via stores indexados (`stwx`/loop) que não aparecem como `stw disp(r13)` — mas até agora não encontramos um writer óbvio.

Há um loop antes disso que lê `lwz r11, 0x15D0(r13)` e consulta `lbz 0(r11)` como “count/limit”, sugerindo que o root tem um layout mínimo tipo:
- `u8 count` em `root+0`
- `u32 entries_base` em `root+4` (confirmado em outras rotinas: `lwz r29, 4(root)`)

#### 3) Tabelas de init de RAM em ROM (incluem SDA/SDA-adj)
Encontramos duas classes de “boot tables” em ROM:

- **Tabela simples de ranges** em `0x00010B40`:
  - `0x003F9000 .. 0x003FCAFF`
  - `0x003FFB00 .. 0x003FFFFF`
  - terminador `0x00000000, 0x00000000`
  - **Aplicador identificado**: `init_copy_or_zero_ranges @ 0x00017AE8` (itera tabela e chama `memset_like_loc_1796C` com fill=0).
  - **Evidência direta (Agente 2)**: 
    - `0x17B08: lis r28, dword_10B40@ha; addi r28, r28, dword_10B40@l` (carrega tabela)
    - `0x17B2C: mtlr r11` (r11 = memset_like_loc_1796C @ 0x1796C)
    - `0x17B44: blrl` (chama memset com fill=0)
  - **impacto direto em `0x15D0` e `0x3FA400`**: como `r13 = 0x003F8F00`, então:
    - `r13+0x15D0 = 0x003FA4D0` (cai dentro de `0x003F9000..0x003FCAFF`)
    - `0x003FA400` também cai dentro do range
    - **Resultado provado**: ambos nascem zerados (NULL/0) após `init_copy_or_zero_ranges`.

- **Tabela mais rica de init de RAM** em `0x0002A540` (**confirmada** por dump raw):
  - inclui exatamente o bloco alvo: `0x003FA400 .. 0x003FCB00` (contém `0x003FA4D0` = `r13(0x003F8F00) + 0x15D0`)
  - começo do dump (primeiros 5 entries parecem ser `start,end,op,arg`):

    ```
    02A540: 003F8000 003F8F00 04000000 00000000
    02A550: 003F9500 003F9D00 04000000 B6000000
    02A560: 003F9D00 003FA400 04000000 00000000
    02A570: 003FA400 003FCB00 04000000 27000000
    02A580: 003FCB00 00400000 14000000 00000000
    ```

  - **hipótese mais consistente com o formato (ainda não “prova”)**:
    - `op=0x04000000` parece “fill/memset” onde o byte de fill está no **top-byte** do 4º word (ex.: `0xB6xxxxxx`, `0x27xxxxxx`).
    - isso explica por que existem `0xB6000000` e `0x27000000` exatamente como *bytes em posição alta*.

Observação crítica (anti-fanfic):
- o `0x27000000` no entry `0x003FA400..0x003FCB00` **não prova** “copy/reloc” e o nosso teste antigo “olhar o BIN e achar NOP” era **metodologicamente errado** (BIN é ROM; a tabela descreve init de RAM em runtime).
- a pergunta correta é: **quem executa/aplica** essa tabela no boot (ainda aberto).

#### 3.1) Consumidor **provado** de `0x0002A540` (mas execução parcial/externa)
**FATO (prova direta):** existe uma rotina PPC em ROM que **carrega `0x0002A540` explicitamente** e é chamada em runtime.

- **Carregamento da tabela (`0x0002A540`)** em `init_range_table_2A540_apply @ 0x00044460`:
  - `0x0004446C: lis r12, word_2A540@ha`
  - `0x00044470: addi r12, r12, word_2A540@l`  (**r12 = 0x0002A540**)
  - `0x00044474: lswi r7, r12, 4` (lê 4 bytes/1 word da tabela)
  - `0x00044478: stswi r7, r11, 4` (copia para stack)

- **Chamadas PPC diretas (BL) para `0x00044460`** dentro de `sub_448D8 @ 0x000448D8`:
  - `0x0004492C: bl init_range_table_2A540_apply`
  - `0x00044988: bl init_range_table_2A540_apply`
  - `0x000449E8: bl init_range_table_2A540_apply`
  - `0x00044A48: bl init_range_table_2A540_apply`
  - `0x00044AA4: bl init_range_table_2A540_apply`

**FATO (anomalia que importa):** dentro de `init_range_table_2A540_apply`, existe um branch para fora do módulo:
- `0x0004449C: b 0x18544A4` (word `0x49810008`, branch relativo com alvo fora de `0x00000000..0x001FFFFF`).

**Impacto no objetivo:**
- Agora sabemos **onde a tabela `0x2A540` entra em execução** (caminho `sub_448D8 -> init_range_table_2A540_apply`).
- Mas ainda falta provar o **loop que escreve** no range `0x003FA400..0x003FCB00`, porque parte do fluxo pode estar no alvo externo (`0x18544A4`) ou em paths ainda não decodificados.

#### 4) Evidência adicional: `0x003FA400` é raiz de “scheduler/task slots”
Sem depender de XREF, achamos consumidores PPC **claros** que tratam `0x003FA400` como um **ponteiro global para uma struct**:
- `sub_30C98 @ 0x00030C98`: faz `lis/addi -> 0x3FA400`, depois `lwz r10, 0(0x3FA400)` e usa campos (`+8`, `+0x10` etc.) e chama `fnptr` via `task_entry+0x4`.
- `iterate_slots_3FA400_and_update_3FA404 @ 0x00031698`:
  - itera `count = *( *(0x3FA400) + 2 )`
  - consulta `*(0x3FA400)+8` e `*(0x3FA400)+0x10`
  - **escreve em `0x3FA404`** (`stw r12, 0(0x3FA404)` e `stb 0` em `+2`) como parte do estado por-slot.

Conclusão operacional: 
- `init_copy_or_zero_ranges` zera o bloco (root em `0x3FA400` nasce NULL).
- Existe uma fase seguinte que **popula estado real** no bloco (ex.: `0x3FA404` via `iterate_slots_3FA400_and_update_3FA404 @ 0x31698`).
- **Prova negativa (Agente 2)**: scan PPC por stores em `*(0x003FA400)` retornou **zero matches** (nenhum writer PPC do root pointer).
- O ponto que ainda falta é: **quem escreve `*(0x003FA400) = root_ptr`** após o zero-init (hipótese: VLE/boot-stage/pré-init).

Nota (fato): existe evidência de tabelas com **top-byte/tag** em ROM (`0xTTxxxxxx`, ex.: `0x7F02A500`, `0x6F0440C4`) dentro do bloco `0x02A500`. Isso significa que buscas por “ponteiro cru” (`0x0002A540`) podem falhar mesmo quando o dado está sendo usado — o consumidor pode decodificar low-24 ou tratar top-byte como opcode.

---

### O que isso implica (pra “solenóide/marcha”)
Sem recuperar **o valor inicial de `r13+0x15D0`**, a tabela/dispatch por ID fica “no escuro”. A boa notícia: agora sabemos **onde procurar**:
- o bloco que contém `r13+0x15D0` está dentro de um range explícito (`0x003FA400..0x003FCB00`) na ROM.

### Status Final (Agentes 1 + 2)
1. ✅ **Init zero de RAM**: `init_copy_or_zero_ranges @ 0x17AE8` zera ranges incluindo `0x003FA400` (prova direta em PPC).
2. ✅ **Consumidor do root**: `sub_30C98 @ 0x30C98` lê `*(0x003FA400)` e resolve `task_entry → fnptr` (prova direta).
3. ✅ **Prova negativa**: zero writers PPC de `*(0x003FA400)` (scan exaustivo em PPC).
4. ❌ **Writer do root**: não encontrado em PPC → **hipótese forte**: VLE/boot-stage/pré-init.

### Próximo passo (coordenado com VLE-scan)
1. VLE-scan: procurar stores em endereço absoluto `0x003FA400` (ou padrões VLE equivalentes a `lis 0x40; addi -0x5C00; stw`).
2. Se encontrado: validar que seta `*(0x003FA400)` e extrair o `root_ptr` inicial.
3. Com `root_ptr`, aplicar o layout provado: `slots = *(root+8)`, `slot3 = slots + 3*0xC`, `task_entry = *(slot3+8)`, `fnptr = *(task_entry+4)` → verificar se bate com `0x395B4`.


