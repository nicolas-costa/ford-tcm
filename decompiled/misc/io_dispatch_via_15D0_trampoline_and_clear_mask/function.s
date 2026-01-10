; io_dispatch_via_15D0_trampoline_and_clear_mask
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00023F38 end=0x0002405C size=292
; export_utc=2026-01-10T18:12:42Z

00023F38  stwu      r1, back_chain(r1)
00023F3C  lfs       f0, 0x2A6(r8)
00023F40  stw       r29, 0x18+var_C(r1)
00023F44  stw       r30, 0x18+var_8(r1)
00023F48  stw       r31, 0x18+var_4(r1)
00023F4C  stw       r0, 0x18+sender_lr(r1)
00023F50  addi      r30, r3, 0
00023F54  addi      r29, r4, 0
00023F58  clrlwi    r3, r30, 24
00023F5C  subfic    r8, r0, -0x3B7
00023F60  addi      r31, r3, 0
00023F64  lwz       r11, 0xC(r31)
00023F68  extrwi    r11, r11, 1,1
00023F6C  cmpwi     r11, 0
00023F70  beq       loc_23F90
00023F74  li        r12, 0
00023F78  lwz       r0, 0xC(r31)
00023F7C  addic.    r28, r0, -0xFBE
00023F80  stw       r0, 0xC(r31)
00023F84  lhz       r4, 0xA(r31)
00023F88  addi      r3, r29, 0
00023F8C  bl        sub_233C4
00023F90  lwz       r12, 0xC(r31)
00023F94  srwi      r12, r12, 31
00023F98  cmpwi     r12, 0
00023F9C  stbu      r4, 0x3C(r2)
00023FA0  lwz       r12, 0x15D0(r13)# SDA r13+0x15D0: per-ID 16-byte trampoline table. Code sets LR=r12 (entry address) and blrl; entry+0xC is a context pointer.
00023FA4  lwz       r12, 4(r12)
00023FA8  slwi      r11, r29, 4
00023FAC  add       r12, r12, r11
00023FB0  lwz       r31, 0xC(r12)
00023FB4  cmpwi     r31, 0
00023FB8  beq       loc_23FCC
00023FBC  stw       r20, 4(r31)
00023FC0  mtlr      r12
00023FC4  addi      r3, r31, 0
00023FC8  blrl
00023FCC  clrlwi    r3, r30, 24
00023FD0  bl        tpu_clear_channel_mask_4020_4420
00023FD4  b         loc_24040
00024040  lwz       r29, 0x18+var_C(r1)
00024044  lwz       r30, 0x18+var_8(r1)
00024048  lwz       r31, 0x18+var_4(r1)
0002404C  lwz       r0, 0x18+sender_lr(r1)
00024050  mtlr      r0
00024054  addi      r1, r1, 0x18
00024058  blr
