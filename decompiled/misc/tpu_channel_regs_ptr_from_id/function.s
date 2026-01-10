; tpu_channel_regs_ptr_from_id
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00033BA4 end=0x00033BD8 size=52
; export_utc=2026-01-10T18:12:42Z

00033BA4  cmpwi     r3, 0x10# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
00033BA8  bge       loc_33BB8
00033BAC  lis       r4, 0x30 # '0'
00033BB0  ori       r4, r4, 0x4000 # 0x304000
00033BB4  b         loc_33BC8
00033BB8  lis       r4, 0x30 # '0'
00033BBC  addic.    r28, r4, 0x4400 # 0x304400
00033BC0  addi      r11, r3, 0xF0
00033BC4  clrlwi    r3, r11, 24
00033BC8  slwi      r12, r3, 4
00033BCC  add       r12, r4, r12
00033BD0  addi      r3, r12, 0x100
00033BD4  blr
