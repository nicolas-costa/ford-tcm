## 03 — Tick/Scheduler + IO (primeiras âncoras úteis)

### Tick ISR (fato)
- `isr_decrementer_tick_dispatch @ 0x000396D0`
  - Evidência: padrão de ISR de Decrementer + dispatch por casos (tabela de jump/cases).
  - Foram observados **6 casos** (nomeados como `tick_case_0` … `tick_case_5` durante a sessão).

### Scheduler hook (fato)
- `scheduler_post_or_arm_task @ 0x00039E18`
  - Papel: pós-dispatch / armamento / enfileiramento de trabalho periódico (nome funcional; validar por XREFs).

### Funções de IO já “com cara de hardware” (fato)
- `io_read_306030_or_3060B0_and_compute @ 0x000245E8`
  - Lê registradores em região `0x30xxxx` e calcula/deriva valor (provável sensoriamento/estado).
- `io_update_masks_and_outputs_30xx @ 0x0003BB10`
  - Atualiza máscaras/saídas em `0x30xxxx` (provável atuadores/solenóides via registradores mapeados).

### Correção importante (fato): o firmware usa dispatch indireto para IO
Não existe um padrão confiável de `bl 0x3BB10` (call direto) para “IO update”. O binário tem **dispatch por ID/tabela** (trampolines) e **call indireto** (`blrl`).

Âncoras desta mecânica:
- `io_write_by_id_dispatch_15D0_15D4 @ 0x0003C16C`
- `io_dispatch_via_15D0_trampoline_and_clear_mask @ 0x00023F38`

Detalhes e implicação para “solenóides via TPU/PWM”: ver `07-io-tpu-pwm.md`.

### Temporização / delay (fato)
- `timing_delay_or_measure @ 0x00041C88`
  - Padrão de função ligada a tempo (loops/contadores). Útil para reconhecer “tarefas” que dependem de tick.

### Estado global (ponto crítico pendente)
Foi observado acesso a globais via `r13` (Small Data Area), com offsets como:
- `r13+0x6D42`, `r13+0x6D44`, `r13+0x6D4E` (estado/flags)
- outros offsets citados durante a sessão: `0x6D3E`, `0x6C30`, `0x6C34`, `0x6C0C`, `0x6C0D`, `0x6C10`

**O que é**: offsets soltos, sem tipo/sem nome, espalhados em múltiplas funções.  
**O que deveria ser**: um ou mais `struct` de estado (ex.: `tcm_state_t`) com campos nomeados e XREFs rastreados.

### Próximo passo recomendado (map-gear-state-globals)
- Catalogar todos os acessos `r13+0x6Cxx/0x6Dxx` (load/store) e puxar XREFs.
- Agrupar por “cluster” de função (tick cases, tasks, IO update).
- Nomear campos por comportamento (ex.: `gear_cmd`, `gear_actual`, `shift_phase`, `solenoid_mask`, `fault_flags`), **só quando houver evidência**.


