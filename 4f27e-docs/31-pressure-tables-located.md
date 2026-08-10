# 31 — Tabelas de Pressão / Rastro EPC (atualizado)

**Data:** 2026-08-07 (rev. rastro invertido EPC)  
**Status:** 🔴 Hipótese “`0x181xxx` = EPC line-pressure” **FALSIFICADA** — rastro de duty EPC sobe até QADC, sem lookup ROM de pressão  
**Dependência:** pipeline de duty (docs 15-17), channel→solenoid (doc 23), shift tables (doc 24), cal_mod (análise 2026-08-07)  
**Script:** `scripts/scan_calibration_descriptors.py` · logger: `scripts/tcm_pressure_logger.py`

---

## Resumo Executivo

1. **FATO:** Região `0x181258–0x181C88` contém muitas tabelas float no formato `(valor, breakpoint)` com ranges que *parecem* kPa×throttle / fator×RPM. Isso **não** prova função EPC.
2. **FATO (2026-08-07):** As tabelas consumidas por `cal_mod_lookup_to_3FC068/06C/064` (`0x8841C` / `0x8888C` / `0x889A8`) — incluindo runs em `0x181278+`, `0x181518+`, `0x1816C8+` — alimentam o **modulador de threshold de troca** (`0x3FC070` → `shift_threshold_compute_with_mode @ 0x93510`). **Não** o solenóide EPC.
3. **FATO (doc 23 + IDA):** EPC físico = slot **`0x34`** (idx4, hw_ch=`0x11`, io_id=`7`, TPU_B ch1, ~100 Hz). Duty sai só via `solenoid_outputs_update_7ch @ 0x42584` → `io_set_float @ 0x3BFCC`.
4. **FATO (rastro invertido):** entrada variável do duty EPC = `qadc_read_result_by_logical_ch @ 0x35CD0`(`0x11`) lendo `*(QADC_base + 0x280 + 2×slot)` com base `0x304C00` (QADC_B).
5. **FATO (MPC555 RM):** `0x304C00+0x280` = **RJURR[0]** (Result Word Table, `0x304E80–0x304EFE`). Preenchimento = **hardware QADC** após conversão — não há writer de software no flash (e não precisa). Sample = **resultado ADC** (10-bit), não lookup ROM.
6. **FATO (init):** único caller `boot_io_qadc_init_chain @ 0x3E380` → `blrl 0x346C8` com r3=`0x2A6CC`; header com count=`0x17` / entries=`0x2A5B8` está em **`0x2A6C8`** (Δ=4 no immediato `0xA6CC` vs `0xA6C8`). Entry `0x11`: ANx=0, flags=`0xA59C`.
7. **HIPÓTESE:** RJURR EPC start slot **23** → `0x304EAE` (modelo multi-CCW). **FATO:** `0x18C0` sem writers; path `0x41190` sem caller externo a órfão `0x4B390`.
8. **PENDENTE:** prova viva do off-by-4 / slot; origem do pedido de pressão se não for este laço ADC.

---

## ⛔ FALSIFICADO: `0x181xxx` como EPC line-pressure

| Afirmação antiga (doc 31 original) | Status |
|------------------------------------|--------|
| `0x1814E0` “forte candidata EPC” | **FALSIFICADA** — path estático → `0x3FC06C` / max → `0x3FC070` → shift threshold |
| Scan “pressão vs throttle” = mapas EPC | **HIPÓTESE morta** sem novo lastro; ranges kPa são coincidência de domínio numérico |
| Próximo passo = “cruzar descritor → EPC” nessas tabelas | **Substituído** pelo rastro invertido a partir do duty |

Pipeline real dessas tabelas (citação):

```
ROM 0x181xxx  →  cal_mod_lookup_to_3FC06C @ 0x8888C (etc.)
              →  cal_mod_max_*_to_3FC070 @ 0x88AD8
              →  shift_threshold_compute_with_mode @ 0x93510
```

Dispatcher: `cal_mod_switch_and_pipeline_9AE3C @ 0x9AE3C` (`blrl` para entry+4 em `0x9CFE0+`).

---

## Rastro invertido EPC (FATO — 2026-08-07)

```
EPC slot 0x34 / TPU_B ch1 / io_id=7 / idx4 / struct @ 0x3FA714
        ▲
io_set_float_by_id_and_dispatch_15D0 @ 0x3BFCC
        ▲  lhz r4, +0xE ; lbz r3, io_id @ 0x252F5
solenoid_outputs_update_7ch_from_252F5 @ 0x42584
  +0  ← sub_424FC(scale de +2)
  +0xE← solenoid_duty_ramp_calculate @ 0x41DFC(+0, +4)
        ▲
solenoid_outputs_prepare_cycle_from_252F4 @ 0x42674
  +2  ← média de sub_35CD0(byte0 da entry)
  EPC: byte0 = 0x11  (entry @ 0x252F4+0x10 = 11 07 00 05)
        ▲
qadc_read_result_by_logical_ch @ 0x35CD0
  base = qadc_module_base_table[(desc>>6)&3]
        0x288B8 = 0x304800 (QADC_A), 0x288BC = 0x304C00 (QADC_B)
  return lhz @(base + 0x280 + 2*slot)   # ex. 0x35DEC
        = RJURR[slot]   # QADC_B: 0x304E80 + 2*slot  (MPC555 RM 13.12.12)
```

Ciclo: `0x4A640` → prepare → update → snapshot `0x41050`.

**Implicação:** o path de duty do EPC é um laço em torno de um **ADC** (candidata forte: current-sense do driver) com alvo `+4` (fixo em 100 se `0x18C0` permanece 0). **Não** há mapa `0x181xxx` nesta cadeia.

### FATO — `+0x280` = RJURR (MPC555)

| Módulo | Base | RJURR[0] | Citação |
|--------|------|----------|---------|
| QADC_A | `0x304800` @ `0x288B8` | `0x304A80` | RM: RJURR `0x304A80–0x304AFE` |
| QADC_B | `0x304C00` @ `0x288BC` | `0x304E80` | RM: RJURR `0x304E80–0x304EFE` |

`0x304C00+0x280 = 0x304E80`. Hardware grava o result word; software só lê (`lhz` em `0x35DEC` etc.).

### FATO — CCW montado em `qadc_descriptor_table_init @ 0x346C4`

```
0x34BE8  lbz  r12, 0(r24)        # config entry byte0
0x34BEC  clrlwi r12, r12, 26     # ANx = byte0 & 0x3F
0x34BF0  or   r7, r9, r12        # CCW = sample_time_bits | ANx
0x34C74  sth  r7, 0x200(r10)     # CCW[slot] @ module+0x200
```

Tabela auxiliar `0x288C8`: halfwords **`0x0034, 0x0035, 0x0036`** OR-ados no CCW em modos multi-slot (`0x34CA8–0x34CB0`). Coincidem com os slot IDs dos solenóides PWM/virtuais — **HIPÓTESE (lastro parcial):** ANx 52/53/54 ligados a sense desses canais; falta provar o descritor do lógico `0x11`.

### Struct por canal (inalterado)

- Base: `r13+0x17C4` = **`0x3FA6C4`**; stride **`0x14`**; 7 canais na ordem `0x252F4`.
- Duty em **`+0xE`** (u16) → `io_set`.

| Canal | idx | hw | io | period | Duty (+0xE) |
|-------|-----|----|----|--------|-------------|
| SSA | 0 | 0x0D | 3 | 0 (ON/OFF) | 0x3FA6D2 |
| SSB | 1 | 0x0C | 2 | 0 | 0x3FA6E6 |
| SSC | 2 | 0x0E | 4 | 0 | 0x3FA6FA |
| SSD | 3 | 0x0F | 5 | 0 | 0x3FA70E |
| **EPC** | **4** | **0x11** | **7** | **100 (~100Hz)** | **0x3FA722** |
| SSE | 5 | 0x10 | 6 | 300 (~33Hz) | 0x3FA736 |
| virtual | 6 | 0x03 | 4 | flags 0x05 | 0x3FA74A |

### Campo `+4` (alvo de ramp) e slots `0x18B8–0x18C4`

- Init (`0x42210`): `+4 = period×10` (EPC → 100).
- `solenoid_apply_period_targets_from_18B8 @ 0x41190` lê `r13+0x18B8…18C4` (EPC = **`0x18C0` → `0x3FA7C0`**) e regrava `+4` via `solenoid_next_pending_channel_find @ 0x42398`.
- **FATO:** no binário de 2 MB **não há nenhum store** para `0x18B8–0x18C4(r13)` — só os 7 `lhz` em `0x4119C+`. Com cmd=0 (BSS), o clamp usa `period×10` → EPC `+4` permanece 100.

### Cal no path de duty (não é mapa de pressão)

| ROM | Uso em `0x41DFC` |
|-----|------------------|
| `0x18A1EC`, `0x18A208`, `0x18A1FA` | ganhos / termos de slew |
| `0x18A244`, `0x18A27E` | clamp do duty resultante |
| `0x18A254`, `0x18A28C` | clamp do acumulador `+8` |
| `0x18A2A8` | período (×10 → `+4` no init) |

Únicos callers de `io_set_float` no path de solenóide: init `0x421DC`, update `0x425F8/614`, `sub_25244`.

---

## Região `0x181258–0x181C88` (ainda útil — outra função)

Scan estrutural (`scripts/scan_calibration_descriptors.py`) continua válido como **inventário**. Reclassificação:

| Offset (amostra) | Papel **provado** / status |
|------------------|----------------------------|
| `0x181278+`, `0x181518+` | input do `cal_mod_*` → **shift threshold**, não EPC |
| `0x1816C8` / `1710` / `1758` / `17A0` | idem via `0x8888C` → `0x3FC06C` |
| `0x1817A8+` fator×RPM | **DESCONHECIDO** no path EPC; inventário 1D pendente |
| Demais runs “kPa-like” | **DESCONHECIDO** — não rotular como EPC sem rastro |

**Descritores** `0x186874–0x187954`: cruzamento descritor→função ainda aberto, mas **não** priorizar como “achar EPC” — o EPC não lê essa região no path de duty.

---

## ⛔ FALSIFICADO EM CAMPO (2026-08-03): `0x3FA722` NÃO é o duty vivo observado

Teste UDS 0x23 (D + carga): `0x3FA722` = **`0x0000` constante**. Em P/N lia `0xFFFF`.

Layout estático (`+0xE` @ idx4 = `0x3FA722`) **bate com o disasm**; persistência/atividade em campo **não**. Hipóteses compatíveis com o rastro novo (não exclusivas):

- bit de enable em struct `+0xC` (teste @ `0x425A8`) desligado → update força `io_set(id, 0)`;
- ramp com `+4==0` retorna 0 (canais ON/OFF); EPC não deveria cair aqui se `+4=100`;
- proxy de carga visto em campo está no **idx0** (`0x3FA6C4/C8/D2`), não no EPC.

Células vivas (corr THR ≈ −0.84):

| Endereço | papel |
|----------|--------|
| **0x3FA6C4** | proxy primário (idle~9400 → accel~7700) — struct idx0 `+0` |
| **0x3FA6C8** | quase idêntico — idx0 `+4` |
| **0x3FA6D2** | mesma tendência — idx0 `+0xE` (SSA duty, não EPC) |

TPU/MIOS MMIO **não** legível via 0x23.

---

## ⚠️ Classe de risco

Modificar qualquer tabela *suspeita* de pressão continua o patch de **maior risco**:

- Pressão baixa → patinação / destruição rápida.
- Pressão alta → trocas duras / choque de linha.

**Regra:** nenhuma edição “de pressão” em flash sem (1) rastro até duty/slot `0x34` **provado**, (2) validação ao vivo do comando real, (3) range OEM (diff BH/BL/CA). As tabelas `0x181xxx` **não** cumprem (1) para EPC.

---

## Init QADC / config (FATO — 2026-08-07 cont.)

### Caller
Único site: `boot_io_qadc_init_chain @ 0x3E380`:

```
0x3E47C  addi r9, r9, 0x46C8     # LR = 0x346C8 = qadc_descriptor_table_init+4
0x3E484  lis  r3, 3
0x3E488  addi r3, r3, -0x5934    # r3 = 0x2A6CC   (insn SI=0xA6CC)
0x3E48C  blrl
```

### Config ROM — off-by-4
| EA | Campo | Valor |
|----|-------|-------|
| **`0x2A6C8`** | count (u8) | **`0x17` (23)** ← layout que `346C4` espera |
| `0x2A6C8+1` | b1 | `0x0B` |
| `0x2A6CC` | entries ptr | **`0x2A5B8`** |
| `0x2A6CC` | valor em r3 | **hdr+4** |

**FATO:** encoding atual `addi …,0xA6CC` → `0x2A6CC`. Header válido exige `0xA6C8` → `0x2A6C8` (Δ=4).  
**FATO:** com r3=`0x2A6CC`, `lbz count` lê `0x00` e `lwz +4` lê `0x01000000` — init quebrado.  
**HIPÓTESE:** bug de constante (word off-by-one); pretendido = `0x2A6C8`. Sem reloc/patch no binário.

### Entry lógica `0x11` (EPC) @ `0x2A5B8+0xCC`
`00 02 A5 9C 00 00 00 00 74 00 00 10`

| Campo | Valor |
|-------|-------|
| byte0 / ANx | `0x00` / **0** |
| flags +2 | `0xA59C` → sample `word_2890C[3]=0x0140`; path multi-CCW (`low4≠0`) |
| +4 | 0 |

### RJURR slot (HIPÓTESE simulada, header `0x2A6C8`)
Modelo: flags=0 → 1 slot; flags `0xA59C` → 2 slots (path `0x34DF0`).

| Lógico | RJURR start |
|--------|-------------|
| … | … |
| `0x10` | 21 |
| **`0x11` (EPC)** | **23** → **`0x304EAE`** (`0x304E80+2×23`) |
| `0x12` | 25 |

**DESCONHECIDO até dump vivo** de `*(r13+0x155C)+3×0x11+1`.

---

## Setpoint / `+4` (FATO)

| Item | Evidência |
|------|-----------|
| Writers `0x18B8–0x18C4(r13)` | **zero** no binário 2 MB (só `lhz` em `0x4119C+`) |
| `solenoid_apply_period_targets_from_18B8 @ 0x41190` | lê cmds → escreve `+4`; **sem** `bl`/`blrl` externo a `sub_4B390` |
| `sub_4B390` | **sem** caller estático encontrado (órfão) |
| Init `+4` EPC | `period×10` = **100** @ `0x42210` |

**Conclusão operacional:** com a evidência estática atual, o alvo de ramp do EPC fica em **100**; a variação de duty, se houver, vem de **`+2` ← RJURR** (ADC), não de mapa ROM nem de `0x18C0`.

---

## Plano de investigação (atualizado)

1. ~~Mapear switch `0x9C300`~~ → **feito** em [32-cal-mod-mode-switch-9C300.md](32-cal-mod-mode-switch-9C300.md).
2. **ROI:** CAN-ID TouCAN_B MB1 (doc 41) — eixo slots via CAN.
3. **ROI vivo (quando houver log):** dump `0x155C` / `desc[0x11]` / `*(0x304EAE)`; também `0x3FBBCC` + gates do switch.
4. Inventário 1D restante (fora shift/cal_mod) — possível origem de pedido de pressão noutro atuador.
5. Diff BH/BL/CA `0x181xxx` = threshold only.

---

## Nota de escopo

O tranco 3→2 abaixo de 30 km/h é **secundário** (Patch 5 / downshift fora da faixa). Antes de qualquer patch hidráulico: adaptação/relearn. Este doc registra o estado do rastro — **não** autoriza patch de pressão.
