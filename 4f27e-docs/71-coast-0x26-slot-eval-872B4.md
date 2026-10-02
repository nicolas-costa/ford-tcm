# 71 — Tipo `0x26` (coast): o que muda em `shift_slot_eval` `0x872B4`

**Data:** 2026-10-01
**Método:** IDA MCP (disasm). Fecha a opção E.
Cross-ref: [63](63-ratios-scale-3FBBCC-shift-type.md) (quem grava `0x26`),
[69](69-calmod-handlers-per-shift-type.md) (cal_mod no-op),
[70](70-can-load-3FBBD4-pressure-modifiers.md) (carga CAN).

## FATO — origem do tipo
Doc 63: encoder `0x869F4` faz `3FC3AA != 0 → 3FBBCC = 0x26`. No jumptable cal_mod
`0x9C300` o índice `0x26` é **no-op** (`0x9CFD8`). O efeito do coast está **fora** do cal_mod.

## FATO — único switch de tabela no slot-eval (`0x87BEC`–`0x87C84`)
Entra neste bloco só se `*(u8)3FC3FE != 0`, `3FC0D4 < flt_185E24` e `3FC353 == 0`
(`0x87BB4`/`0x87BD0`/`0x87BE0`). Senão grava `3FBC14 = 0.25` e segue outro fator.

| | coast `3FBBCC==0x26` (`0x87BF4` tomado) | normal (`bne 0x87C58`) |
|--|------------------------------------------|------------------------|
| 2D | `blrl 0xBBE48`, `r3=0x187514`, `f1=3FBD6C`, `f2=3FBBD4`; `stfs f1, 3FC15C` (`0x87C28`) | não roda |
| 1D | `blrl` trampoline, `r3=0x181908`, `f1=3FC08C` (`0x87C44`) | `r3=0x184218`, `f1=3FC08C` (`0x87C70`) |
| escala | `f31 = f1 * *(3FC15C)` (`0x87C4C`) | `f31 = f1 * *(3FC148)` (`0x87C7C`) |
| store | `stfs f31, 3FBC14` (`0x87CD4`); em seguida `3FBC18 = 0.25` | idem |

⇒ Coast **não substitui** a 1D normal pela 2D. Troca as **duas** peças:
base 1D `0x181908` (não `0x184218`) **e** o multiplicador (resultado 2D em `3FC15C`,
eixos peso `3FBD6C` × carga CAN `3FBBD4`, em vez do escalar fixo `3FC148`).
O comentário no IDA em `0x87BE8` ("0x26 usa 0x187514, senão 0x184218") está **incompleto**:
`0x184218` e `0x181908` são 1Ds distintas; `0x187514` só produz o fator `3FC15C`.

## FATO — bytes no endereço passado
`0x187514`: `00 18 2E C8  00 18 09 D0  00 18 74 B4`, e `+0xC = 3C 9F BE 77` (não é ponteiro ROM).
A sequência `-256/22` em `0x182ECC` **não** é o grid indexado por este call — ver doc 72.

## FATO — outros consumidores de `3FBBCC==0x26` (cmpwi a ≤0x40 do `lhz -0x4434`)
- `shift_delay_gate_3FC3AB @0x86470`: se tipo `==0x21` **ou** `==0x26` (e dois flags
  `3FC39B`/`3FC3AF` zerados não desviam antes), `stfs` da constante `dbl_1882A4` (**0.25**)
  em `0(r3)` (`0x86480`). Mesmo ramo do tipo `0x21`.
- `sub_949D4`: em `0x94A50` (e de novo `0x94B60/94B80/94C4C/94C6C/94D04/94D18`) tipo
  `0x21` **ou** `0x26` cai no ramo que faz `stb 1`, `sth` do tipo em `0x3FD41C` e
  1D `r3=0x185AD8` (`0x94A58`–`0x94A84`).

## HIPÓTESE
- O par `3FBC14`/`3FBC18` é o 4º canal de pressão do slot-eval (os três anteriores
  são `3FBBFC/3FBC00`, `3FBC04/3FBC08`, `3FBC0C/3FBC10` no mesmo função). O coast
  só remonta **este** canal.

## DESCONHECIDO
- Rótulo de marcha do tipo `0x21` (anda junto com `0x26` nos dois consumidores laterais,
  mas **não** no switch de tabela `0x87BF0`).
- Qual célula o `blrl 0xBBE48` realmente lê: o descritor passado está 4 bytes depois de um header `06 04` coerente (doc 72). Sem resolver esse deslocamento, o número de marcha/velocidade do coast continua aberto.
- Objeto exato de `r3` em `shift_delay_gate_3FC3AB`.

## Resumo Executivo BRUTAL
- PROVADO: `0x26` é setado por `3FC3AA` (doc 63) e é **no-op no cal_mod**; o efeito está
  em `0x872B4`.
- PROVADO: no slot-eval o coast grava `3FBC14 = lookup1D(0x181908, 3FC08C) * lookup2D(0x187514, 3FBD6C, 3FBBD4)`;
  o normal grava `3FBC14 = lookup1D(0x184218, 3FC08C) * 3FC148`.
- PROVADO: a carga CAN `3FBBD4` entra **só** no fator 2D do coast — elo direto coast×rede (doc 70).
- PROVADO: `0x26` também força o ramo `0.25` do delay-gate `0x86470` e o ramo `0x21|0x26` de `sub_949D4`.
- PRÓXIMO ROI: achar quem chama o 1D entrando em `0xBBDC4` (com `addi r3,-4`) ou provar que
  `lbz 0(r3)` em `0xBBDCC` não é o count que a cal usa. Sem isso o grid do coast não fecha (doc 72).
