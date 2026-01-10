; io_read_306030_or_3060B0_and_compute
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000245E8 end=0x00024834 size=588
; export_utc=2026-01-10T18:12:42Z

000245E8  stwu      r1, back_chain(r1)
000245EC  mflr      r0
000245F0  stw       r29, 0x28+var_C(r1)
000245F4  stw       r30, 0x28+var_8(r1)
000245F8  stw       r31, 0x28+var_4(r1)
000245FC  rlwimi    r1, r16, 0,0,22
00024600  addi      r29, r3, 0
00024604  lwz       r12, 0x1520(r13)
00024608  mulli     r11, r29, 0x14
0002460C  add       r30, r12, r11
00024610  lwz       r4, 0x151C(r13)
00024614  slwi      r31, r29, 4
00024618  lwz       r11, 4(r4)
0002461C  lfs       f19, -0x5EC(r11)
00024620  lwz       r11, 4(r11)
00024624  stw       r11, 0x28+var_10(r1)
00024628  addi      r3, r29, 0
0002462C  li        r5, 0
00024630  bl        loc_2447C
00024634  lwz       r4, 0x151C(r13)
00024638  lwz       r3, 4(r4)
0002463C  bc        19, so, loc_24050
00024640  lbz       r11, 2(r11)
00024644  cmpwi     r11, 2
00024648  bne       loc_2465C
0002464C  lis       r31, 0x30 # '0'
00024650  lhz       r11, 0x60B0(r31)
00024654  sth       r11, 0x28+var_1E(r1)
00024658  b         loc_24668
0002465C  andis.    r0, r7, 0x30
00024660  lhz       r11, 0x6030(r31)
00024664  sth       r11, 0x28+var_1E(r1)
00024668  slwi      r12, r29, 4
0002466C  lbzx      r12, r3, r12
00024670  addi      r3, r12, 0x9C
00024674  lis       r11, 0x30 # '0'
00024678  ori       r11, r11, 0x6058 # 0x306058
0002467C  dozi      r27, r10, 0x1D78
00024680  add       r3, r11, r10
00024684  lwz       r12, 0(r3)
00024688  stw       r12, 0x28+var_14(r1)
0002468C  lbz       r31, 0x12(r30)
00024690  clrlwi    r31, r31, 25
00024694  cmplwi    r31, 2
00024698  bge       loc_246B8
0002469C  sth       r20, sub_0
000246A0  stw       r12, 0x28+var_1C(r1)
000246A4  cmpwi     r31, 0
000246A8  bne       loc_24764
000246AC  li        r12, 0
000246B0  stw       r12, 0x28+var_1C+4(r1)
000246B4  b         loc_24764
000246B8  lbz       r12, 0x1524(r13)
000246BC  addi      r0, r12, -0x1800
000246C0  bgt       loc_246D0
000246C4  lhz       r3, 8(r30)
000246C8  cmpwi     r3, 0
000246CC  bne       loc_246F0
000246D0  lhz       r12, 0x28+var_14(r1)
000246D4  lhz       r11, 0x28+var_14+2(r1)
000246D8  subf      r12, r11, r12
000246DC  clrrwi    r1, r28, 25
000246E0  lwz       r10, 0x28+var_1C(r1)
000246E4  clrlwi    r10, r10, 16
000246E8  stw       r10, 0x28+var_1C(r1)
000246EC  b         loc_2474C
000246F0  lis       r12, 0
000246F4  ori       r12, r12, 0xF580 # 0xF580
000246F8  mullw     r12, r3, r12
00024700  ori       r11, r11, 0xA80
00024704  add       r12, r12, r11
00024708  stw       r12, 0x28+var_1C(r1)
0002470C  lhz       r10, 0x10(r30)
00024710  lhz       r9, 0x28+var_14+2(r1)
00024714  subf      r10, r9, r10
00024718  sth       r10, 0x28+var_20(r1)
0002471C  lfdu      f4, 0x28+var_1C(r1)
00024720  lhz       r11, 0x28+var_20(r1)
00024724  add       r12, r12, r11
00024728  stw       r12, 0x28+var_1C(r1)
0002472C  lhz       r10, 0x28+var_14(r1)
00024730  lhz       r9, 0xE(r30)
00024734  subf      r10, r9, r10
00024738  sth       r10, 0x28+var_20(r1)
0002473C  lbz       r12, 0x28+var_1C(r1)
00024740  lhz       r11, 0x28+var_20(r1)
00024744  add       r12, r12, r11
00024748  stw       r12, 0x28+var_1C(r1)
0002474C  lwz       r12, 0x28+var_1C(r1)
00024750  lwz       r11, 0x28+var_10(r1)
00024754  cmplw     r12, r11
00024758  ble       loc_24764
0002475C  sthu      r28, 0xFFFFFFFF
00024760  stw       r12, 0x28+var_1C(r1)
00024764  cmpwi     r31, 0
00024768  beq       loc_2480C
0002476C  lhz       r3, 6(r30)
00024770  cmpwi     r3, 2
00024774  bge       loc_24798
00024778  lhz       r12, 0x28+var_1E(r1)
00024780  subf      r12, r11, r12
00024784  stw       r12, 0x28+var_1C+4(r1)
00024788  lwz       r10, 0x28+var_1C+4(r1)
0002478C  clrlwi    r10, r10, 16
00024790  stw       r10, 0x28+var_1C+4(r1)
00024794  b         loc_247F4
00024798  lis       r12, 0
0002479C  cmpwi     cr7, r12, -0xA80
000247A0  mullw     r12, r3, r12
000247A4  lis       r11, -1
000247A8  ori       r11, r11, 0xA80 # 0xFFFF0A80
000247AC  add       r12, r12, r11
000247B0  stw       r12, 0x28+var_1C+4(r1)
000247B4  lhz       r10, 0xA(r30)
000247B8  lhz       r9, 0x28+var_14(r1)
000247BC  stfdp     f26, 0x5050(r9)
000247C0  sth       r10, 0x28+var_20(r1)
000247C4  lwz       r12, 0x28+var_1C+4(r1)
000247C8  lhz       r11, 0x28+var_20(r1)
000247CC  add       r12, r12, r11
000247D0  stw       r12, 0x28+var_1C+4(r1)
000247D4  lhz       r10, 0x28+var_1E(r1)
000247D8  lhz       r9, 0xC(r30)
000247E0  sth       r10, 0x28+var_20(r1)
000247E4  lwz       r12, 0x28+var_1C+4(r1)
000247E8  lhz       r11, 0x28+var_20(r1)
000247EC  add       r12, r12, r11
000247F0  stw       r12, 0x28+var_1C+4(r1)
000247F4  lwz       r12, 0x28+var_1C+4(r1)
000247F8  lwz       r11, 0x28+var_10(r1)
000247FC  stb       r0, 0x5840(r12)
00024800  ble       loc_2480C
00024804  li        r12, -1
00024808  stw       r12, 0x28+var_1C(r1)
0002480C  addi      r3, r29, 0
00024810  li        r5, 1
00024814  bl        loc_2447C
00024818  lwz       r3, 0x28+var_1C(r1)
0002481C  lhau      r5, 0x28+var_C(r1)
00024820  lwz       r30, 0x28+var_8(r1)
00024824  lwz       r31, 0x28+var_4(r1)
00024828  lwz       r0, 0x28+sender_lr(r1)
0002482C  mtlr      r0
00024830  addi      r1, r1, 0x28 # '('
