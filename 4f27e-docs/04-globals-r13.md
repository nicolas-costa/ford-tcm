## 04 — Globais via `r13` (SDA): mapa inicial (0x6C00–0x6DFF)

### Resumo (fato)
Scan automático dentro do IDA filtrando **somente** instruções com operand `disp(r13)` no range `0x6C00..0x6DFF`:
- **Offsets únicos**: 25
- **Referências totais**: 144
- **Arquivo fonte do scan**: `.ida-mcp/r13_sda_scan_full.json` (gerado a partir do IDA)

### SDA base (`r13`) (fato)
O firmware inicializa `r13` com **SDA base = `0x003F8F00`** via padrão `lis/ori`:

- **`reset_handler @ 0x0000864C`**:
  - `0x00008654`: `lis r13, 0x3F`
  - `0x00008658`: `ori r13, r13, 0x8F00`  → `r13 = 0x003F8F00`
- **`boot_alt_startup @ 0x000182C4`** (duplicado/alternativo):
  - `0x000182D0`: `lis r13, 0x3F`
  - `0x000182D4`: `ori r13, r13, 0x8F00`  → `r13 = 0x003F8F00`

Isso resolve os offsets para RAM real:  
`abs = 0x003F8F00 + offset`, então o bloco `0x6C00..0x6DFF` cai em `0x003FFB00..0x003FFCFF`.

### SDA fora do scan `0x6C00..0x6DFF` (fato, e bem mais importante do que parece)
O scan acima foi intencionalmente restrito a `0x6C00..0x6DFF` (estado “core” suspeito).  
Mas a rodada mais recente confirmou campos **críticos** de scheduler/IO fora desse range:

- **`r13+0x15A8`**: ponteiro de fila/worklist de TPU/PWM (drenada por `tpu_pwm_queue_service_15A8 @ 0x394C8`).
- **`r13+0x15C0`**: ponteiro “root” do scheduler/tick context (usado por `scheduler_post_or_arm_task @ 0x39E18`).
- **`r13+0x15D0`**: raiz/tabela de descritores/trampoline por ID (stride **16 bytes**), com call indireto (`blrl`).
- **`r13+0x15D4`**: tabela auxiliar (word/bitfield) usada em paths de IDs maiores no dispatcher por ID.

Para a rodada completa (com endereços e implicação “solenóide/PWM”), ver `07-io-tpu-pwm.md`.

### Top offsets por volume (sinal forte)
Os offsets abaixo aparecem mais — normalmente isso indica **estado central** (flags/máquina de estados/telemetria interna).

- **`r13+0x6C00`** (`abs 0x003FFB00`): 29 refs (R=1 / W=5) em 5 funções  
  - `init_state_check_or_task`, `sub_1B318`, `sub_1BF2C`, `sub_1C8BC`, `state_service_6D4x_and_hooks`
- **`r13+0x6D4F`** (`abs 0x003FFC4F`): 12 refs (R=0 / W=10) em 3 funções  
  - `sub_19E24`, `sub_1B318`, `sub_45558`
- **`r13+0x6C30`** (`abs 0x003FFB30`): 11 refs (R=3 / W=5) em 6 funções  
  - `init_state_check_or_task`, `sub_1B318`, `sub_1BF2C`, `sub_1C8BC`, `sub_45558`, `state_service_6D4x_and_hooks`
- **`r13+0x6C0D`** (`abs 0x003FFB0D`): 9 refs (R=2 / W=5) em 5 funções  
  - `sub_1C8BC`, `sub_1CD54`, `sub_1CE14`, `state_service_6D4x_and_hooks`, `sub_46478`
- **`r13+0x6C10`** (`abs 0x003FFB10`): 9 refs (R=5 / W=2) em 3 funções  
  - `sub_1B318`, `sub_1C8BC`, `sub_46324`
- **`r13+0x6C34`** (`abs 0x003FFB34`): 8 refs (R=2 / W=4) em 6 funções  
  - `init_state_check_or_task`, `sub_1B318`, `sub_1BF2C`, `sub_1C8BC`, `sub_45558`, `state_service_6D4x_and_hooks`

### O que isso é vs o que deveria ser (sem autoengano)
- **O que é agora**: “offsets no vácuo”. Sem SDA base, sem segmento RAM, sem struct → você não tem **nome**, **tipo**, nem **semântica**.
- **O que deveria ser**: pelo menos 1 struct de estado (ex.: `tcm_state_t`) pendurada no `r13` (SDA base), com campos nomeados e xrefs rastreados.

### Próximo passo obrigatório (para virar engenharia e não narrativa)
1. **Descobrir onde `r13` é inicializado** no bootstrap (SDA base).
2. Criar um segmento “RAM” no IDA (mesmo que sintético) e apontar `r13`/SDA para ele.
3. Converter os offsets mais usados em campos de struct (começando por `0x6C00`, `0x6D4F`, `0x6D42/0x6D44`).


