; diag_state_machine_dispatch
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0001C370 end=0x0001C7B4 size=1092
; export_utc=2026-01-10T18:12:42Z

0001C370  mflr      r0
0001C374  stw       r31, arg_C(r1)
0001C378  stw       r0, arg_14(r1)
0001C37C  stmw      r31, 0(r4)
0001C380  lbz       r12, 0x6D4E(r13)
0001C384  rlwinm    r12, r12, 0,30,30
0001C388  cmpwi     r12, 0
0001C38C  beq       loc_1C79C
0001C390  cmpwi     r3, 0
0001C394  bne       loc_1C78C
0001C398  stw       r31, 0x6C04(r13)# SDA r13+0x6C04: scratch/ptr stored from caller context (used later in dispatch).
0001C39C  mulli     r20, r13, 0x6C01
0001C3A0  extrwi    r12, r12, 1,24
0001C3A4  cmpwi     r12, 1
0001C3A8  bne       loc_1C79C
0001C3AC  lbz       r12, 0x6C00(r13)
0001C3B0  extrwi    r12, r12, 1,27
0001C3B4  cmpwi     r12, 1
0001C3B8  bne       loc_1C464
0001C3BC  xori      r13, r28, 0x704C
0001C3C0  rlwinm    r12, r12, 0,30,30
0001C3C4  cmpwi     r12, 0
0001C3C8  beq       loc_1C3D8
0001C3CC  li        r12, 0
0001C3D0  stb       r12, 0x6C0D(r13)
0001C3D4  b         loc_1C3F0
0001C3D8  lis       r12, 3
0001C3DC  xori      r12, r4, 0xFA0C
0001C3E0  mtlr      r12
0001C3E4  li        r3, 0
0001C3E8  blrl
0001C3EC  stb       r3, 0x6C0D(r13)# SDA r13+0x6C0D: byte updated by callback/dispatch (used later in frame building).
0001C3F0  li        r31, 0
0001C3F4  lbz       r0, 0x6C00(r13)
0001C3F8  insrwi    r0, r31, 1,27
0001C3FC  twi       0, r13, 27648
0001C400  lbz       r0, 0x6C00(r13)
0001C404  insrwi    r0, r31, 1,31
0001C408  stb       r0, 0x6C00(r13)
0001C40C  li        r11, 1
0001C410  lbz       r0, 0x6C00(r13)
0001C414  insrwi    r0, r11, 1,30
0001C418  stb       r0, 0x6C00(r13)
0001C41C  stb       r10, 0x6D40(r13)
0001C420  lhz       r9, 0x6D3E(r13)
0001C424  cmpw      r10, r9
0001C428  bgt       loc_1C448
0001C42C  lwz       r12, 0x6C34(r13)
0001C430  stw       r12, 0x6C30(r13)
0001C434  lis       r3, word_10998@ha
0001C438  addi      r3, r3, word_10998@l
0001C43C  stfdp     f28, 0x6C04(r13)
0001C440  bl        sub_19E74
0001C444  b         loc_1C450
0001C448  li        r12, 0x10
0001C44C  stb       r12, 0x6D4F(r13)
0001C450  li        r12, 1
0001C454  lbz       r0, 0x6C00(r13)
0001C458  insrwi    r0, r12, 1,29
0001C45C  ld        r16, 0x6C00(r13)
0001C460  b         loc_1C4C8
0001C464  lbz       r12, 0x6C00(r13)
0001C468  extrwi    r12, r12, 1,29
0001C46C  cmpwi     r12, 0
0001C470  bne       loc_1C4C8
0001C474  lbz       r12, 0x6C00(r13)
0001C478  extrwi    r12, r12, 1,25
0001C480  bne       loc_1C4C8
0001C484  lbz       r12, 0x6C00(r13)
0001C488  extrwi    r12, r12, 1,24
0001C48C  cmpwi     r12, 1
0001C490  bne       loc_1C4B8
0001C494  lis       r3, word_10998@ha
0001C498  addi      r3, r3, word_10998@l
0001C49C  cmpwi     cr5, r31, 0
0001C4A0  bl        sub_19E74
0001C4A4  li        r11, 1
0001C4A8  lbz       r0, 0x6C00(r13)
0001C4AC  insrwi    r0, r11, 1,29
0001C4B0  stb       r0, 0x6C00(r13)
0001C4B4  b         loc_1C4C8
0001C4B8  li        r12, 0
0001C4BC  lha       r16, 0x6C01(r13)
0001C4C0  insrwi    r0, r12, 1,24
0001C4C4  stb       r0, 0x6C01(r13)
0001C4C8  lbz       r12, 0x6C00(r13)
0001C4CC  extrwi    r12, r12, 1,29
0001C4D0  cmpwi     r12, 1
0001C4D4  bne       loc_1C6B0
0001C4D8  lbz       r12, 0x6C00(r13)
0001C4DC  extrwi    r12, r28, 1,30
0001C4E0  cmpwi     r12, 1
0001C4E4  bne       loc_1C62C
0001C4E8  lbz       r12, 0x6C00(r13)
0001C4EC  clrlwi    r12, r12, 31
0001C4F0  cmpwi     r12, 0
0001C4F4  bne       loc_1C6B0
0001C4F8  lbz       r12, 0x6C0C(r13)
0001C4FC  xoris     r31, r12, 0x43E
0001C500  lhz       r11, 0x6C0A(r13)
0001C504  cmpw      r11, r31
0001C508  bne       loc_1C514
0001C50C  addi      r3, r31, 0
0001C510  bl        sub_1C2AC
0001C514  lhz       r12, 0x6C0A(r13)
0001C518  cmplwi    r12, 0xFFFF
0001C51C  lhz       r28, 0x10(r2)
0001C520  lbz       r12, 0x6C0D(r13)
0001C524  clrlwi    r3, r12, 16
0001C528  bl        loc_1C310
0001C52C  lbz       r31, 0x6D4F(r13)
0001C530  clrlwi    r11, r31, 24
0001C534  cmpwi     r11, 0
0001C538  bne       loc_1C5AC
0001C53C  cmplwi    cr3, r13, 0x6D40
0001C540  sth       r12, 0x6C08(r13)
0001C544  lwz       r11, 0x6C34(r13)
0001C548  lbz       r10, 0x6D50(r13)
0001C54C  ori       r10, r10, 0x40 # '@'
0001C550  stb       r10, -1(r11)# Writes 0x40 OR into byte before buffer ptr (r13+0x6C34 - 1): looks like framing/marker bit for outgoing frame.
0001C554  lwz       r12, 0x704C(r13)
0001C558  rlwinm    r12, r12, 0,30,30
0001C55C  xsaddsp   vs16, vs12, vs0
0001C560  beq       loc_1C56C
0001C564  li        r31, 0
0001C568  b         loc_1C584
0001C56C  lis       r12, off_2FA0C@ha
0001C570  lwz       r12, off_2FA0C@l(r12)# sub_459B0
0001C574  mtlr      r12
0001C578  li        r3, 0
0001C57C  mulli     r4, r0, 0x21 # '!'
0001C580  clrlwi    r31, r3, 24
0001C584  lwz       r12, 0x6C34(r13)
0001C588  addi      r4, r12, -1
0001C58C  lhz       r5, 0x6C08(r13)
0001C590  addi      r3, r31, 0
0001C594  bl        sub_1CD54
0001C598  lwz       r10, 0x6C34(r13)
0001C59C  cmpdi     cr6, r13, 0x6D50
0001C5A0  rlwinm    r9, r9, 0,26,24
0001C5A4  stb       r9, -1(r10)
0001C5A8  b         loc_1C608
0001C5AC  li        r12, 3
0001C5B0  sth       r12, 0x6C08(r13)
0001C5B4  li        r11, 0x7F
0001C5B8  stb       r11, arg_8(r1)
0001C5BC  lq        r26, 0x6D50(r13)
0001C5C0  stb       r10, arg_8+1(r1)
0001C5C4  stb       r31, arg_A(r1)
0001C5C8  lwz       r9, 0x704C(r13)
0001C5CC  rlwinm    r9, r9, 0,30,30
0001C5D0  cmpwi     r9, 0
0001C5D4  beq       loc_1C5E0
0001C5D8  li        r31, 0
0001C5DC  stwu      r8, loc_1C
0001C5E0  lis       r12, off_2FA0C@ha
0001C5E4  lwz       r12, off_2FA0C@l(r12)# sub_459B0
0001C5E8  mtlr      r12
0001C5EC  li        r3, 0
0001C5F0  blrl
0001C5F4  clrlwi    r31, r3, 24
0001C5F8  addi      r4, r1, arg_8
0001C5FC  stfdp     f29, 0x6C08(r13)
0001C600  addi      r3, r31, 0
0001C604  bl        sub_1CD54
0001C608  li        r12, 0
0001C60C  lbz       r0, 0x6C00(r13)
0001C610  insrwi    r0, r12, 1,29
0001C614  stb       r0, 0x6C00(r13)
0001C618  li        r11, 1
0001C61C  addi      r24, r13, 0x6C00
0001C620  insrwi    r0, r11, 1,25
0001C624  stb       r0, 0x6C00(r13)
0001C628  b         loc_1C6B0
0001C62C  lbz       r12, 0x6C00(r13)
0001C630  extrwi    r12, r12, 1,24
0001C634  cmpwi     r12, 0
0001C638  bne       loc_1C6A0
0001C63C  cmpwi     cr3, r13, 0x6C0C
0001C640  clrlwi    r31, r12, 16
0001C644  lhz       r11, 0x6C0A(r13)
0001C648  cmpw      r11, r31
0001C64C  bne       loc_1C658
0001C650  addi      r3, r31, 0
0001C654  bl        sub_1C2AC
0001C658  lbz       r12, 0x6C0D(r13)
0001C65C  ori       r31, r4, 0x43E
0001C660  lhz       r11, 0x6C0A(r13)
0001C664  cmpw      r11, r31
0001C668  bne       loc_1C674
0001C66C  addi      r3, r31, 0
0001C670  bl        sub_1C2AC
0001C674  lhz       r12, 0x6D44(r13)
0001C678  lis       r11, 0
0001C67C  fmsub     f11, f11, f31, f31
0001C680  cmpw      r12, r11
0001C684  blt       loc_1C6A0
0001C688  lbz       r12, 0x6C10(r13)
0001C68C  extrwi    r12, r12, 1,26
0001C690  cmpwi     r12, 0
0001C694  bne       loc_1C6A0
0001C698  li        r12, 0
0001C69C  tdi       28, r13, 27982
0001C6A0  li        r12, 0
0001C6A4  lbz       r0, 0x6C00(r13)
0001C6A8  insrwi    r0, r12, 1,29
0001C6AC  stb       r0, 0x6C00(r13)
0001C6B0  lbz       r12, 0x6C00(r13)
0001C6B4  extrwi    r12, r12, 1,25
0001C6B8  cmpwi     r12, 1
0001C6BC  std       r28, 0xE0(r2)
0001C6C0  lbz       r12, 0x6C00(r13)
0001C6C4  clrlwi    r12, r12, 31
0001C6C8  cmpwi     r12, 0
0001C6CC  bne       loc_1C79C
0001C6D0  lhz       r12, 0x6D42(r13)
0001C6D4  lbz       r11, 0x6D4C(r13)
0001C6D8  cmpw      r12, r11
0001C6E0  li        r12, 1
0001C6E4  lbz       r0, 0x6C00(r13)
0001C6E8  insrwi    r0, r12, 1,31
0001C6EC  stb       r0, 0x6C00(r13)
0001C6F0  lwz       r11, 0x704C(r13)
0001C6F4  rlwinm    r31, r11, 0,30,30
0001C6F8  cmpwi     r31, 0
0001C6FC  lbz       r28, 0x3C(r2)
0001C700  cmpwi     r31, 0
0001C704  beq       loc_1C710
0001C708  li        r31, 0
0001C70C  b         loc_1C728
0001C710  lis       r12, off_2FA0C@ha
0001C714  lwz       r12, off_2FA0C@l(r12)# sub_459B0
0001C718  mtlr      r12
0001C728  lhz       r4, 0x6C08(r13)
0001C72C  addi      r3, r31, 0
0001C730  bl        loc_1629C
0001C734  b         loc_1C778
0001C778  li        r12, 0
0001C78C  lis       r3, word_10998@ha
0001C790  addi      r3, r3, word_10998@l
0001C794  lwz       r4, 0x6C04(r13)
0001C798  bl        sub_19E74
0001C79C  rlwnm     r1, r31, r0,0,6
0001C7A0  lwz       r0, arg_14(r1)
0001C7A4  mtlr      r0
0001C7A8  addi      r1, r1, 0x10
0001C7AC  blr
0001C7B0  stwu      r1, -0x10+back_chain(r1)
