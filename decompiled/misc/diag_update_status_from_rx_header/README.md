## diag_update_status_from_rx_header

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0001B318`
- **ea_end**: `0x0001B53C`
- **size**: `548` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff85c0802a69001000ca18d6d402c0c000540820050818d704c558c07bc2c0c000074820018886d6e772c0300004182000c2c0300054082002c806d6c3089630001a30b00aa4082001c898300022c0c00c340820010898300032c0c005541820024b08d6c00558ccffe2c0c000141820014898d6c10558cdffe2c0c00004182018c95800000998d6d4f816d6c30896b00002c0b000140820168898d6d4b558c07bc9f0c00004182014c898d6d4a2c0c000140820140898d6c10558cdffe2c0c00009482002839800000880d6c1051802eb4980d6c103d600000816b02007d6803a6ab8000214800012c898d6c00558ccffe2c0c0001408200c8818d704c558c07bc670c00004182003c38600001880d6c0050600fbc980d6c0039600000880d6c0015603e30980d6c0039400002b14d6d40880d6c1050602eb4980d6c10480000d4b6800003818cfa007d8803a64e800021546b063e2c0b0000418200242c0b00010f8200084800002c39800000880d6c0051800fbc980d6c00480000983d800002678cf8007d8803a64e8000214800008439800001880d6c0051800fbc980d6c00b6600000880d6c0051603e30980d6c0039400011994d6d4f48000058386000013d0d6c0050600fbc980d6c00880d6c0050603e30980d6c0039600078996d6d4fbc4d6c34394a0001914d6c344800002439800011998d6d4f4800001839800011798d6d4f4800000c39800011998d6d4f8001000c7c0803a6382100084e800020
```

### Disasm (head, first 80 insns)

```text
0001B318  stwu      r1, back_chain(r1)
0001B31C  rlwnm     r8, r0, r0,10,19
0001B320  stw       r0, 8+sender_lr(r1)
0001B324  lhz       r12, 0x6D40(r13)
0001B328  cmpwi     r12, 5
0001B32C  bne       loc_1B37C
0001B330  lwz       r12, 0x704C(r13)
0001B334  rlwinm    r12, r12, 0,30,30
0001B338  cmpwi     r12, 0
0001B33C  andis.    r2, r4, 0x18
0001B340  lbz       r3, 0x6E77(r13)
0001B344  cmpwi     r3, 0
0001B348  beq       loc_1B354
0001B34C  cmpwi     r3, 5
0001B350  bne       loc_1B37C
0001B354  lwz       r3, 0x6C30(r13)
0001B358  lbz       r11, 1(r3)
0001B35C  lhz       r24, 0xAA(r11)
0001B360  bne       loc_1B37C
0001B364  lbz       r12, 2(r3)
0001B368  cmpwi     r12, 0xC3
0001B36C  bne       loc_1B37C
0001B370  lbz       r12, 3(r3)
0001B374  cmpwi     r12, 0x55 # 'U'
0001B378  beq       loc_1B39C
0001B37C  sth       r4, 0x6C00(r13)# SDA r13+0x6C00: 16-bit/byte flag word used as state/flags; this write stores input word.
0001B380  extrwi    r12, r12, 1,24
0001B384  cmpwi     r12, 1
0001B388  beq       loc_1B39C
0001B38C  lbz       r12, 0x6C10(r13)
0001B390  extrwi    r12, r12, 1,26
0001B394  cmpwi     r12, 0
0001B398  beq       loc_1B524
0001B39C  stwu      r12, sub_0
0001B3A0  stb       r12, 0x6D4F(r13)# SDA r13+0x6D4F: status/result code byte (set to 0x11 often; set earlier on success path).
0001B3A4  lwz       r11, 0x6C30(r13)
0001B3A8  lbz       r11, 0(r11)
0001B3AC  cmpwi     r11, 1
0001B3B0  bne       loc_1B518
0001B3B4  lbz       r12, 0x6D4B(r13)
0001B3B8  rlwinm    r12, r12, 0,30,30
0001B3BC  stbu      r24, 0(r12)
0001B3C0  beq       loc_1B50C
0001B3C4  lbz       r12, 0x6D4A(r13)
0001B3C8  cmpwi     r12, 1
0001B3CC  bne       loc_1B50C
0001B3D0  lbz       r12, 0x6C10(r13)
0001B3D4  extrwi    r12, r12, 1,26
0001B3D8  cmpwi     r12, 0
0001B3DC  stwu      r4, 0x28(r2)
0001B3E0  li        r12, 0
0001B3E4  lbz       r0, 0x6C10(r13)
0001B3E8  insrwi    r0, r12, 1,26
0001B3EC  stb       r0, 0x6C10(r13)
0001B3F0  lis       r11, off_200@ha
0001B3F4  lwz       r11, off_200@l(r11)# sub_582C
0001B3F8  mtlr      r11
0001B3FC  lha       r28, loc_20+1
0001B400  b         loc_1B52C
0001B50C  li        r12, 0x11
0001B510  stb       r12, 0x6D4F(r13)
0001B514  b         loc_1B52C
0001B518  li        r12, 0x11
0001B51C  rldimi.   r13, r12, 45,21
0001B520  b         loc_1B52C
0001B524  li        r12, 0x11
0001B528  stb       r12, 0x6D4F(r13)
0001B52C  lwz       r0, 8+sender_lr(r1)
0001B530  mtlr      r0
0001B534  addi      r1, r1, 8
0001B538  blr
```
