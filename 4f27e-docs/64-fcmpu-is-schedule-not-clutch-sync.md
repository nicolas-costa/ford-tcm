# 64 — `fcmpu 3FC1F0` é zona de marcha, não sincronismo de embreagem

Escopo: pergunta de sincronismo; arranque `3FBBCC`→IO. Sem dump. Sem PHF.

## Resposta directa (FATO)

O `fcmpu` @ `83954` (e clones `83998`/`839E4`/`83A28`/`83A74`/`83AB8`) **escolhe o GT** `{1,2,4,8}` e faz `stb 3FC239` @ `83AD0`. O mesmo conjunto de destinos que o ramo **inteiro** `837F4`–`838D8` (`cmpw` velocidade-byte vs slots `3FBC24`–`29`).

Não existe neste bloco: flag “synced”, `stb` de solenóide, `bl` para `io_set_float` / `15D0` / `15A8`.

## Dois caminhos, um resultado (FATO)

`0x837C4` `blrl` (entry interna do evaluator, dispatcher `9E984`):

```
837C8  lbz  3FC404          ; -0x3BFC
837D0  bne  loc_838DC       ; caminho FLOAT
837D8  lbz  3FD728          ; -0x28D8
837E0  bne  loc_838DC
; senão: cmpw byte 3FD493 (-0x2B6D) vs S24–S29
```

Caminho float: `3FC1F0` vs `(u8 slot)→float * f1`, com

```
f1 = 3FBDB8 * 3FDFB8 / 862.5 / 1023.0     ; 838E4–8390C → stfs 3FBBF0
3FC1F0 = 3FC1F8 * r(106)/r(105)           ; 84FCC 850F0–850FC
```

`li r3,8/4/2/1` + `b 83ACC` idêntico nos dois ramos. É **schedule em domínio float**, não um detector de overlap.

## Eixo `3FC1F8` (FATO)

Dispatcher `9E8D4` `lhz 3FBBCC`:

- se `3FBBCC==0` **ou** `3FC3AC≠0`: `stfs 3FC23C → 3FC1F8` @ `9E8FC` (também copia `3FBF98→3FBFB8`, `3FBBD4→3FC0F0`).
- se `3FBBCC≠0` **e** `3FC3AC==0`: **não** actualiza `3FC1F8` (`beq 9E930`).

`3FC23C` writer SIMM: `81270` `stfs` de `lfs 3FD9AC` (`-0x2654`) em `sub_81238` (caller `cal_mod_pipeline_mirror_9EBCC` @ `9EC04`).

`3FD9AC`: `stfs f2, 0(r31)` @ `B1D24`/`B1D30` com `f2 = lfs 3FDA6C` (`-0x2594`). Filtro/derivada para `3FD9A0`.

`3FDFB8`: único `stfs` SIMM `0xBD1B8` em `sub_BC88C` (após `blrl` com `f1,f2,f3`; cals `18A52C=4.22`, `18A530=4.18`).

**DESCONHECIDO:** se `3FDA6C` e o sensor de `BC88C` são o mesmo eixo (VSS) ou ISS vs OSS. Sem dois eixos **provados**, não há prova de sincronismo de embreagem.

## `3FBBCC` → TPU neste passo (FATO)

`bl` directo no range `0x10000`–`0xC0000`:

| dest                                    | callers                                   |
| --------------------------------------- | ----------------------------------------- |
| `io_set_float @ 0x3BFCC`                | `25244`, init `421DC`, update `425F8/614` |
| `io_write @ 0x3C16C`                    | `25244` só                                |
| `solenoid_outputs_update_7ch @ 0x42584` | `4A650`                                   |
| `tpu_pwm_queue_service_15A8 @ 0x394C8`  | `4A274`                                   |

Nenhum destes está em `0x83xxx`–`0x86xxx`. Scan SIMM `C106` / `C239` / `BBCC` em `0x20000`–`0x60000`: **zero hits**. O GR/GT/mode **não** alimentam o path 7ch por SIMM `0x40` (alinha doc 52: shift solenoids fora de `3FA6C4`).

`lhz 3FBBCC` @ `803E0` ainda só arma flags (`3FC42E` etc.), não IO.

## HIPÓTESE

Float path = mesma lei de slots quando `3FC404`/`3FD728` forçam domínio contínuo (histérese). Congelar `3FC1F8` com `3FBBCC≠0` evita que o eixo de schedule mude a meio da troca — anti-glitch, não medição de slip.

## Resumo executivo

- Sincronismo de embreagem: **não provado**. O `fcmpu` escreve `3FC239`.
- `3FC1F8` é cópia (por vezes congelada) de `3FC23C` ← `3FD9AC` ← `3FDA6C`.
- Zero ponte SIMM GR/GT/`3FBBCC` → `15D0`/`15A8`/`3BFCC`.

**Próximo passo (ROI):** writers TPU/`sth` `0x304xxx` ou GPIO que leiam GR via **ponteiro** (não SIMM `C106`); produtores `15A8` fora do 7ch.
