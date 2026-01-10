## boot_init_stage1_apply_dword_10B40

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00017D20`
- **ea_end**: `0x00017EDC`
- **size**: `444` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693c1000893e1000c900100143bc300002c1e0000bc8200343c60000138630b4083e300043d400001394a796c7d4803a6812300083f3f485038890001387f000038a000004e8000217c1113a63d807fff618cffff038d073c3d600040396b9000916d07303d400040394a9600914d073439200000f42d07383d800001398c205c7d8803a63c600001386311f44e800021394000026a4d704c3d2000023929d2b07d2803a63c60000138630e804e8000213d600001256b67a07d6803a63c600001386305204e8000213d20000139296d387d2803a64b6000013863050c4e8000213d600001396b70807d6803a63860ffff38800005178000212c1e0000408200243d800002398c99787d8803a64e8000213d600002526b9ae87d6803a64e8000213d800001398c3c147d8803a63c60000138630f1c9b8000213d400001394a4a4c7d4803a63c600001386375784e8000213d8000013c8c4c447d8803a64e8000213d600001396b18207d6803a63c600001386311c4db8000213d20000239298c147d2803a64e8000213d800002398c97a07d8803a6cc60000138630f144e80002183c1000883e1000c800100147c0803a638210010
```

### Disasm (head, first 80 insns)

```text
00017D20  stwu      r1, back_chain(r1)
00017D24  mflr      r0
00017D28  stw       r30, 0x10+var_8(r1)
00017D2C  stw       r31, 0x10+var_4(r1)
00017D30  stw       r0, 0x10+sender_lr(r1)
00017D34  addi      r30, r3, 0
00017D38  cmpwi     r30, 0
00017D3C  stmw      r4, 0x34(r2)
00017D40  lis       r3, dword_10B40@ha
00017D44  addi      r3, r3, dword_10B40@l
00017D48  lwz       r31, (dword_10B44 - 0x10B40)(r3)
00017D4C  lis       r10, memset_like_loc_1796C@ha
00017D50  addi      r10, r10, memset_like_loc_1796C@l
00017D54  mtlr      r10
00017D58  lwz       r9, (dword_10B48 - 0x10B40)(r3)
00017D5C  addis     r25, r31, 0x4850
00017D60  addi      r4, r9, 1
00017D64  addi      r3, r31, 0
00017D68  li        r5, 0
00017D6C  blrl
00017D70  mtspr     eid, r0 # External interrupt disable
00017D74  lis       r12, 0x7FFF
00017D78  ori       r12, r12, 0xFFFF # 0x7FFFFFFF
00017E90  mtlr      r11
00017E94  lis       r3, word_111C4@ha
00017E98  addi      r3, r3, word_111C4@l
00017E9C  stfd      f28, loc_20+1
00017EA0  lis       r9, word_18C14@ha
00017EA4  addi      r9, r9, word_18C14@l
00017EA8  mtlr      r9
00017EAC  blrl
00017EB0  lis       r12, word_197A0@ha
00017EB4  addi      r12, r12, word_197A0@l
00017EB8  mtlr      r12
00017EBC  lfdu      f3, sub_0+1
00017EC0  addi      r3, r3, 0xF14
00017EC4  blrl
00017EC8  lwz       r30, 0x10+var_8(r1)
00017ECC  lwz       r31, 0x10+var_4(r1)
00017ED0  lwz       r0, 0x10+sender_lr(r1)
00017ED4  mtlr      r0
00017ED8  addi      r1, r1, 0x10
```
