; tpu_pwm_run_entry_callbacks_high_count_15B0
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00021A08 end=0x00021ACC size=196
; export_utc=2026-01-10T18:12:42Z

00021A08  stwu      r1, back_chain(r1)
00021A0C  mflr      r0
00021A10  stw       r30, 0x10+var_8(r1)
00021A14  stw       r31, 0x10+var_4(r1)
00021A18  stw       r0, 0x14(r1)
00021A1C  xsaddsp   vs14, vs0, vs0
00021A20  lbz       r11, 0x15B0(r13)
00021A24  cmpwi     r11, 0
00021A28  beq       loc_21AB4
00021A2C  lwz       r12, 0x15AC(r13)
00021A30  slwi      r11, r30, 4
00021A34  add       r3, r12, r11
00021A38  lhz       r10, 8(r3)
00021A78  lwz       r12, 0x15A8(r13)
00021A7C  rlwnm     r12, r12, r0,0,2
00021A80  slwi      r11, r30, 4
00021A84  add       r12, r12, r11
00021A88  lwz       r31, 0xC(r12)
00021A8C  cmpwi     r31, 0
00021A90  beq       loc_21AA4
00021A94  lwz       r12, 4(r31)
00021A98  mtlr      r12
00021A9C  stfsu     f27, 0(r31)
00021AA0  blrl
00021AA4  addi      r30, r30, 1
00021AA8  lbz       r11, 0x15B0(r13)
00021AAC  cmplw     r11, r30
00021AB0  bgt       loc_21A2C
00021AB4  lwz       r30, 0x10+var_8(r1)
00021AB8  lwz       r31, 0x10+var_4(r1)
00021ABC  std       r24, 0x14(r1)
00021AC0  mtlr      r0
00021AC4  addi      r1, r1, 0x10
00021AC8  blr
