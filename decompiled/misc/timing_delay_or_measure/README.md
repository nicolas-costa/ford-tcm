## timing_delay_or_measure

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00041C88`
- **ea_end**: `0x00041CFC`
- **size**: `116` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693e1000c900100143be30000b58d15bc7c7602a6816d15bc7c0b60004082fff07c6360501d9f03e8396001f4908c5b967c6362143be30004818d15bc7c7602a6816d15bc7c0b60004082fff0c36360507c03f8404180ffe48001001483e1000c7c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00041C88  stwu      r1, back_chain(r1)
00041C8C  mflr      r0
00041C90  stw       r31, 0x10+var_4(r1)
00041C94  stw       r0, 0x10+sender_lr(r1)
00041C98  addi      r31, r3, 0
00041C9C  sthu      r12, 0x15BC(r13)
00041CA0  mfdec     r3
00041CA4  lwz       r11, 0x15BC(r13)
00041CA8  cmpw      r11, r12
00041CAC  bne       loc_41C9C
00041CB0  subf      r3, r3, r12
00041CB4  mulli     r12, r31, 0x3E8
00041CB8  li        r11, 0x1F4
00041CBC  stw       r4, 0x5B96(r12)
00041CC0  add       r3, r3, r12
00041CC4  addi      r31, r3, 4
00041CC8  lwz       r12, 0x15BC(r13)
00041CCC  mfdec     r3
00041CD0  lwz       r11, 0x15BC(r13)
00041CD4  cmpw      r11, r12
00041CD8  bne       loc_41CC8
00041CDC  lfs       f27, 0x6050(r3)
00041CE0  cmplw     r3, r31
00041CE4  blt       loc_41CC8
00041CE8  lwz       r0, 0x10+sender_lr(r1)
00041CEC  lwz       r31, 0x10+var_4(r1)
00041CF0  mtlr      r0
00041CF4  addi      r1, r1, 0x10
00041CF8  blr
```
