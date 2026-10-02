# 63 — Relações: escala de velocidade; `3FBBCC` = ID de troca

Escopo: porquê `185F80`–`8C` no pipeline; `0x86414` / `0x869F4`. Sem dump. Sem PHF.

## Relações não operam válvulas (FATO)

`gear_ratio_from_105_106` @ `850EC`–`850FC`:

```
850EC  lfs   f2, -0x3E08        ; 3FC1F8
850F0  fdivs f3, f4, f3         ; f3 = ratio(106) / ratio(105)
850F4  fmuls f11, f2, f3
850FC  stfs  f11, -0x3E10       ; 3FC1F0 = 3FC1F8 * (r_to / r_from)
```

`f4`/`f3` vêm de `185F80/84/88/8C` = `{1.4978, 1.0, 0.7259, 1.5}` conforme `105`/`106` ∈ `{1,2,4,else}`.

O evaluator **compara** esse `3FC1F0` com um eixo de velocidade, não escreve IO:

```
838E4  lfs   f13, -0x4248       ; 3FBDB8 = ratio(GR) gravado no mesmo 84FCC
838E8  lfs   f12, -0x2048       ; 3FDFB8
838F0  fmuls f13, f13, f12
83900  fdivs f13, f13, f11      ; f11 = flt_185FD8 = 862.5
8390C  fdivs f1,  f13, f12      ; f12 = flt_1882EC = 1023.0
83910  stfs  f1,  -0x4410       ; 3FBBF0
83948  lfs   f13, -0x3E10       ; 3FC1F0
83950  fmuls f12, f1, f12
83954  fcmpu cr1, f13, f12      ; gate de zona (repete 8398C/839D8/83A1C/83A68/83AAC)
```

`stfs 3FDFB8` no código varrido: `0xBD1B8` (`sub_BC88C`). Escritor único SIMM `DFB8` `stfs` nesse range.

Único `stfs` runtime de `3FC1F0` fora deste bloco: os dois de `84FCC`. `lfs 3FC1F0` no evaluator, `shift_helper_1d_maps_8546C`, `sub_861E0`, cal_mod workers, `sub_8C1C0`/`8D10C` (doc 62).

**Interpretação objetiva:** `r_to/r_from` reescala um float de eixo (`3FC1F8`) para o domínio da marcha de destino. O `fcmpu` decide zona/histerese. Não há `stb`/`15D0`/`15A8` nesta conta.

## `0x86414` — gate de atraso `3FC3AB` (FATO)

Com `3FC36C≠0`: `cmpw GR, 105` escolhe cal:

| ramo          | EA cal         | float                 |
| ------------- | -------------- | --------------------- |
| GR==105       | `1865CC`       | 0.128                 |
| GR>105        | `1865E0`       | 0.200                 |
| senão + flags | `1865D8/DC/D0` | 0.025 / 0.300 / 0.500 |

`stfs` → `3FBF90` (`r4` @ `86418`). Depois:

```
86630  fcmpu  3FBF90, 0.25     ; dbl_1882A4
86638  li r4, 1  /  86640 li r4, 0
86648  stb r4, -0x3C55         ; 3FC3AB
```

Lido no prólogo de `gear_update_GR_3FC106` @ `84784` e de `0x869F4` @ `86A5C`. Sem MMIO.

## `0x869F4` — **único** `sth` para `3FBBCC` (FATO)

Scan `0x8000`–`0xC0000`: um `sth` SIMM `BBCC` = `0x86BB0`. Doc 32 listava writer **DESCONHECIDO**.

```
86BB0  sth r5, -0x4434         ; 3FBBCC
```

Se `3FC3A9` (`-0x3C57`) ≠0 → `r5=0x21`. Se `3FC3AA` (`-0x3C56`) ≠0 → `r5=0x26` (coast, doc 24). Se `3FC3AB==0` → `r5=0` (não-troca).

Senão, encoder `(105, GR)` → ID:

| 105 | GR  | ID  | EA `li r5` |
| --- | --- | --- | ---------- |
| 1   | 2   | 1   | `86AD0`    |
| 1   | 4   | 2   | `86AE0`    |
| 1   | 8   | 3   | `86AF0`    |
| 2   | 4   | 4   | `86B08`    |
| 2   | 8   | 5   | `86B18`    |
| 4   | 8   | 6   | `86B30`    |
| 8   | 4   | 7   | `86B48`    |
| 8   | 2   | 8   | `86B58`    |
| 8   | 1   | 9   | `86B68`    |
| 4   | 2   | 0xA | `86B80`    |
| 4   | 1   | 0xB | `86B90`    |
| 2   | 1   | 0xC | `86BA8`    |

Extras: `0xC` @ `86AB0`, `0x32` @ `86AB8` por flags `3FC331`/`3FC332`/`3FC36C`. Combo inválida: skip `sth` (`86BB4`).

`lhz 3FBBCC`: 55 sítios (dispatcher 1D, evaluator, cal_mod `0x9C300` jumptable 0..0x32, slots `FF`, etc.).

IDA: `shift_delay_gate_3FC3AB`, `shift_type_id_to_3FBBCC`.

## HIPÓTESE

`3FBBCC` é o **índice de tipo de troca** que o resto do firmware já trata como mode (doc 24/32). As relações só alinham rpm/velocidade ao par from/to. O hardware de solenóide, se existir neste domínio, está **a jusante** dos consumidores de `3FBBCC` / slots `3FBC24`, não nas `stfs` de razão.

`{1.498, 1.0, 0.726}` coincidem com razões 2ª/3ª/4ª 4F27E; `else→1.5` ≠ 1ª (~2.82). O encoder usa bitmask `{1,2,4,8}` como eixos do ID — **não** prova sozinho 1=1ª.

## DESCONHECIDO

- Identidade física de `3FC1F8` / `3FDFB8` (eixo rpm vs VSS).
- Caminho `3FBBCC` → padrão SSA/SSB/SSC / TPU.
- Unidade dos 0.128–0.600 em `1865xx` (tempo vs outro).

## Resumo executivo

- Relações: `3FC1F0 = 3FC1F8 * r(106)/r(105)`; evaluator `fcmpu` contra `3FBDB8 * 3FDFB8 / 862.5 / 1023`.
- `0x869F4` é o writer de `3FBBCC` (fechou o buraco do doc 32).
- `0x86414` só arma `3FC3AB` a partir de `3FBF90`.

**Próximo passo (ROI):** de `3FBBCC` / slots `3FBC24` até writer de IO (`15D0`/`15A8` / doc 05), não mais floats de razão.
