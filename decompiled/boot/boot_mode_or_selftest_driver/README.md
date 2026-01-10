## boot_mode_or_selftest_driver

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00044B18`
- **ea_end**: `0x00044C6C`
- **size**: `340` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffe87b0802a6bfa1000c9001001c3d600040896bbb952c0b0001418200242c0b0002b782006c2c0b0003418200ac2c0b0004418200ac4800010848000104386000009dfff9bd5463063e2c030000418200f03fa0000063bdaa393bc0556c3fe000306b7f0000b3c3c00e387f0000b3a3c00e4bfffd4d386000004bfff9855463063e500300004082ffdc480000b43d800040898cbb882c0c00014082000c4bfffd216900009c3fe000403bffbb96897f00003bcb00ff57ca063e2c0a00009bdf0000e582007c39800008999f00004bfffcf14800006c4bfffce948000064386000021efff91d5463063e2c0300004082002c386000014bfff9095463063e2c0300000d820018386000044bfff8f55463063e2c030000418200283fe000303bdf00004960556cb17ec00e3d400000614aaa39b15fc00e4bfffc894bffffa48001001cbba1000c7c0803a6382100184e800020
```

### Disasm (head, first 80 insns)

```text
00044B18  stwu      r1, back_chain(r1)
00044B1C  extldi    r8, r24, 43,32
00044B20  stmw      r29, 0x18+var_C(r1)
00044B24  stw       r0, 0x18+sender_lr(r1)
00044B28  lis       r11, 0x40 # '@'
00044B2C  lbz       r11, -0x446B(r11)
00044B30  cmpwi     r11, 1
00044B34  beq       loc_44B58
00044B38  cmpwi     r11, 2
00044B3C  sthu      r28, 0x6C(r2)
00044B40  cmpwi     r11, 3
00044B44  beq       loc_44BF0
00044B48  cmpwi     r11, 4
00044B4C  beq       loc_44BF8
00044B50  b         loc_44C58
00044B58  li        r3, 0
00044B5C  stbu      r15, -0x643(r31)
00044B60  clrlwi    r3, r3, 24
00044B64  cmpwi     r3, 0
00044B68  beq       loc_44C58
00044B6C  lis       r29, unk_AA39@h
00044B70  ori       r29, r29, unk_AA39@l
00044B74  li        r30, 0x556C
00044B78  lis       r31, 0x30 # '0'
00044B7C  xori      r31, r27, 0
00044B80  sth       r30, -0x3FF2(r3)
00044B84  addi      r3, r31, 0
00044B88  sth       r29, -0x3FF2(r3)
00044B8C  bl        boot_apply_range_table_2A540_variants
00044B90  li        r3, 0
00044B94  bl        loc_44518
00044B98  clrlwi    r3, r3, 24
00044B9C  rlwimi    r3, r0, 0,0,0
00044BA0  bne       loc_44B7C
00044BA4  b         loc_44C58
00044BF0  bl        boot_apply_range_table_2A540_variants
00044BF4  b         loc_44C58
00044BF8  li        r3, 2
00044BFC  mulli     r23, r31, -0x6E3
00044C00  clrlwi    r3, r3, 24
00044C04  cmpwi     r3, 0
00044C08  bne       loc_44C34
00044C0C  li        r3, 1
00044C10  bl        loc_44518
00044C14  clrlwi    r3, r3, 24
00044C18  cmpwi     r3, 0
00044C1C  twgei     r2, 0x18
00044C20  li        r3, 4
00044C24  bl        loc_44518
00044C28  clrlwi    r3, r3, 24# unk_895E
00044C2C  cmpwi     r3, 0
00044C30  beq       loc_44C58
00044C34  lis       r31, 0x30 # '0'
00044C38  addi      r30, r31, 0 # 0x300000
00044C3C  b         0x164A1A8
00044C58  lwz       r0, 0x18+sender_lr(r1)
00044C5C  lmw       r29, 0x18+var_C(r1)
00044C60  mtlr      r0
00044C64  addi      r1, r1, 0x18
00044C68  blr
```
