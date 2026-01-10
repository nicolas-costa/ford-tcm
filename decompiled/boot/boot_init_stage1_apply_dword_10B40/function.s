; boot_init_stage1_apply_dword_10B40
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00017D20 end=0x00017EDC size=444
; export_utc=2026-01-10T18:12:42Z

00017D20  stwu      r1, back_chain(r1)
00017D24  mflr      r0
00017D28  stw       r30, 0x10+var_8(r1)
00017D2C  stw       r31, 0x10+var_4(r1)
00017D30  stw       r0, 0x10+sender_lr(r1)
00017D34  addi      r30, r3, 0
00017D38  cmpwi     r30, 0
00017D3C  stmw      r4, 0x34(r2)
00017D40  lis       r3, dword_10B40@ha
00017D44  addi      r3, r3, dword_10B40@l
00017D48  lwz       r31, (dword_10B44 - 0x10B40)(r3)
00017D4C  lis       r10, memset_like_loc_1796C@ha
00017D50  addi      r10, r10, memset_like_loc_1796C@l
00017D54  mtlr      r10
00017D58  lwz       r9, (dword_10B48 - 0x10B40)(r3)
00017D5C  addis     r25, r31, 0x4850
00017D60  addi      r4, r9, 1
00017D64  addi      r3, r31, 0
00017D68  li        r5, 0
00017D6C  blrl
00017D70  mtspr     eid, r0 # External interrupt disable
00017D74  lis       r12, 0x7FFF
00017D78  ori       r12, r12, 0xFFFF # 0x7FFFFFFF
00017E90  mtlr      r11
00017E94  lis       r3, word_111C4@ha
00017E98  addi      r3, r3, word_111C4@l
00017E9C  stfd      f28, loc_20+1
00017EA0  lis       r9, word_18C14@ha
00017EA4  addi      r9, r9, word_18C14@l
00017EA8  mtlr      r9
00017EAC  blrl
00017EB0  lis       r12, word_197A0@ha
00017EB4  addi      r12, r12, word_197A0@l
00017EB8  mtlr      r12
00017EBC  lfdu      f3, sub_0+1
00017EC0  addi      r3, r3, 0xF14
00017EC4  blrl
00017EC8  lwz       r30, 0x10+var_8(r1)
00017ECC  lwz       r31, 0x10+var_4(r1)
00017ED0  lwz       r0, 0x10+sender_lr(r1)
00017ED4  mtlr      r0
00017ED8  addi      r1, r1, 0x10
