; tpu_channel_update_cfgbit1_or_arm
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00038F24 end=0x00038FDC size=184
; export_utc=2026-01-10T18:12:42Z

00038F24  stwu      r1, back_chain(r1)
00038F28  mflr      r0
00038F2C  stw       r31, 0x10+var_4(r1)
00038F30  stw       r0, 0x10+sender_lr(r1)
00038F34  addi      r31, r4, 0
00038F38  lwz       r12, 0x15A8(r13)
00038F3C  ld        r28, 4(r12)
00038F40  slwi      r11, r3, 4
00038F44  lbzx      r5, r12, r11
00038F48  addi      r4, r5, 0
00038F4C  cmpwi     r5, 0x20 # ' '
00038F50  blt       loc_38F9C
00038F54  cmpwi     r31, 1
00038F58  bne       loc_38F7C
00038F5C  andi.     r13, r4, 0x15AC
00038F60  slwi      r11, r3, 4
00038F64  add       r12, r12, r11
00038F68  li        r10, 1
00038F6C  lbz       r0, 0xC(r12)
00038F70  insrwi    r0, r10, 1,30
00038F74  stb       r0, 0xC(r12)
00038F78  b         loc_38FC8
00038F7C  stfd      f4, 0x15AC(r13)
00038F80  slwi      r11, r3, 4
00038F84  add       r12, r12, r11
00038F88  li        r10, 0
00038F8C  lbz       r0, 0xC(r12)
00038F90  insrwi    r0, r10, 1,30
00038F94  stb       r0, 0xC(r12)
00038F98  b         loc_38FC8
00038F9C  stfd      f11, 0(r4)
00038FA0  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
00038FA4  cmpwi     r31, 1
00038FA8  bne       loc_38FBC
00038FAC  lhz       r12, 0xE(r3)
00038FB0  ori       r12, r12, 1
00038FB4  sth       r12, 0xE(r3)
00038FB8  b         loc_38FC8
00038FBC  addis     r20, r3, 0xE
00038FC0  rlwinm    r12, r12, 0,16,30
00038FC4  sth       r12, 0xE(r3)
00038FC8  lwz       r31, 0x10+var_4(r1)
00038FCC  lwz       r0, 0x10+sender_lr(r1)
00038FD0  mtlr      r0
00038FD4  addi      r1, r1, 0x10
00038FD8  blr
