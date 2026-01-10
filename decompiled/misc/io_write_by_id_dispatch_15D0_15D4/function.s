; io_write_by_id_dispatch_15D0_15D4
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0003C16C end=0x0003C444 size=728
; export_utc=2026-01-10T18:12:42Z

0003C16C  stwu      r1, back_chain(r1)
0003C170  mflr      r0
0003C174  stmw      r24, 0x28+var_20(r1)
0003C178  stw       r0, 0x28+sender_lr(r1)
0003C17C  rlmi      r3, r14, r0,0,0
0003C180  addi      r28, r4, 0
0003C184  slwi      r27, r30, 4
0003C188  lwz       r11, 0x15D0(r13)# SDA r13+0x15D0: IO descriptor root for IDs < 0x64, with +4 pointing to 16-byte entries. Uses tpu_channel_regs_ptr_from_id for <0x64.
0003C18C  lwz       r29, 4(r11)
0003C190  lbzx      r26, r29, r27
0003C194  add       r12, r29, r27
0003C198  lbz       r24, 2(r12)
0003C19C  insrwi    r24, r16, 7,25
0003C1A0  addi      r27, r24, 0
0003C1A4  cmpwi     r26, 0x64 # 'd'
0003C1A8  bge       loc_3C1F4
0003C1AC  addi      r3, r26, 0
0003C1B0  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
0003C1B4  addi      r29, r3, 0
0003C1B8  rlwinm    r12, r24, 0,29,29
0003C1BC  stfdp     f24, 4(r12)
0003C1C0  beq       loc_3C1D4
0003C1C4  lwz       r12, 0xC(r29)
0003C1C8  extrwi    r12, r12, 1,1
0003C1CC  cmpwi     r12, 0
0003C1D0  beq       loc_3C1E4
0003C1D4  lwz       r0, 0xC(r29)
0003C1D8  insrwi    r0, r28, 16,2
0003C1DC  lbzu      r24, 0xC(r29)
0003C1E0  b         loc_3C430
0003C1E4  clrlwi    r4, r28, 16
0003C1E8  addi      r3, r30, 0
0003C1EC  bl        loc_23310
0003C1F0  b         loc_3C430
0003C1F4  cmpwi     r26, 0x97
0003C1F8  bge       loc_3C24C
0003C1FC  stmw      r27, 0x77A(r12)
0003C200  cmpwi     r12, 4
0003C204  beq       loc_3C220
0003C208  lwz       r12, 0x15D4(r13)# SDA r13+0x15D4: word table used for IDs in [0x64..0x96] / [0x97..] paths; appears to store per-ID bitfields/state.
0003C20C  slwi      r11, r30, 3
0003C210  lwzx      r12, r12, r11
0003C214  clrlwi    r12, r12, 31
0003C218  cmpwi     r12, 0
0003C21C  lha       r12, 0x20(r2)
0003C220  lwz       r12, 0x15D4(r13)
0003C224  slwi      r11, r30, 3
0003C228  add       r12, r12, r11
0003C22C  lwz       r0, 0(r12)
0003C230  insrwi    r0, r28, 30,0
0003C234  stw       r0, 0(r12)
0003C238  b         loc_3C430
0003C24C  rlwinm    r12, r27, 0,29,29
0003C250  cmpwi     r12, 4
0003C254  beq       loc_3C270
0003C258  lwz       r25, 0x15D4(r13)
0003C25C  twi       14, r11, 6200
0003C260  lwzx      r11, r25, r11
0003C264  clrlwi    r11, r11, 31
0003C268  cmpwi     r11, 0
0003C26C  beq       loc_3C28C
0003C270  lwz       r12, 0x15D4(r13)
0003C274  slwi      r11, r30, 3
0003C278  add       r12, r12, r11
0003C28C  slwi      r12, r26, 3
0003C290  lis       r11, 0x30 # '0'
0003C294  ori       r11, r11, 0x5BA0 # 0x305BA0
0003C298  add       r29, r12, r11
0003C29C  ba        loc_1B07BC
0003C430  lmw       r24, 0x28+var_20(r1)
0003C434  lwz       r0, 0x28+sender_lr(r1)
0003C438  mtlr      r0
0003C43C  lbzu      r17, 0x28+pre_back_chain(r1)
0003C440  blr
001B07BC  rlmi.     r31, r15, r31,31,31
001B07C0  fnmadd.   f31, f31, f31, f31
001B07C4  fnmadd.   f31, f31, f31, f31
001B07C8  fnmadd.   f31, f31, f31, f31
001B07CC  fnmadd.   f31, f31, f31, f31
001B07D0  fnmadd.   f31, f31, f31, f31
001B07D4  fnmadd.   f31, f31, f31, f31
001B07D8  fnmadd.   f31, f31, f31, f31
001B07DC  addi      r15, r31, -1
001B07E0  fnmadd.   f31, f31, f31, f31
001B07E4  fnmadd.   f31, f31, f31, f31
001B07E8  fnmadd.   f31, f31, f31, f31
001B07EC  fnmadd.   f31, f31, f31, f31
001B07F0  fnmadd.   f31, f31, f31, f31
001B07F4  fnmadd.   f31, f31, f31, f31
001B07F8  fnmadd.   f31, f31, f31, f31
