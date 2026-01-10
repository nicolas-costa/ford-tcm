## tpu_pwm_entry_apply_via_tpu_regs

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00021CB8`
- **ea_end**: `0x00021F74`
- **size**: `700` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffe0cc0802a6bf410008900100243b8300003ba40000579a2036817d00047f6bd0aecda0000238a51ec0389c0000387b000048011cc9387b00003880000b38a0000246c0000148011ed9387b000048011e9d3bc30000815d00047faad214897d0002dc0b0000418200202c0b0001418200202c0b0002418200102c0b000341820010550000103be00000480000083be00030899d0001558b07be2c0b0000418200208f0b0001418200282c0b0002418200302c0b0003418200384800004063ff0004f1600000b17e00024800003063ff000839600001b17e00024800002063ff0008fa600100b17e00024800001063ff000439600101b17e0002b3fe00003d8000055b8ca5fc578b20367d8c5a148bec00022c1f000040820014818d1ee838cc0000f4a00000480000702c1f000140820014818d1eec38cc000038a00000480000589d1f000240820014818d1ef038cc000038a00000480000402c1f000340820014fb8d1ef438cc000038a00000480000282c1f000440820014818d1ee038cc000001a0000048000010818d1ee438cc000038a00000a19d00047c0c29d67c6c30166f6302147c8c31d638a000003cc0000060c6f42448003fd93b840000281c7fff6b81001039807fffb19e000848000008b39e000839800000919e000439600000b57e000e387b000038800003bb410008800100247c0803a638210020480123b00c21fff07c0802a693e1000c900100143be4000048011cd5a1830004a1630008800c580040820044a183000e558c05ee2c0c000041820070818d15a8818c0004afeb20367d8c5a1483ec000c2c1f000041820054819f00047d8803a6387f00004c80002148000040a183000e558c07fe2c0c000041820030818d15a8818c00040beb20367d8c5a1483ec00082c1f000041820014819f00047d8803a6387f00005080002183e1000c800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00021CB8  stwu      r1, back_chain(r1)
00021CBC  lfdu      f0, 0x2A6(r8)
00021CC0  stmw      r26, 0x20+var_18(r1)
00021CC4  stw       r0, 0x20+sender_lr(r1)
00021CC8  addi      r28, r3, 0
00021CCC  addi      r29, r4, 0
00021CD0  slwi      r26, r28, 4
00021CD4  lwz       r11, 4(r29)
00021CD8  lbzx      r27, r11, r26
00021CDC  lfdu      f13, sub_0+2
00021CE0  addi      r5, r5, 0x1EC0
00021CE4  addi      r4, r28, 0
00021CE8  addi      r3, r27, 0
00021CEC  bl        sub_339B4
00021CF0  addi      r3, r27, 0
00021CF4  li        r4, 0xB
00021CF8  li        r5, 2
00021D00  bl        loc_33BD8
00021D04  addi      r3, r27, 0
00021D08  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
00021D0C  addi      r30, r3, 0
00021D10  lwz       r10, 4(r29)
00021D14  add       r29, r10, r26
00021D18  lbz       r11, 2(r29)
00021D1C  stfdu     f0, 0(r11)
00021D20  beq       loc_21D40
00021D24  cmpwi     r11, 1
00021D28  beq       loc_21D48
00021D2C  cmpwi     r11, 2
00021D30  beq       loc_21D40
00021D34  cmpwi     r11, 3
00021D38  beq       loc_21D48
00021D3C  clrrwi    r0, r8, 23
00021D40  li        r31, 0
00021D44  b         loc_21D4C
00021D48  li        r31, 0x30 # '0'
00021D4C  lbz       r12, 1(r29)
00021D50  clrlwi    r11, r12, 30
00021D54  cmpwi     r11, 0
00021D58  beq       loc_21D78
00021D5C  lbzu      r24, 1(r11)
00021D60  beq       loc_21D88
00021D64  cmpwi     r11, 2
00021D68  beq       loc_21D98
00021D6C  cmpwi     r11, 3
00021D70  beq       loc_21DA8
00021D74  b         loc_21DB4
00021D78  ori       r31, r31, 4
00021D7C  xsaddsp   vs11, vs0, vs0
00021D80  sth       r11, 2(r30)
00021D84  b         loc_21DB4
00021D88  ori       r31, r31, 8
00021D8C  li        r11, 1
00021D90  sth       r11, 2(r30)
00021D94  b         loc_21DB4
00021D98  ori       r31, r31, 8
00021D9C  std       r19, 0x100(r0)
00021DA0  sth       r11, 2(r30)
00021DA4  b         loc_21DB4
00021DA8  ori       r31, r31, 4
00021DAC  li        r11, 0x101
00021DB0  sth       r11, 2(r30)
00021DB4  sth       r31, 0(r30)
00021DB8  lis       r12, word_4A5FC@ha
00021DBC  rlmi      r12, r28, r20,23,30
00021DC0  slwi      r11, r28, 4# unk_143C
00021DC4  add       r12, r12, r11
00021DC8  lbz       r31, (byte_C902 - 0xC900)(r12)
00021DCC  cmpwi     r31, 0
00021DD0  bne       loc_21DE4
00021DD4  lwz       r12, 0x1EE8(r13)
00021DD8  addi      r6, r12, 0
00021DDC  stfdp     f5, sub_0
00021DE0  b         loc_21E50
00021DE4  cmpwi     r31, 1
00021DE8  bne       loc_21DFC
00021DEC  lwz       r12, 0x1EEC(r13)
00021DF0  addi      r6, r12, 0
00021DF4  li        r5, 0
00021DF8  b         loc_21E50
```
