## tpu_pwm_post_apply_dispatch_and_callbacks

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00021ACC`
- **ea_end**: `0x00021BC4`
- **size**: `248` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff87c0802a69001000c38e300005d84000454eb20367ccc58ae394600e05546063e7cc026707c0001941c000010ad603050396b000b5564063e2c050001408200642c060010408000243ca0003032650000a1656c04394000017d4a20307d6b5378b1636c04480000203ca0003056650000a1656c44394000017d4a20307d6b5378b1636c443986000b5583063e44a0000238a519443887000048011f4d480000482c060010408000243ce00030d7c70000396000017d6b2030a1476c047d4b5878b1666c04480000203ce0003049c70000396000017d6b2030a1476c447d4b5878b1666c448001000c7c0803a6a32100084e800020
```

### Disasm (head, first 80 insns)

```text
00021ACC  stwu      r1, back_chain(r1)
00021AD0  mflr      r0
00021AD4  stw       r0, 8+sender_lr(r1)
00021AD8  addi      r7, r3, 0
00021ADC  rlwnm     r4, r12, r0,0,2
00021AE0  slwi      r11, r7, 4
00021AE4  lbzx      r6, r12, r11
00021AE8  addi      r10, r6, 0xE0
00021AEC  clrlwi    r6, r10, 24
00021AF0  srawi     r0, r6, 4
00021AF4  addze     r0, r0
00021AF8  mulli     r0, r0, 0x10
00021AFC  lhau      r11, loc_3050
00021B00  addi      r11, r11, (unk_382C - 0x3821)
00021B04  clrlwi    r4, r11, 24
00021B08  cmpwi     r5, 1
00021B0C  bne       loc_21B70
00021B10  cmpwi     r6, 0x10
00021B14  bge       loc_21B38
00021B18  lis       r5, 0x30 # '0'
00021B1C  addic     r19, r5, 0 # 0x300000
00021B20  lhz       r11, 0x6C04(r5)
00021B24  li        r10, 1
00021B28  slw       r10, r10, r4
00021B2C  or        r11, r11, r10
00021B30  sth       r11, 0x6C04(r3)
00021B34  b         loc_21B54
00021B38  lis       r5, 0x30 # '0'
00021B3C  clrrwi    r5, r19, 31
00021B40  lhz       r11, 0x6C44(r5)
00021B44  li        r10, 1
00021B48  slw       r10, r10, r4
00021B4C  or        r11, r11, r10
00021B50  sth       r11, 0x6C44(r3)
00021B54  addi      r12, r6, 0xB
00021B58  clrlwi    r3, r12, 24
00021B60  addi      r5, r5, 0x1944
00021B64  addi      r4, r7, 0
00021B68  bl        sub_33AB4
00021B6C  b         loc_21BB4
00021B70  cmpwi     r6, 0x10
00021B74  bge       loc_21B98
00021B78  lis       r7, 0x30 # '0'
00021B7C  stfsu     f30, 0(r7)
00021B80  li        r11, 1
00021B84  slw       r11, r11, r4
00021B88  lhz       r10, 0x6C04(r7)
00021B8C  andc      r11, r10, r11
00021B90  sth       r11, 0x6C04(r6)
00021B94  b         loc_21BB4
00021B98  lis       r7, 0x30 # '0'
00021B9C  b         0x1C91B9C
00021BA0  li        r11, 1
00021BA4  slw       r11, r11, r4
00021BA8  lhz       r10, 0x6C44(r7)
00021BAC  andc      r11, r10, r11
00021BB0  sth       r11, 0x6C44(r6)
00021BB4  lwz       r0, 8+sender_lr(r1)
00021BB8  mtlr      r0
00021BBC  lhz       r25, 8+pre_back_chain(r1)
00021BC0  blr
```
