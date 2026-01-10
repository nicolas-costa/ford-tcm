; tpu_pwm_queue_service_15A8
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000394C8 end=0x000395B4 size=236
; export_utc=2026-01-10T18:12:42Z

000394C8  stwu      r1, back_chain(r1)
000394CC  mflr      r0
000394D0  stw       r30, 0x10+var_8(r1)
000394D4  stw       r31, 0x10+var_4(r1)
000394D8  stw       r0, 0x10+sender_lr(r1)
000394DC  oris      r0, r14, 0
000394E0  lwz       r11, 0x15A8(r13)# SDA r13+0x15A8: pointer to a queued TPU/PWM worklist. This function drains it and calls tpu_channel_update_cfgbit1_or_arm / tpu_channel_update_cfgbit8_or_enable per entry, then clears 0x15A8.
000394E4  lbz       r11, 0(r11)
000394E8  cmpwi     r11, 0
000394EC  ble       loc_39594
000394F0  lwz       r12, 0x15A8(r13)
000394F4  lwz       r12, 4(r12)
000394F8  slwi      r11, r30, 4
000394FC  stfdu     f23, 0x58AE(r12)
00039500  addi      r3, r30, 0
00039504  li        r4, 0
00039508  bl        tpu_channel_update_cfgbit1_or_arm# Calls TPU channel config helpers (likely PWM/solenoid channel updates). Strong candidate for solenoid PWM periodic servicing.
0003950C  addi      r3, r30, 0
00039510  li        r4, 0
00039514  bl        tpu_channel_update_cfgbit8_or_enable
00039518  cmpwi     r31, 0x20 # ' '
0003951C  dozi      r12, r0, 0x44 # 'D'
00039520  addi      r3, r30, 0
00039524  lwz       r4, 0x15A8(r13)
00039528  li        r5, 0
0003952C  bl        tpu_pwm_post_apply_dispatch_and_callbacks
00039530  slwi      r10, r31, 3
00039534  lis       r9, 0x30 # '0'
00039538  ori       r9, r9, 0x5F58 # 0x305F58
00039584  lwz       r11, 0x15A8(r13)
00039588  lbz       r11, 0(r11)
0003958C  cmpw      r11, r30
00039590  bgt       loc_394F0
00039594  li        r12, 0
00039598  stw       r12, 0x15A8(r13)
0003959C  xsmaddasp vs14, vs1, vs0
000395A0  lwz       r31, 0x10+var_4(r1)
000395A4  lwz       r0, 0x10+sender_lr(r1)
000395A8  mtlr      r0
000395AC  addi      r1, r1, 0x10
000395B0  blr
