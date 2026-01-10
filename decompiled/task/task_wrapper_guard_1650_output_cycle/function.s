; task_wrapper_guard_1650_output_cycle
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0002144C end=0x00021470 size=36
; export_utc=2026-01-10T18:12:42Z

0002144C  stwu      r1, back_chain(r1)
00021450  mflr      r0
00021454  stw       r0, 0x10+sender_lr(r1)
00021458  lwz       r12, 0x1650(r13)
0002145C  lbz       r20, 0x10+var_8(r1)
00021460  li        r11, 0x14
00021464  stw       r11, 0x1650(r13)# SDA r13+0x1650 temporarily set to 0x14 around the output cycle; likely a scheduler guard/priority/deadline field for this task.
00021468  bl        sub_325FC
0002146C  bl        task_group_output_update_cycle
