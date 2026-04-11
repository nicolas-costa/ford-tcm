## 18 — UDS/diag: dispatch indireto + estado (`r13+0x6D40/0x6D4F`) + builders de TX (`r13+0x6C34`)

### Escopo (o que este doc prova)
Este documento registra **FATO** (EA/bytes/instruções) para:
- cadeia `diag_state_machine_dispatch → sub_19E74 → handler` (dispatch indireto),
- uso de **estado global** em SDA (`r13+0x6D40` e `r13+0x6D4F`) pelos handlers,
- prova objetiva de **construção do TX** via `r13+0x6C34` no builder `0x000459B0`,
- **bloqueio** atual para fechar o fluxo do `svc 0x3B`: branch para `0xFE02BF28` (fora de segmento).

---

### FATO 1) State machine despacha handlers UDS via `sub_19E74`
- **EA:** `0x0001C78C..0x0001C798` (`diag_state_machine_dispatch`)
- **Assembly:**
  - `0x0001C78C: lis r3, uds_service_dispatch_table_10998@ha`
  - `0x0001C790: addi r3, r3, uds_service_dispatch_table_10998@l`
  - `0x0001C794: lwz r4, 0x6C04(r13)`
  - `0x0001C798: bl sub_19E74`

**Impacto:** prova de que o state machine entra no dispatcher da tabela UDS (não é “switch” direto).

---

### FATO 2) `sub_19E74` chama handler por ponteiro (call indireta)
- **EA:** `0x00019F00..0x00019F08` (`sub_19E74`)
- **Assembly:**
  - `0x00019F00: lwz r12, 0(r31)`
  - `0x00019F04: mtlr r12`
  - `0x00019F08: blrl`

**Impacto:** XREF de `bl handler` não existe; a relação é por **ponteiro em tabela**.

---

### FATO 3) Builder TX `0x000459B0` escreve no TX via `r13+0x6C34` e é guardado por `6D40==2`
#### 3.1) Guard por estado (`r13+0x6D40`)
- **EA:** `0x000459C4..0x000459CC` (`diag_tx_builder_copy_template_459B0`)
- **Assembly:**
  - `0x000459C4: lhz r12, 0x6D40(r13)`
  - `0x000459C8: cmpwi r12, 2`
  - `0x000459CC: bne loc_45C40`

#### 3.2) Escrita sequencial no TX (byte-a-byte)
- **EA:** `0x00045C6C` (`diag_tx_builder_copy_template_459B0`)
- **Assembly:**
  - `0x00045C6C: stbu r12, 1(r8)`

**Impacto:** prova objetiva de “onde o TX é preenchido”: stores via ponteiro (cursor) construído a partir de `r13+0x6C34`.

---

### FATO 4) State machine chama o builder por LR (`mtlr` + `blrl`) via `off_2FA0C`
- **EA:** `0x0001C5E4..0x0001C5F0` (`diag_state_machine_dispatch`)
- **Assembly:**
  - `0x0001C5E4: lwz r12, off_2FA0C@l(r12)` (**carrega `0x000459B0`**)
  - `0x0001C5E8: mtlr r12`
  - `0x0001C5F0: blrl`

**Impacto:** o builder TX não é chamado por `bl 0x459B0`. É chamado por ponteiro/tabela.

---

### FATO 5) Serviços que setam `r13+0x6D40 = 2` (habilita o builder `0x459B0`)
Origem: varredura estrutural dos handlers da tabela `uds_service_dispatch_table_10998 @ 0x000109A4`.

#### 5.1) `svc 0x27` (`uds_svc_27_handler_entry`)
- **EA:** `0x0001A314..0x0001A34C`
- **Assembly (trecho):**
  - `0x0001A314: li r12, 2`
  - `0x0001A318: sth r12, 0x6D40(r13)`
  - `0x0001A34C: blr`

#### 5.2) `svc 0x3B` (`uds_svc_3B_handler_entry`)
- **EA:** `0x0001BEEC..0x0001BEF8`
- **Assembly (trecho):**
  - `0x0001BEEC: li r12, 2`
  - `0x0001BEF0: sth r12, 0x6D40(r13)`
  - `0x0001BEF8: stb r11, 0x6D4F(r13)` (no caminho observado: `r11=0`)

**Impacto:** prova objetiva de que `svc 0x27` e `svc 0x3B` ajustam o estado global que o builder `0x459B0` exige.

---

### FATO 6) `svc 0x3B` tem tail-branch para endereço fora de segmento (`0xFE02BF28`)
#### 6.1) Trecho final observado no handler
- **EA:** `0x0001BF14..0x0001BF1C`
- **Assembly:**
  - `0x0001BF14: li r12, 0`
  - `0x0001BF18: stw r12, 0x7044(r13)`
  - `0x0001BF1C: b 0xFE02BF28`

#### 6.2) Bytes da instrução de branch
- **EA:** `0x0001BF1C`
- **Bytes:** `4A 01 00 0C`
- **Word:** `0x4A01000C`

#### 6.3) Segmentos carregados (base 0)
- `ROM`: `0x00000000..0x00200000`
- `ROM18`: `0x01854000..0x01856000`

**Impacto no objetivo:** com o IDB atual, o alvo `0xFE02BF28` está fora de qualquer segmento; **não dá** para provar estaticamente que `svc 0x3B` retorna ao caller (dispatcher/state machine).

---

### FATO 7) Tabela UDS em `0x000109A4` tem entries com top-byte/tag (ponteiro “tagged”)
Exemplos (raw u32 BE na tabela = `tag<<24 | low24`):
- `svc 0x29`: raw `0xB101C200` (low24 `0x01C200`)
- `svc 0x20`: raw `0xBC01C174` (low24 `0x01C174`)

**Impacto:** análises devem tratar ponteiros da tabela como **low24** (o top-byte pode ser tag/metadata).

---

### Resumo brutalmente honesto
- **Provado:** o TX é escrito por um builder (`0x459B0`) via ponteiro `r13+0x6C34` e ele é chamado por `mtlr/blrl` (`0x1C5F0`).
- **Provado:** `svc 0x27` e `svc 0x3B` setam `r13+0x6D40 = 2`, que é exatamente o guard do builder (`0x459C8`).
- **Travado:** `svc 0x3B` salta para `0xFE02BF28` (fora de segmento), então o retorno/encadeamento completo não é demonstrável sem ajustar o mapeamento no IDA.

### Próximo passo (ROI máximo)
1. **Criar segmento-espelho:** no IDA, File → Script file... → `scripts/ida_add_mirror_segment_fe000000.py`. Cria segmento `ROM_mirror_FE` em `0xFE000000..0xFE030000` (mesmos bytes do ROM).
2. **Re-analisar:** ir para `0xFE02BF28`, Edit → Code (C); decidir se o fluxo é epílogo comum ou dispatcher externo e documentar o resultado.

