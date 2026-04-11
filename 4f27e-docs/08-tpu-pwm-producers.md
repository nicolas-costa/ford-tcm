## 08 — Produtores do TPU/PWM (fila `r13+0x15A8`)

### Resumo brutalmente honesto
O caminho “real” de PWM não é `io_set_float...` nem `0x3BB10` direto.
O firmware tem um padrão claro:
- alguém **monta/aplica** uma lista de entries (stride `0x10`)
- publica o ponteiro dessa lista em **`r13+0x15A8`**
- arma a execução do serviço via scheduler
- o serviço drena e zera `r13+0x15A8`

Se você quer chegar em **EPC/TCC/shift**, o alvo agora é: **quem preenche `entry+0x4`** (valor) e os campos de modo antes de chamar o builder.

---

### Âncoras (fato)

#### Consumer (drain)
- **`tpu_pwm_queue_service_15A8 @ 0x000394C8`**
  - **Lê** `r13+0x15A8` (ponteiro para a fila)
  - processa entries e chama:
    - `tpu_channel_update_cfgbit1_or_arm @ 0x00038F24`
    - `tpu_channel_update_cfgbit8_or_enable @ 0x00038FDC`
  - **Zera** `r13+0x15A8` no fim (fila consumida)

Wrapper observado:
- **`task_service_pwm_queue_and_housekeeping @ 0x0004A264`** → chama `tpu_pwm_queue_service_15A8`

#### Produtor (build + publish + schedule)
- **`tpu_pwm_queue_build_and_schedule_task3 @ 0x000395B4`**
  - recebe um ponteiro `queue` em `r3`
  - usa `queue->count` em `0x0` e `queue->entries` em `0x4` (stride `0x10`)
  - conta quantos entries são do “grupo >= 0x20” e grava isso em **`r13+0x15B0`**
    - evidência: loop em `0x395E8..0x39610` incrementa `0x15B0(r13)` quando `entry[0] >= 0x20`
  - aloca um buffer temporário em **`r13+0x15AC`** com tamanho **`(r13+0x15B0) * 0x10`**
    - evidência: `r3 = (u8)0x15B0 << 4` → `loc_26218` → `stw r3, 0x15AC(r13)` @ `0x39624`
    - depois zera com `sub_2610C(r3=0x15AC, r4=(u8)0x15B0<<4, r5=0)`
  - escolhe o path por entry:
    - **MIOS/aux regs**: `tpu_pwm_entry_apply_via_mios_305f58 @ 0x00021BC4`
    - **TPU regs**: `tpu_pwm_entry_apply_via_tpu_regs @ 0x00021CB8`
  - publica o ponteiro da fila:
    - **`stw r30, 0x15A8(r13)` @ `0x0003968C`**
  - arma a execução via `scheduler_post_or_arm_task` usando **TaskID = 3**
    - evidência: no epílogo (`0x3969C..0x396B4`) chama `scheduler_post_or_arm_task(r3=3, r4=1/0)`
    - gate: se `r13+0x15B0 != 0` posta com `r4=1`, senão `r4=0`

---

### Aplicadores (o que eles fazem)

#### `tpu_pwm_entry_apply_via_mios_305f58 @ 0x00021BC4`
- usa base MMIO **`0x305F58`** com indexação por ID (`8 * id`)
- monta flags do tipo `0x2001/0x2801` (+ OR `0x20` dependendo do modo)
- escreve palavras/halfwords em offsets do bloco `0x305F58`

#### `tpu_pwm_entry_apply_via_tpu_regs @ 0x00021CB8`
- resolve `id -> regs` via `tpu_channel_regs_ptr_from_id @ 0x00033BA4` (**`0x304000/0x304400`**)
- puxa o valor principal do entry:
  - **`lhz r12, 4(r29)` @ `0x00021E50`** (interprete como “raw command”/period/scale — ainda sem semântica fechada)
- calcula um valor escalado e **clampa em `0x7FFF`** antes de escrever em regs (`sth ... 8(r30)` etc.)
- usa ponteiros/constantes em SDA para selecionar escala (evidência de “modos”):
  - `r13+0x1EE0, 0x1EE4, 0x1EE8, 0x1EEC, 0x1EF0, 0x1EF4`

---

### Implicações (fato → próximo passo)
- `r13+0x15A8` **não é “uma tabela de handlers”**: é um **ponteiro para uma fila/lista**.
- o lugar certo para achar EPC/TCC/shift é **antes** do builder:
  - quem monta `queue->entries[i]` (especialmente `entry+0x4`)
  - e quem decide o modo/flags (campos `entry+0x1`, `entry+0x2`, etc.)

---

### Layout do entry (inférencia forte a partir de `tpu_pwm_entry_apply_via_tpu_regs`)
Para `tpu_pwm_entry_apply_via_tpu_regs`, o acesso é consistente com:
- **`entry+0x0` (`u8`)**: **IO/Channel ID** (alvo físico)
  - evidência: `lbzx` do `entries_base + (idx<<4)` e depois `tpu_channel_regs_ptr_from_id(r3=id)`
- **`entry+0x1` (`u8`)**: flags/mode (usa `& 0x3` via `clrlwi ..., 30` para selecionar bits `0x4/0x8` e `sth ... 2(regs)`)
- **`entry+0x2` (`u8`)**: grupo/mux de path/config (testa 0..4; influencia `sth r31, 0(regs)` com `r31` em `0` ou `0x30`)
- **`entry+0x4` (`u16`)**: **raw command** (vira duty/period/scale depois de multiplicação e clamp)
  - evidência: `lhz r12, 4(entry)` e depois pipeline de `mul*` → `clamp <= 0x7FFF` → `sth ..., 8(regs)`

Observação crítica (isso ajuda muito a chegar em EPC/TCC/shift):
- existe um “seletor de escala” que parece depender do **índice do entry no array** (não do ID).
  - evidência: calcula `0x00050000 + (idx<<4) + 2` e lê um byte para escolher qual constante usar de `r13+0x1EE0..0x1EF4`.
  - isso sugere que a **ordem da fila é semântica** (o `idx` já “significa” qual atuador lógico é; o `id` é o mapeamento para o canal físico).

### Próximo passo (objetivo)
1. Aceitar a realidade: **não existe `bl 0x395B4`** no BIN; então esse “produtor” provavelmente roda como **task por dispatch indireto** (scheduler).
2. Recuperar o **TaskTable entry** que aponta para `0x395B4` e, principalmente, o **`ctx` que vira `r3`** (o `queue`).
3. Com o endereço do `queue` em RAM, achar os **writers**:
   - quem escreve `queue->count` (`+0x0`)
   - quem escreve `queue->entries` (`+0x4`) e os `entries[i]` (stride `0x10`)
   - especificamente **`entry+0x4`** (valor/duty/command) e bits de modo (`entry+0x0/0x1/0x2/...`)
4. Só depois colar nomes EPC/TCC/shift com evidência.


