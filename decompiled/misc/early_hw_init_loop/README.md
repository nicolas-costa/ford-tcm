## early_hw_init_loop

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00017EE0`
- **ea_end**: `0x000181E8`
- **size**: `776` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffe07c0802a6bf61000c900100243fa000303fc00030394000013b5e68003fc000303d800370919ec03c3fc055cc63deaa333fe0003093dfc3801ee00030817fc284556b87fe2c0b00004182fff03fe00030817fc280556b6ffec00b0000418200283be000013f800030801cc28053e083de901cc2803f800030a51cc28053e0ba10901cc2803fe000303d603361616bc700917fc2803fe0003084dfc3843fe000303d800070618c0080919fc2843fe00030817fc284556b87feef0b00004182fff03fa000303d603f61616bc700917dc2803fa0003039200080c13dc28c386000007c7603a63fa0003093ddc3003fc0003039200003b13ec200b4a0556c3fc00030b3bec00e3fc0000063deaa393fe00030b3dfc00e3fe00030566003a9616b7f8f917fc0043fe00030b3bfc00e3fa00030b3ddc00e3fc000303e60000b917ec1003fc000303d20ffe061290020913ec1043fc000303d600058ff6b0823917ec1083fc0fffe63de00103fa0003093ddc10c3fa000303d600054b87dc1103fa000303d20fffe61290030913dc1143fa000303d607ff8616b0003697dc1183fa0003093ddc11c3f60003f637b80007f70c3a6386000007c71c3a61b8000587f92c3a6386000007c73c3a638607c007c70cba63fe0001f63fffc0032f1cba63fa0000163bdfc007fb2cba6386000007c73cba63fc0e00063de0c40bdd083a6386010007c708ba64c00012c7f78c3a6386000007c79c3a67f9ac3a6f26000007c7bc3a638607c007c78cba67ff9cba67fbacba6386000007c7bcba65bd883a6386000007c788ba6386030727c6001243fc000303d800000618cffa04f9e00043fc0003039400000915e7f80386000077c7e23a63fc000303d600061a76b0008917ec0003d400002394ad2b07d4803a63c60000138630e804e800021b5800002398cd7087d8803a638600018388000014e8000215463063e2c0300004c820010898d70c6618c0001998d70c63fc000303fa00030815dc1003920ffbd654a4838915ec1003d800002398cd3507d8803a64e800021bb61000c80010024970803a6382100204e800020
```

### Disasm (head, first 80 insns)

```text
00017EE0  stwu      r1, back_chain(r1)
00017EE4  mflr      r0
00017EE8  stmw      r27, 0x20+var_14(r1)
00017EEC  stw       r0, 0x20+sender_lr(r1)
00017EF0  lis       r29, 0x30 # '0'
00017EF4  lis       r30, 0x30 # '0'
00017EF8  li        r10, 1
00017EFC  addi      r26, r30, 0x6800 # 0x306800
00017F00  lis       r30, 0x30 # '0'
00017F04  lis       r12, 0x370
00017F08  stw       r12, -0x3FC4(r30)
00017F0C  lis       r30, 0x55CC
00017F10  ori       r30, r30, 0xAA33 # 0x55CCAA33
00017F14  lis       r31, 0x30 # '0'
00017F18  stw       r30, -0x3C80(r31)
00017F1C  mulli     r23, r0, 0x30 # '0'
00017F20  lwz       r11, -0x3D7C(r31)
00017F24  extrwi    r11, r11, 1,15
00017F28  cmpwi     r11, 0
00017F2C  beq       loc_17F1C
00017F30  lis       r31, 0x30 # '0'
00017F34  lwz       r11, -0x3D80(r31)
00017F38  extrwi    r11, r11, 1,12
00017F3C  lfs       f0, 0(r11)
00017F40  beq       loc_17F68
00017F44  li        r31, 1
00017F48  lis       r28, 0x30 # '0'
00017F4C  lwz       r0, -0x3D80(r28)
00017F50  insrwi    r0, r31, 1,15
00017F54  stw       r0, -0x3D80(r28)
00017F58  lis       r28, 0x30 # '0'
00017F5C  lhzu      r8, -0x3D80(r28)
00017F60  insrwi    r0, r31, 1,8
00017F64  stw       r0, -0x3D80(r28)
00017F68  lis       r31, 0x30 # '0'
00017F6C  lis       r11, 0x3361
00017F70  ori       r11, r11, 0xC700 # 0x3361C700
00017F74  stw       r11, -0x3D80(r31)
00017F78  lis       r31, 0x30 # '0'
00017F7C  lwzu      r6, -0x3C7C(r31)
00017F80  lis       r31, 0x30 # '0'
00017F84  lis       r12, 0x70 # 'p'
00017F88  ori       r12, r12, 0x80 # 0x700080
00017F8C  stw       r12, -0x3D7C(r31)
00017F90  lis       r31, 0x30 # '0'
00017F94  lwz       r11, -0x3D7C(r31)
00017F98  extrwi    r11, r11, 1,15
00017FA0  beq       loc_17F90
00017FA4  lis       r29, 0x30 # '0'
00017FA8  lis       r11, 0x3F61
00017FAC  ori       r11, r11, 0xC700 # 0x3F61C700
00017FB0  stw       r11, -0x3D80(r29)
00017FB4  lis       r29, 0x30 # '0'
00017FB8  li        r9, 0x80
00017FBC  lfs       f9, -0x3D74(r29)
00017FC0  li        r3, 0
00017FC4  mtdec     r3
00017FC8  lis       r29, 0x30 # '0'
00017FCC  stw       r30, -0x3D00(r29)
00017FD0  lis       r30, 0x30 # '0'
00017FD4  li        r9, 3
00017FD8  sth       r9, -0x3E00(r30)
00017FDC  sthu      r5, loc_556C
00017FE0  lis       r30, 0x30 # '0'
00017FE4  sth       r29, -0x3FF2(r30)
00017FE8  lis       r30, unk_AA39@h
00017FEC  ori       r30, r30, unk_AA39@l
00017FF0  lis       r31, 0x30 # '0'
00017FF4  sth       r30, -0x3FF2(r31)
00017FF8  lis       r31, 0x30 # '0'
00017FFC  rlwinm.   r0, r19, 0,14,20
00018000  ori       r11, r11, 0x7F8F
00018004  stw       r11, -0x3FFC(r31)
00018008  lis       r31, 0x30 # '0'
0001800C  sth       r29, -0x3FF2(r31)
00018010  lis       r29, 0x30 # '0'
00018014  sth       r30, -0x3FF2(r29)
00018018  lis       r30, 0x30 # '0'
0001801C  lis       r19, 0xB
00018020  stw       r11, -0x3F00(r30)
```
