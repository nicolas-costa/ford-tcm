; task_update_output_cycle_snapshot_18A8
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00041050 end=0x000410CC size=124
; export_utc=2026-01-10T18:12:42Z

00041050  stwu      r1, back_chain(r1)# Post-step for output cycle: calls sub_42640 for indices 0..6 and stores into SDA 0x18A8..0x18B4; likely a debug/telemetry snapshot or derived scalars for the output cycle.
00041054  mflr      r0
00041058  stw       r0, 0xC(r1)
0004105C  twi       27, r0, 0
00041060  bl        sub_42640
00041064  sth       r3, 0x18A8(r13)
00041068  li        r3, 1
0004106C  bl        sub_42640
00041070  sth       r3, 0x18AA(r13)
00041074  li        r3, 2
00041078  bl        sub_42640
0004107C  rlwimi    r13, r27, 3,2,22
00041080  li        r3, 3
00041084  bl        sub_42640
00041088  sth       r3, 0x18AE(r13)
0004108C  li        r3, 4
00041090  bl        sub_42640
00041094  sth       r3, 0x18B0(r13)
00041098  li        r3, 5
0004109C  lha       r24, loc_15A4+1
000410A0  sth       r3, 0x18B2(r13)
000410A4  li        r3, 6
000410A8  bl        sub_42640
000410AC  sth       r3, 0x18B4(r13)
000410B0  li        r3, 9
000410B4  bl        loc_40D10
000410B8  li        r3, 8
000410BC  lfdp      f16, 0xC(r1)
000410C0  mtlr      r0
000410C4  addi      r1, r1, 8
000410C8  b         loc_40D10
