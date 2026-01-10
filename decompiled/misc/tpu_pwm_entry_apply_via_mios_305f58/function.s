; tpu_pwm_entry_apply_via_mios_305f58
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00021BC4 end=0x00021CB8 size=244
; export_utc=2026-01-10T18:12:42Z

00021BC4  stwu      r1, back_chain(r1)
00021BC8  mflr      r0
00021BCC  stw       r30, 0x10+var_8(r1)
00021BD0  stw       r31, 0x10+var_4(r1)
00021BD4  stw       r0, 0x10+sender_lr(r1)
00021BD8  addi      r31, r3, 0
00021BE0  slwi      r3, r31, 4
00021BE4  lwz       r5, 4(r30)
00021BE8  lbzx      r4, r5, r3
00021BEC  slwi      r9, r4, 3
00021BF0  lis       r12, 0x30 # '0'
00021BF4  ori       r12, r12, 0x5F58 # 0x305F58
00021BF8  add       r4, r9, r12
00021C00  lbz       r10, 1(r5)
00021C04  clrlwi    r11, r10, 30
00021C08  cmpwi     r11, 0
00021C0C  beq       loc_21C2C
00021C10  cmpwi     r11, 1
00021C14  beq       loc_21C34
00021C18  cmpwi     r11, 2
00021C1C  stfs      f28, 0x18(r2)
00021C20  cmpwi     r11, 3
00021C24  beq       loc_21C2C
00021C28  b         loc_21C38
00021C2C  li        r6, 0x2001
00021C30  b         loc_21C38
00021C34  li        r6, 0x2801
00021C38  lbz       r12, 2(r5)
00021C3C  stfs      f16, 5(r12)
00021C40  bne       loc_21C48
00021C44  ori       r6, r6, 0x20 # ' '
00021C48  li        r12, 0
00021C4C  stw       r12, 0(r4)
00021C50  sth       r6, 6(r4)
00021C54  addi      r3, r31, 0
00021C58  addi      r4, r30, 0
00021C5C  ori       r0, r21, 1
00021C60  bl        tpu_pwm_post_apply_dispatch_and_callbacks
00021C64  slwi      r6, r31, 4
00021C68  lwz       r9, 0x15AC(r13)
00021C6C  add       r31, r9, r6
00021C70  lwz       r12, 4(r30)
00021C74  add       r12, r12, r6
00021C78  lhz       r12, 4(r12)
00021C7C  lwz       r28, 0x3E8(r12)
00021C80  lis       r11, 4
00021C84  ori       r11, r11, 0xC4B4 # 0x4C4B4
00021C88  divw      r12, r12, r11
00021C8C  sth       r12, 0xA(r31)
00021C90  addi      r30, r31, 0xA
00021C94  lhz       r9, 0(r30)
00021C98  addi      r9, r9, 1
00021C9C  stfs      f9, 0(r30)
00021CA0  lwz       r30, 0x10+var_8(r1)
00021CA4  lwz       r31, 0x10+var_4(r1)
00021CA8  lwz       r0, 0x10+sender_lr(r1)
00021CAC  mtlr      r0
00021CB0  addi      r1, r1, 0x10
00021CB4  blr
