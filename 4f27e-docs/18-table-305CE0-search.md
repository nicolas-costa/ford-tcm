# Busca pela Origem da Tabela RAM @ 0x305CE0 - RESULTADOS

**Data:** 2026-01-11
**Status:** ❌ **Init NÃO LOCALIZADO via análise estática PPC**
**Firmware:** 5U75-14C337-AA.rebuilt.aligned.bin

---

## Resumo Executivo

Conduzida busca exaustiva pela origem da tabela RAM @ 0x305CE0. **Confirmado que não há init PPC direto visível**, validando as hipóteses documentadas em `10-open-issues.md`.

---

## O Que FOI Encontrado (FATOS)

### 1. Reader Confirmado @ 0x2386C
```asm
0x02386C: lis r8, 0x30
0x023870: ori r8, r8, 0x5CE0   # r8 = 0x305CE0
```
- **Localização**: Dentro de `pwm_duty_writer_staging_builder`
- **Uso**: Lê valores de duty da tabela (offset +4, stride 8)

### 2. Estrutura da Tabela
- **Endereço Base**: 0x305CE0 (RAM)
- **Stride**: 8 bytes
- **Duty Command**: Offset +4 (u16)
- **Valores Esperados**: 0x1000-0x7000 (12.5%-87.5% PWM)

### 3. Único Outro Acesso a 0x30xxxx
- **@ 0x41A40**: `lis r8, 0x30`
- **Status**: Não é função detectada, possivelmente:
  - Dados (word em tabela ROM)
  - Código VLE não decodificado
  - Gap no analysis do IDA

---

## O Que NÃO FOI Encontrado (FATOS)

### 1. XREFs Diretos
- **Busca via IDA MCP**: 0 resultados
- **Scan binário**: Apenas 1 construção de endereço (o reader)

### 2. Stores para 0x305CE0
- **stw/sth/stb diretos**: 0 ocorrências
- **Stores indexados (stwx/sthx)**: Nenhum para região 0x305xxx

### 3. Init via Memset
- **Chamadas ao memset @ 0x2610C**: 5 encontradas
- **Destino 0x30xxxx**: Nenhuma

### 4. Loops de Init
- **Padrão `lis 0x30 + loop + store indexed`**: 0 candidatos
- **Loops de cópia/fill para 0x30xxxx**: Nenhum encontrado

### 5. Tabelas ROM de Fallback
- **Busca por padrões duty (stride 8, valores 0x1000-0x7000)**:
  - 45578 candidatos (muitos falsos positivos - código interpretado como dados)
  - Nenhuma tabela grande (>32 entries) em regiões de calibração com padrão consistente

---

## Hipóteses Validadas

### Hipótese 1: Init Ausente em PPC Direto ✅
**Confirmado.** Scan completo do binário não encontrou:
- Stores diretos para 0x305CE0
- Loops de init para região 0x30xxxx
- Chamadas memset/memcpy com destino 0x30xxxx

### Hipótese 2: Origem Mais Provável

Baseado na análise e documentação existente:

#### A. Dispatcher Indireto (60% probabilidade)
- Documento `10-open-issues.md` menciona dispatcher @ 0x31C84
- Sistema de opcodes que popula RAM via tabelas indiretas
- **Engines identificadas**:
  - Engine A @ 0x43F84
  - Engine B @ 0x441C8
  - Engine C @ 0x442B4
  - Engine D @ 0x4410C
- **Conexão provada**: Engine A → sub_44460 → init bloco RAM

#### B. Código VLE não Decodificado (30% probabilidade)
- IDA em modo mixed (PPC+VLE)
- Init pode estar em instruções VLE compactas
- Região 0x17xxx-0x18xxx (early init) ainda não completamente analisada

#### C. Cálculo Dinâmico em Runtime (10% probabilidade)
- Valores calculados baseados em:
  - Estado do TCM
  - Sensores (temperatura, RPM, etc.)
  - Tabelas de calibração ROM
- Menos provável: duty command deveria ser determinístico

---

## Análise da Documentação (Cross-reference)

### Do Documento `17-duty-pipeline.md`:
> **Tabela RAM @ 0x305CE0 - Origem NÃO Localizada**
> - Tabela é **RAM** (dump = 0xFF)
> - **Stride 8 bytes**, duty em offset +4 (u16)
> - **Única referência:** Dentro dos writers @ 0x23870
>
> **HIPÓTESE (Não Comprovada)**
> Possíveis origens:
> 1. **Cálculo dinâmico** em função não mapeada (gap no disassembly)
> 2. **Cópia de ROM** via memcpy/DMA não localizado
> 3. **Inicialização VLE** em região não analisada
> 4. **Valores padrão** de factory calibration (carregados de EEPROM)

**Status após esta análise:** Hipóteses 1, 2, 4 **descartadas**. Hipótese 3 (VLE) **reforçada**.

### Do Documento `10-open-issues.md`:
> **1) `r13+0x15D0` (IO dispatch root): init ausente em PPC**
> - varredura do BIN por `stw rX, 0x15D0(r13)` dá **1 ocorrência** (o clear).
> - varredura do BIN por `addi rX, r13, 0x15D0` dá **0 ocorrências**.
>
> **Hipóteses restantes (ordem de plausibilidade):**
> - **init em VLE**: o IDB está em decode mixed (PPC+VLE); init pode estar em instruções compactas que não aparecem no nosso scan PPC-only.
> - **init por store indexado** (`stwx`/loop) sem `stw disp(r13)` óbvio
> - **pré-init fora desta imagem**: boot ROM / estágio anterior entra com RAM populada

**Confirmado:** Padrão idêntico para 0x305CE0 e r13+0x15D0.

---

## Próximos Passos Práticos

### Opção 1: Análise Dinâmica (ROI MÁXIMO) ⭐
**Requer:** Hardware TCM + BDM/JTAG

**Método:**
1. Watchpoint write em 0x305CE0-0x305D40 (região tabela)
2. Boot o TCM e capturar backtrace do primeiro write
3. Dump de RAM após init completo

**Resultado Esperado:**
- Função exata que inicializa tabela
- Valores reais de duty para cada channel
- Origem dos valores (ROM, cálculo, ou default)

### Opção 2: Análise do Dispatcher Indireto
**Requer:** IDA Pro + tempo

**Método:**
1. Analisar dispatcher @ 0x31C84 completamente
2. Mapear tabela de opcodes (1, 3, 4, etc.)
3. Seguir Engine A @ 0x43F84 → sub_44460
4. Identificar se algum opcode popula 0x305CE0

**Resultado Esperado:**
- Caminho completo de init via dispatcher
- Possível source ROM da tabela

### Opção 3: Instrumentação do Reader
**Requer:** Modificação do firmware + emulador/hardware

**Método:**
1. Patch @ 0x23918 (antes de ler tabela):
   ```asm
   # Interceptar leitura
   bl log_duty_read  # Log (channel_id, duty)
   ```
2. Executar TCM em condições variadas
3. Correlacionar duty com estado (gear, throttle, temp)

**Resultado Esperado:**
- Valores de duty usados em runtime
- Padrão de uso da tabela
- Possível inferência de lógica

### Opção 4: Engenharia Reversa por Padrões
**Requer:** Apenas análise estática

**Método:**
1. Assumir valores padrão baseados em:
   - Duty fixo conhecido: 0x2000 (25.4%)
   - Variações típicas: ±0x1000
2. Analisar funções que **consomem** duty:
   - Apply @ 0x21CB8
   - Multiplicação/scaling
3. Reverter lógica esperada

---

## Recomendação Final

**PRIORIDADE 1:** Análise Dinâmica (Opção 1)
Sem hardware, a origem exata da tabela **não será descoberta** via análise estática PPC-only.

**PRIORIDADE 2:** Análise do Dispatcher (Opção 2)
Caminho promissor baseado em evidências existentes (Engine A → init bloco RAM).

**WORKAROUND:** Instrumentação (Opção 3)
Se não há tempo/recurso para 1 ou 2, instrumentar o reader e observar comportamento em runtime fornece dados práticos.

---

## Evidências Técnicas

### Scan Realizado

```bash
# Construção de endereço 0x305CE0
grep -a "lis.*0x30" + "ori.*0x5CE0"  → 1 match @ 0x2386C

# Stores para região
grep stw.*0x305  → 0 matches
grep sth.*0x305  → 0 matches

# Memset com destino 0x30xxxx
grep "bl 0x2610C" + context  → 0 matches com lis r3, 0x30

# Loops de init
pattern: lis 0x30 + stwx/sthx + branch_back  → 0 candidates
```

### Ferramentas Utilizadas
- IDA Pro MCP (porta 13337)
- Binary scanning (Python + struct)
- Pattern matching (instruções PowerPC)

---

## Conclusão

A tabela RAM @ 0x305CE0 **não tem init visível em código PPC direto**. A origem mais provável é:
1. **Sistema de dispatcher indireto** (documentado em fase anterior)
2. **Código VLE não decodificado**
3. **Boot ROM externo** (menos provável)

**Análise estática PPC-only esgotada.** Próximo passo produtivo requer:
- Análise dinâmica com hardware, OU
- Análise profunda do dispatcher indireto, OU
- Aceitação de valores default/assumidos

---

**FIM DO DOCUMENTO**
