# 62 — `3FC3Bx` são flags de transição, não comando de solenóide

Escopo: `0x84DE8` / `0x84FCC` / `0x8518C` / `0x85348` e consumidores SIMM. Sem dump. Sem PHF.

## Dispatcher (FATO)

Após `gear_update_GR_3FC106`:

`0x9EA08` `blrl` `0x84DE8` → `0x9EA18` `0x84FCC` → `0x9EA28` `0x8518C` → `0x9EA38` `0x85348` → `0x9EA48` `0x8546C` → `0x9EA58` `0x85B60` (entry no meio de `0x8546C`–`0x85D20`) → `0x9EA68` `0x85D24` → `0x9EA78` `0x85FA4` (entry no meio de `0x85D24`).

IDA: `sub_84FCC` `0x84FCC`–`0x85188`; `sub_8518C` `0x8518C`–`0x85348`; `sub_85348` `0x85348`–`0x85468`. Nomes: `gear_trans_flags_3FC3Bx`, `gear_ratio_from_105_106`, `gear_trans_gate_3FC388`.

`bl 0x25F58` @ `85D2C` **não** é TPU: `stfd f30/f31` + `stw r0,4(r11)` + `blr` (frame helper).

## `0x84DE8` — mapa 105→106 → bytes (FATO)

Pré-condição: `lbz 3FC36C` (`-0x3C94`) @ `84E0C`; se 0, salta o preenchimento (`84F28`). Se ≠0, zera o cluster e depois:

Ponteiros @ `84DF0`–`84E48`:

| reg       | dest     |
| --------- | -------- |
| `r10`     | `3FC3B9` |
| `r4`      | `3FC3BC` |
| `r5`      | `3FC3BF` |
| `r31`     | `3FC3BB` |
| `r6`      | `3FC3BE` |
| `r7`      | `3FC3C1` |
| `r8`/`r3` | `3FC3CA` |

`r9` = `3FC105` @ `84E64`. `GR` = `3FC106` (`lbz -0x3EFA`).

| condição               | store                     | dest     |
| ---------------------- | ------------------------- | -------- |
| `105==1` e `GR!=1`     | `stb 1, 0(r10)` @ `84E84` | `3FC3B9` |
| (join `84E90`) `GR>=4` | `stb 1, 0(r4)` @ `84EA4`  | `3FC3BC` |
| `105!=8` e `GR==8`     | `stb 1, 0(r5)` @ `84EC4`  | `3FC3BF` |
| `105!=1` e `GR==1`     | `stb 1, 0(r31)` @ `84EE4` | `3FC3BB` |
| `105>=4` e `GR<=2`     | `stb 1, 0(r6)` @ `84F04`  | `3FC3BE` |
| `105==8` e `GR!=8`     | `stb 1, 0(r7)` @ `84F24`  | `3FC3C1` |

OR:

```
84F58  stb 1, 0(r8)          ; 3FC3CA
84F90  stb r11, -0x3C3C      ; 3FC3C4
84FB8  stb r11, -0x3C3A      ; 3FC3C6
```

`3FC3CA` sobe se `*r10` ou `3FC3BC` ou `3FC3BF` ≠0. `3FC3C4` se `*r31` ou `3FC3BE` ou `3FC3C1` ≠0. `3FC3C6` se `*r3` (`3FC3CA`) ou `3FC3C4` ≠0.

Nenhum `lis 0x30` / fila `15A8` / trampolim `15D0` nesta função.

## `0x84FCC` — razões float, não actuador (FATO)

`lbz 3FC105` @ `84FD0` escolhe `f3`; `lbz 3FC106` @ `85040` escolhe `f4` (se `3FC3AE` `-0x3C52` ≠1).

| cmp   | cal      | float BE              |
| ----- | -------- | --------------------- |
| `==1` | `185F80` | `1.4978` (`3FBFB7E9`) |
| `==2` | `185F84` | `1.0`                 |
| `==4` | `185F88` | `0.7259` (`3F39D495`) |
| else  | `185F8C` | `1.5`                 |

Mesma tabela que `gear_commit_3FC104` @ `83F54`–`83F94`.

Stores: `stfs 3FBE38` (`-0x41C8` @ `8501C`), `stfs 3FBDB8` (`-0x4248` @ `8508C`), `stfs 3FC1F0` (`-0x3E10` @ `850FC`/`8512C`), `stfs 3FBFB4` (`-0x404C`), `stfs 3FBFC4` (`-0x403C` @ `85140`), `stfs 3FC2AC` (`-0x3D54` @ `8517C`). Só float.

## Consumidores do cluster (FATO)

SIMM `lbz`/`stb` `C3B9`–`C3CA` **não** aparecem em writers MMIO `30xxxx`. Exemplos:

| EA                          | função                              | acção                                                                         |
| --------------------------- | ----------------------------------- | ----------------------------------------------------------------------------- |
| `851A0`                     | `sub_8518C`                         | lê `3FC3CA`; `stb 3FC3F5` @ `851F4`                                           |
| `853A8`/`853F0`/`85400`     | `0x85348`                           | lê `3FC3C6`/`3FC3BC`/`3FC3BF`; `stb 3FC388` @ `8545C`                         |
| `85D38`/`86068`/`86154`     | `sub_85D24`                         | lê `3FC3C6`/`3FC3CA`/`3FC3BC`; `stb 3FC115` @ `86088`; `stb 3FC387` @ `861C4` |
| `89868`                     | `cal_mod_mode_cond_clear_3FC27C`    | lê `3FC3B9` (doc 33)                                                          |
| `8C22C` / `8D178` / `8E54C` | helpers 1D                          | se flag=0, `stfs 0` em `3FC26C`/`3FC284`                                      |
| `93DB4`                     | `shift_threshold_compute_with_mode` | lê `3FC3B9`                                                                   |
| `9EABC`                     | dispatcher                          | lê `3FC3CA` → `3FC3F3`                                                        |

`3FC388` xrefs código: `stb` só `8545C`; `lbz` `80310`, `86004`.

## HIPÓTESE

Cada `3FC3B*` é um **tipo de troca** (origem `105` vs destino `106`), usado para armar 1D / limpar floats / gates (`3FC388`), não SSA/SSB/SSC.

Bitmask `{1,2,4,8}` nestes cmp **não** está mapeado aqui para 1ª–4ª física; os floats `1.498/1.0/0.726` coincidem com razões 2ª/3ª/4ª 4F27E, mas `else→1.5` **não** é a 1ª (`~2.82`). Sem evidência extra, o mapeamento bitmask↔marcha fica DESCONHECIDO.

## DESCONHECIDO

- Quem leva `3FC115` / `3FC387` / `3FC388` a PWM/TPU.
- Corpo útil de `0x86414` / `0x86654` / `0x869F4` (lê GR; `86414` `stb 3FC3AB` @ `86648`).
- Writer `sub_95B74` (`stb` `3FC3BC/BE/BF/C1` @ `95E5C`–`95E78`) vs overwrite do fan-out.

## Resumo executivo

- Fan-out `84DE8` grava flags booleanas de **transição** `3FC3B9`…`3FC3C6`, não duty/solenóide.
- `84FCC` só converte `105`/`106` em floats de razão (`185F80`–`8C`) → `3FBE38`/`3FBDB8`/`3FC1F0`.
- Consumidores imediatos continuam em flags/1D.

**Próximo passo (ROI):** `0x86414` / `0x869F4` e `lbz 3FC115`/`3FC387`/`3FC388` até IO `15D0`/`15A8`.
