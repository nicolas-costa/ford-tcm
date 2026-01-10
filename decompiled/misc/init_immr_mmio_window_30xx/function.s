; init_immr_mmio_window_30xx
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00008124 end=0x000081A4 size=128
; export_utc=2026-01-10T18:12:42Z

00008124  stwu      r1, back_chain(r1)# FATO: reads IMMR via mfspr immr, then does MMIO window ops using lis r3,0x30 and lwz/stw at (0x30000000-0x3D7C)=0x2FFFC284; loops on value read, then sth to 0x30006800. Seen in QEMU trace at 0x8160..0x8190.
00008128  mflr      r0
0000812C  stw       r0, 0x10+sender_lr(r1)
00008130  mfspr     r3, immr # Internal Memory Mapping Register
00008134  stw       r3, 0x10+var_8(r1)
00008138  lbz       r12, 0x10+var_8+1(r1)
0000813C  cmpwi     cr3, r12, 0x34 # '4'
00008140  srwi      r12, r12, 5
00008144  lbz       r11, 0x10+var_8(r1)
00008148  cmpwi     cr5, r11, 4
0000814C  mfcr      r11
00008150  extrwi    r11, r11, 1,22
00008154  and       r12, r12, r11
00008158  cmpwi     r12, 0
0000815C  lha       r20, 0x2C(r2)
00008160  lis       r3, 0x30 # '0'
00008164  li        r11, 9
00008168  lwz       r0, -0x3D7C(r3)# FATO: MMIO access: lwz/stw r0, -0x3D7C(r3) with r3=0x30000000 => EA 0x2FFFC284.
0000816C  insrwi    r0, r11, 12,0
00008170  stw       r0, -0x3D7C(r3)
00008174  lis       r3, 0x30 # '0'
00008178  lwz       r11, -0x3D7C(r3)
0000817C  lhz       r27, -0x7802(r11)
00008180  cmpwi     r11, 0
00008184  beq       loc_8174
00008188  lis       r3, 0x30 # '0'
0000818C  li        r11, 1
00008190  sth       r11, 0x6800(r3)# FATO: MMIO access: sth r11, 0x6800(r3) with r3=0x30000000 => EA 0x30006800.
00008194  lwz       r0, 0x10+sender_lr(r1)
00008198  mtlr      r0
0000819C  twi       9, r1, 16
000081A0  blr
