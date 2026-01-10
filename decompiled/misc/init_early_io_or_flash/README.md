## init_early_io_or_flash

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00017BE8`
- **ea_end**: `0x00017CC4`
- **size**: `220` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693e1000c900100143fe00030c57fc288556ba7fe2c0b0000418200443860556c3fe00030b07fc00e3fe0000093ffaa393c800030b3e4c00e3c8000303d6003a9616b7f8f9164c0043c800030fa64c00e3c600030b3e3c00e480000683860556c3fe00030b07fc00e3fe000009effaa393c800030b3e4c00e3c8000303d6003a9616b7f8f9164c0043c800030ba64c00e3c600030b3e3c00e7c7602a63d80fffe618c23337fe362147c7602a6c903f8404181fff8898d70c6618c0004998d70c683e1000c800100147c0803a6892100104e800020
```

### Disasm (head, first 80 insns)

```text
00017BE8  stwu      r1, back_chain(r1)
00017BEC  mflr      r0
00017BF0  stw       r31, 0x10+var_4(r1)
00017BF4  stw       r0, 0x10+sender_lr(r1)
00017BF8  lis       r31, 0x30 # '0'
00017BFC  lfsu      f11, -0x3D78(r31)
00017C00  extrwi    r11, r11, 1,19
00017C04  cmpwi     r11, 0
00017C08  beq       loc_17C4C
00017C0C  li        r3, 0x556C
00017C10  lis       r31, 0x30 # '0'
00017C14  sth       r3, -0x3FF2(r31)
00017C18  lis       r31, 0
00017C1C  stw       r31, -0x55C7(r31)
00017C20  lis       r4, 0x30 # '0'
00017C24  sth       r31, -0x3FF2(r4)
00017C28  lis       r4, 0x30 # '0'
00017C2C  lis       r11, 0x3A9
00017C30  ori       r11, r11, 0x7F8F # 0x3A97F8F
00017C34  stw       r11, -0x3FFC(r4)
00017C38  lis       r4, 0x30 # '0'
00017C3C  stq       r19, -0x3FF4(r4)
00017C40  lis       r3, 0x30 # '0'
00017C44  sth       r31, -0x3FF2(r3)
00017C48  b         loc_17CB0
00017C4C  li        r3, 0x556C
00017C50  lis       r31, 0x30 # '0'
00017C54  sth       r3, -0x3FF2(r31)
00017C58  lis       r31, 0
00017C5C  stbu      r23, -0x55C7(r31)
00017C60  lis       r4, 0x30 # '0'
00017C64  sth       r31, -0x3FF2(r4)
00017C68  lis       r4, 0x30 # '0'
00017C6C  lis       r11, 0x3A9
00017C70  ori       r11, r11, 0x7F8F # 0x3A97F8F
00017C74  stw       r11, -0x3FFC(r4)
00017C78  lis       r4, 0x30 # '0'
00017C7C  lmw       r19, -0x3FF2(r4)
00017C80  lis       r3, 0x30 # '0'
00017C84  sth       r31, -0x3FF2(r3)
00017C88  mfdec     r3
00017C8C  lis       r12, -2
00017C90  ori       r12, r12, 0x2333 # 0xFFFE2333
00017C94  add       r31, r3, r12
00017C98  mfdec     r3
00017C9C  lfd       f8, -0x7C0(r3)
00017CA0  bgt       loc_17C98
00017CA4  lbz       r12, 0x70C6(r13)
00017CA8  ori       r12, r12, 4
00017CAC  stb       r12, 0x70C6(r13)
00017CB0  lwz       r31, 0x10+var_4(r1)
00017CB4  lwz       r0, 0x10+sender_lr(r1)
00017CB8  mtlr      r0
00017CBC  lbz       r9, 0x10+pre_back_chain(r1)
00017CC0  blr
```
