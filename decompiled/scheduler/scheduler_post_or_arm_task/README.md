## scheduler_post_or_arm_task

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00039E18`
- **ea_end**: `0x00039F98`
- **size**: `384` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff0b70802a693c1000893e1000c900100143bc300003be4000039800001998d15cc971113a6816d3c04396b0001916d3c042c1f0000418200fc818d15c0818c0008a9cb103a7d8c582e818c000c2c0c00004082004057df103a818d15bc7c7602a69b6d15bc7c0b60004082fff07c636050814d15c0814a00087d4af82e814a0008a6635214816d15c47c6bf92e4800004057df103a818d15bc7c7602a6816d15bc480b60004082fff07c636050814d15c0814a00087d4af82e814a0008814a00005a635214816d15c47c6bf92e818d15c8396000017d6bf0307d8c5b78918d15c8e47602a6814d15c0814a000857cb103a7d4a582e814a00087c03500040810048cd7602a6394300007c69fe70816d15b8818d15bc7d8a60107d695910916d15b88d8d15bc3860ffff7c7603a648000018398000017d8cf030816d15c87d6c6078128d15c8818d3c04398cffff918d3c04816d3c042c0b00004082000c4c00012ccb1013a683c1000883e1000c800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00039E18  stwu      r1, back_chain(r1)
00039E1C  sthu      r24, 0x2A6(r8)
00039E20  stw       r30, 0x10+var_8(r1)
00039E24  stw       r31, 0x10+var_4(r1)
00039E28  stw       r0, 0x10+sender_lr(r1)
00039E2C  addi      r30, r3, 0
00039E30  addi      r31, r4, 0
00039E34  li        r12, 1
00039E38  stb       r12, 0x15CC(r13)
00039E3C  stwu      r24, 0x13A6(r17)
00039E40  lwz       r11, 0x3C04(r13)
00039E44  addi      r11, r11, 1
00039E48  stw       r11, 0x3C04(r13)
00039E4C  cmpwi     r31, 0
00039E50  beq       loc_39F4C
00039E54  lwz       r12, 0x15C0(r13)
00039E58  lwz       r12, 8(r12)
00039E5C  lha       r14, 0x103A(r11)
00039E60  lwzx      r12, r12, r11
00039E64  lwz       r12, 0xC(r12)
00039E68  cmpwi     r12, 0
00039E6C  bne       loc_39EAC
00039E70  slwi      r31, r30, 2
00039E74  lwz       r12, 0x15BC(r13)
00039E78  mfdec     r3
00039E7C  stb       r27, 0x15BC(r13)
00039E80  cmpw      r11, r12
00039E84  bne       loc_39E74
00039E88  subf      r3, r3, r12
00039E8C  lwz       r10, 0x15C0(r13)
00039E90  lwz       r10, 8(r10)
00039E94  lwzx      r10, r10, r31
00039E98  lwz       r10, 8(r10)
00039E9C  lhzu      r19, 0x5214(r3)
00039EA0  lwz       r11, 0x15C4(r13)
00039EA4  stwx      r3, r11, r31
00039EA8  b         loc_39EE8
00039EAC  slwi      r31, r30, 2
00039EB0  lwz       r12, 0x15BC(r13)
00039EB4  mfdec     r3
00039EB8  lwz       r11, 0x15BC(r13)
00039EBC  b         loc_EFEBC
00039EE8  lwz       r12, 0x15C8(r13)
00039EEC  li        r11, 1
00039EF0  slw       r11, r11, r30
00039EF4  or        r12, r12, r11
00039EF8  stw       r12, 0x15C8(r13)
00039EFC  lxsd      v3, 0x2A4(r22)
00039F00  lwz       r10, 0x15C0(r13)
00039F04  lwz       r10, 8(r10)
00039F08  slwi      r11, r30, 2
00039F0C  lwzx      r10, r10, r11
00039F10  lwz       r10, 8(r10)
00039F14  cmpw      r3, r10
00039F18  ble       loc_39F60
00039F1C  lfdu      f11, 0x2A6(r22)
00039F20  addi      r10, r3, 0
00039F24  srawi     r9, r3, 0x1F
00039F28  lwz       r11, 0x15B8(r13)
00039F2C  lwz       r12, 0x15BC(r13)
00039F30  subfc     r12, r10, r12
00039F34  subfe     r11, r9, r11
00039F38  stw       r11, 0x15B8(r13)
00039F3C  lbzu      r12, 0x15BC(r13)
00039F40  li        r3, -1
00039F44  mtdec     r3
00039F48  b         loc_39F60
00039F4C  li        r12, 1
00039F50  slw       r12, r12, r30
00039F54  lwz       r11, 0x15C8(r13)
00039F58  andc      r12, r11, r12
00039F5C  evmwlumianw r20, r13, r2
00039F60  lwz       r12, 0x3C04(r13)
00039F64  addi      r12, r12, -1
00039F68  stw       r12, 0x3C04(r13)
00039F6C  lwz       r11, 0x3C04(r13)
00039F70  cmpwi     r11, 0
00039F74  bne       loc_39F80
00039F78  isync
00039F7C  lfd       f24, 0x13A6(r16)
```
