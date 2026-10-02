# 52 — idx0 é o solenóide de pressão (não SSA); shift solenoids não estão na struct 0x3FA6C4

**Data:** 2026-09-07 (rodada de rua, veículo em movimento)
**Status:** 🟢 Dois FATOS novos + 1 HIPÓTESE forte que reposiciona docs 23 e 31
**Log:** `tcm_pressure_20260907_173525.csv` (2286 amostras, ~0.9 Hz, `--sol6`)
**Dependência:** doc 23 (mapa de canais), doc 31 (rastro EPC), doc 24 (shift schedule)

---

## Resumo Executivo

1. **FATO:** `D1…D5` (duty `+0xE` dos idx1–5) = **0 em 2286/2286 amostras**, cobrindo P, R, N e marchas 1, 2, 3, 4 até 71 km/h TCM. A struct de 7 canais **não carrega as shift solenoids**.
2. **FATO:** o duty do **idx0** é função monotônica **inversa** do acelerador, medida com **marcha constante** (4ª, sem troca): 3114 @10% → 2244 @22.5%.
3. **HIPÓTESE forte:** **idx0 é o solenóide de controle de pressão (EPC)**. O rótulo `idx4 = EPC` do doc 23 está errado — por isso `0x3FA722` sempre leu 0 em campo.
4. ~~**HIPÓTESE:** tranco = pré-carga rasa~~ → **FALSIFICADA** na rodada 2 (§5-B). O sinal está **depois** da troca: o duty salta (pressão desaba) com o setpoint parado.
5. **FATO:** o tranco na 3→2 leve é **sistemático** — 13 de 19 downshifts da rodada 2 batem o critério, e o condutor estimou "10 ou mais" na mesma volta.

---

## 1. FATO — shift solenoids não estão nesta struct

Endereços lidos (base `0x3FA6C4` + idx×`0x14` + `0xE`):

| idx | duty EA | valor observado |
|-----|---------|-----------------|
| 0 | `0x3FA6D2` | **1982–3973**, sempre ativo |
| 1 | `0x3FA6E6` | 0 |
| 2 | `0x3FA6FA` | 0 |
| 3 | `0x3FA70E` | 0 |
| 4 | `0x3FA722` | 0 |
| 5 | `0x3FA736` | 0 |

Cobertura: alavanca em **P, R, N, D**; marchas **1, 2, 3, 4**; 0–71 km/h TCM; pedal 0–26%.

O chart OEM (ATSG / manual Ford) exige, em Drive:

| Marcha | SSA | SSB | SSC | SSD | SSE |
|--------|-----|-----|-----|-----|-----|
| 1ª | OFF | OFF | OFF | **ON** | **ON** |
| 2ª | OFF | OFF | OFF | OFF | **ON** |
| 3ª | OFF | OFF | OFF | OFF | OFF |
| 4ª | **ON** | OFF | **ON** | OFF | OFF |

Em 1ª (SSD+SSE obrigatoriamente energizados) e em 4ª (SSA+SSC), **nada** apareceu em `D1…D5`.

**Conclusão:** o modelo do doc 23 ("7 canais = 6 solenóides físicos") não descreve o runtime. As shift solenoids saem por outro caminho — candidato: dispatch `15D0` / TPU direto, sem passar pelo laço de rampa `0x41DFC`.

**Mecanismo compatível (assembly, doc 31):** em `0x425A4–0x425B0` o update testa o **bit1** de `+0xC`; se limpo, chama `io_set(id, 0)` e **não** escreve `+0xE`. Com `+0xE` nunca escrito desde o boot (BSS), a leitura 0 é consistente. Complementarmente, a rampa `0x41DFC` retorna 0 quando o alvo `+4 == 0` (`0x41EDC` `cmpwi r6,0` → `beq`), e o init dá `+4 = 0` para idx0–3.

**DESCONHECIDO:** por qual caminho as shift solenoids realmente recebem comando.

---

## 2. FATO — curva de carga do idx0 com marcha constante

Janela `t=944000–985000` do CSV: **4ª marcha o tempo todo**, 56–65 vel, sem troca. Isola carga de marcha.

| THR % | n | duty idx0 |
|-------|---|-----------|
| 10.0 | 2 | 3114 |
| 12.5 | 2 | 3058 |
| 15.0 | 2 | 3020 |
| 17.5 | 15 | 2693 |
| 20.0 | 13 | 2512 |
| 22.5 | 3 | 2244 |

Monotônica, com joelho entre 15% e 17.5%.

Correlações no log anterior (`tcm_pressure_20260907_073433.csv`, n=1601):
`corr(THR, duty) = −0.77`, `corr(THR, sense) = −0.85`, `corr(duty, sense) = +0.83`.

Médias por marcha no log de hoje — **não codificam marcha**:

| gear | n | duty médio |
|------|---|-----------|
| 1 | 236 | 3450 |
| 2 | 88 | 3249 |
| 3 | 377 | 3430 |
| 4 | 100 | 3268 |

**Convenção derivada:** pressão de linha tem de subir com carga ⇒ **duty baixo = pressão alta** (inverso clássico Ford EPC).

---

## 3. HIPÓTESE forte — idx0 é o EPC

Lastro:

- Energizado **idêntico** em P, R, N e D parado — nenhuma shift solenoid faz isso; EPC sim.
- Duty função de carga, **independente da marcha**.
- Laço fechado com **QADC** (`+2` = EMA do canal lógico `0x0D`; `+0` = escala via `sub_424FC`) — current sense, típico de solenóide de força variável.
- Modula no evento de troca (§4).

Isso **corrige** doc 23, que atribuiu `idx4 = EPC` só pelo período de 100 Hz na tabela `0x18A2A8`. A classificação por período **não** sobreviveu ao teste vivo.

**Não provado:** identidade OEM dos idx1–5, e o mapeamento pino/hw do idx0 (`hw_ch = 0x0D`, `io_id = 3`).

---

## 4. FATO — duty cai em toda troca real, não em troca de alavanca parado

17 transições sob carga: duty na troca entre **2895 e 3130**, sempre abaixo da média da marcha (3250–3450).
2 transições com o carro parado (só alavanca): **3364** e **3430** — sem queda.

A queda acompanha o **evento** de troca, não a identidade da marcha.

---

## 5-B. Rodada 2 (18h34, modo `--shift`, 1.5 Hz) — o sinal está DEPOIS da troca

**Log:** `tcm_pressure_20260907_183411.csv` (2324 amostras) + `_marks.txt`
**Modo:** `--shift` = GEAR + SPEED + THR + `C8` (setpoint `+4`) + `D0` (duty `+0xE`)

### FATO — setpoint `C8` é vivo e segue carga
Parado: `C8 = 9400` constante. Com pedal: cai para 4800–8200. Confirma que `0x3FA6C8` é escrito em runtime (o init estático dá 0) — o writer continua **DESCONHECIDO**.

### Métrica de pré-carga: FALSIFICADA
Hipótese da §5 (profundidade do mergulho de duty antes da troca) previa liso para `D0_pre_min < 2250`.
Teste cego falhou no primeiro evento:

| evento | `D0_pre_min` | rótulo real |
|--------|--------------|-------------|
| `t=956696` | 2169 | liso |
| `t=1119634` | **2164** | **tranco** |

Valores praticamente idênticos, resultados opostos. **Métrica descartada.**

### FATO — separação está no ΔD0 pós-troca

| evento | ΔD0 (1 amostra após) | Δpedal | rótulo |
|--------|----------------------|--------|--------|
| liso (hoje `t=956696`) | −13 | −2.0 | liso |
| liso (manhã `t=729250`) | −5 | +1.0 | liso |
| tranco (hoje `t=1119634`) | **+688** | **0.0** | tranco |
| tranco (manhã `t=958213`) | +331 | −6.0 | tranco |

O caso `t=1119634` é o mais limpo: **pedal inalterado** (7.5% antes e depois) e duty saltou +688.
O caso da manhã está contaminado (pedal caiu 6 pontos, que sozinho já elevaria o duty).

### FATO — o salto não vem do setpoint
No tranco de `t=1119634`: `C8` ficou **parado** (6310 → 6320) enquanto `D0` saltou +688.
Como o duty sai da rampa sobre o erro (`+4` alvo − `+0` sense, `0x41E04`–`0x41EE0`), alvo constante + saída saltando ⇒ **o sense (`+0` / `C4`) caiu**. Isto é perda de corrente real no solenóide, não decisão de calibração.

**DESCONHECIDO:** `C4` não estava no log deste modo. Próxima rodada tem de incluir.

### FATO — o tranco é sistemático, não excepcional
Critério ΔD0 > +200 classifica **13 de 19** downshifts 3→2 desta rodada como tranco.
Estimativa do condutor na mesma volta: **"10 ou mais"**. Taxa base compatível; os 2 eventos rotulados explicitamente também batem.

**Implicação:** o tranco na 3→2 leve é o comportamento **padrão** deste calibre, não um caso de borda. Os patches v6.2 aumentaram a exposição a ele ao abrir 3→2 na faixa de pedal baixo.

**Ressalva:** 2 rótulos explícitos + 1 estimativa agregada. Critério **não validado** evento a evento.

---

## 5. HIPÓTESE (rodada 1) — o tranco 3→2 é falta de pressão

Alinhamento de três eventos (t=0 no instante da troca):

| Evento | pedal | duty em −1 s (pré-carga) | duty na troca | sensação |
|--------|-------|--------------------------|---------------|----------|
| Kickdown 3→2 @41 vel | 26% | **2111** | 2868 | suave |
| Tip-in 3→2 @23 vel | 11.5% | **2080** | 3058 | suave |
| Tip-in 3→2 @23 vel | 6.0% | **2425** | 3226 | **tranco** |

Os dois primeiros vêm de logs diferentes (hoje / manhã) e concordam. O evento com tranco é o de **menor pedal**, **pré-carga mais rasa** e **maior duty na troca** — a troca mais fraca em pressão dos três.

**Leitura:** o tranco não é engate duro por excesso de pressão; é troca sob pressão baixa, com enchimento lento e agarre atrasado.

**Por que importa para os patches:** os patches v6.2 passaram a permitir 3→2 exatamente na faixa de **pedal baixo / velocidade baixa**, que é onde o TCM comanda a menor pressão. Kickdown a ~40 vel é suave porque o pedal fundo já preparou a linha.

**Ressalva:** n=1 por caso. Direção consistente nos três, mas **não é FATO**. Precisa de mais eventos marcados e do logger rápido para resolver a rampa entre amostras.

---

## 6. Impacto nos docs

| Doc | Estado |
|-----|--------|
| 23 | `idx4 = EPC` e `idx0 = SSA` **falsificados** em runtime. Nomes OEM dos idx1–5 seguem abertos. |
| 31 | `0x181xxx ≠ EPC` continua válido. Mas o fenômeno "pressão" volta ao jogo **pelo laço de corrente do idx0**, não por tabela ROM. |
| 24 / 26 / 50 / 51 | Shift schedule inalterado. Ganham contexto: a faixa que os patches abriram é de pressão baixa. |

---

## 7. Próximo passo de maior ROI

**Achar o writer runtime de `idx0 +4` (`0x3FA6C8`).** Ele é o **setpoint de pressão**, e hoje é `DESCONHECIDO`:

- init dá `+4 = period×10 = 0` para idx0 (`0x42210`, tabela `0x18A2A8[1] = 0`);
- em campo `+4` fica **~9400** e lidera a queda na troca;
- stores estáticos para `r13+0x18B8…18C4` = **zero** no binário de 2 MB;
- `solenoid_apply_period_targets_from_18B8 @ 0x41190` só tem caller órfão `sub_4B390`.

Ou seja: existe um writer que a varredura PPC não achou. Candidatos: código **VLE**, store indexado (`sthx`) com base calculada, ou escrita via ponteiro em tabela. Essa função é o alvo real de qualquer calibração de pressão — não `0x181xxx`.

**Rodada de rua complementar (prioridade após §5-B):** modo `--shift` **com `C4` incluído**. A pergunta aberta é se o duty salta porque a corrente medida caiu (perda física de carga no solenóide) ou por outro motivo. Sem `C4` não dá para fechar.

Rotular **cada** 3→2 individualmente (liso/tranco) para validar o critério ΔD0 > +200 evento a evento — hoje só há 2 rótulos explícitos e 1 estimativa agregada.
