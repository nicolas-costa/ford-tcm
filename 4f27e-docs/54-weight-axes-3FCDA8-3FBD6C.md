# 54 — Eixos de peso `0x3FCDA8` / `0x3FBD6C` e efeito nos slots

**Data:** 2026-09-25  
**Status:** estático AA; dump vivo **diferido** (depois de esgotar IDA)  
**Dependência:** docs 24, 36–43, 50; dispatcher `0x9D860`

---

## Resumo Executivo

1. **FATO:** `3FCDA8` e `3FBD6C` são eixos de **peso** (`wB0=3FBCB0`, `w80=3FBD80`), não o eixo dos mapas 184xxx (`3FC1BC`).
2. **FATO:** com G5=`*(0x3FC384)==0` (Group5), os mapas T4/T6/T7 continuam a base; os pesos só escalam parcelas 182/180.
3. **FATO:** na AA, quase todas as 182 do Group5 têm Y=0. Exceção: `0x182AE0` Y=**−7** @ X≈99.6. As 180 têm Y=**−1** (e −2/−3 pontuais em `0x180A38`).
4. **DESCONHECIDO (vivo):** valor de `3FCDA8` na pista — só isso decide se `wB0` está ~1 ou 0 (LUT `0x182A88`, X=22…31.875). **Não dumpar agora.**

---

## Afirmação (mecanismo)

| Camada                    | Os eixos de peso mudam?                                       |
| ------------------------- | ------------------------------------------------------------- |
| Qual grupo (G5 vs Group4) | **Não.** `lbz 0x3FC384` @ `0x9E438`.                          |
| Qual mapa 184xxx          | **Não.** Lookup T4/T6/T7 não lê `3FCDA8`/`3FBD6C`.            |
| GATE `0x3FD48C`           | **Não** como fonte. Armado em `0x9DA10` por outras condições. |
| Número no slot (G5=0)     | **Sim, aditivo pequeno**, escalado por `w`.                   |

Group5 S26 (`0x9E5E4`–`0x9E66C`):

```
S26 = T6(184C28) + 182D20·w8C + 182AE0·wB0 + 180AD8·w80
```

Y medido (ptr + n do footer):

| Tabela                         | Papel           | Y na AA                          |
| ------------------------------ | --------------- | -------------------------------- |
| `182D20` / `182C70` / `1829A0` | × `w8C` / `wB0` | **0** em todos os X úteis        |
| `182AE0`                       | × `wB0`         | **0** até X=93; **−7** @ 99.60   |
| `180AD8`                       | × `w80`         | **−1** (X=0…99.6)                |
| `180A38` (S24)                 | × `w80`         | **−1**; **−3** @ 59; **−2** @ 71 |

`w80` LUT `0x180B68`: Y ∈ {0.5, 1.0} no domínio 10–22.  
`wB0` LUT `0x182A88`: Y ≈ 0.99 @ X=22–24; 0.49 @ 26–28; **0** @ 31.875.

**Consequência numérica (G5=0, AA):**

- `w8C` · 182 = **0** sempre.
- `w80` · 180 ≈ **−0.5 a −3** km/h TCM (típico **−1**).
- `wB0` · `182AE0` = **0** fora de WOT; **até −7** se eixo `3FC1BC`≈100 **e** `wB0≠0`.

Não há troca de estratégia de marcha. Há correção aditiva. O único termo que sai da casa de 1 km/h é o **−7 @ WOT**, e só se `3FCDA8` deixar `wB0` ligado.

Path `0x9DA64` (GATE): `182D78` Y=0; `182B38` Y=0 exceto **−4** @ 99.61; `180B10` Y=**−1**. Mesma classe: aditivo, não mapa.

---

## Origem dos eixos (estático)

| Eixo       | Writer           | Fonte                                                                                                                                |
| ---------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `0x3FCDA8` | `stfs` `0xBD7B4` | byte `0x3FA80A` ← `stb 0x190A(r13)` @ `0x4ADDC`, canal HW **`0x4E0`**, `lbz 0xB(r1)` (byte 3). Skip se `0x3FA7E7≠0` ou byte==`0xFF`. |
| `0x3FBD6C` | `stfs` `0x81940` | cópia do IIR `0x3FBF44`; **congela** se `*(0x3FBBCC)≠0`. Entrada `0x3FDA60` = `9·(*(0x3FD738)−5)` se `*(0x3FD8FC)≠0`.                |

Kill `wB0`→0.25 se `3FC346≠0` **ou** `3FD456≠0` (`0x990E0`).  
`3FD456`=`1` sse `*(0x3FA802)`∈{1,2} (3 bits de canal **`0x440`**, `0x4AAF8`).

---

## `3FC346` ← LUT `0x182F20` vs `3FBD6C` (FATO)

`sub_99150` @ `0x992C4`–`0x992F8`, chamado por interior `0x99154` desde o cluster `0x994EC`. Orchestrator `0x993BC` é `blrl` a partir do dispatcher `0x9EDE8`.

```
992B8  r3 = 0x3FBF40          ; eixo do lookup
992C4  addi r3, … 0x2F20      ; footer 0x182F20
992C8  blrl
992CC  lfs  f12, 0(r31)       ; r31 = 0x3FBD6C
992D0  fcmpu  f1, f12
992D4  ble → 3FC346=0
992DC  lbz  0x3FC3B4
992E4  bne → 3FC346=0
992E8  li r31, 1
992F8  stb → 0x3FC346
```

LUT `0x182F20` (n=10, ptr `0x182ED0`): Y=**22** em X≤20; Y=**30** @ 32; Y=**32** @ 254.

`0x3FBF40` recebe cópia de `3FBD6C` @ `0x99218` quando o acumulador `0x3FBF8C` > **400.0** (`0x18617C`) e `*(0x3FC3A6)==0`.

`0x3FC3B4` sobe a 1 @ `0x992AC` após outro acumulador (`0x3FDD54` + 4762.5) > `0x185D50` (40.0). Enquanto 1, `3FC346` fica 0.

---

## Writer `0x3FD738` (FATO)

Único `stfs` em `0xAB8A4` (`sub_AB700`), `r30=0x3FD738`.

Com `*(0x3FD8FC)==0`: copia `*(0x3FD73C)`.  
Senão: slew de `3FD738` em direção a `3FD73C` (passo `lfs 0x1891C4`, bytes `0A 50 00 00` — **não** interpretar como 0.75 sem prova).

`3FD73C` (`stfs -0x28C4` no mesmo fn): cópia de `0x3FDA54` ou `0x3FD730`, ou `f1` derivado de `0x3FE0F8` (`BD850`, byte `0x3FA80C` = CAN `0x4E0[0]`).

`3FD8FC`: único store `stb 0(r28)` @ `0xAB90C` (mesmo fn).

**DESCONHECIDO:** caller de `AB700` / `B3674`. Scan `bl` / `lis+addi` / dword `0x000AB700` no ROM = 0 hits.

---

## QADC no ramo `3FDA50` (FATO)

`sub_B3674` @ `0xB3690`: `lhz 0x3FA7CC` (`r13+0x18CC`).

Writer: `0x41120` `li r3, 1` / `bl qadc_read_result_by_logical_ch` / `sth r3, 0x18CC(r13)` @ `0x41128`.

`3FDA50 = (u16 − 0.004887) × 1.8` (`0x189B48` / `0x189B4C`).

Path `lwz 0x1896F0; cmpwi 1` @ `0xB36C8`: ROM `0x1896F0 = 0x43870000` (**270.0** float) ≠ 1 → **não** corre `stfs 3FDA60` @ `0xB36F8` nem `stfs 3FDA54` @ `0xB371C` nesta calibração.

**DESCONHECIDO:** ANx do lógico 1 (tabela RAM `r13+0x155C`, 3 B/entrada).

---

## Dump vivo — diferido

**Quando:** depois de esgotar a estática deste bloco.  
**Não** é bloqueio da conclusão de mecanismo.

| EA                      | Porquê                                            |
| ----------------------- | ------------------------------------------------- |
| `0x3FA80A`              | raw CAN `0x4E0[3]`                                |
| `0x3FCDA8`              | X da LUT `182A88` (liga/desliga `wB0` e o −7 WOT) |
| `0x3FBCB0`              | `wB0` já interpolado                              |
| `0x3FBD6C` / `0x3FBD80` | eixo / `w80`                                      |
| `0x3FC384`              | confirma G5=0                                     |
| `0x3FC1BC`              | para saber se o −7 WOT está no domínio            |
| `0x3FC346` / `0x3FD456` | kill dos lookups de peso                          |
| `0x3FA7CC`              | QADC lógico 1 (bruto)                             |
| `0x3FD738` / `0x3FD8FC` | follower / enable do IIR `3FDA60`                 |
| `0x3FE0F8`              | CAN `0x4E0[0]` já escalado                        |

---

## IDA

| EA        | Nome / papel                                            |
| --------- | ------------------------------------------------------- |
| `0xBD400` | `veh_signal_to_3FDF68_block` (incl. `3FCDA8`, `3FE0F8`) |
| `0x4A90C` | `veh_pkt_fill_from_hw_channels_4A90C`                   |
| `0x41108` | QADC ch 6→`18CE`; ch 1→`3FA7CC`                         |
| `0x990E0` | `stfs` → `3FBCB0`                                       |
| `0x99150` | `182F20` vs `3FBD6C` → `3FC346`                         |
| `0x99348` | `stfs` → `3FBD80`                                       |
| `0x993B8` | orchestrator pesos; entry usada `0x993BC`               |
| `0x81798` | IIR → `3FBD6C`                                          |
| `0xAB700` | slew `3FD738`; writer `3FD8FC`                          |
| `0xB3674` | QADC ch1 → `3FDA50`                                     |

---

## Resumo Executivo BRUTAL

- **Provado:** pesos não escolhem mapa/grupo; na AA só somam ~−1 (180) e −7 @ WOT se `wB0≠0` (`182AE0`).
- **Provado:** `3FCDA8` ← `0x4E0[3]`; `3FBD6C` ← IIR `3FBF44`; `3FC346` ← `182F20(*3FBF40) > 3FBD6C`.
- **Provado:** `3FD738` ← `AB8A4`; `3FA7CC` ← QADC lógico **1**.
- **Diferido:** dump `3FCDA8` (+ QADC/`3FD738` na mesma lista).
- **Próximo estático:** writers de `0x3FC34C` (doc 55: liga S28=`184F28` vs `0xFF`). Caller `AB700` = parede (0 xref).
