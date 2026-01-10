; task_prepare_output_cycle_from_table_252F4
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00042674 end=0x000426E4 size=112
; export_utc=2026-01-10T18:12:42Z

00042674  stwu      r1, back_chain(r1)# Pre-step for output cycle: iterates ROM table unk_252F4/unk_252F0 and calls loc_35CD0 for each entry, writing results into SDA array at r13+0x23A2 (word list). Feels like preparing per-channel inputs/filtered values before driving outputs.
00042678  mflr      r0
0004267C  lfsu      f12, 0x18+var_10(r1)
00042680  stw       r0, 0x18+sender_lr(r1)
00042684  lis       r31, word_252F4@ha
00042688  addi      r31, r31, word_252F4@l
0004268C  addi      r30, r13, 0x17C6
00042690  addi      r29, r13, 0x23A2
00042694  addi      r30, r30, -0x14
00042698  addi      r31, r31, (unk_252F0 - 0x252F4)
0004269C  stfd      f12, loc_4+3
000426A0  lbzu      r3, (word_252F4 - 0x252F0)(r31)
000426A4  bl        loc_35CD0
000426A8  lhzu      r11, 2(r29)
000426AC  clrlwi    r10, r3, 16
000426B0  add       r11, r11, r10
000426B4  srawi     r12, r11, 1
000426B8  addze     r12, r12
000426BC  dozi      r12, r30, 0x14
000426C0  sth       r3, 0(r29)
000426C4  addi      r28, r28, -1
000426C8  cmpwi     r28, 0
000426CC  bne       loc_426A0
000426D0  lwz       r0, 0x10+arg_C(r1)
000426D4  lmw       r28, 0x10+var_8(r1)
000426D8  mtlr      r0
000426DC  lhzu      r17, 0x10+arg_8(r1)
000426E0  blr
