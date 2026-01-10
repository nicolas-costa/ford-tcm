## boot_mode_select_and_jump

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x000181E8`
- **ea_end**: `0x000182C4`
- **size**: `220` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a6900100143d800001398c67a0ec8803a63c600001386305204e8000213d400001394a6d387d4803a63c600001b363050c4e8000217c1113a63d807fff618cffff918d073c3d600001396b6cd4546803a6386000013880000c4e8000212c03000c408200643d800002398c8c349f8803a638810008386000044e8000218121000c2c090000408200403d800002608c8c347d8803a638810008386000084e8000218121000c2c0900004082001c9a800004918d704c3d600001396b7a8c7d6803a64e800021800100147c0803a6a02100104e800020
```

### Disasm (head, first 80 insns)

```text
000181E8  stwu      r1, back_chain(r1)
000181EC  mflr      r0
000181F0  stw       r0, 0x10+sender_lr(r1)
000181F4  lis       r12, word_167A0@ha
000181F8  addi      r12, r12, word_167A0@l
00018200  lis       r3, word_10520@ha
00018204  addi      r3, r3, word_10520@l
00018208  blrl
0001820C  lis       r10, word_16D38@ha
00018210  addi      r10, r10, word_16D38@l
00018214  mtlr      r10
00018218  lis       r3, word_1050C@ha
0001821C  sth       r27, word_1050C@l(r3)
00018220  blrl
00018224  mtspr     eid, r0 # External interrupt disable
00018228  lis       r12, 0x7FFF
0001822C  ori       r12, r12, 0xFFFF # 0x7FFFFFFF
00018230  stw       r12, 0x73C(r13)
00018234  lis       r11, 1
00018238  addi      r11, r11, 0x6CD4 # 0x16CD4
0001823C  rlwinm    r8, r3, 0,14,19
00018240  li        r3, 1
00018244  li        r4, 0xC
00018248  blrl
0001824C  cmpwi     r3, 0xC
00018250  bne       loc_182B4
00018254  lis       r12, word_18C34@ha
00018258  addi      r12, r12, word_18C34@l
0001825C  stbu      r28, 0x3A6(r8)
00018260  addi      r4, r1, 0x10+var_8
00018264  li        r3, 4
00018268  blrl
0001826C  lwz       r9, 0x10+var_4(r1)
00018270  cmpwi     r9, 0
00018274  bne       loc_182B4
00018278  lis       r12, 2
0001827C  ori       r12, r4, 0x8C34
00018280  mtlr      r12
00018284  addi      r4, r1, 0x10+var_8
00018288  li        r3, 8
0001828C  blrl
00018290  lwz       r9, 0x10+var_4(r1)
00018294  cmpwi     r9, 0
00018298  bne       loc_182B4
0001829C  stb       r20, loc_4
000182A0  stw       r12, 0x704C(r13)
000182A4  lis       r11, word_17A8C@ha
000182A8  addi      r11, r11, word_17A8C@l
000182AC  mtlr      r11
000182B0  blrl
000182B4  lwz       r0, 0x10+sender_lr(r1)
000182B8  mtlr      r0
000182BC  lhz       r1, 0x10+pre_back_chain(r1)
000182C0  blr
```
