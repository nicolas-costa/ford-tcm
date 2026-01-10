; tpu_pwm_entry_apply_via_tpu_regs
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00021CB8 end=0x00021F74 size=700
; export_utc=2026-01-10T18:12:42Z

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
00021DFC  stbu      r8, 2(r31)
00021E00  bne       loc_21E14
00021E04  lwz       r12, 0x1EF0(r13)
00021E08  addi      r6, r12, 0
00021E0C  li        r5, 0
00021E10  b         loc_21E50
00021E14  cmpwi     r31, 3
00021E18  bne       loc_21E2C
00021E1C  std       r28, 0x1EF4(r13)
00021E20  addi      r6, r12, 0
00021E24  li        r5, 0
00021E28  b         loc_21E50
00021E2C  cmpwi     r31, 4
00021E30  bne       loc_21E44
00021E34  lwz       r12, 0x1EE0(r13)
00021E38  addi      r6, r12, 0
00021E40  b         loc_21E50
00021E44  lwz       r12, 0x1EE4(r13)
00021E48  addi      r6, r12, 0
00021E4C  li        r5, 0
00021E50  lhz       r12, 4(r29)
00021E54  mullw     r0, r12, r5
00021E58  mulhwu    r3, r12, r6
00021E5C  xoris     r3, r27, 0x214
00021E60  mullw     r4, r12, r6
00021E64  li        r5, 0
00021E68  lis       r6, 0
00021E6C  ori       r6, r6, 0xF424 # 0xF424
00021E70  bl        sub_25E48
00021E74  addi      r28, r4, 0
00021E78  cmplwi    r28, 0x7FFF
00021E7C  xori      r1, r28, 0x10
00021E80  li        r12, 0x7FFF
00021E84  sth       r12, 8(r30)
00021E88  b         loc_21E90
00021E8C  sth       r28, 8(r30)
00021E90  li        r12, 0
00021E94  stw       r12, 4(r30)
00021E98  li        r11, 0
00021E9C  sthu      r11, 0xE(r30)
00021EA0  addi      r3, r27, 0
00021EA4  li        r4, 3
00021EA8  lmw       r26, 0x20+var_18(r1)
00021EAC  lwz       r0, 0x20+sender_lr(r1)
00021EB0  mtlr      r0
00021EB4  addi      r1, r1, 0x20 # ' '
00021EB8  b         loc_34268
00021EBC  twlgti    r1, -0x10
00021EC0  mflr      r0
00021EC4  stw       r31, arg_C(r1)
00021EC8  stw       r0, arg_14(r1)
00021ECC  addi      r31, r4, 0
00021ED0  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
00021ED4  lhz       r12, 4(r3)
00021ED8  lhz       r11, 8(r3)
00021EDC  lwz       r0, 0x5800(r12)
00021EE0  bne       loc_21F24
00021EE4  lhz       r12, 0xE(r3)
00021EE8  rlwinm    r12, r12, 0,23,23
00021EEC  cmpwi     r12, 0
00021EF0  beq       loc_21F60
00021EF4  lwz       r12, 0x15A8(r13)
00021EF8  lwz       r12, 4(r12)
00021EFC  lhau      r31, 0x2036(r11)
00021F00  add       r12, r12, r11
00021F04  lwz       r31, 0xC(r12)
00021F08  cmpwi     r31, 0
00021F0C  beq       loc_21F60
00021F10  lwz       r12, 4(r31)
00021F14  mtlr      r12
00021F18  addi      r3, r31, 0
00021F1C  bgelrl
00021F20  b         loc_21F60
00021F24  lhz       r12, 0xE(r3)
00021F28  clrlwi    r12, r12, 31
00021F2C  cmpwi     r12, 0
00021F30  beq       loc_21F60
00021F34  lwz       r12, 0x15A8(r13)
00021F38  lwz       r12, 4(r12)
00021F3C  tdui      r11, 0x2036
00021F40  add       r12, r12, r11
00021F44  lwz       r31, 8(r12)
00021F48  cmpwi     r31, 0
00021F4C  beq       loc_21F60
00021F50  lwz       r12, 4(r31)
00021F54  mtlr      r12
00021F58  addi      r3, r31, 0
00021F5C  rlwimi.   r0, r4, 0,0,16
00021F60  lwz       r31, arg_C(r1)
00021F64  lwz       r0, arg_14(r1)
00021F68  mtlr      r0
00021F6C  addi      r1, r1, 0x10
00021F70  blr
