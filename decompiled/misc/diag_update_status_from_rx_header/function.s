; diag_update_status_from_rx_header
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0001B318 end=0x0001B53C size=548
; export_utc=2026-01-10T18:12:42Z

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
