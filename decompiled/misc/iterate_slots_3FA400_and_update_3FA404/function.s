; iterate_slots_3FA400_and_update_3FA404
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00031698 end=0x000317A8 size=272
; export_utc=2026-01-10T18:12:42Z

00031698  stwu      r1, back_chain(r1)
0003169C  addi      r0, r8, 0x2A6
000316A0  stmw      r27, 0x20+var_14(r1)
000316A4  stw       r0, 0x20+sender_lr(r1)
000316A8  lis       r28, 0x40 # '@'
000316AC  addi      r28, r28, -0x5C00 # 0x3FA400
000316B0  lwz       r10, 0(r28)
000316B4  li        r31, 0
000316B8  lbz       r10, 2(r10)
000316BC  stfsu     f16, 0(r10)
000316C0  ble       loc_31794
000316C4  lis       r27, 0x40 # '@'
000316C8  addi      r27, r27, -0x5BFC # 0x3FA404
000316CC  lwz       r3, 0(r28)
000316D0  slwi      r4, r31, 3
000316D4  lwz       r29, 0x10(r3)
000316D8  add       r9, r29, r4
000316DC  clrrwi    r9, r14, 30
000316E0  lhzx      r4, r29, r4
000316E4  mulli     r29, r30, 3
000316E8  lwz       r10, 0(r27)
000316EC  add       r10, r10, r29
000316F0  lbz       r10, 2(r10)
000316F4  cmpwi     r10, 0
000316F8  beq       loc_31780
000316FC  clrrwi    r30, r6, 25
00031700  lwz       r11, 8(r3)
00031704  lbzx      r11, r11, r30
00031708  extrwi    r11, r11, 2,24
0003170C  cmpwi     r11, 1
00031710  bne       loc_31780
00031714  addi      r3, r4, 0
00031718  li        r4, 0
0003171C  li        r24, 0x5F5D
00031720  clrlwi    r11, r3, 24
00031724  cmpwi     r11, 0
00031728  beq       loc_31780
0003172C  lwz       r12, 0(r28)
00031730  lwz       r12, 8(r12)
00031734  lbzx      r12, r12, r30
00031738  extrwi    r12, r12, 2,26
0003173C  xsaddsp   vs8, vs12, vs0
00031740  bne       loc_3175C
00031744  lis       r12, 3
00031748  addi      r12, r12, 0xEC4 # 0x30EC4
0003174C  mtlr      r12
00031750  clrlwi    r3, r31, 24
00031754  blrl
00031758  b         loc_31780
0003175C  stw       r12, 0(r27)
00031760  li        r11, 0
00031764  add       r12, r12, r29
00031768  stb       r11, 2(r12)
0003176C  lis       r10, loc_3099C@ha
00031770  addi      r10, r10, loc_3099C@l
00031774  mtlr      r10
00031778  clrlwi    r3, r31, 24
00031780  lwz       r11, 0(r28)
00031784  addi      r31, r31, 1
00031788  lbz       r11, 2(r11)
0003178C  cmpw      r11, r31
00031790  bgt       loc_316CC
00031794  lwz       r0, 0x20+sender_lr(r1)
00031798  lmw       r27, 0x20+var_14(r1)
000317A0  addi      r1, r1, 0x20
000317A4  blr
