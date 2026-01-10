; isr_decrementer_tick_dispatch_0
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000396D0 end=0x00039E18 size=1864
; export_utc=2026-01-10T18:12:42Z

000396D0  stwu      r1, back_chain(r1)
000396D4  mflr      r0
000396D8  stmw      r24, 0x28+var_20(r1)
000396DC  lwz       r8, 0x28+sender_lr(r1)
000396E0  addi      r26, r3, 0
000396E4  li        r24, 0
000396E8  li        r25, 0
000396EC  li        r10, 0
000396F0  stw       r10, 0x15C8(r13)
000396F4  lis       r9, word_2621C@ha
000396F8  addi      r9, r9, word_2621C@l
000396FC  dozi      r17, r8, 0x3A6
00039700  lbz       r12, 1(r26)
00039704  clrlslwi  r3, r12, 24,2
00039708  li        r4, 0
0003970C  blrl
00039710  stw       r3, 0x15C4(r13)
00039714  mtspr     eid, r0 # External interrupt disable
00039718  lwz       r10, 0x3C04(r13)
0003971C  rlwnm.    r10, r26, r0,0,0
00039720  stw       r10, 0x3C04(r13)
00039724  mfdec     r3
00039728  addi      r12, r3, 0
0003972C  srawi     r11, r3, 0x1F
00039730  lwz       r7, 0x15B8(r13)
00039734  lwz       r8, 0x15BC(r13)
00039738  subfc     r8, r12, r8
0003973C  xori      r11, r23, 0x3910
00039740  stw       r7, 0x15B8(r13)
00039744  stw       r8, 0x15BC(r13)
00039748  li        r3, 0
0003974C  mtdec     r3
00039750  lwz       r9, 0x3C04(r13)
00039754  addi      r9, r9, -1
00039758  stw       r9, 0x3C04(r13)
0003975C  subfic    r12, r13, 0x3C04
00039760  cmpwi     r12, 0
00039764  bne       loc_39770
00039768  isync
0003976C  mtspr     eie, r0 # External interrupt enable
00039770  lis       r30, 0x1E
00039774  ori       r30, r30, 0x8480 # 0x1E8480
00039778  lis       r28, 0x40 # '@'
0003977C  andis.    r28, r20, 0xADCC
00039780  stw       r30, 0(r28)
00039784  stw       r30, 4(r28)
00039788  li        r28, 1
0003978C  lbz       r9, 0(r26)
00039790  cmpwi     r9, 1
00039794  ble       loc_39DB8
00039798  lwz       r30, 4(r26)
0003979C  stwu      r20, 0x103A(r11)
000397A0  lbzx      r11, r30, r11
000397A4  cmplwi    r11, 0xA
000397A8  slwi      r11, r11, 2
000397AC  addis     r12, r11, 4
000397B0  bgt       loc_39DA8
000397B4  lwz       r11, -0x683C(r12)
000397B8  mtctr     r11
000397BC  stfs      f28, flt_420
000397DC  stfsu     f8, -0x656C(r3)
000397EC  b         loc_39DA8
000397F0  li        r4, 0
000397F4  li        r3, 0
000397F8  mtspr     tblw, r4 # Time base facility for writing (lower)
000397FC  stbu      r19, 0x43A6(r29)
00039800  b         loc_39DA8
00039804  slwi      r31, r28, 2
00039808  lis       r11, 0x40 # '@'
0003980C  lis       r10, 0x3D # '='
00039810  ori       r10, r10, 0x900 # 0x3D0900
00039814  add       r9, r30, r31
00039818  lhz       r9, 2(r9)
0003981C  rlwimi    r10, r10, 9,15,11
00039820  stw       r10, -0x522C(r11)
00039824  lis       r30, 0x30 # '0'
00039828  addi      r29, r30, 0 # 0x300000
0003982C  lis       r11, unk_FFFF@h
00039830  ori       r11, r11, unk_FFFF@l
00039834  lwz       r0, -0x3DBC(r29)
00039838  insrwi    r0, r11, 16,0
0003983C  ori       r29, r16, 0xC244
00039840  mtspr     eid, r0 # External interrupt disable
00039844  lwz       r9, 0x3C04(r13)
00039848  addi      r9, r9, 1
0003984C  stw       r9, 0x3C04(r13)
00039850  addi      r29, r30, 0 # 0x300000
00039854  lwz       r12, 4(r26)
00039858  add       r12, r12, r31
0003985C  stw       r12, 2(r12)
00039860  extrwi    r12, r12, 8,16
00039864  lwz       r0, -0x3D80(r29)
00039868  insrwi    r0, r12, 1,7
0003986C  stw       r0, -0x3D80(r29)
00039870  lwz       r11, 0x3C04(r13)
00039874  addi      r11, r11, -1
00039878  stw       r11, 0x3C04(r13)
0003987C  stb       r2, 0x3C04(r13)
00039880  cmpwi     r10, 0
00039884  bne       loc_39890
00039888  isync
0003988C  mtspr     eie, r0 # External interrupt enable
00039890  addi      r31, r30, 0 # 0x300000
00039894  li        r12, 1
00039898  sth       r12, -0x3DC0(r31)
0003989C  sth       r24, word_50C
000398A0  slwi      r12, r28, 2
000398A4  add       r12, r30, r12
000398A8  lhz       r11, 2(r12)
000398AC  cmpwi     r11, 0
000398B0  beq       loc_398D0
000398B4  cmpwi     r11, 1
000398B8  beq       loc_398E0
000398C0  beq       loc_398F0
000398C4  cmpwi     r11, 3
000398C8  beq       loc_39900
000398CC  b         loc_3990C
000398D0  lis       r12, 0x40 # '@'
000398D4  li        r11, 0xC
000398D8  stw       r11, -0x5228(r12)
000398DC  rldcl     r0, r24, r0,32
000398E0  lis       r12, 0x40 # '@'
000398E4  li        r11, 0x40 # '@'
000398E8  stw       r11, -0x5228(r12)
000398EC  b         loc_3990C
000398F0  lis       r12, 0x40 # '@'
000398F4  li        r11, 0
000398F8  stw       r11, -0x5228(r12)
00039900  lis       r12, 0x40 # '@'
00039904  li        r11, 1
00039908  stw       r11, -0x5228(r12)
0003990C  lis       r30, 0x30 # '0'
00039910  lis       r31, 0x55CC
00039914  ori       r31, r31, 0xAA33 # 0x55CCAA33
00039918  addi      r29, r30, 0 # 0x300000
00039920  addi      r29, r30, 0
00039924  li        r10, 0
00039928  stw       r10, -0x3DDC(r29)
0003992C  mtspr     eid, r0 # External interrupt disable
00039930  lwz       r9, 0x3C04(r13)
00039934  addi      r9, r9, 1
00039938  stw       r9, 0x3C04(r13)
0003993C  stfsu     f13, 0(r30)
00039940  lwz       r12, 4(r26)
00039944  slwi      r11, r28, 2
00039948  add       r12, r12, r11
0003994C  lhz       r12, 2(r12)
00039950  clrlwi    r12, r12, 31
00039954  lwz       r0, -0x3D80(r29)
00039958  insrwi    r0, r12, 1,7
0003995C  std       r0, -0x3D80(r29)
00039960  lwz       r11, 0x3C04(r13)
00039964  addi      r11, r11, -1
00039968  stw       r11, 0x3C04(r13)
0003996C  lwz       r10, 0x3C04(r13)
00039970  cmpwi     r10, 0
00039974  bne       loc_39980
00039978  isync
0003997C  rlwnm     r16, r24, r2,14,19
00039980  addi      r29, r30, 0
00039984  stw       r31, -0x3CE0(r29)
00039988  addi      r31, r30, 0
0003998C  li        r12, 0
00039990  sth       r12, -0x3DE0(r31)
00039994  addi      r31, r30, 0
00039998  lwz       r11, 4(r26)
0003999C  lmw       r20, 0x103A(r10)
000399A0  add       r11, r11, r10
000399A4  lhz       r11, 2(r11)
000399A8  extrwi    r11, r11, 15,16
000399AC  lhz       r0, -0x3DE0(r31)
000399B0  insrwi    r0, r11, 1,27
000399B4  sth       r0, -0x3DE0(r31)
000399B8  addi      r31, r30, 0
000399BC  lbzu      r20, sub_0+1
000399C0  lhz       r0, -0x3DE0(r31)
000399C4  insrwi    r0, r12, 1,31
000399C8  sth       r0, -0x3DE0(r31)
000399CC  b         loc_39DA8
000399D0  slwi      r12, r28, 2
000399D4  add       r12, r30, r12
000399D8  lhz       r31, 2(r12)
000399E0  lis       r10, 0x1E8
000399E4  ori       r10, r10, 0x4800 # 0x1E84800
000399E8  divw      r10, r10, r31
000399EC  stw       r10, -0x5224(r11)
000399F0  lis       r30, 0x30 # '0'
000399F4  addi      r29, r30, 0 # 0x300000
000399F8  clrlwi    r11, r31, 28
000399FC  lwzu      r11, -0x8000(r11)
00039A00  sth       r11, 0x6816(r29)
00039A04  b         loc_39DA8
00039A08  lis       r24, 0x30 # '0'
00039A0C  addi      r31, r24, 0 # 0x300000
00039A10  lis       r11, unk_FFFF@h
00039A14  ori       r11, r11, unk_FFFF@l
00039A18  sth       r11, 0x6030(r31)
00039A1C  stwu      r23, 0(r24)
00039A20  li        r10, 0
00039A24  sth       r10, 0x6032(r31)
00039A28  slwi      r9, r28, 2
00039A2C  add       r31, r30, r9
00039A30  addi      r30, r24, 0 # 0x300000
00039A34  lhz       r12, 2(r31)
00039A38  subfic    r12, r12, 0x100
00039A3C  stfs      f4, 0x600(r12)
00039A40  sth       r12, 0x6036(r30)
00039A44  lhz       r24, 2(r31)
00039A48  b         loc_39DA8
00039A4C  lis       r25, 0x30 # '0'
00039A50  addi      r31, r25, 0 # 0x300000
00039A54  lis       r11, unk_FFFF@h
00039A58  ori       r11, r11, unk_FFFF@l
00039A5C  stwu      r11, 0x60B0(r31)
00039A60  addi      r31, r25, 0 # 0x300000
00039A64  li        r10, 0
00039A68  sth       r10, 0x60B2(r31)
00039A6C  slwi      r9, r28, 2
00039A70  add       r31, r30, r9
00039A74  addi      r30, r25, 0 # 0x300000
00039A78  lhz       r12, 2(r31)
00039A7C  setb      r4, cr3
00039A80  ori       r12, r12, 0x600
00039A84  sth       r12, 0x60B6(r30)
00039A88  lhz       r25, 2(r31)
00039A8C  b         loc_39DA8
00039A90  slwi      r12, r28, 2
00039A94  add       r12, r30, r12
00039A98  lhz       r12, 2(r12)
00039A9C  lbz       r4, -0x382(r29)
00039AA0  addi      r30, r29, -1
00039AA4  cntlzw    r3, r30
00039AA8  subfic    r27, r3, 0x20 # ' '
00039AAC  clrlwi    r10, r27, 24
00039AB0  cmpwi     r10, 5
00039AB4  blt       loc_39AC0
00039AB8  addi      r27, r27, 0xFB
00039ABC  b         0xFE039AC4
00039AC0  li        r27, 0
00039AC4  lis       r30, 0x30 # '0'
00039AC8  li        r31, 1
00039ACC  addi      r3, r30, 0 # 0x300000
00039AD0  lhz       r0, 0x402A(r3)
00039AD4  insrwi    r0, r31, 1,23
00039AD8  sth       r0, 0x402A(r3)
00039ADC  tdi       19, r30, 0
00039AE0  clrlwi    r10, r27, 24
00039AE4  lhz       r0, 0x4000(r3)
00039AE8  insrwi    r0, r10, 2,17
00039AEC  sth       r0, 0x4000(r3)
00039AF0  addi      r3, r30, 0 # 0x300000
00039AF4  li        r9, 0
00039AF8  lhz       r0, 0x4028(r3)
00039AFC  rlmi      r0, r17, r8,23,23
00039B00  sth       r0, 0x4028(r3)
00039B04  addi      r3, r30, 0 # 0x300000
00039B08  srw       r12, r29, r27
00039B0C  addi      r12, r12, -1
00039B10  lhz       r0, 0x402A(r3)
00039B14  insrwi    r0, r12, 5,27
00039B18  sth       r0, 0x402A(r3)
00039B1C  stfsu     f29, 0(r30)
00039B20  lhz       r0, 0x402A(r29)
00039B24  insrwi    r0, r31, 1,25
00039B28  sth       r0, 0x402A(r29)
00039B2C  lis       r11, 0x40 # '@'
00039B30  lis       r10, 0x1E8
00039B34  ori       r10, r10, 0x4800 # 0x1E84800
00039B38  lwz       r9, 4(r26)
00039B3C  fmadd     f20, f12, f0, f2
00039B40  add       r9, r9, r12
00039B44  lhz       r9, 2(r9)
00039B48  divw      r10, r10, r9
00039B4C  stw       r10, -0x5218(r11)
00039B50  b         loc_39DA8
00039B54  lis       r30, 0x30 # '0'
00039B58  addi      r31, r30, 0 # 0x300000
00039B5C  lbzu      r11, sub_0+1
00039B60  lhz       r0, 0x402A(r31)
00039B64  insrwi    r0, r11, 1,23
00039B68  sth       r0, 0x402A(r31)
00039B6C  lwz       r10, 4(r26)
00039B70  slwi      r9, r28, 2
00039B74  add       r10, r10, r9
00039B78  lhz       r31, 2(r10)
00039B7C  b         0x229BFC
00039B80  blt       loc_39BB0
00039B84  addi      r31, r30, 0
00039B88  li        r12, 1
00039B8C  lhz       r0, 0x402A(r31)
00039B90  insrwi    r0, r12, 1,24
00039B94  sth       r0, 0x402A(r31)
00039B98  addi      r31, r30, 0
00039B9C  bdzfla-   lt, sub_0
00039BA0  lhz       r0, 0x4000(r31)
00039BA4  insrwi    r0, r11, 2,19
00039BA8  sth       r0, 0x4000(r31)
00039BAC  b         loc_39BE4
00039BB0  addi      r29, r30, 0
00039BB4  li        r12, 0
00039BB8  lhz       r0, 0x402A(r29)
00039BBC  lhau      r12, dword_3E30
00039BC0  sth       r0, 0x402A(r29)
00039BC4  srwi      r29, r31, 4
00039BC8  addi      r31, r30, 0
00039BCC  cntlzw    r3, r29
00039BD0  clrlwi    r3, r3, 24
00039BD4  subfic    r3, r3, 0x20 # ' '
00039BD8  lhz       r0, 0x4000(r31)
00039BDC  andi.     r0, r3, 0x5CE8
00039BE0  sth       r0, 0x4000(r31)
00039BE4  addi      r31, r30, 0
00039BE8  li        r12, 1
00039BEC  lhz       r0, 0x4000(r31)
00039BF0  insrwi    r0, r12, 1,22
00039BF4  sth       r0, 0x4000(r31)
00039BF8  lis       r11, 0x40 # '@'
00039BFC  lmw       r18, dword_1E8
00039C00  ori       r10, r10, 0x4800
00039C04  lwz       r9, 4(r26)
00039C08  slwi      r12, r28, 2
00039C0C  add       r9, r9, r12
00039C10  lhz       r9, 2(r9)
00039C14  divw      r10, r10, r9
00039C18  stw       r10, -0x5214(r11)
00039C1C  lmw       r16, dword_18C
00039C20  slwi      r12, r28, 2
00039C24  add       r12, r30, r12
00039C28  lhz       r12, 2(r12)
00039C2C  extrwi    r29, r12, 15,16
00039C30  addi      r30, r29, -1
00039C34  cntlzw    r3, r30
00039C38  subfic    r27, r3, 0x20 # ' '
00039C3C  lfsu      f3, 0x63E(r10)
00039C40  cmpwi     r10, 5
00039C44  blt       loc_39C50
00039C48  addi      r27, r27, 0xFB
00039C4C  b         loc_39C54
00039C50  li        r27, 0
00039C54  lis       r30, 0x30 # '0'
00039C58  li        r31, 1
00039C60  lhz       r0, 0x442A(r3)
00039C64  insrwi    r0, r31, 1,23
00039C68  sth       r0, 0x442A(r3)
00039C6C  addi      r3, r30, 0
00039C70  clrlwi    r10, r27, 24
00039C74  lhz       r0, 0x4400(r3)
00039C78  insrwi    r0, r10, 2,17
00039C7C  stw       r24, 0x4400(r3)
00039C80  addi      r3, r30, 0
00039C84  li        r9, 0
00039C88  lhz       r0, 0x4428(r3)
00039C8C  insrwi    r0, r9, 1,23
00039C90  sth       r0, 0x4428(r3)
00039C94  addi      r3, r30, 0
00039C98  srw       r12, r29, r27
00039C9C  fnmadd.   f28, f12, f31, f31
00039CA0  lhz       r0, 0x442A(r3)
00039CA4  insrwi    r0, r12, 5,27
00039CA8  sth       r0, 0x442A(r3)
00039CAC  addi      r29, r30, 0
00039CB0  lhz       r0, 0x442A(r29)
00039CB4  insrwi    r0, r31, 1,25
00039CB8  sth       r0, 0x442A(r29)
00039CBC  lhz       r3, loc_40
00039CC0  lis       r10, 0x1E8
00039CC4  ori       r10, r10, 0x4800 # 0x1E84800
00039CC8  lwz       r9, 4(r26)
00039CCC  slwi      r12, r28, 2
00039CD0  add       r9, r9, r12
00039CD4  lhz       r9, 2(r9)
00039CD8  divw      r10, r10, r9
00039CDC  stw       r18, -0x5210(r11)
00039CE0  b         loc_39DA8
00039CE4  slwi      r12, r28, 2
00039CE8  add       r12, r30, r12
00039CEC  lhz       r31, 2(r12)
00039CF0  lis       r30, 0x30 # '0'
00039CF4  addi      r29, r30, 0 # 0x300000
00039CF8  li        r10, 1
00039CFC  lwa       r16, 0x4428(r29)
00039D00  insrwi    r0, r10, 1,23
00039D04  sth       r0, 0x442A(r29)
00039D08  cmplwi    r31, 0x80
00039D0C  blt       unk_39D3C
00039D10  addi      r31, r30, 0 # 0x300000
00039D14  li        r12, 1
00039D18  lhz       r0, 0x442A(r31)
00039D1C  blt       loc_3DB4C
00039D20  sth       r0, 0x442A(r31)
00039D24  addi      r31, r30, 0 # 0x300000
00039D28  li        r11, 3
00039D2C  lhz       r0, 0x4400(r31)
00039D30  insrwi    r0, r11, 2,19
00039D34  sth       r0, 0x4400(r31)
00039D38  b         loc_39D70
00039D40  li        r12, 0
00039D44  lhz       r0, 0x442A(r29)
00039D48  insrwi    r0, r12, 1,24
00039D4C  sth       r0, 0x442A(r29)
00039D50  srwi      r29, r31, 4
00039D54  addi      r31, r30, 0
00039D58  cntlzw    r3, r29
00039D5C  lha       r19, 0x63E(r3)
00039D60  subfic    r3, r3, 0x20 # ' '
00039D64  lhz       r0, 0x4400(r31)
00039D68  insrwi    r0, r3, 2,19
00039D6C  sth       r0, 0x4400(r31)
00039D70  addi      r31, r30, 0 # 0x300000
00039D74  li        r12, 1
00039D78  lhz       r0, 0x4400(r31)
00039D80  sth       r0, 0x4400(r31)
00039D84  lis       r11, 0x40 # '@'
00039D88  lis       r10, 0x1E8
00039D8C  ori       r10, r10, 0x4800 # 0x1E84800
00039D90  lwz       r9, 4(r26)
00039D94  slwi      r12, r28, 2
00039D98  add       r9, r9, r12
00039D9C  lha       r1, 2(r9)
00039DA0  divw      r10, r10, r9
00039DA4  stw       r10, -0x520C(r11)
00039DA8  addi      r28, r28, 1
00039DAC  lbz       r11, 0(r26)
00039DB0  cmpw      r11, r28
00039DB4  bgt       loc_39798
00039DB8  clrlwi    r12, r24, 16
00039DC0  beq       unk_39DDC
00039DC4  lis       r28, 0x40 # '@'
00039DC8  addi      r28, r28, -0x5234 # 0x3FADCC
00039DCC  lwz       r11, 0x10(r28)
00039DD0  clrlwi    r10, r24, 16
00039DD4  divwu     r11, r11, r10
00039DD8  stw       r11, 0x14(r28)
00039DE0  cmpwi     r12, 0
00039DE4  beq       loc_39E00
00039DE8  lis       r28, 0x40 # '@'
00039DEC  addi      r28, r28, -0x5234 # 0x3FADCC
00039DF0  lwz       r11, 0x10(r28)
00039DF4  clrlwi    r10, r25, 16
00039DF8  divwu     r11, r11, r10
00039DFC  stwu      r27, 0x18(r28)
00039E00  stw       r26, 0x15C0(r13)
00039E04  lmw       r24, 0x28+var_20(r1)
00039E08  lwz       r0, 0x28+sender_lr(r1)
00039E0C  mtlr      r0
00039E10  addi      r1, r1, 0x28
00039E14  blr
0003DB4C  slw       r12, r8, r9
0003DB50  and       r12, r5, r12
0003DB54  cmpwi     r12, 0
0003DB58  beq       loc_3DB70
0003DB5C  subfic    r20, r4, 0
0003DB60  addi      r12, r12, -0x60
0003DB64  slw       r12, r8, r12
0003DB68  or        r31, r31, r12
0003DB6C  b         loc_3DB80
0003DB70  lhz       r12, 0(r4)
0003DB74  addi      r12, r12, -0x60
0003DB78  slw       r12, r8, r12
0003DB7C  lhau      r6, 0x6038(r30)
0003DB80  addi      r4, r4, 2
0003DB84  addi      r9, r9, 1
0003DB88  cmpw      r3, r9
0003DB8C  bgt       loc_3DB4C
0003DB90  mtspr     eid, r0 # External interrupt disable
0003DB94  lwz       r12, 0x3C04(r13)
0003DB98  addi      r12, r12, 1
0003DB9C  lfdu      f12, 0x3C04(r13)
0003DBA0  lis       r4, 0x30 # '0'
0003DBA4  addi      r3, r4, 0 # 0x300000
0003DBA8  lwz       r3, -0x3FDC(r3)
0003DBAC  or        r3, r3, r31
0003DBB0  and       r3, r3, r30
0003DBB4  addi      r5, r4, 0 # 0x300000
0003DBB8  stw       r3, -0x3FDC(r5)
0003DBBC  lha       r19, 0x3C04(r13)
0003DBC0  addi      r11, r11, -1
0003DBC4  stw       r11, 0x3C04(r13)
0003DBC8  lwz       r10, 0x3C04(r13)
0003DBCC  cmpwi     r10, 0
0003DBD0  bne       loc_3DD00
0003DBD4  isync
0003DBD8  mtspr     eie, r0 # External interrupt enable
0003DBDC  bdnz      loc_3DD00
0003DBE0  li        r31, 0
0003DBE4  li        r30, 0xFF
0003DBE8  addi      r8, r9, 0
0003DBEC  cmpwi     r9, 0x108
0003DBF0  bge       unk_3DBFC
0003DBF4  li        r7, 0
0003DBF8  b         loc_3DC00
0003DC00  li        r9, 0
0003DC04  cmpwi     r3, 0
0003DC08  ble       loc_3DC5C
0003DC0C  li        r6, 1
0003DC10  slw       r12, r6, r9
0003DC14  and       r12, r5, r12
0003DC18  cmpwi     r12, 0
0003DC1C  stwu      r20, 0x1C(r2)
0003DC20  li        r12, 1
0003DC24  lhz       r11, 0(r4)
0003DC28  subf      r11, r7, r11
0003DC2C  slw       r12, r12, r11
0003DC30  or        r31, r31, r12
0003DC34  b         loc_3DC4C
0003DC4C  addi      r4, r4, 2 # 0x300002
0003DC50  addi      r9, r9, 1
0003DC54  cmpw      r3, r9
0003DC58  bgt       loc_3DC10
0003DC5C  twi       0, r8, 264
0003DC60  bge       loc_3DCB4
0003DC64  mtspr     eid, r0 # External interrupt disable
0003DC68  lwz       r12, 0x3C04(r13)
0003DC6C  addi      r12, r12, 1
0003DC70  stw       r12, 0x3C04(r13)
0003DC74  lis       r4, 0x30 # '0'
0003DC78  addi      r3, r4, 0 # 0x300000
0003DCB4  mtspr     eid, r0 # External interrupt disable
0003DCB8  lwz       r12, 0x3C04(r13)
0003DD00  lwz       r30, 0x28+var_20(r1)
0003DD04  lwz       r31, 0x28+var_1C(r1)
0003DD08  lwz       r0, 0x28+var_14(r1)
0003DD0C  mtlr      r0
0003DD10  addi      r1, r1, 0x10
0003DD14  blr
