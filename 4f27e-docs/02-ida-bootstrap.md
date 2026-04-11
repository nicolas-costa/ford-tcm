## 02 — IDA: setup + bootstrap (âncoras iniciais)

### Setup no IDA (fato)
- **CPU**: PowerPC, **big-endian**, 32-bit
- **Decode**: PPC + VLE (mixed) — necessário para este binário
- **Base**: `0x0`
- **Segmento**: `ROM 0x000000..0x200000`, permissões **`r-x`**

Se o IDA recarregar e o `ROM` voltar para `---`, é um bug/armadilha comum: sem `r-x` o IDA falha em criar funções (você perde tempo achando que “a detecção está ruim” quando o problema é permissão).

### Cadeia de bootstrap (fato: nomes já usados durante a sessão)
Os nomes abaixo são **mapeamentos progressivos** a partir do que “parece” reset/boot. Alguns ainda são “best-effort naming” (a validação vem por XREFs, padrões de init e efeito em registradores).

- `reset_handler @ 0x0000864C`
- `system_init @ 0x00008204`
- `boot_alt_startup @ 0x000182C4`
- `init_immr_and_bootflags @ 0x00017B78`
- `early_hw_init_loop @ 0x00017EE0`
- `init_fpu_flags @ 0x????????` (nomeado durante a sessão; endereço precisa ser consolidado via XREF no IDA)
- `init_copy_or_zero_ranges @ 0x????????`
- `init_early_io_or_flash @ 0x????????`

### Por que isso importa (realidade operacional)
Sem âncoras de boot você fica “caçando marcha” em um oceano de funções. O caminho produtivo é:
- reset/early init → setup de mem/IMMR → instalação de ISRs → scheduler/tick → tasks periódicas → lógica de controle

### Próximo passo (objetivo técnico)
Usar o bootstrap para localizar:
- instalação do handler do **Decrementer** (tick);
- criação/uso de tabelas de dispatch;
- inicialização de globais baseadas em `r13` (small data area), que tendem a carregar o estado do controle.


