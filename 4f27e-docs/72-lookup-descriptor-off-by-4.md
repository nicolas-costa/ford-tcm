# 72 — Descritores de lookup: o call passa o ponteiro, o count está 4 bytes antes

**Data:** 2026-10-01
**Método:** bytes IDA + disasm de `0xBBDC8` / `0xBBE48`. Corrige o alvo de patch do doc 24.

## FATO — contrato do 1D em `0xBBDC8`

O `blrl` cai em `0xBBDC8` (`lis 0xC` + `addi` imm `0xBDC8` → `0xBBDC8`), **não** em `0xBBDC4`.

```
BBDC8  lwz  r4, 4(r3)          ; data
BBDCC  lbz  r11, 0(r3)         ; count
BBDD0  clrlslwi r11, r11, 24, 3 ; count * 8
BBDD8  addi r3, r11, -8        ; último par = data + count*8 - 8
BBDDC  lfs  f12, 0(r4)         ; breakpoint do 1º par
BBDE8  lfs  f5,  4(r4)         ; valor se input <= 1º bp
```

Par = 8 bytes `(breakpoint, valor)`. A instrução em `0xBBDC4` (`frsp f5, f1`) **não executa** nesse call: o imediato resolve `0xBBDC8`. O compare usa `f5`, e `shift_slot_eval` (`0x872B4`) não escreve `f5` nenhuma vez.

## FATO — o objeto na ROM está 4 bytes atrás do endereço passado

Três calls do canal `3FBC14` (doc 71), mesmo desenho:

| endereço passado                 | byte 0 (o que `lbz` lê) | word −4       | word 0 (ponteiro) | word +4       |
| -------------------------------- | ----------------------- | ------------- | ----------------- | ------------- |
| `0x184218` normal                | `00`                    | `08 00 00 00` | `00 18 41 D8`     | `00 00 00 00` |
| `0x181908` coast                 | `00`                    | `08 00 00 00` | `00 18 18 C8`     | `00 00 00 00` |
| `0x1809D0` (eixo, `*(0x187518)`) | `00`                    | `06 00 00 00` | `00 18 09 A0`     | `00 00 00 00` |

O 2D `0xBBE48` faz `lwz r3, 4(r31)` / `lwz r3, 8(r31)` / `lbz` em `0` e `1` / `lwz r28, 0xC(r31)`.
Com `r3=0x187514` (o `addi 0x7514` de `0x87C20`):

| off  | word          | papel que o código lê                   |
| ---- | ------------- | --------------------------------------- |
| +0   | `00 18 2E C8` | `nx=0`, `ny=0x18`                       |
| +4   | `00 18 09 D0` | eixo `f1`                               |
| +8   | `00 18 74 B4` | eixo `f2`                               |
| +0xC | `3C 9F BE 77` | base do `lfsx` — **não é ponteiro ROM** |

Quatro bytes antes, em `0x187510`: `06 04 00 00` (`nx=6`, `ny=4`) seguido dos três ponteiros `0x182EC8`, `0x1809D0`, `0x1874B4`. Esse header **não é o `r3` do call**.

## FATO — os 22.0 não são a tabela do coast

Doc 24 trata `0x182ED0` como "7 × 22.0 km/h". Os bytes a partir de `0x182ECC` são pares soltos `-256, 22` repetidos. O 1D cujo ponteiro está em `0x182EC8` aponta para **`0x182E88`**, não para `0x182ED0`. Pares em `0x182E88` (até o footer `08 00 00 00` em `0x182EC4`):

| bp  | valor |
| --- | ----- |
| 0   | -30   |
| 0   | -10   |
| 1   | 6     |
| 2   | 20    |
| 3   | 40    |
| 4   | 80    |
| 5   | 65534 |

O `22.0` em `0x182ED0` é a 2ª palavra de um objeto **seguinte**. Patchar `0x182ED0` não edita o grid que `0x87C20` passa em `r3`.

## HIPÓTESE — curvas se o count fosse o byte em `addr−4` e o data fosse `*addr`

Não é o que `lbz 0(r3)` faz. Serve só para mostrar que a cal tem curvas monotônicas nesse layout.

`0x1841D8` (normal), 7 pares antes do footer:

| bp   | valor  |
| ---- | ------ |
| 1.50 | 400    |
| 1.50 | 600    |
| 1.89 | 700    |
| 2.06 | 800    |
| 2.23 | 1000   |
| 2.57 | 1275   |
| 3.11 | 327675 |

`0x1818C8` (coast):

| bp   | valor  |
| ---- | ------ |
| 2.09 | 600    |
| 2.09 | 700    |
| 2.22 | 800    |
| 2.42 | 1000   |
| 2.68 | 1100   |
| 2.68 | 1275   |
| 2.68 | 327675 |

## DESCONHECIDO

- Por que o call entra em `0xBBDC8` (count no byte alto do ponteiro = 0, data em `+4` = 0) e mesmo assim a imagem traz count e pares 4 bytes antes. `lfs` com data `NULL` lê o endereço 0, que nesta imagem é ROM mapeada — não prova que o valor devolvido seja o par da cal.
- `f5` (entrada do compare) não é escrito no caller. `0xBBDC4` faria `f5=f1`, mas não é o alvo do `blrl`.

## Resumo Executivo BRUTAL

- PROVADO: `0x87C20` passa `r3=0x187514`. O interpolador lê `nx`/`ny` aí (`0` e `0x18`) e a base do grid em `+0xC` (`0x3C9FBE77`).
- PROVADO: o header `nx=6, ny=4` está em `0x187510`, 4 bytes antes. O 1D tem o mesmo deslocamento (count em `addr−4`, ponteiro em `addr`).
- PROVADO: `0x182ED0 = 22.0` não é o payload do descritor passado. O doc 24 aponta o objeto errado.
- NÃO PROVADO: o valor numérico que o coast grava em `3FBC14`.
- PRÓXIMO ROI: fechado no doc 73 — não há `addi -4`. O call `0x9DC08` continua sem casar com o Y=10 da estrada.
