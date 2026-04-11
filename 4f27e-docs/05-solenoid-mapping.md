## 05 — Mapeamento de Solenoides e IO (0x3BB10)

### O "Driver" de IO
A função `io_update_masks_and_outputs_30xx @ 0x0003BB10` atua como HAL (Hardware Abstraction Layer) centralizado para saídas.

### 1. Fatos (O que o código diz explicitamente)
- **Endereço**: `0x3BB10`
- **Lógica**: A função decide onde escrever em MMIO (`0x30xxxx`) com base em um **ID** e um **valor**.
  - Evidência: no corpo existem comparações com `0x10` (16), `0x64` (100), `0x74` (116), `0x97` (151) e `0xA7` (167) para selecionar caminhos e bases como `0x304000`, `0x304400` e `0x306Cxx`.
  - Importante: o ID **aparece vindo de `r29`** (ex.: `clrlwi r10, r29, 24`), mas isso **não prova** que `r29` é “argumento oficial”: em PPC EABI o normal é argumento em `r3..r10`. Aqui, ou existe **wrapper/dispatcher** carregando `r29`, ou o IDA está com **problema de fronteira/ABI** nessa rotina. Trate como **hipótese forte**, não “fato”.
- **Ranges de IDs e Destinos de Memória**:
  - **IDs 0 a 15**: Escreve em offsets relativos a `0x304000`.
  - **IDs 16 a 31**: Escreve em offsets relativos a `0x304400`.
  - **IDs 100+**: Caminhos em `0x306Cxx` (com sub-ranges internas).

### 2. Hipóteses (Inferências a validar)
As afirmações abaixo são derivadas do mapeamento de memória MPC5xx e da documentação do 4F27E.

- **[HIPÓTESE 1] Identificação de Hardware**:
  - `0x304000`: **TPU A** (Time Processing Unit A).
  - `0x304400`: **TPU B** (Time Processing Unit B).
  - `0x306C00`: **MIOS1** (Modular I/O System).
  
- **[HIPÓTESE 2] Distribuição de Funções**:
  - **Solenoides PWM (EPC, TCC, Shift C/D/E)**: Ligados ao **TPU B** (IDs 16-31).
  - **Solenoides On/Off (Shift A, Shift B)**: Ligados ao **MIOS1** (IDs 100+).

### 3. Obstáculos na Análise Estática (Aviso Técnico)
- **Callers Indetectáveis**: A função `0x3BB10` não possui referências cruzadas (XREFs) diretas detectadas pelo IDA.
- **Convenção de Chamada / ABI**: o uso de `r29` como “ID” é **sinal**, mas ainda não é prova. Antes de afirmar “ABI customizada”, precisamos achar o dispatcher real (provável `bctrl`/tabela).
- **Callgraph quebrado não implica ofuscação**: ausência de XREF pode ser só **chamada indireta** (CTR/LR), **codegen agressivo** ou **fronteiras de função erradas** no IDA.

### 4. Próximos Passos (Engenharia Reversa Avançada)
1. **Localizar o dispatcher real**: procurar padrões de `mtctr`/`bctrl` + tabelas que selecionem rotina de IO (e onde o “ID” é carregado).
2. **Varredura Dinâmica**: Monitorar escritas em `0x304400` durante execução simulada para pegar o PC do caller.
3. **Firmware Comparativo**: Analisar binários de outras transmissões Ford (5M5P) para ver se a estrutura de chamada é menos opaca.
