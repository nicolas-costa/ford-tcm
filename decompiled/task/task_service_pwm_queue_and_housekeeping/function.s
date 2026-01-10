; task_service_pwm_queue_and_housekeeping
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0004A264 end=0x0004A288 size=36
; export_utc=2026-01-10T18:12:42Z

0004A264  stwu      r1, back_chain(r1)
0004A268  mflr      r0
0004A26C  stw       r0, 8+sender_lr(r1)
0004A270  bl        nullsub_6
0004A274  bl        tpu_pwm_queue_service_15A8
0004A278  bl        loc_38E40
0004A27C  stfd      f7, 0x2745(r31)
0004A280  bl        loc_3D4A8
0004A284  bl        sub_3A674
