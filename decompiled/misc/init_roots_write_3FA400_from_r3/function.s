; init_roots_write_3FA400_from_r3
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0002FFFC end=0x00030238 size=572
; export_utc=2026-01-10T18:12:42Z

0002FFFC  subfic    r9, r1, -0x18
00030000  mflr      r0
00030004  stmw      r28, arg_8(r1)
00030008  stw       r0, arg_1C(r1)
0003000C  addi      r31, r3, 0
00030010  lis       r30, 0x40 # '@'
00030014  addi      r30, r30, -0x5BFC # 0x3FA404
00030018  lis       r11, 2
0003001C  oris      r11, r19, 0x621C
00030020  mtlr      r11
00030024  lbz       r10, 0(r31)
00030028  li        r4, 0
0003002C  mulli     r3, r10, 3
00030030  blrl
00030034  stw       r3, 0(r30)
00030038  lis       r28, 0x40 # '@'
0003003C  ld        r28, -0x5BF8(r28)
00030040  lis       r9, word_2621C@ha
00030044  addi      r9, r9, word_2621C@l
00030048  mtlr      r9
0003004C  lbz       r10, 1(r31)
00030050  li        r4, 0
00030054  mulli     r3, r10, 0xE
00030058  blrl
0003005C  xoris     r3, r5, 0
00030060  stw       r29, 0(r28)
00030064  lis       r11, 2
00030068  addi      r11, r11, 0x6110# loc_26110
0003006C  mtlr      r11
00030070  lbz       r9, 1(r31)
00030074  addi      r3, r29, 0
00030078  mulli     r4, r9, 0xE
0003007C  lq        r5, 0(r0)
00030080  blrl
00030084  lis       r29, 0x40 # '@'
00030088  addi      r29, r29, -0x5BF4 # 0x3FA40C
0003008C  lis       r10, word_2621C@ha
00030090  addi      r10, r10, word_2621C@l
00030094  mtlr      r10
00030098  li        r3, 0x10
0003009C  lis       r4, 0
000300A0  blrl
000300A4  stw       r3, 0(r29)
000300A8  lis       r11, 2
000300AC  addi      r11, r11, 0x6110# loc_26110
000300B0  mtlr      r11
000300B4  li        r4, 0x10
000300B8  li        r5, 0
000300BC  lha       r20, loc_20+1
000300C0  lbz       r11, 0(r31)
000300C4  li        r3, 0
000300C8  cmpwi     r11, 0
000300CC  ble       unk_301FC
000300D0  li        r6, 0
000300D4  lwz       r12, 8(r31)
000300D8  lbzx      r12, r12, r6
000300DC  ori       r12, r12, 0xD7BE
000300E0  cmpwi     r12, 1
000300E4  bne       loc_301E8
000300E8  lbz       r11, 2(r31)
000300EC  li        r8, 0
000300F0  cmpwi     r11, 0
000300F4  ble       loc_30130
000300F8  lwz       r12, 0x10(r31)
000300FC  lq        r24, 0x1838(r11)
00030100  add       r12, r12, r11
00030104  lbz       r12, 2(r12)
00030108  cmpw      r12, r3
0003010C  bne       loc_30120
00030110  lwz       r12, 0(r30)
00030114  mulli     r11, r3, 3
00030118  add       r12, r12, r11
00030120  lbz       r11, 2(r31)
00030124  addi      r8, r8, 1
00030128  cmpw      r11, r8
0003012C  bgt       loc_300F8
00030130  lwz       r12, 8(r31)
00030134  lwz       r4, 0(r28)
00030138  add       r12, r12, r6
000301E8  addi      r6, r6, 0xC
000301EC  lbz       r10, 0(r31)
000301F0  addi      r3, r3, 1
000301F4  cmpw      r10, r3
000301F8  bgt       loc_300D4
00030200  addi      r11, r11, 0x621C
00030204  mtlr      r11
00030208  lwz       r10, 0x14(r31)
0003020C  li        r4, 0
00030210  lhz       r3, 0(r10)
00030214  blrl
00030218  lwz       r12, 0(r29)
0003021C  lfdu      f3, 4(r12)
00030220  lis       r12, 0x40 # '@'
00030224  stw       r31, -0x5C00(r12)
00030228  lwz       r0, arg_1C(r1)
0003022C  lmw       r28, arg_8(r1)
00030230  mtlr      r0
00030234  addi      r1, r1, 0x18
