# Estudo preliminar — swap 4F27E/Ford FN para FNR5 no Focus Mk2.5

## 1. Objetivo

Este documento consolida os achados levantados até aqui sobre a viabilidade elétrica e eletrônica de substituir a transmissão automática Ford FN/4F27E do Focus Mk2.5 por uma FNR5, mantendo o PCM do Focus e utilizando o TCM dedicado da FNR5.

O foco desta etapa é a arquitetura dos módulos, chicotes, conectores, sensores e atuadores. A compatibilidade mecânica e a compatibilidade real das mensagens CAN ainda precisam ser verificadas separadamente.

---

## 2. Materiais analisados

### Diagrama elétrico atribuído ao Focus C307

Arquivo analisado:

- identificação impressa: `PH8M5T-70000-AD`;
- veículo/programa indicado no próprio documento: `MY 2010 C307`;
- origem: arquivo encontrado na internet e fornecido para este estudo;
- status: a procedência, autenticidade, revisão e aplicabilidade exata ao Focus Mk2.5 brasileiro 2.0 ainda não foram verificadas de forma independente.

Páginas utilizadas:

- **página 60** — `POWERTRAIN TRANSMISSION CONTROL — AUTOMATIC TRANSMISSION, FORD FN`;
- **página 127** — `SIGMA NON VCT ENGINE PART CONNECTOR FACEVIEWS`;
- **página 130** — `NI4 ENGINE PART CONNECTOR FACEVIEWS`.

> Limitação: a página 60 é apresentada no arquivo como aplicação `1.6 SIGMA FN`. Ela é útil para compreender a topologia do TCM, do chicote `14K039` e dos conectores `C116`, `C117` e `C414`, mas não comprova, por si só, que toda a pinagem seja idêntica à do Focus brasileiro 2.0. Nenhuma ligação deve ser feita apenas por equivalência visual; é necessário confirmar no veículo, por continuidade elétrica e por documentação específica da aplicação.

### Material técnico da FNR5

Foram analisadas imagens e tabelas técnicas fornecidas para este estudo, contendo:

- TCM Mitsubishi Electric Ford `7E51-7A100-AA`;
- conector A de 16 vias;
- conector B de 24 vias;
- pinagem dos sensores TSS, ISS e OSS;
- pinagem do sensor de faixa;
- pinagem do corpo de válvulas principal;
- pinagem do corpo de válvulas da quinta marcha;
- esquema interno do chicote do corpo de válvulas.

---

## 3. Correções importantes estabelecidas

### 3.1 O Focus usa PCM e TCM separados

A arquitetura correta do Focus com Ford FN/4F27E é:

```text
PCM do motor
    │
    ├── HS-CAN
    │
TCM dedicado da transmissão
    │
    └── chicote e componentes da 4F27E
```

O módulo da transmissão não está integrado ao PCM.

### 3.2 O Fusion brasileiro dessa geração com FNR5 era FWD

Para este estudo, o doador relevante é o Fusion 2.3 FWD equipado com FNR5. Considerações sobre AWD não se aplicam ao caso brasileiro analisado.

### 3.3 O C414 é o conector do TCM Ford FN

Na página 130, o conector é identificado como:

- `C414`
- `TO TRANSMISSION CONTROL UNIT FN`
- `HARNESS 14K039`
- corpo/conector `3M5T-14A464-UTA`

No arquivo analisado, a página 60 apresenta o detalhamento funcional dos circuitos que chegam ao TCM por esse conector.

---

## 4. Arquitetura do chicote original do Focus

A topologia levantada é:

```text
TCM Ford FN / 4F27E
        │
        │ C414 — conector grande do TCM
        │
   chicote 14K039
        │
        ├── C116
        └── C117
               │
               └── chicote 12A690 / restante da instalação
                      ├── gearshift mode switch
                      ├── transmission valve solenoid assembly
                      ├── transmission speed sensor
                      ├── output shaft speed sensor
                      ├── gear shift module
                      ├── alimentação
                      ├── aterramentos
                      └── HS-CAN
```

O chicote `14K039` é, portanto, um chicote intermediário dedicado ao TCM. Ele possui:

- o conector grande `C414` em uma extremidade;
- os conectores `C116` e `C117` na outra extremidade.

Isso é favorável ao swap porque permite pensar em uma adaptação removível, sem necessariamente modificar internamente o chicote principal do veículo.

---

## 5. Conector C414 — lado do TCM Ford FN

### 5.1 Identificação

No arquivo analisado, a página 130 apresenta o faceview do `C414`, ligado ao TCM da transmissão Ford FN pelo chicote `14K039`.

O conector possui grande número de posições, várias delas não ocupadas na aplicação mostrada. Ele concentra:

- alimentação do TCM;
- aterramentos;
- HS-CAN;
- leitura da alavanca;
- entradas de sensores da transmissão;
- saídas para os solenoides da 4F27E;
- sinais auxiliares ligados ao módulo/seletor de marchas.

### 5.2 Papel no swap

Embora o C414 permita entender o TCM original, ele não é necessariamente o melhor ponto físico para adaptação. Para um swap reversível, os conectores `C116` e `C117` parecem mais úteis, pois são a interface destacável entre o chicote do TCM e o restante da instalação.

---

## 6. Conectores C116 e C117

No arquivo analisado, a página 127 mostra os faceviews de ambos os lados dos conectores, pois eles unem:

- `HARNESS 14K039`; e
- `HARNESS 12A690`.

### 6.1 C116 — função predominante

O mapeamento funcional preliminar indica que o `C116` concentra principalmente:

- leitura do `gearshift mode switch`;
- circuitos do `transmission valve solenoid assembly`;
- alimentação e comando de solenoides;
- retornos ligados ao corpo de válvulas da 4F27E.

A página 60 mostra contatos do seletor identificados como:

- `PARK`;
- `NEUT`;
- `TSD`;
- `TSR`;
- `TS2`;
- `TS1`.

Isso sugere leitura por combinação de contatos discretos, em vez de um único valor analógico.

Também aparecem no C116 diversos circuitos com prefixo `TA`, associados à transmissão, por exemplo:

- `15S-TA17`;
- `15S-TA23`;
- `15S-TA24`;
- `15S-TA37`;
- `15S-TA38`;
- `15S-TA39`;
- `15S-TA40`;
- `15S-TA63`;
- `15S-TA64`;
- `15S-TA65`;
- `8-TA36`;
- `9-TA36`.

Resumo funcional:

```text
C116
├── posição/modo da alavanca
├── alimentação dos solenoides
├── comandos de solenoides
└── retornos do conjunto hidráulico
```

### 6.2 C117 — função predominante

O `C117` concentra principalmente a interface do TCM com o veículo e os sensores externos da transmissão:

- VBAT/alimentação permanente;
- alimentações comutadas;
- HS-CAN High;
- HS-CAN Low;
- aterramentos;
- transmission speed sensor;
- transmission output shaft speed sensor;
- sinais ligados ao gear shift module;
- retornos/alimentações de sensores.

Na página 60 aparecem explicitamente circuitos e componentes como:

- `30-TA55` — alimentação permanente;
- linhas `15...` — alimentações comutadas;
- linhas `91...` — aterramentos/retornos;
- `HS CAN +`;
- `HS CAN -`;
- `TRANSMISSION SPEED SENSOR`;
- `TRANS. OUTPUT SHAFT SPEED SENSOR`;
- `GEAR SHIFT MODULE`.

Resumo funcional:

```text
C117
├── VBAT
├── alimentação comutada
├── HS-CAN +
├── HS-CAN -
├── aterramentos
├── transmission speed sensor
├── output shaft speed sensor
└── interfaces auxiliares do gear shift module
```

### 6.3 Divisão funcional aproximada

| Conector | Função predominante |
|---|---|
| `C116` | alavanca, corpo de válvulas e solenoides da 4F27E |
| `C117` | alimentação, CAN, aterramentos, sensores de velocidade e interface com o veículo |

Essa separação não é absoluta, mas é suficientemente clara para orientar a engenharia do adaptador.

---

## 7. Gearshift mode switch e gear shift module

O esquema apresenta dois elementos que não devem ser confundidos.

### 7.1 Gearshift mode switch

É o conjunto de contatos usado para informar ao TCM a posição/modo da alavanca.

No esquema aparecem contatos discretos associados a:

- Park;
- Neutral;
- Drive/reduções/modos intermediários.

A leitura parece ocorrer por uma matriz/combinação de contatos.

### 7.2 Gear shift module

O diagrama também mostra um `GEAR SHIFT MODULE`, ligado a circuitos adicionais. Pelo material disponível, ainda não está confirmado se ele é:

- apenas o conjunto físico da alavanca e intertravamento;
- um módulo eletrônico ativo;
- ou uma combinação de chave, iluminação, trava e sinais discretos.

É necessário consultar uma descrição funcional ou esquema específico desse módulo antes de definir como ele será mantido ou substituído no swap.

---

## 8. TCM da FNR5

### 8.1 Identificação do módulo

O módulo anexado é:

- Ford/Mitsubishi Electric;
- engineering number `7E51-7A100-AA`;
- utilizado com a transmissão FNR5.

Fisicamente ele possui dois conectores:

- conector A — 16 vias;
- conector B — 24 vias.

Não há compatibilidade física direta com o C414 do TCM Ford FN.

---

## 9. Pinagem do TCM FNR5

### 9.1 Conector A — 16 vias

O conector A concentra alimentação, aterramentos e acionamento dos solenoides.

| Pino | Função |
|---:|---|
| 1 | Ground |
| 2 | FNR5 relay switched output |
| 3 | Voltage at all times, overload protected |
| 4 | Not used |
| 5 | Linear pressure control solenoid PCA − |
| 6 | Linear pressure control solenoid PCA + |
| 7 | Shift solenoid C — SSC |
| 8 | Shift solenoid A — SSA |
| 9 | Ground |
| 10 | FNR5 relay switched output |
| 11 | Not used |
| 12 | Shift solenoid F — SSF |
| 13 | Shift solenoid E — SSE |
| 14 | Shift solenoid D — SSD |
| 15 | Pressure control solenoid B — PCB |
| 16 | Shift solenoid B — SSB |

### 9.2 Conector B — 24 vias

O conector B concentra CAN, sensores, sensor de faixa e controle do relé.

| Pino | Função |
|---:|---|
| 1 | High-speed CAN + |
| 2 | Not used |
| 3 | Not used |
| 4 | Not used |
| 5 | Signal return |
| 6 | Oil temperature signal |
| 7 | TSS sensor return |
| 8 | TSS sensor signal |
| 9 | Not used |
| 10 | Not used |
| 11 | Not used |
| 12 | Not used |
| 13 | High-speed CAN − |
| 14 | Not used |
| 15 | Not used |
| 16 | FNR5 transmission relay control |
| 17 | OSS sensor signal |
| 18 | Not used |
| 19 | ISS sensor signal |
| 20 | Transmission fluid pressure switch signal |
| 21 | Transmission range sensor signal |
| 22 | Not used |
| 23 | Not used |
| 24 | Not used |

---

## 10. Sensores e atuadores da FNR5

### 10.1 Sensores de rotação

A FNR5 possui três sensores distintos:

- `TSS` — Turbine Shaft Speed;
- `ISS` — Intermediate Shaft Speed;
- `OSS` — Output Shaft Speed.

#### TSS

| Pino | Função |
|---:|---|
| 1 | TSS signal |
| 2 | TSS return |

#### ISS

| Pino | Função |
|---:|---|
| 1 | Ground |
| 2 | ISS signal |
| 3 | FNR5 relay switched output |

#### OSS

| Pino | Função |
|---:|---|
| 1 | Ground |
| 2 | OSS signal |
| 3 | FNR5 relay switched output |

A presença do ISS é uma diferença estrutural importante em relação à Ford FN/4F27E mostrada no esquema do Focus.

### 10.2 Sensor de faixa da transmissão

| Pino | Função |
|---:|---|
| 1 | Ground |
| 2 | Transmission range sensor return |
| 3 | Transmission range sensor signal |
| 4 | Not used |
| 5 | Not used |
| 6 | Park/neutral switch signal |

A FNR5 usa um sensor de faixa com sinal dedicado e uma saída separada de Park/Neutral.

### 10.3 Pressostato do fluido

O material mostra um `Transmission Fluid Pressure Switch` de uma via, ligado ao pino 20 do conector B do TCM.

### 10.4 Corpo de válvulas principal

Conector externo de 9 vias:

| Pino | Função |
|---:|---|
| 1 | Duty solenoid C |
| 2 | Linear pressure control solenoid PCA + |
| 3 | Duty solenoid A |
| 4 | Oil temperature signal return |
| 5 | Oil temperature signal |
| 6 | On/off solenoid D |
| 7 | Linear pressure control solenoid PCA − |
| 8 | On/off solenoid E |
| 9 | Duty solenoid B |

### 10.5 Corpo de válvulas da quinta marcha

Conector de 2 vias:

| Pino | Função |
|---:|---|
| 1 | On/off solenoid F |
| 2 | Duty solenoid PCB |

Isso confirma que a FNR5 possui dois canais adicionais diretamente relacionados à quinta marcha:

- `SSF`;
- `PCB`.

### 10.6 Chicote interno do corpo de válvulas

O esquema interno apresenta os seguintes pontos:

| Ponto | Função |
|---:|---|
| 1 | Shift Solenoid C — SSC |
| 2 | Pressure Control A — PCA |
| 3 | Shift Solenoid A — SSA |
| 4 | TFT return |
| 5 | TFT signal |
| 6 | Shift Solenoid D — SSD |
| 7 | Pressure Control A — PCA |
| 8 | Shift Solenoid E — SSE |
| 9 | Shift Solenoid B — SSB |
| 10 | SSC ground |
| 11 | SSA ground |
| 12 | SSB ground |

---

## 11. Por que o TCM original da 4F27E não deve controlar a FNR5

A FNR5 exige recursos ausentes na estratégia e, possivelmente, no hardware do TCM original da Ford FN/4F27E:

- controle do solenoide F;
- controle do pressure-control solenoid B;
- leitura do sensor ISS;
- leitura do pressostato de fluido;
- lógica hidráulica da quinta marcha;
- calibração específica de cinco marchas;
- controle adaptativo e sincronização próprios da FNR5.

Portanto, a solução coerente é usar o TCM FNR5 `7E51-7A100-AA` com seu próprio chicote e seus próprios sensores/atuadores.

---

## 12. Correspondência funcional preliminar

Não existe equivalência física direta, mas há uma correspondência funcional entre os sistemas.

| Focus Ford FN/4F27E | FNR5 |
|---|---|
| C116 — solenoides e corpo de válvulas | Conector A — saídas de solenoides |
| C116 — contatos da alavanca | Conector B pino 21 + sensor TR |
| C117 — HS-CAN | Conector B pinos 1 e 13 |
| C117 — alimentação e terras | Conector A pinos 1, 2, 3, 9 e 10 |
| C117 — sensores de velocidade | Conector B pinos 7, 8, 17 e 19 |
| C117 — alimentação/relé | Conector B pino 16 + conector A pinos 2/10 |

Essa tabela é apenas conceitual. Não representa autorização para conexão direta.

---

## 13. Estratégia elétrica recomendada para o swap

### 13.1 Manter o TCM e o chicote completos da FNR5

A solução mais segura é instalar:

- TCM FNR5;
- conectores A e B originais;
- chicote completo da FNR5;
- relé da FNR5;
- fusíveis correspondentes;
- sensores TSS/ISS/OSS;
- sensor de faixa;
- pressostato;
- corpo de válvulas principal;
- corpo de válvulas da quinta marcha.

### 13.2 Adaptar somente a interface com o Focus

A adaptação deveria extrair do veículo apenas:

- VBAT;
- alimentação pós-chave/relé, conforme a estratégia adotada;
- terra;
- HS-CAN High;
- HS-CAN Low;
- Park/Neutral, se exigido externamente;
- ré;
- intertravamento da alavanca;
- sinais auxiliares necessários ao PJB/PCM/painel.

### 13.3 Ponto físico preferencial

O ponto mais promissor para uma adaptação reversível é o lado `C116/C117`, e não o C414.

Possível arquitetura:

```text
Chicote do Focus
   │
   ├── C116/C117 ou derivações equivalentes
   │
   └── adaptador removível
           │
           ├── TCM FNR5 conector A
           ├── TCM FNR5 conector B
           └── chicote completo da FNR5
```

O C116 provavelmente terá pouco reaproveitamento, exceto sinais relacionados à alavanca. O C117 tende a concentrar a maior parte das conexões úteis com o veículo.

---

## Critérios de confiabilidade das informações

Este documento separa três níveis de evidência:

1. **Observação direta dos anexos:** identificação visual de módulos, conectores, etiquetas e tabelas de pinagem fornecidas.
2. **Leitura do diagrama `PH8M5T-70000-AD`:** interpretação das páginas 60, 127 e 130 do arquivo encontrado na internet.
3. **Inferência técnica:** conclusões sobre a melhor estratégia de adaptação, compatibilidade provável e divisão funcional dos conectores.

As afirmações derivadas do diagrama devem ser tratadas como referência de trabalho, não como validação final da aplicação brasileira. A confirmação deve ser feita por pelo menos um dos seguintes meios:

- esquema elétrico específico do VIN/ano-modelo;
- medição de continuidade no chicote `14K039`;
- identificação dos circuitos e cores no veículo;
- leitura de sinais com multímetro/osciloscópio;
- captura CAN;
- documentação de oficina ou catálogo Ford correspondente ao veículo brasileiro.

---

## 14. Principal risco ainda não resolvido: protocolo CAN

O fato de ambos os veículos possuírem TCM separado e HS-CAN aumenta a plausibilidade do swap, mas não garante compatibilidade.

Ainda precisa ser comprovado se o TCM FNR5 reconhece as mensagens transmitidas pelo PCM/ABS/painel do Focus, incluindo:

- rotação do motor;
- torque calculado;
- carga;
- posição do acelerador;
- temperatura do motor;
- estado do freio;
- velocidade do veículo;
- estado de ignição;
- redução de torque durante as trocas;
- mensagens de plausibilidade e configuração.

Também é necessário saber se os demais módulos do Focus aceitam o que o TCM FNR5 transmite:

- marcha selecionada;
- marcha atual;
- solicitação de redução de torque;
- falha de transmissão;
- solicitação de MIL;
- temperatura da transmissão;
- estado de Park/Neutral;
- velocidade calculada.

Possíveis resultados:

1. **Compatibilidade direta:** o TCM funciona conectado ao HS-CAN do Focus.
2. **Compatibilidade parcial:** funciona com DTCs, pressão máxima, trocas ruins ou recursos desabilitados.
3. **Incompatibilidade:** será necessário gateway CAN ou alteração de firmware/calibração.

---

## 15. Itens mecânicos ainda não comprovados

Este documento não confirma:

- padrão completo da campana;
- profundidade do conversor;
- compatibilidade do flexplate;
- posição do motor de partida;
- suporte superior/lateral;
- apoio inferior;
- comprimento e estrias dos semieixos;
- posição do diferencial;
- interferência com agregado/longarina;
- tubulação de arrefecimento;
- cabo e curso do seletor;
- relação final;
- compatibilidade com pneus, ABS e cálculo de velocidade.

Esses itens exigem medição física ou documentação dimensional.

---

## 16. Próximos passos recomendados

### Etapa 1 — fechar a pinagem do Focus

Produzir uma tabela completa contendo:

- pino do C414;
- circuito Ford;
- cor e bitola;
- passagem por C116 ou C117;
- destino final;
- função;
- classificação: veículo, alavanca, sensor ou atuador.

### Etapa 2 — identificar apenas a interface necessária

Separar os fios em quatro grupos:

1. infraestrutura do veículo;
2. alavanca/intertravamento;
3. componentes exclusivos da 4F27E;
4. circuitos que serão eliminados.

### Etapa 3 — obter o chicote completo do Fusion/FNR5

Idealmente adquirir em conjunto:

- TCM `7E51-7A100-AA`;
- plugs A e B com rabicho;
- chicote integral da transmissão;
- relé e porta-fusível;
- seletor/sensor de faixa;
- conectores dos sensores;
- conectores dos dois corpos de válvulas.

### Etapa 4 — teste em bancada

Antes da instalação mecânica:

- alimentar o TCM com fusíveis adequados;
- implementar o relé conforme documentação;
- conectar CAN com terminação correta;
- verificar comunicação por FORScan/UDS;
- ler part number, strategy e DTCs;
- confirmar comportamento das saídas sem carga e com cargas simuladas adequadas.

### Etapa 5 — captura e comparação CAN

Capturar tráfego de:

- Focus 4F27E em funcionamento;
- Fusion FNR5 em funcionamento.

Comparar:

- IDs;
- frequências;
- counters;
- checksums;
- sinais correlacionados com RPM, torque, freio, TPS e marcha;
- mensagens enviadas pelo TCM durante trocas.

### Etapa 6 — avaliação mecânica

Somente após validar a possibilidade eletrônica:

- conferir campana e conversor;
- medir suportes;
- comparar semieixos;
- comparar relação final;
- definir seletor e cabo;
- verificar arrefecimento.

---

## 17. Avaliação preliminar de viabilidade

| Área | Avaliação atual |
|---|---|
| Arquitetura com TCM separado | favorável |
| Existência de HS-CAN no Focus | favorável |
| Chicote intermediário removível 14K039 | favorável |
| Identificação de C116/C117/C414 | confirmada no esquema |
| Pinagem do TCM FNR5 | confirmada pelos anexos |
| Uso do TCM FNR5 | necessário |
| Compatibilidade física dos conectores | inexistente; requer adaptador |
| Construção do chicote adaptador | tecnicamente viável |
| Compatibilidade CAN | desconhecida e crítica |
| Compatibilidade de alavanca/range | adaptável, ainda não fechada |
| Compatibilidade mecânica | não comprovada |
| Viabilidade geral | média, condicionada principalmente ao CAN e à mecânica |

---

## 18. Conclusão

Os achados mostram que o swap não é eletricamente absurdo. O Focus e o Fusion/FNR5 utilizam arquitetura semelhante em alto nível:

- PCM separado;
- TCM separado;
- comunicação HS-CAN;
- TCM controlando diretamente a transmissão.

No Focus, o chicote `14K039` liga o TCM pelo `C414` aos conectores intermediários `C116` e `C117`. O C116 é majoritariamente associado à alavanca e ao conjunto de solenoides da 4F27E; o C117 concentra alimentação, CAN, aterramentos, sensores de velocidade e interfaces auxiliares.

Na FNR5, o TCM `7E51-7A100-AA` utiliza conectores A/B próprios e controla diretamente todos os solenoides, incluindo os canais específicos da quinta marcha, além de ler TSS, ISS, OSS, temperatura, pressão e faixa.

A estratégia mais coerente é:

1. manter integralmente o TCM e o chicote da FNR5;
2. remover o TCM/chicote específico da Ford FN;
3. construir uma interface removível com o Focus, preferencialmente a partir do lado C116/C117;
4. preservar apenas alimentação, terras, CAN, sinais de alavanca/intertravamento e interfaces externas necessárias;
5. validar o protocolo CAN antes de concluir a adaptação mecânica.

O maior risco atual não é a pinagem dos solenoides, que está bem documentada. É a compatibilidade de mensagens e calibração entre o PCM do Focus e o TCM da FNR5.
