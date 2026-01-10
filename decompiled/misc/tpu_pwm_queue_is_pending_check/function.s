; tpu_pwm_queue_is_pending_check
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00039484 end=0x00039498 size=20
; export_utc=2026-01-10T18:12:42Z

00039484  stwu      r1, back_chain(r1)
00039488  mflr      r0
0003948C  stw       r0, 0x10+sender_lr(r1)
00039490  addi      r4, r1, 0x10+var_8
00039494  bl        sub_39090
