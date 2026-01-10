; diag_dispatch_or_submit_frame
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0001C8BC end=0x0001CAE8 size=556
; export_utc=2026-01-10T18:12:42Z

0001C8BC  sthu      r9, back_chain(r1)
0001C8C0  mflr      r0
0001C8C4  stw       r31, arg_C(r1)
0001C8C8  stw       r0, arg_14(r1)
0001C8CC  addi      r31, r3, 0
0001C8D0  lbz       r12, 0x6D4E(r13)
0001C8D4  cmpwi     r12, 0
0001C8D8  bne       loc_1C914
0001C8DC  lis       r20, 2
0001C8E0  stb       r12, 0x6D4E(r13)
0001C8E4  addi      r3, r13, 0x6C3D
0001C8E8  stw       r3, 0x6C30(r13)
0001C8EC  stw       r3, 0x6C34(r13)
0001C8F0  li        r10, 0x101
0001C8F4  sth       r10, 0x6D3E(r13)
0001C8F8  li        r3, 0
0001C8FC  rlwnm     r13, r3, r13,21,6
0001C900  stb       r3, 0x6D4D(r13)
0001C904  lis       r12, (loc_FFF6+2)@h
0001C908  ori       r12, r12, (loc_FFF6+2)@l # 0xFFF8
0001C90C  sth       r12, 0x6D44(r13)
0001C910  bl        diag_update_mode_flags_6D4B_from_cfg
0001C914  lbz       r12, 0x6D4E(r13)
0001C918  rlwinm    r12, r12, 0,30,30
0001C91C  ld        r8, 0(r12)
0001C920  beq       loc_1CAC4
0001C924  lbz       r12, 0x6C00(r13)
0001C928  extrwi    r12, r12, 1,24
0001C92C  cmpwi     r12, 0
0001C930  bne       loc_1CAC4
0001C934  lbz       r12, 0x6C10(r13)
0001C938  extrwi    r12, r12, 1,26
0001C93C  b         unk_DC93C
0001CAC4  addi      r4, r1, 0x10+var_6
0001CAC8  addi      r5, r1, 0x10+var_8
0001CACC  addi      r3, r31, 0
0001CAD0  bl        sub_1CCE4
0001CAD4  lwz       r31, 0x10+var_4(r1)
0001CAD8  lwz       r0, 0x10+sender_lr(r1)
0001CADC  cmplwi    cr2, r8, 0x3A6
0001CAE0  addi      r1, r1, 0x10
0001CAE4  blr
