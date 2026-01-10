## tpu_clear_channel_mask_4020_4420

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x000343E8`
- **ea_end**: `0x00034444`
- **size**: `92` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
546c063e2c0c0010408000243ca0003038850000e9644020394000017d4a18307d4a50f8b1454020480000303ca000303885000008644420394000015469063e3d800000618cfff07d2962147d4a48307d4a50f8954544204e800020
```

### Disasm (head, first 80 insns)

```text
000343E8  clrlwi    r12, r3, 24
000343EC  cmpwi     r12, 0x10
000343F0  bge       loc_34414
000343F4  lis       r5, 0x30 # '0'
000343F8  addi      r4, r5, 0 # 0x300000
000343FC  ld        r11, 0x4020(r4)
00034400  li        r10, 1
00034404  slw       r10, r10, r3
00034408  not       r10, r10
0003440C  sth       r10, 0x4020(r5)
00034410  b         locret_34440
00034414  lis       r5, 0x30 # '0'
00034418  addi      r4, r5, 0 # 0x300000
0003441C  tdi       3, r4, 17440
00034420  li        r10, 1
00034424  clrlwi    r9, r3, 24
00034428  lis       r12, (loc_FFEE+2)@h
0003442C  ori       r12, r12, (loc_FFEE+2)@l # 0xFFF0
00034430  add       r9, r9, r12
00034434  slw       r10, r10, r9
00034438  not       r10, r10
0003443C  stwu      r10, 0x4420(r5)
00034440  blr
```
