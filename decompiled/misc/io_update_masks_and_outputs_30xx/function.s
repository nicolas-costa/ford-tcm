; io_update_masks_and_outputs_30xx
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0003BB10 end=0x0003BFCC size=1212
; export_utc=2026-01-10T18:12:42Z

0003BB10  stwu      r1, back_chain(r1)
0003BB14  mflr      r0
0003BB18  stw       r29, 0x18+var_C(r1)
0003BB1C  lfsu      f14, 0x18+var_8(r1)
0003BB20  stw       r31, 0x18+var_4(r1)
0003BB24  stw       r0, 0x18+sender_lr(r1)
0003BB28  addi      r30, r3, 0
0003BB2C  addi      r31, r4, 0
0003BB30  lwz       r12, 0x15D0(r13)
0003BB34  lwz       r12, 4(r12)
0003BB38  slwi      r11, r30, 4
0003BB3C  stfs      f29, 0x58AE(r12)
0003BB40  clrlwi    r10, r29, 24
0003BB44  cmpwi     r10, 0x64 # 'd'
0003BB48  bge       loc_3BC50
0003BB4C  clrlwi    r12, r29, 24
0003BB50  cmpwi     r12, 0x10
0003BB54  bge       loc_3BB64
0003BB58  lis       r30, 0x30 # '0'
0003BB60  b         loc_3BB70
0003BB64  lis       r30, 0x30 # '0'
0003BB68  ori       r30, r30, 0x4400 # 0x304400
0003BB6C  addi      r29, r29, 0xF0
0003BB70  mtspr     eid, r0 # External interrupt disable
0003BB74  lwz       r12, 0x3C04(r13)
0003BB78  addi      r12, r12, 1
0003BB7C  stfdp     f20, 0x3C04(r13)
0003BB80  li        r11, 1
0003BB84  slw       r11, r11, r29
0003BB88  lhz       r10, 0xA(r30)
0003BB8C  andc      r11, r10, r11
0003BB90  sth       r11, 0xA(r30)
0003BB94  lwz       r12, 0x3C04(r13)
0003BB98  addi      r12, r12, -1
0003BB9C  lfs       f20, 0x3C04(r13)
0003BBA0  lwz       r10, 0x3C04(r13)
0003BBA4  cmpwi     r10, 0
0003BBA8  bne       loc_3BBB4
0003BBAC  isync
0003BBB0  mtspr     eie, r0 # External interrupt enable
0003BBB4  clrlwi    r3, r29, 24
0003BBB8  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
0003BBBC  mr        r3, r30
0003BBC0  clrlwi    r11, r31, 24
0003BBC4  lwz       r0, 0xC(r30)
0003BBC8  insrwi    r0, r11, 1,0
0003BBCC  stw       r0, 0xC(r30)
0003BBD0  clrlwi    r10, r31, 24
0003BBD4  cmpwi     r10, 0
0003BBD8  beq       loc_3BFB0
0003BBE0  addi      r3, r31, 0
0003BBE4  bl        tpu_clear_channel_mask_4020_4420
0003BBE8  cmpwi     r31, 0x10
0003BBEC  bge       loc_3BBFC
0003BBF0  lis       r31, 0x30 # '0'
0003BBF4  ori       r31, r31, 0x4000 # 0x304000
0003BBF8  b         loc_3BC08
0003BBFC  ld        r15, 0x30(r0)
0003BC00  ori       r31, r31, 0x4400
0003BC04  addi      r29, r29, 0xF0
0003BC08  mtspr     eid, r0 # External interrupt disable
0003BC0C  lwz       r12, 0x3C04(r13)
0003BC10  addi      r12, r12, 1
0003BC14  stw       r12, 0x3C04(r13)
0003BC18  lhz       r11, 0xA(r31)
0003BC1C  oris      r0, r10, 1
0003BC20  slw       r10, r10, r29
0003BC24  or        r11, r11, r10
0003BC28  sth       r11, 0xA(r31)
0003BC2C  lwz       r12, 0x3C04(r13)
0003BC30  addi      r12, r12, -1
0003BC34  stw       r12, 0x3C04(r13)
0003BC38  lwz       r10, 0x3C04(r13)
0003BC3C  bdnzt     4*cr2+eq, loc_3BC3C
0003BC40  bne       loc_3BFB0
0003BC44  isync
0003BC48  mtspr     eie, r0 # External interrupt enable
0003BC4C  b         loc_3BFB0
0003BC50  clrlwi    r12, r29, 24
0003BC54  cmpwi     r12, 0x97
0003BC58  bge       loc_3BE08
0003BC5C  lwzu      r13, 0x63E(r12)
0003BC60  cmpwi     r12, 0x74 # 't'
0003BC64  bge       loc_3BD38
0003BC68  lis       r6, 0x30 # '0'
0003BC6C  lis       r4, 0
0003BC70  ori       r4, r4, 0xFF9C # 0xFF9C
0003BC74  addi      r5, r6, 0 # 0x300000
0003BC78  addi      r3, r6, 0 # 0x300000
0003BC7C  rlmi.     r0, r18, r0,0,0
0003BC80  clrlwi    r9, r29, 24
0003BC84  add       r9, r9, r4
0003BC88  slw       r10, r10, r9
0003BC8C  lhz       r12, 0x6C04(r3)
0003BC90  andc      r10, r12, r10
0003BC94  sth       r10, 0x6C04(r5)
0003BC98  lwz       r5, 0x15D4(r13)
0003BC9C  fmsubs    f6, f9, f0, f3
0003BCA0  clrlwi    r12, r31, 24
0003BCA4  lwzx      r0, r5, r9
0003BCA8  insrwi    r0, r12, 1,30
0003BCAC  stwx      r0, r5, r9
0003BCB0  clrlwi    r10, r31, 24
0003BCB4  cmpwi     r10, 0
0003BCB8  bne       loc_3BCD0
0003BCBC  xoris     r12, r14, 0x1838
0003BCC0  lwzx      r12, r5, r12
0003BCC4  clrlwi    r12, r12, 31
0003BCC8  cmpwi     r12, 0
0003BCCC  beq       loc_3BFB0
0003BCD0  slwi      r12, r30, 3
0003BCD4  lwzx      r12, r5, r12
0003BCD8  clrlwi    r12, r12, 31
0003BCDC  sth       r8, 0(r12)
0003BCE0  bne       loc_3BD10
0003BCE4  addi      r31, r6, 0 # 0x300000
0003BCE8  lhz       r12, 0x6C00(r31)
0003BCEC  addi      r31, r6, 0 # 0x300000
0003BCF0  addi      r30, r6, 0 # 0x300000
0003BCF4  li        r11, 1
0003BCF8  clrlwi    r10, r29, 24
0003BCFC  .byte 0x4C # L
0003BCFE  .byte 0x22 # "
0003BD00  slw       r11, r11, r10
0003BD04  lhz       r12, 0x6C00(r30)
0003BD08  andc      r11, r12, r11
0003BD0C  sth       r11, 0x6C00(r31)
0003BD10  addi      r31, r6, 0 # 0x300000
0003BD14  addi      r30, r6, 0 # 0x300000
0003BD18  lhz       r12, 0x6C04(r30)
0003BD1C  lfdu      f19, sub_0+1
0003BD20  clrlwi    r10, r29, 24
0003BD24  add       r10, r10, r4
0003BD28  slw       r11, r11, r10
0003BD2C  or        r12, r12, r11
0003BD30  sth       r12, 0x6C04(r31)
0003BD34  b         loc_3BFB0
0003BD38  lis       r6, 0x30 # '0'
0003BD3C  addic     r12, r0, 0
0003BD40  ori       r4, r4, 0xFF8C
0003BD44  addi      r5, r6, 0 # 0x300000
0003BD48  addi      r3, r6, 0 # 0x300000
0003BD4C  li        r10, 1
0003BD50  clrlwi    r9, r29, 24
0003BD54  add       r9, r9, r4
0003BD58  slw       r10, r10, r9
0003BD5C  ori       r3, r28, 0x6C44
0003BD60  andc      r10, r12, r10
0003BD64  sth       r10, 0x6C44(r5)
0003BD68  lwz       r5, 0x15D4(r13)
0003BD6C  slwi      r9, r30, 3
0003BD70  clrlwi    r12, r31, 24
0003BD74  lwzx      r0, r5, r9
0003BD78  insrwi    r0, r12, 1,30
0003BD7C  stfd      f16, 0x492E(r5)
0003BD80  clrlwi    r10, r31, 24
0003BD84  cmpwi     r10, 0
0003BD88  bne       loc_3BDA0
0003BD8C  slwi      r12, r30, 3
0003BD90  lwzx      r12, r5, r12
0003BD94  clrlwi    r12, r12, 31
0003BD98  cmpwi     r12, 0
0003BD9C  stfdp     f12, 0x214(r2)
0003BDA0  slwi      r12, r30, 3
0003BDA4  lwzx      r12, r5, r12
0003BDA8  clrlwi    r12, r12, 31
0003BDAC  cmpwi     r12, 0
0003BDB0  bne       loc_3BDE0
0003BDB4  addi      r31, r6, 0 # 0x300000
0003BDB8  lhz       r12, 0x6C40(r31)
0003BDBC  lbz       r23, 0(r6)
0003BDC0  addi      r30, r6, 0 # 0x300000
0003BDC4  li        r11, 1
0003BDC8  clrlwi    r10, r29, 24
0003BDCC  add       r10, r10, r4
0003BDD0  slw       r11, r11, r10
0003BDD4  lhz       r12, 0x6C40(r30)
0003BDD8  andc      r11, r12, r11
0003BDDC  addi      r19, r31, 0x6C40
0003BDE0  addi      r31, r6, 0 # 0x300000
0003BDE4  addi      r30, r6, 0 # 0x300000
0003BDE8  lhz       r12, 0x6C44(r30)
0003BDEC  li        r11, 1
0003BDF0  clrlwi    r10, r29, 24
0003BDF4  add       r10, r10, r4
0003BDF8  slw       r11, r11, r10
0003BDFC  evstwwemx r20, r12, r11
0003BE00  sth       r12, 0x6C44(r31)
0003BE04  b         loc_3BFB0
0003BE08  clrlwi    r12, r29, 24
0003BE0C  cmpwi     r12, 0xA7
0003BE10  bge       loc_3BEE4
0003BE14  lis       r6, 0x30 # '0'
0003BE18  lis       r4, 0
0003BE1C  lhau      r28, -0x8C(r4)
0003BE20  addi      r5, r6, 0 # 0x300000
0003BE24  addi      r3, r6, 0 # 0x300000
0003BE28  li        r10, 1
0003BE2C  clrlwi    r9, r29, 24
0003BE30  add       r9, r9, r4
0003BE34  slw       r10, r10, r9
0003BE38  lhz       r12, 0x6C04(r3)
0003BE3C  lfs       f20, 0x5078(r10)
0003BE40  sth       r10, 0x6C04(r5)
0003BE44  lwz       r5, 0x15D4(r13)
0003BE48  slwi      r9, r30, 3
0003BE4C  clrlwi    r12, r31, 24
0003BE50  lwzx      r0, r5, r9
0003BE54  insrwi    r0, r12, 1,30
0003BE58  stwx      r0, r5, r9
0003BE60  cmpwi     r10, 0
0003BE64  bne       unk_3BE7C
0003BE68  slwi      r12, r30, 3
0003BE6C  lwzx      r12, r5, r12
0003BE70  clrlwi    r12, r12, 31
0003BE74  cmpwi     r12, 0
0003BE78  beq       loc_3BFB0
0003BE80  lwzx      r12, r5, r12
0003BE84  clrlwi    r12, r12, 31
0003BE88  cmpwi     r12, 0
0003BE8C  bne       loc_3BEBC
0003BE90  addi      r31, r6, 0
0003BE94  lhz       r12, 0x6C00(r31)
0003BE98  addi      r31, r6, 0
0003BE9C  lhz       r14, 0(r6)
0003BEA0  li        r11, 1
0003BEA4  clrlwi    r10, r29, 24
0003BEA8  add       r10, r10, r4
0003BEAC  slw       r11, r11, r10
0003BEB0  lhz       r12, 0x6C00(r30)
0003BEB4  andc      r11, r12, r11
0003BEB8  sth       r11, 0x6C00(r31)
0003BEBC  mulli     r23, r6, 0
0003BEC0  addi      r30, r6, 0
0003BEC4  lhz       r12, 0x6C04(r30)
0003BEC8  li        r11, 1
0003BECC  clrlwi    r10, r29, 24
0003BED0  add       r10, r10, r4
0003BED4  slw       r11, r11, r10
0003BED8  or        r12, r12, r11
0003BEDC  andi.     r31, r12, 0x6C04
0003BEE0  b         loc_3BFB0
0003BEE4  lis       r6, 0x30 # '0'
0003BEE8  lis       r4, (loc_FF62+2)@h
0003BEEC  ori       r4, r4, (loc_FF62+2)@l # 0xFF64
0003BEF0  addi      r5, r6, 0 # 0x300000
0003BEF4  addi      r3, r6, 0 # 0x300000
0003BEF8  li        r10, 1
0003BEFC  .byte 0x45 # E
0003BEFE  .byte    6
0003BF00  add       r9, r9, r4
0003BF04  slw       r10, r10, r9
0003BF08  lhz       r12, 0x6C44(r3)
0003BF0C  andc      r10, r12, r10
0003BF10  sth       r10, 0x6C44(r5)
0003BF14  lwz       r5, 0x15D4(r13)
0003BF18  slwi      r9, r30, 3
0003BF1C  xxsel     vs31, vs44, vs32, vs56
0003BF20  lwzx      r0, r5, r9
0003BF24  insrwi    r0, r12, 1,30
0003BF28  stwx      r0, r5, r9
0003BF2C  clrlwi    r10, r31, 24
0003BF30  cmpwi     r10, 0
0003BF34  bne       loc_3BF4C
0003BF38  slwi      r12, r30, 3
0003BF3C  lxsd      v28, 0x602C(r5)
0003BF40  clrlwi    r12, r12, 31
0003BF44  cmpwi     r12, 0
0003BF48  beq       loc_3BFB0
0003BF4C  slwi      r12, r30, 3
0003BF50  lwzx      r12, r5, r12
0003BF54  clrlwi    r12, r12, 31
0003BF58  cmpwi     r12, 0
0003BF5C  lfdp      f28, 0x30(r2)
0003BF60  addi      r31, r6, 0
0003BF64  lhz       r12, 0x6C40(r31)
0003BF68  addi      r31, r6, 0
0003BF6C  addi      r30, r6, 0
0003BF70  li        r11, 1
0003BF74  clrlwi    r10, r29, 24
0003BF78  add       r10, r10, r4
0003BF7C  lfsu      f3, 0x5030(r11)
0003BF80  lhz       r12, 0x6C40(r30)
0003BF84  andc      r11, r12, r11
0003BF88  sth       r11, 0x6C40(r31)
0003BF8C  addi      r31, r6, 0
0003BF90  addi      r30, r6, 0
0003BF94  lhz       r12, 0x6C44(r30)
0003BF98  li        r11, 1
0003BF9C  fnmadds   f29, f10, f24, f0
0003BFA0  add       r10, r10, r4
0003BFA4  slw       r11, r11, r10
0003BFA8  or        r12, r12, r11
0003BFAC  sth       r12, 0x6C44(r31)
0003BFB0  lwz       r29, 8+sender_lr(r1)
0003BFB4  lwz       r30, 8+arg_8(r1)
0003BFB8  lwz       r31, 8+arg_C(r1)
0003BFC0  mtlr      r0
0003BFC4  addi      r1, r1, 0x18
0003BFC8  blr
