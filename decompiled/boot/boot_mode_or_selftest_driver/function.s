; boot_mode_or_selftest_driver
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00044B18 end=0x00044C6C size=340
; export_utc=2026-01-10T18:12:42Z

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
