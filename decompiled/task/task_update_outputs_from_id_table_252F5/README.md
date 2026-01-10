## task_update_outputs_from_id_table_252F5

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00042584`
- **ea_end**: `0x00042640`
- **size**: `188` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693c1000893e1000c900100144bfffba5d9c000003bed17c4899f000c558c07bc2c0c00004182005057cc063e5586043e769f0002386600004bffff39b07f000038660000389f00004bfff829b07f000e4ec3043e4bfff9653d200002392952f557cc103a7c6960aea09f000e4bff99d56a00001c3d800002398c52f557cb103a7c6c58ae388000004bff99b93bff00148fde00012c1e00074180ff80800100147c0803a683c1000883e1000c3821001008800020
```

### Disasm (head, first 80 insns)

```text
00042584  stwu      r1, back_chain(r1)# Task: iterates a small fixed list of IO IDs from ROM table byte_252F5 (stride 4) and calls io_set_float_by_id_and_dispatch_15D0(id, r4=0, f4/f.. as value). Strong candidate for periodic solenoid/actuator output update path.
00042588  mflr      r0
0004258C  stw       r30, 0x10+var_8(r1)
00042590  stw       r31, 0x10+var_4(r1)
00042594  stw       r0, 0x10+sender_lr(r1)
00042598  bl        sub_4213C
0004259C  stfd      f14, sub_0
000425A0  addi      r31, r13, 0x17C4
000425A4  lbz       r12, 0xC(r31)
000425A8  rlwinm    r12, r12, 0,30,30
000425AC  cmpwi     r12, 0
000425B0  beq       loc_42600
000425B4  clrlwi    r12, r30, 24
000425B8  clrlwi    r6, r12, 16
000425BC  andis.    r31, r20, 2
000425C0  addi      r3, r6, 0
000425C4  bl        sub_424FC
000425C8  sth       r3, 0(r31)
000425CC  addi      r3, r6, 0
000425D0  addi      r4, r31, 0
000425D4  bl        loc_41DFC
000425D8  sth       r3, 0xE(r31)
000425FC  xori      r0, r16, 0x1C
00042600  lis       r12, (word_252F4+1)@ha# ROM table byte_252F5 used as ID list with 4-byte stride (lbzx r3, base, 4*idx). Parse table to extract candidate actuator IDs.
00042604  addi      r12, r12, (word_252F4+1)@l # 0x252F5
00042608  slwi      r11, r30, 2
0004260C  lbzx      r3, r12, r11
00042610  li        r4, 0
00042614  bl        io_set_float_by_id_and_dispatch_15D0
00042618  addi      r31, r31, 0x14
0004261C  lbzu      r30, 1(r30)
00042620  cmpwi     r30, 7
00042624  blt       loc_425A4
00042628  lwz       r0, 0x10+sender_lr(r1)
0004262C  mtlr      r0
00042630  lwz       r30, 0x10+var_8(r1)
00042634  lwz       r31, 0x10+var_4(r1)
00042638  addi      r1, r1, 0x10
0004263C  tdeqi     r0, 0x20 # ' '
```
