; boot_apply_range_table_2A540_variants
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000448D8 end=0x00044B18 size=576
; export_utc=2026-01-10T18:12:42Z

000448D8  stwu      r1, back_chain(r1)
000448DC  stw       r0, 0x2A6(r8)
000448E0  stmw      r28, 0x20+var_10(r1)
000448E4  stw       r0, 0x20+sender_lr(r1)
000448E8  lis       r31, 0x40 # '@'
000448EC  addi      r31, r31, -0x4478 # 0x3FBB88
000448F0  li        r30, 0
000448F4  lbz       r11, 0(r31)
000448F8  cmpwi     r11, 0
000448FC  andi.     r2, r12, 0x10
00044900  cmpwi     r11, 1
00044904  beq       loc_44AE4
00044908  b         loc_44AFC
0004490C  li        r29, 0
00044910  lis       r28, 0x40 # '@'
00044914  lbz       r28, -0x4469(r28)
00044918  rlwinm    r10, r28, 0,28,28
0004491C  addi      r0, r10, 8
00044920  bne       loc_44974
00044924  lis       r3, 0x40 # '@'
00044928  addi      r3, r3, -0x44A0 # 0x3FBB60
0004492C  bl        init_range_table_2A540_apply# FATO: boot_apply_range_table_2A540_variants chama init_range_table_2A540_apply (0x44460) repetidamente em diferentes bases 0x3FBB60/68/70/80 etc.
00044930  stw       r3, 0x20+var_18(r1)
00044934  lbz       r11, 0x20+var_18+2(r1)
00044938  cmpwi     r11, 1
0004493C  xxsel     vs20, vs2, vs0, vs32
00044940  li        r29, 1
00044944  lhz       r30, 0x20+var_18(r1)
00044948  addi      r3, r30, 0
0004494C  li        r4, 2
00044950  li        r5, 1
00044954  bl        sub_447BC
00044958  li        r12, 2
0004495C  ori       r31, r4, 1
00044960  sth       r30, 4(r31)
00044964  li        r11, 1
00044968  stb       r11, 0(r31)
0004496C  li        r30, 1
00044970  b         loc_449CC
00044974  rlwinm    r12, r28, 0,30,30
00044978  cmpwi     r12, 2
0004497C  addic.    r20, r2, 0x50 # 'P'
00044980  lis       r3, 0x40 # '@'
00044984  addi      r3, r3, -0x4498 # 0x3FBB68
00044988  bl        init_range_table_2A540_apply
0004498C  stw       r3, 0x20+var_18(r1)
00044990  lbz       r11, 0x20+var_18+2(r1)
00044994  cmpwi     r11, 1
00044998  bne       loc_449D4
0004499C  cmpldi    cr7, r0, 1
000449A0  lhz       r30, 0x20+var_18(r1)
000449A4  addi      r3, r30, 0
000449A8  li        r4, 1
000449AC  li        r5, 1
000449B0  bl        sub_447BC
000449B4  li        r12, 0
000449B8  stb       r12, 1(r31)
000449BC  subfic    r6, r31, 4
000449C0  li        r11, 1
000449C4  stb       r11, 0(r31)
000449C8  li        r30, 1
000449CC  cmpwi     r29, 0
000449D0  bne       loc_44A2C
000449D4  rlwinm    r12, r28, 0,27,27
000449D8  cmpwi     r12, 0x10
000449E0  lis       r3, 0x40 # '@'
000449E4  addi      r3, r3, -0x4480 # 0x3FBB80
000449E8  bl        init_range_table_2A540_apply
000449EC  stw       r3, 0x20+var_18(r1)
000449F0  lbz       r11, 0x20+var_18+2(r1)
000449F4  cmpwi     r11, 1
000449F8  bne       loc_44A34
00044A00  lhz       r30, 0x20+var_18(r1)
00044A04  addi      r3, r30, 0
00044A08  li        r4, 4
00044A0C  li        r5, 1
00044A10  bl        sub_447BC
00044A14  li        r12, 4
00044A18  stb       r12, 1(r31)
00044A20  li        r11, 1
00044A24  stb       r11, 0(r31)
00044A28  li        r30, 1
00044A2C  cmpwi     r29, 0
00044A30  bne       loc_44A88
00044A34  rlwinm    r12, r28, 0,29,29
00044A38  cmpwi     r12, 4
00044A3C  cmpwi     cr7, r2, 0x4C # 'L'
00044A40  lis       r3, 0x40 # '@'
00044A44  addi      r3, r3, -0x4490 # 0x3FBB70
00044A48  bl        init_range_table_2A540_apply
00044A4C  stw       r3, 0x20+var_18(r1)
00044A50  lbz       r11, 0x20+var_18+2(r1)
00044A54  cmpwi     r11, 1
00044A58  bne       loc_44A90
00044A5C  cmpldi    cr5, r0, 1
00044A60  lhz       r30, 0x20+var_18(r1)
00044A64  addi      r3, r30, 0
00044A68  li        r4, 0
00044A6C  li        r5, 1
00044A70  bl        sub_447BC
00044A74  li        r3, 1
00044A78  stb       r3, 1(r31)
00044A7C  ori       r31, r22, 4
00044A80  stb       r3, 0(r31)
00044A84  li        r30, 1
00044A88  cmpwi     r29, 0
00044A8C  bne       loc_44AFC
00044A90  clrlwi    r12, r28, 31
00044A94  cmpwi     r12, 1
00044A98  bne       loc_44AFC
00044A9C  lha       r27, loc_40
00044AA0  addi      r3, r3, -0x4488
00044AA4  bl        init_range_table_2A540_apply
00044AA8  stw       r3, 0x20+var_18(r1)
00044AAC  lbz       r11, 0x20+var_18+2(r1)
00044AB0  cmpwi     r11, 1
00044AB4  bne       loc_44AFC
00044AB8  lhz       r29, 0x20+var_18(r1)
00044ABC  stfs      f11, 0(r29)
00044AC0  li        r4, 3
00044AC4  li        r5, 1
00044AC8  bl        sub_447BC
00044ACC  li        r9, 3
00044AD0  stb       r9, 1(r31)
00044AD4  sth       r29, 4(r31)
00044AD8  li        r12, 1
00044AE0  b         loc_448F0
00044AE4  bl        loc_441EC
00044AE8  lbz       r12, 0(r31)
00044AEC  cmpwi     r12, 2
00044AF0  bne       loc_44B04
00044AF4  li        r12, 0
00044AF8  stb       r12, 0(r31)
00044AFC  sth       r24, sub_0(r30)
00044B00  bne       loc_448F0
00044B04  lwz       r0, 0x20+sender_lr(r1)
00044B08  lmw       r28, 0x20+var_10(r1)
00044B0C  mtlr      r0
00044B10  addi      r1, r1, 0x20
00044B14  blr
