; init_copy_or_zero_ranges
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00017AE8 end=0x00017B78 size=144
; export_utc=2026-01-10T18:12:42Z

00017AE8  stwu      r1, back_chain(r1)
00017AEC  mflr      r0
00017AF0  stw       r28, 0x18+var_10(r1)
00017AF4  stw       r29, 0x18+var_C(r1)
00017AF8  stw       r30, 0x18+var_8(r1)
00017AFC  lwz       r23, 0x18+var_4(r1)
00017B00  stw       r0, 0x18+sender_lr(r1)
00017B04  li        r31, 0
00017B08  lis       r28, dword_10B40@ha
00017B0C  addi      r28, r28, dword_10B40@l
00017B10  lwz       r10, (dword_10B40 - 0x10B40)(r28)
00017B14  cmpwi     r10, 0
00017B18  beq       loc_17B58
00017B1C  mulli     r14, r28, 0
00017B20  lwz       r29, 4(r30)
00017B24  lis       r11, memset_like_loc_1796C@ha
00017B28  addi      r11, r11, memset_like_loc_1796C@l
00017B2C  mtlr      r11
00017B30  lwzu      r10, 8(r30)
00017B34  subf      r10, r29, r10
00017B38  addi      r4, r10, 1
00017B3C  twi       3, r29, 0
00017B40  li        r5, 0
00017B44  blrl
00017B48  addi      r31, r31, 1
00017B4C  lwz       r9, (dword_10B40 - 0x10B40)(r28)
00017B50  cmplw     r9, r31
00017B54  bgt       loc_17B20
00017B58  lwz       r28, 0x18+var_10(r1)
00017B5C  rlmi      r1, r29, r0,0,6
00017B60  lwz       r30, 0x18+var_8(r1)
00017B64  lwz       r31, 0x18+var_4(r1)
00017B68  lwz       r0, 0x18+sender_lr(r1)
00017B6C  mtlr      r0
00017B70  addi      r1, r1, 0x18
00017B74  blr
