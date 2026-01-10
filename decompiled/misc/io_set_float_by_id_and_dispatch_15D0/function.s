; io_set_float_by_id_and_dispatch_15D0
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0003BFCC end=0x0003C01C size=80
; export_utc=2026-01-10T18:12:42Z

0003BFCC  stwu      r1, back_chain(r1)
0003BFD0  mflr      r0
0003BFD4  stw       r0, 8+sender_lr(r1)
0003BFD8  lwz       r12, 0x15D0(r13)# Uses SDA r13+0x15D0 as base for per-ID entries; stores float (f4) to entry+4 then dispatches based on ID range (<0x64 / <0x97 / etc). Likely generic IO write-by-ID helper.
0003BFDC  stfs      f4, 4(r12)
0003BFE0  slwi      r11, r3, 4
0003BFE4  lbzx      r5, r12, r11
0003BFE8  cmpwi     r5, 0x64 # 'd'
0003BFEC  bge       loc_3BFF8
0003BFF0  bl        sub_233C4
0003BFF4  b         loc_3C00C
0003BFF8  cmpwi     r5, 0x97
0003BFFC  stfs      f28, sub_C
0003C000  bl        loc_23748
0003C004  b         loc_3C00C
0003C00C  lwz       r0, 8+sender_lr(r1)
0003C010  mtlr      r0
0003C014  addi      r1, r1, 8
0003C018  blr
