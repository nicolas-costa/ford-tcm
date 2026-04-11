## 13 — Pendência de Hardware para Emulação / Análise Dinâmica

### Contexto (por que isso existe)
Este projeto já identificou gargalos onde **análise estática não fecha** sem virar “fanfic”: precisamos observar **estado real em RAM** e/ou capturar **caller (PC)** em acessos MMIO durante execução.

### Pendência (o que precisa ser feito)
Para avançar com **emulação** ou **análise dinâmica real**, é necessário **remover o módulo TCM e abrir a carcaça** para coletar informações de hardware da PCB.

### Evidências de que dinâmica é necessária (FATO)
- **Dump de RAM para fechar layout de `TaskEntry`**: o dispatcher usa `task_entry+0x4` como `fnptr`, mas `+0x8/+0xC` ainda precisam ser mapeados com dump do bloco em RAM (explicitamente citado como “via debug/emulação”).  
  - Referência: `4f27e-docs/06-scheduler-anatomy.md` (seção “O Que Ainda Falta”, item 3).
- **Capturar o PC do caller em escrita MMIO**: foi definido como próximo passo “monitorar escritas em `0x304400` durante execução simulada” para achar o caller real.  
  - Referência: `4f27e-docs/05-solenoid-mapping.md` (seção “Próximos Passos”, item 2).

### Por que dados da placa são obrigatórios (FATO)
Sem identificar **MCU exato** e **porta de debug** (BDM/JTAG) na placa, não existe como:
- executar o firmware num alvo real com visibilidade de registradores/memória;
- colocar **watchpoints/data breakpoints** em MMIO (ex.: `0x304400`) para capturar o PC do `store`;
- validar/popular dumps de RAM (ex.: bloco `0x003FA400..`) com origem verificável.

### Boot em QEMU trava por “polling de ready” (FATO)
Existe um loop de inicialização que **poll** até um valor MMIO ficar **!= 0**. Em QEMU “cru” não há dispositivo respondendo, então o boot não progride.

**Evidência (BIN `5U75-14C337-AA.rebuilt.aligned.bin`):**
- `0x00008174: lis r3,0x30`
- `0x00008178: lwz r11,-0x3D7C(r3)` ⇒ EA `0x2FFFC284`
- `0x00008180: cmpwi r11,0`
- `0x00008184: beq 0x00008174` (loop enquanto lê `0`)

**Interpretação objetiva:**
- Se a leitura em `0x2FFFC284` retornar **não-zero**, o loop termina e o boot segue.
- Se retornar `0`, o boot fica preso.
**DESCONHECIDO:** qual periférico real alimenta `0x2FFFC284` no hardware (sem spec/IDCODE/memory map do MCU).

### Checklist do que coletar ao abrir o módulo (FATO: requisitos operacionais)
- **Identificação do MCU**: part number completo (foto legível do marking do chip).
- **Identificação da interface de debug**: presença de pads/headers e padrão (BDM vs JTAG).
- **Fotos da PCB**: frente/verso em alta resolução + close de pads de teste/conectores.
- **Alimentação em bancada**: pontos de 12V, GND e sinais de ignição/reset (se acessíveis).
- **Clock**: cristal/oscilador e frequência (foto do componente + marcação).
- **Memórias externas**: flash/RAM externas (se houver) e suas referências/part numbers.

### Riscos/alertas (DESCONHECIDO até abrir e confirmar)
- Debug pode estar **desabilitado/lockado** em produção (depende do MCU/strap/fuses).
- Pode existir “cola”/resina/tinta que dificulta acesso a pads.
- Sem esquema elétrico, o pinout de pads pode exigir continuidade/ohmímetro.

### Status
- **Estado atual**: parcialmente desbloqueado (identificação física do TCU/TCM coletada), mas **ainda bloqueado** para dinâmica por falta de **mapeamento de interface de debug/pads**.
- **Dependência**: fotos macro frente/verso + identificação inequívoca de **pads/headers de debug** e pontos de alimentação/clock.
- **Update do operador — 2026-01-08 (FATO):** o **TCM é um módulo separado** do **ECU/PCM** (não integrado). Naquela data, o TCM **ainda não tinha sido removido**.
- **Identificadores externos coletados (FATO: fornecidos pelo operador)**:
  - `vp6g9u14a638ac`
  - `v96g9u12b523a`
**DESCONHECIDO (origem exata do módulo/etiqueta não confirmada):**
- Foi registrada uma **etiqueta com “ESU-411”** em foto anterior (texto: `9M55-12A650-CD`, `YKC2`, `ESU-411`, `S/N: y6htbanxf99`), mas após o update 2026-01-09 isso deve ser tratado como **potencialmente pertencente ao PCM/ECU** (Visteon ESU-411), não ao TCU/TCM.

### Update de bancada (update do operador — 2026-01-08)
**FATO (informado pelo operador):**
- **Condição do selante**: “silicone/adesivo” **não amoleceu** com soprador térmico durante abertura.
- **Acesso à PCB**:
  - O lado com chips/MCU **não estava acessível** de imediato por estar **colado ao metal** com “silicone + pasta térmica”.

**DESCONHECIDO (até validação por foto/medição):**
- Se `PWB13992`, `ESU-4xx`, `VP7ELU-AA` são identificação de PCB / engenharia / calibração.

### Update de bancada (update do operador — 2026-01-09)
**FATO (informado pelo operador):**
- O módulo em bancada e aberto é **somente TCU/TCM**.
- A **ECU/PCM** do veículo é **Visteon ESU-411** (módulo separado).

**FATO (identificação externa do TCU/TCM em foto; fornecida pelo operador):**
- **Fornecedor**: Continental (Siemens VDO Continental)
- **Hardware P/N**: `5WP22350BI-K`
- **Ford P/N (módulo)**: `5M5P-12B565-BL`
- **SW/Strategy (módulo)**: `5M5P-14C337-BL`
- **Aplicação**: `1.8/2.0`
- **S/N**: `93510173`

**FATO (markings de ICs em foto; fornecida pelo operador):**
- **Processador/SoC (marking)**: `A2C00023028` (`UQMZFM0926`)
- **Memória (marking)**: Spansion `925MB467`
- **Memória (marking adicional, fornecido pelo operador)**: `s29cd016jomqfm11`

**FATO (fornecido pelo operador; evidência visual no encapsulamento):**
- O MCU possui **logo Freescale** impressa.

**HIPÓTESE (fornecida pelo operador; origem: Gemini; pendente de confirmação objetiva):**
- O core do MCU seria **PowerPC e200z4** ou **e200z6** (PowerPC 32-bit).
- O MCU seria da linha **NXP/Freescale Qorivva**.

### Identificação via app (FATO: informado pelo operador; coletado via diagnóstico/OBD)
#### TCM — Transmission Control Module
- **Part number**: `5U75-12B565-AA`
- **Calibration level**: `5U75-12B565-AA`
- **Strategy**: `5U75-14C337-AA`
- **Software version (data)**: `2008-06-25`

#### PCM — Powertrain Control Module
- **Part number**: `9U75-12A650-GB`
- **Calibration level**: `9U75-12A650-GB`
- **Strategy**: `9U75GB`
- **Hardware type**: `ESU-411 / ESU-418`
- **Copyright**: `Visteon Corp. 2010`
- **Software version**: `v1`
- **VIN**: `8AFFZZFFC9J289305`

### Atualização importante sobre “ESU-411 / Visteon” vs TCM (update do operador — 2026-01-08)
**FATO (consistência dos dados acima):**
- No diagnóstico atual, **`ESU-411 / Visteon` aparece no bloco do PCM** (não no do TCM).
- Como o operador confirmou que **TCM e ECU/PCM são módulos separados**, é **errado** tratar `ESU-411/Visteon` como “identificação do TCM” sem evidência física da PCB.

### Atualização importante sobre “ESU-411 / Visteon” vs TCU/TCM (update do operador — 2026-01-09)
**FATO (informado pelo operador):**
- “Aqui é só **TCU**; a **ECU é Visteon ESU-411**.”
- Portanto, `ESU-411 / Visteon` deve ser tratado como **identificador do PCM/ECU**, não do TCU/TCM.

**DESCONHECIDO (até abrir e confirmar por foto do marking):**
- Fabricante exato do TCM, MCU, interface debug e relação com `ESU-4xx` visto em etiqueta/placa.

### Interpretação desses códigos (DESCONHECIDO até validação por evidência)
- Sem foto macro legível da PCB e do marking dos componentes, não é possível afirmar se `PWB13992/ESU-4xx/VP7ELU-AA` são:
  - identificação de PCB (board number/rev),
  - estratégia/calibração Ford,
  - ou identificação de peça/engenharia do conjunto.

### Próximo passo (maior ROI, único)
Coletar **foto macro do marking completo do MCU** (todas as linhas legíveis, incluindo códigos pequenos de maskset/lote) **e/ou** ler **IDCODE** via interface de debug (JTAG/BDM). Isso é o que fecha a discussão “PowerPC vs não-PowerPC” e (se aplicável) o core exato (e200z4/e200z6).


