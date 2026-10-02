# 73 — O 1D não tem `addi r3,-4`. O call do modifier não fecha com o `lwz`

**Data:** 2026-10-01
**Método:** bytes + disasm. Fecha o ROI do doc 72.

## FATO — não existe o ajuste

Em `0xBB000`–`0xBD000` não há `addi r3,r3,-4` (`0x3863FFFC`) nem `addi r4,r4,-4`.
O `blrl` do modifier entra em `0xBBDC8`. A instrução anterior `0xBBDC4` (`frsp f5,f1`, word `0xFCA00818`) não é o alvo.

```
BBDC8  80830004  lwz   r4, 4(r3)     ; data = *(r3+4)
BBDCC  89630000  lbz   r11, 0(r3)    ; count = byte 0
BBDE0  FC856000  fcmpu cr1, f5, f12  ; compara f5, não f1
BBDE8  C0A40004  lfs   f5, 4(r4)     ; se input <= 1º bp, devolve o 2º float
BBE3C  FC202890  fmr   f1, f5        ; retorno em f1; f5 continua com o resultado
```

Par confirmado pelo interpolador: breakpoint em `+0`, valor em `+4` (`0xBBE14`–`0xBBE24`).

## FATO — o call que a estrada provou devolver ~10

`0x9DC00`–`0x9DC0C` (doc 50: S25 = T5 + esse retorno, 12+10=22 com GATE):

```
9DBFC  lfs  f1, 0(r28)       ; eixo 3FD464 vai para f1
9DC00  lis  r3, 0x18
9DC04  addi r3, r3, 0x5708   ; r3 = 0x185708
9DC08  blrl                  ; → 0xBBDC8
9DC0C  fmr  f25, f1          ; f25 é o que depois soma em S25
```

Bytes em `0x185708`:

| addr       | word          | leitura                                              |
| ---------- | ------------- | ---------------------------------------------------- |
| `0x185704` | `08 00 00 00` | count 8, 4 bytes antes do `r3`                       |
| `0x185708` | `00 18 56 C8` | ponteiro; `lbz 0(r3)` lê `0x00`                      |
| `0x18570C` | `C2 C8 00 00` | **-100.0**. É o que `lwz r4,4(r3)` usa como endereço |

`0x18570C` é o começo da **segunda cópia** da curva, inline: `(-100, 10), (-9, 10), (-8, 10), (-7, 10), (-3, 10), (-3, 5), (0, 5)`.
Essa sequência, se o 1D a lesse como endereço `r3+4` (sem dereferenciar), devolve **10** para eixo negativo e **5** para eixo ≥ 0. É o número da estrada.

A cópia anterior, ponteiro `0x1856C8`, começa no **10.0**, não no −100. `lbz`/`lwz` como estão não selecionam nem uma nem outra: `r4` sai `0xC2C80000`.

## FATO — `f1` do caller não é o `f5` do compare

Entre `0x9DB9C` e `0x9DC08` há quatro `blrl` para o mesmo 1D. Cada um termina com `f5` = resultado. O seguinte faz `lfs f1, …` e **não** escreve `f5`. O compare em `0xBBDE0` usa o `f5` que sobrou do lookup anterior (`r3=0x180A70` em `0x9DBE4`), não o `f1` carregado em `0x9DBFC`.

## DESCONHECIDO

Como a imagem em execução devolve ~10 com `lwz r4,4(r3)` e `fcmpu f5`. As duas leituras (ponteiro `0xC2C80000`, entrada = resultado do lookup anterior) não são a curva `(-100 → 10)`. Não há `addi` escondido neste range.

## Resumo Executivo BRUTAL

- PROVADO: o ROI do doc 72 fechou pelo lado negativo. Não há `addi r3/r4, -4` no 1D.
- PROVADO: a curva que produz Y=10/5 está inline em `0x18570C` (cópia 2) e, deslocada, em `0x1856C4` (cópia 1).
- PROVADO: o opcode em `0xBBDC8` dereferencia `*(r3+4)` e compara `f5`. No call `0x9DC08` isso não é essa curva nem o eixo recém-carregado em `f1`.
- NÃO PROVADO: o mecanismo que mesmo assim põe ~10 em `f25` na estrada.
- PRÓXIMO ROI: um log com `3FD464`, `f`-equivalente (S25, T5) e o byte em `0x18570C` na imagem **gravada** (stock vs v6.2). Se v6.2 zerou `0x18570C` e S25 caiu a 12, a rotina lê essa word como float inline, e o `lwz` do IDA não é o que a CPU executa.
