; iterate_slots_3FA400_call_3734C_38D18
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000317A8 end=0x0003185C size=180
; export_utc=2026-01-10T18:12:42Z

000317A8  stwu      r1, back_chain(r1)
000317AC  mflr      r0
000317B0  stmw      r29, 0x18+var_C(r1)
000317B4  stw       r0, 0x18+sender_lr(r1)
000317B8  lis       r30, 0x40 # '@'
000317BC  andis.    r30, r14, 0xA400
000317C0  lwz       r10, 0(r30)
000317C4  li        r31, 0
000317C8  lbz       r10, 2(r10)
000317CC  cmpwi     r10, 0
000317D0  beq       loc_31810
000317D4  slwi      r29, r31, 3
000317D8  lwz       r11, 0(r30)
000317DC  lhz       r11, 0x10(r11)
000317E0  lhzx      r3, r11, r29
000317E4  bl        loc_3734C
000317E8  lwz       r12, 0(r30)
000317EC  li        r4, 0
000317F0  lwz       r12, 0x10(r12)
000317F4  lhzx      r3, r12, r29
000317F8  bl        sub_38D18
00031810  lwz       r30, 0(r30)
00031814  li        r31, 0
00031818  lbz       r10, 0(r30)
0003181C  andi.     r10, r8, 0
00031820  beq       loc_31848
00031824  lis       r12, word_30BC0@ha
00031828  addi      r12, r12, word_30BC0@l
0003182C  mtlr      r12
00031830  clrlwi    r3, r31, 24
00031834  blrl
00031838  lbz       r9, 0(r30)
0003183C  clrrwi.   r31, r15, 31
00031840  cmplw     r9, r31
00031844  bgt       loc_31824
00031848  lwz       r0, 0x18+sender_lr(r1)
0003184C  lmw       r29, 0x18+var_C(r1)
00031850  mtlr      r0
00031854  addi      r1, r1, 0x18
00031858  blr
