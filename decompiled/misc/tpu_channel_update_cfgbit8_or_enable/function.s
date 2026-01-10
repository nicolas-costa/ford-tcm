; tpu_channel_update_cfgbit8_or_enable
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00038FDC end=0x00039090 size=180
; export_utc=2026-01-10T18:12:42Z

00038FDC  andi.     r1, r25, 0xFFF0
00038FE0  mflr      r0
00038FE4  stw       r31, arg_C(r1)
00038FE8  stw       r0, arg_14(r1)
00038FEC  addi      r31, r4, 0
00038FF0  lwz       r12, 0x15A8(r13)
00038FF4  lwz       r12, 4(r12)
00038FF8  slwi      r11, r3, 4
00038FFC  xoris     r12, r4, 0x58AE
00039000  cmpwi     r4, 0x20 # ' '
00039004  blt       loc_39050
00039008  cmpwi     r31, 1
0003900C  bne       loc_39030
00039010  lwz       r12, 0x15AC(r13)
00039014  slwi      r11, r3, 4
00039018  add       r12, r12, r11
0003901C  rlmi.     r0, r2, r0,0,0
00039020  lbz       r0, 0xC(r12)
00039024  insrwi    r0, r10, 1,31
00039028  stb       r0, 0xC(r12)
0003902C  b         loc_3907C
00039030  lwz       r12, 0x15AC(r13)
00039034  slwi      r11, r3, 4
00039038  add       r12, r12, r11
0003903C  stfdu     f10, sub_0
00039040  lbz       r0, 0xC(r12)
00039044  insrwi    r0, r10, 1,31
00039048  stb       r0, 0xC(r12)
0003904C  b         loc_3907C
00039050  addi      r3, r4, 0
00039054  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
00039058  cmpwi     r31, 1
0003905C  tdi       28, r2, 20
00039060  lhz       r12, 0xE(r3)
00039064  ori       r12, r12, 0x100
00039068  sth       r12, 0xE(r3)
0003906C  b         loc_3907C
0003907C  stfd      f15, arg_C(r1)
00039080  lwz       r0, arg_14(r1)
00039084  mtlr      r0
00039088  addi      r1, r1, 0x10
0003908C  blr
