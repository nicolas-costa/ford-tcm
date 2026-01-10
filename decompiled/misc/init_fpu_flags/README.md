## init_fpu_flags

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00017BBC`
- **ea_end**: `0x00017BE8`
- **size**: `44` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
4321fff87c0802a69001000c3880000438600000ff00010cff80410c8001000c770803a6382100084e800020
```

### Disasm (head, first 80 insns)

```text
00017BBC  bc        25, gt, loc_17BB4
00017BC0  mflr      r0
00017BC4  stw       r0, arg_C(r1)
00017BC8  li        r4, 4
00017BCC  li        r3, 0
00017BD0  mtfsfi    6, 0
00017BD4  mtfsfi    7, 4
00017BD8  lwz       r0, arg_C(r1)
00017BDC  andis.    r8, r24, 0x3A6
00017BE0  addi      r1, r1, 8
00017BE4  blr
```
