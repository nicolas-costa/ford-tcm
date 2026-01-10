## init_immr_and_bootflags

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00017B78`
- **ea_end**: `0x00017BBC`
- **size**: `68` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff03c0802a69001001439800000998d70c67c7e9aa690610008896100092c0b0000a2820010898d70c6618c0002998d70c6800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00017B78  stwu      r1, back_chain(r1)
00017B7C  addis     r0, r8, 0x2A6
00017B80  stw       r0, 0x10+sender_lr(r1)
00017B84  li        r12, 0
00017B88  stb       r12, 0x70C6(r13)
00017B8C  mfspr     r3, immr # Internal Memory Mapping Register
00017B90  stw       r3, 0x10+var_8(r1)
00017B94  lbz       r11, 0x10+var_8+1(r1)
00017B98  cmpwi     r11, 0
00017B9C  lhz       r20, 0x10(r2)
00017BA0  lbz       r12, 0x70C6(r13)
00017BA4  ori       r12, r12, 2
00017BA8  stb       r12, 0x70C6(r13)
00017BAC  lwz       r0, 0x10+sender_lr(r1)
00017BB0  mtlr      r0
00017BB4  addi      r1, r1, 0x10
00017BB8  blr
```
