# 53 — Writer do setpoint EPC localizado: `func @0x000B2944`

Data: 2026-09-07. Análise estática pura, sem carro.
Imagem de referência: `firmwares/5U75-14C337-AA.from_phf.bin` (2 MiB).

---

## 0. FATO — a amostra "oficial" está furada

`samples/SILVEROAK/5U75-14C337-AA.bin` retorna `FF` nas regiões de
código e calibração:

```
samples/SILVEROAK/5U75-14C337-AA.bin   @0x252F4=ffffffff  @0x18A2A8=ffffffff...
firmwares/5U75-14C337-AA.from_phf.bin  @0x252F4=0d030001  @0x18A2A8=00000000...000a001e0014
```

O banco do IDA bate com o segundo. Toda análise de bytes deve usar
`from_phf.bin` (ou `samples/SILVEROAK/*.rebuilt.aligned.bin`), nunca
`samples/SILVEROAK/5U75-14C337-AA.bin`.

---

## 1. FATO — a cadeia que produz `C8 = 9400`

`solenoid_next_pending_channel_find @0x42398` grava `idx +4` em `0x42434`
(`sth r9, 4(r7)`). Para `idx0` o ordinal é `1`, e as tabelas dão:

| tabela | addr | valor[ord=1] |
|---|---|---|
| period | `0x18A2A8` | `0` |
| clamp_lo | `0x18A270` | `1100` |

Lógica em `0x42404`–`0x42434`:

- `period(0) > valor` → nunca (valor ≥ 0)
- `clamp_lo(1100) < valor` → `+4 = 11000` (teto)
- senão → `+4 = valor * 10`

**`C8 = 9400` ⟹ `valor = 940`**, e o teto seria `11000`. O máximo de campo
observado (~9550) fica abaixo do teto. Consistente.

O `valor` vem de `0x41190`, que lê `r13+0x18B8` = **`0x3FA7B8`**.

---

## 2. FATO — quem escreve `0x3FA7B8`

Varredura na imagem inteira por acesso a `r13+0x18B8..0x18C4`:

```
7 leituras  (0x41198..0x411E4, lhz r3, 0x18Bx(r13))
0 escritas
0 stores indexados com base r13
```

Isso confirma o doc 31 e explica por que buscas anteriores falharam: **o
writer usa endereçamento absoluto**, não `r13`.

Varredura por deslocamento absoluto (`0xA7B8`, base `lis 0x40`):

```
000B2CAC   sth r12, -0x5848(r9)     ; r9 = 0x400000 -> 0x3FA7B8
```

**Store único em toda a imagem.** Função contendo:
`0x000B2944`–`0x000B2CC0`, 224 instruções, prólogo
`stwu r1,-0x30(r1)` / `stmw r29,0x24(r1)`.

---

## 3. FATO — estrutura da função `0x000B2944`

Guarda de entrada em `0x0B2954`: lê `0x1896F0`; se `0`, pula direto para
o epílogo (nada é calculado nem escrito).

Máquina de estados de 3 estados, seletor em `0x3FDA08` (byte):

| estado | ramo | ação |
|---|---|---|
| 0 | `0x0B29A4` | testa bit1 de `0x3FA795`; ramo A carrega constantes fixas, ramo B interpola tabela |
| 1 | `0x0B2A48` | decrementa `0x3FDA04` pelo parâmetro `f1`; enquanto acima do limiar, segura pressão na constante `0x1899E4` |
| 2 | `0x0B2AF8` | testa bit1 de `0x3FA795`, limpa flags e volta a estado 0 |
| else | `0x0B2B5C` | caminho default, interpola tabela |

Células RAM tocadas:

| addr | tipo | papel |
|---|---|---|
| `0x3FD9EC` | u32 | flags; low byte limpo e re-OR com `0x80` / `0x88` |
| `0x3FD9F4` | float | **pressão pedida** (variável principal) |
| `0x3FD9F0`, `0x3FD9F8` | float | cópias da pressão pedida |
| `0x3FD9FC` | float | realimentação escalada |
| `0x3FDA04` | float | temporizador/rampa do estado 1 |
| `0x3FDA08` | u8 | estado |
| `0x3FA7A8` | u16 | **entrada**: telemetria sense/10 do idx0 (`r13+0x18A8`) |
| `0x3FA7B8` | u16 | **saída**: comando EPC (`r13+0x18B8`) |

Interpolador chamado via `mtlr/blrl` em `0x0BBE48`, com
`r3 = 0x1899B8` (descritor de tabela), `f1`/`f2` = entradas.

---

## 4. FATO — cauda da função (`0x0B2C0C`–`0x0B2CAC`)

```
f1  = *0x3FD9F4
if (cal[0x1899E4] > f1) f1 = cal[0x1899E4]      ; clamp inferior = 1.0
else if (f1 > cal[0x1899E8]) f1 = cal[0x1899E8] ; clamp superior = 1000.0
*0x3FD9F4 = *0x3FD9F0 = *0x3FD9F8 = f1

; conversao int->double de *0x3FA7A8 via magic 0x43300000
f12 = lfd([0x43300000, sense])
f12 = f12 - cal[0x1899F0]
f2  = cal[0x1899EC]
*0x3FD9FC = frsp(f12) / f2

f13 = f1 * f2
*0x3FA7B8 = (int)fctiwz(f13)                     ; <== COMANDO EPC
```

Constantes (idênticas em `from_phf`, `v6.2`, `v6.3`, `rebuilt.aligned`,
e também em `5M5P-14C337-BL/CA` — não é corrupção de imagem):

| addr | u32 | float |
|---|---|---|
| `0x1899E4` | `3F800000` | `1.0` |
| `0x1899E8` | `447A0000` | `1000.0` |
| `0x1899EC` | `59800000` | `4.5036e15` (= 2^52) |
| `0x1899F0` | `3CC49BA6` | `0.024` |

---

## 5. DESCONHECIDO — o operando do `fsub` não fecha

O idiom `stw 0x43300000 / stw sense / lfd / fsub` exige subtrair **2^52**.
2^52 está em `0x1899EC`. Mas os bytes em `0x0B2C78` carregam de `0x1899F0`:

```
000B2C78  c16a99f0  lfs f11, -0x6610(r10)   ; r10=0x190000 -> 0x1899F0 = 0.024
000B2C84  c04c99ec  lfs f2,  -0x6614(r12)   ; r12=0x190000 -> 0x1899EC = 2^52
```

Tomando os bytes literalmente, `f2 = 2^52` e portanto
`*0x3FA7B8 = (int)(f1 * 2^52)` saturaria em `0xFFFF` — o que **contradiz o
valor 940 medido em campo**. Logo há erro na minha decodificação ou no
mapeamento arquivo→endereço de carga do pool de constantes, e **não** nos
bytes (verificados em 8 imagens).

Consequência: **`0x1899EC` e `0x1899F0` não estão confirmados como
MIN/MAX/SCALE calibráveis.** Os clamps `1.0` / `1000.0` em
`0x1899E4`/`0x1899E8` também dependem dessa resolução.

**Não altere essas constantes até fechar este ponto.**

---

## 6. Como resolver — leitura em runtime

O logger já foi estendido (`scripts/tcm_pressure_logger.py`):

```
ADDR_EPC_REQ   = 0x3FD9F4   # pressao pedida (float)
ADDR_EPC_FB    = 0x3FD9FC   # realimentacao escalada (float)
ADDR_EPC_SENSE = 0x3FA7A8   # sense/10 de entrada
ADDR_EPC_STATE = 0x3FDA08   # estado
```

e `--shift` agora inclui `C4` e `CMD`:

```
python3 scripts/tcm_pressure_logger.py --shift
# colunas: C4_sense_3FA6C4  C8_target_3FA6C8  D0_duty_3FA6D2  CMD18B8_3FA7B8
```

Verificação decisiva, com motor ligado e parado:

1. `CMD` deve ler ~940 e `C8` ~9400 (fator 10 exato).
2. Ler `0x3FD9F4` como float — se cair entre `1.0` e `1000.0`, os clamps
   estão confirmados e o fator `940 / valor` é o SCALE real.
3. Ler `0x3FD9FC` — se for constante `1.0`, a decodificação literal está
   certa e o caminho de realimentação é morto.

---

## Resumo executivo

- **Provado:** o writer do setpoint EPC é `sth` em `0x000B2CAC`, dentro de
  `func @0x000B2944`, via endereço absoluto — store único na imagem.
- **Provado:** `C8 = valor * 10` com `valor` lido de `0x3FA7B8`, e
  `C8 = 9400 ⟹ valor = 940`, com teto `11000` de `clamp_lo[1] = 1100`.
- **Provado:** `samples/SILVEROAK/5U75-14C337-AA.bin` está em branco nas
  regiões relevantes e invalidou buscas locais anteriores.
- **Não provado:** os valores de MIN/MAX/SCALE. O `fsub` carrega uma
  constante incompatível com o idiom de conversão, e a leitura literal
  produz saturação em `0xFFFF`, contradizendo os 940 medidos.

**Próximo passo de maior ROI:** ligar o motor parado e ler `0x3FD9F4` e
`0x3FD9FC` como float. Isso decide entre "minha decodificação está errada"
e "o pool de constantes está deslocado", e entrega o SCALE real — que é o
número necessário para qualquer calibração de pressão.
