## 07 — IO/TPU/PWM (rodada: tick → tarefas → saídas)

### Resumo brutalmente honesto
Nesta rodada a análise deixou de ser “mapa mental” e virou **evidência executável**:
- Achamos um **serviço periódico** que drena uma fila de trabalho e chama helpers de **configuração de canal TPU/PWM**.
- Achamos um **dispatcher por ID** que resolve **ID → bloco de registradores TPU** (MMIO `0x304000/0x304400`).
- Achamos um **dispatcher por tabela/trampoline** em `r13+0x15D0` (16 bytes por entrada) com call indireto (`blrl`).

Resultado: agora existe um caminho objetivo pra “marcha/solenóide”:
**tick/task → fila PWM → helpers de canal → registradores TPU**.

---

### Âncoras confirmadas (fato)

#### Serviço periódico de PWM (fila em SDA)
- **`tpu_pwm_queue_service_15A8 @ 0x000394C8`**
  - **SDA**: usa e depois **zera** `r13+0x15A8` (ponteiro de fila/lista de trabalho).
  - **Comportamento**: itera uma worklist e invoca helpers de configuração do canal.
  - **Por que importa**: é o tipo de “serviço de PWM” que normalmente alimenta EPC/TCC/shift solenoids (ainda **não** mapeia qual solenóide é qual).

Helpers chamados:
- **`tpu_channel_update_cfgbit1_or_arm @ 0x00038F24`**
- **`tpu_channel_update_cfgbit8_or_enable @ 0x00038FDC`**

Wrapper de task observado:
- **`task_service_pwm_queue_and_housekeeping @ 0x0004A264`**

#### Dispatcher por ID para escrita/atualização de IO
- **`io_write_by_id_dispatch_15D0_15D4 @ 0x0003C16C`**
  - **SDA**:
    - `r13+0x15D0`: raiz de descritores/entradas por ID (**IDs < 0x64**) com stride de 16 bytes (usa `+4` como base e indexa por `16*id`).
    - `r13+0x15D4`: tabela auxiliar (word/bitfield) usada em paths de IDs maiores (faixas `>= 0x64`).
  - **Observação crítica**: aqui a chamada não é um `bl 0x3BB10` “bonitinho” — o código está estruturado pra dispatch por tabela/ID. Isso explica por que procurar XREF direto para `0x3BB10` falhou.

#### Trampoline por ID (call indireto)
- **`io_dispatch_via_15D0_trampoline_and_clear_mask @ 0x00023F38`**
  - **SDA**: lê a entrada em `r13+0x15D0` (16 bytes por ID).
  - **Evidência de design**:
    - carrega um ponteiro de função da entrada
    - ajusta LR e chama **indiretamente** (`blrl`)
    - usa `entry+0xC` como ponteiro de contexto/dados
  - **Implicação**: qualquer “IO update” relevante pode estar pendurado em uma dessas entradas, não em calls diretos.

---

### Mapeamento parcial confirmado: ID → base TPU (fato)
- **`tpu_channel_regs_ptr_from_id @ 0x00033BA4`**
  - IDs 0..15 → **`0x304000 + 0x100 + 0x10*id`**
  - IDs 16..31 → **`0x304400 + 0x100 + 0x10*(id-16)`**
  - (faixas acima disso seguem outro path; ainda não “fechado”)

Operações de limpeza/máscara associadas:
- **`tpu_clear_channel_mask_4020_4420 @ 0x000343E8`**

---

### O que isso NÃO prova ainda (evite fanfic)
- Não prova “qual ID é qual solenóide” (EPC/TCC/SSA/SSB/SSC/SSD etc.).
- Não prova que `0x15A8` é *somente* solenóide (pode ser uma fila genérica de TPU).
- Não prova a semântica das faixas `>= 0x64` (precisamos abrir as tabelas e ver o layout).

---

### Próximo passo certo (pra chegar em marcha)
1. **Extrair a tabela em `r13+0x15D0`**: para cada ID, resolver:
   - `fn_ptr` (handler real)
   - `ctx_ptr` (`+0xC`)
2. Para os handlers reais, filtrar por:
   - writes em MMIO `0x304000/0x304400` (TPU)
   - interações com `r13+0x15A8` (enfileiramento PWM)
3. Só então começar a nomear “solenóide X”.


