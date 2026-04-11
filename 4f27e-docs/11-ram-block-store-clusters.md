## 11 — Clusters de stores no bloco `r13+0x1500..0x3BFF` (0x003FA400..0x003FCB00)

### Objetivo (fato)
Mapear **quem escreve** no bloco RAM do scheduler/IO por **clusters de stores** (proximidade de PC), sem cair em fanfic por XREF/ponteiro cru.

**Escopo do scan (PPC-only):**
- hits: **696**
- range de destino: `stw/sth/stb rX, disp(r13)` com `disp ∈ [0x1500..0x3BFF]`
- clustering: gap **0x80 bytes** entre PCs
- clusters: **127**

### Clusters que tocam offsets críticos (o que importa AGORA)

#### Cluster #24 — `0x39598..0x39744` (runtime: PWM queue + tick bookkeeping)
**Offsets tocados:** `+0x15A8`, `+0x15AC`, `+0x15B8`, `+0x15BC`, `+0x15C4`

**Padrão:** runtime (publish/clear + contador + housekeeping), não “init” do bloco.

**Evidência direta (PPC decode):**
- `tpu_pwm_queue_service_15A8 @ 0x39598`: **clear da fila**
  - `stw r12, 0x15A8(r13)` com `r12=0`
- `tpu_pwm_queue_build_and_schedule_task3 @ 0x39624 / 0x3968C`:
  - `stw r3, 0x15AC(r13)` (**publica ponteiro temp** retornado do allocator)
  - `stw r30, 0x15A8(r13)` (**publica ponteiro da fila**) antes de agendar task
- `isr_decrementer_tick_dispatch_0 @ 0x39710`:
  - `stw r3, 0x15C4(r13)` (state/tempo do tick)
  - `stw r7, 0x15B8(r13)` e `stw r8, 0x15BC(r13)` (bookkeeping de tempo)

**Impacto no bloco SDA:** confirma que `+0x15A8/+0x15AC` são “globals de runtime” usados como **ponteiros**, não campos estáticos.

---

#### Cluster #96 — `0x3C088` (init: alloc/zero do buffer `+0x15D4`)
**Offset tocado:** `+0x15D4`

**Padrão:** init (alloc + memset/zero)

**Evidência direta:**
- `0x3C084: bl loc_26218` (allocator-like)
- `0x3C088: stw r3, 0x15D4(r13)` (**publica ponteiro**)
- `0x3C08C..0x3C098`: chama `sub_2610C` com size `r31<<3` e `r5=0` (**zero-fill**)

**Impacto no bloco SDA:** `+0x15D4` nasce **dinâmico** (buffer runtime).

---

#### Cluster #95 — `0x3A7F8` (teardown: clear do root `+0x15D0`)
**Offset tocado:** `+0x15D0`

**Padrão:** teardown/desregistro (clear explícito)

**Evidência direta:**
- `0x3A7F4: li r12, 0`
- `0x3A7F8: stw r12, 0x15D0(r13)` (**zera root**)

**Impacto no bloco SDA:** confirma “por evidência” que existe **clear**, mas **não prova init** do root.

---

#### Cluster #75 — `0x23CBC` (SUSPEITO: `stb` em `+0x15D0`)
**Offset tocado:** `+0x15D0`

**Padrão:** *unknown* / provável armadilha (VLE vs PPC).

**Evidência direta (bytes):**
- word em `0x23CBC` decodifica como PPC: `stb r19, 0x15D0(r13)`

**Por que isso é perigoso:**
- em outros paths, `+0x15D0` é tratado como **ponteiro** (`lwz r12, 0x15D0(r13)` e depois `lwz r12, 4(r12)`).
- um `stb` real aqui **corromperia** o ponteiro do root (incompatível com o modelo).

**Conclusão operacional:** **não** use `0x23CBC` como “init” até validar execução (VLE/mixed decode) e/ou confirmar que esse bloco é realmente PPC.

---

#### Cluster #94 — `0x3911C` (SUSPEITO: `sth` em `+0x15AC`)
**Offset tocado:** `+0x15AC`

**Padrão:** *unknown* / provável armadilha (VLE vs PPC).

**Evidência direta (bytes):**
- `0x3911C: B14D15AC` → PPC D-form: `sth r10, 0x15AC(r13)`

**Por que isso é perigoso:**
- `tpu_pwm_queue_build_and_schedule_task3` trata `+0x15AC` como **ponteiro** (faz `stw r3, 0x15AC(r13)` e depois `lwz r3, 0x15AC(r13)`).
- um `sth` real aqui **corromperia** o ponteiro.

**Conclusão operacional:** tratar como **misdecode / VLE** até prova em contrário.

---

### Top 20 clusters (mapa do terreno)
Formato: `#idx start-end cnt uniq_off [críticos...]` + top offsets.

- `#00 04A958-04B10C cnt=69 uniq_off=69`
- `#01 043458-043844 cnt=68 uniq_off=37`
- `#02 040DC8-041170 cnt=36 uniq_off=23`
- `#03 024FD8-025234 cnt=35 uniq_off=16`
- `#04 031B60-031F14 cnt=24 uniq_off=15`
- `#05 04A398-04A5D4 cnt=21 uniq_off=12`
- `#06 049334-0494B4 cnt=19 uniq_off=13`
- `#07 047B20-047C98 cnt=18 uniq_off=7`
- `#08 048074-048194 cnt=18 uniq_off=6`
- `#09 045D80-045F10 cnt=14 uniq_off=4`
- `#10 0328B8-032A20 cnt=12 uniq_off=5`
- `#11 032DE4-032EF8 cnt=11 uniq_off=6`
- `#12 0476D0-047744 cnt=11 uniq_off=7`
- `#13 0482A8-048358 cnt=11 uniq_off=9`
- `#14 021364-021478 cnt=10 uniq_off=1`
- `#15 0256D0-0257B8 cnt=10 uniq_off=6`
- `#16 0332AC-033464 cnt=10 uniq_off=7`
- `#17 0469C8-046A10 cnt=10 uniq_off=9`
- `#18 036A4C-036B60 cnt=9 uniq_off=9`
- `#19 047530-047624 cnt=9 uniq_off=3`

### Notas rápidas (classificação) dos top-3 por volume
Isso é **só triagem**, pra separar “init/copy” de “runtime/estado”.

#### #00 `0x04A958..0x04B10C` (cnt=69 / uniq=69)
**Padrão observado:** **ingestão/decodificação de parâmetros** em SDA (muitos `stb/sth` em offsets únicos `0x1858..0x1A3x`), provavelmente vindo de helpers tipo `loc_37678/loc_38260`.

**O que é:** parece rotina de “ler/validar um bloco” e publicar flags/thresholds em `r13+...`.

**O que não é:** não parece `memset/memcpy` nem “builder do TaskTable”; é **estado/config**.

#### #01 `0x043458..0x043844` (cnt=68 / uniq=37)
**Padrão observado:** **contadores/debouncers** e flags em `0x1858..0x1878` (incrementa `lhz` e seta `stb`), com resets e “cap” (ex.: compara com 0xA/0xB).

**O que é:** lógica de runtime (provável diag / anti-bounce / supervisão).

#### #02 `0x040DC8..0x041170` (cnt=36 / uniq=23)
**Padrão observado:** toggles de flags e resets de acumuladores (ex.: `stb 0x189E`, `stw 0x2354`, `stw 0x2358`, manipula `0x188C/0x18A0` etc).

**O que é:** runtime/estado; ainda não tem cara de init do bloco completo.

### Próximo passo sugerido (sem overlap com “tagged pointers”)
Se o objetivo é “quem popula `0x003FA400..`”, o caminho limpo é:
- priorizar clusters grandes com **muitos offsets únicos** (ex.: `#00` e `#01`) e checar se são init/boot (memset/copy/pointer_setup),
- e cruzar com as tabelas de ranges em `09-io-dispatch-init.md` (range `0x003FA400..0x003FCB00`) para identificar o aplicador real (PPC vs VLE).


