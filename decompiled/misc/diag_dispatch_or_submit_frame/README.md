## diag_dispatch_or_submit_frame

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0001C8BC`
- **ea_end**: `0x0001CAE8`
- **size**: `556` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
b521fff07c0802a693e1000c900100143be30000898d6d4e2c0c00004082003c3e800002998d6d4e386d6c3d906d6c30906d6c3439400101b14d6d3e386000005c6d6d4c986d6d4d3d800000618cfff8b18d6d444bffd191898d6d4e558c07bce90c0000418201a4898d6c00558ccffe2c0c000040820194898d6c10558cdffe480c00004082018439800000b18d6d46896d6c00556bdffe2c0b0000408200387e6d6d4239630001894d6d4d7c0b500041800014a18d6d44398c00017c0c1800dd80001439800001880d6c0051801f38980d6c0039800000880d6c0051802eb4620d6c00896d6c00556beffe2c0b0001408200104bffd13539800002998d6d4e61ed6c0c818d704c558c07bc2c0c00004182001039800000998d6c0d4800001c22800003818cfa0c7d8803a6386000004e800021986d6c0d898d6c0c5583043e09fff915a06d6d443880001438a0000a38c0000a4bffcff939600000b16d6d42d8400000880d6c0051401f38980d6c00388d6d4038a10008387f0000480002ad8263063e2c03000040820090818d704c558c07bc2c0c000041820020818d6c30278cffffa0cd6d40387f000038a000004bff8379480000283d800003818cfa3c928803a6816d6c30388bffffa0cd6d40387f000038a000004e800021818d6c305b8cffff998d6d503be00001880d6c0053e026f6980d6c00880d6c0153e03e30600d6c01480000143881000a38a10008387f00004800021583e1000c80010014290803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
0001C8BC  sthu      r9, back_chain(r1)
0001C8C0  mflr      r0
0001C8C4  stw       r31, arg_C(r1)
0001C8C8  stw       r0, arg_14(r1)
0001C8CC  addi      r31, r3, 0
0001C8D0  lbz       r12, 0x6D4E(r13)
0001C8D4  cmpwi     r12, 0
0001C8D8  bne       loc_1C914
0001C8DC  lis       r20, 2
0001C8E0  stb       r12, 0x6D4E(r13)
0001C8E4  addi      r3, r13, 0x6C3D
0001C8E8  stw       r3, 0x6C30(r13)
0001C8EC  stw       r3, 0x6C34(r13)
0001C8F0  li        r10, 0x101
0001C8F4  sth       r10, 0x6D3E(r13)
0001C8F8  li        r3, 0
0001C8FC  rlwnm     r13, r3, r13,21,6
0001C900  stb       r3, 0x6D4D(r13)
0001C904  lis       r12, (loc_FFF6+2)@h
0001C908  ori       r12, r12, (loc_FFF6+2)@l # 0xFFF8
0001C90C  sth       r12, 0x6D44(r13)
0001C910  bl        diag_update_mode_flags_6D4B_from_cfg
0001C914  lbz       r12, 0x6D4E(r13)
0001C918  rlwinm    r12, r12, 0,30,30
0001C91C  ld        r8, 0(r12)
0001C920  beq       loc_1CAC4
0001C924  lbz       r12, 0x6C00(r13)
0001C928  extrwi    r12, r12, 1,24
0001C92C  cmpwi     r12, 0
0001C930  bne       loc_1CAC4
0001C934  lbz       r12, 0x6C10(r13)
0001C938  extrwi    r12, r12, 1,26
0001C93C  b         unk_DC93C
0001CAC4  addi      r4, r1, 0x10+var_6
0001CAC8  addi      r5, r1, 0x10+var_8
0001CACC  addi      r3, r31, 0
0001CAD0  bl        sub_1CCE4
0001CAD4  lwz       r31, 0x10+var_4(r1)
0001CAD8  lwz       r0, 0x10+sender_lr(r1)
0001CADC  cmplwi    cr2, r8, 0x3A6
0001CAE0  addi      r1, r1, 0x10
0001CAE4  blr
```
