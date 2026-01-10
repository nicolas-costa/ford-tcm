; early_hw_init_loop
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00017EE0 end=0x000181E8 size=776
; export_utc=2026-01-10T18:12:42Z

00017EE0  stwu      r1, back_chain(r1)
00017EE4  mflr      r0
00017EE8  stmw      r27, 0x20+var_14(r1)
00017EEC  stw       r0, 0x20+sender_lr(r1)
00017EF0  lis       r29, 0x30 # '0'
00017EF4  lis       r30, 0x30 # '0'
00017EF8  li        r10, 1
00017EFC  addi      r26, r30, 0x6800 # 0x306800
00017F00  lis       r30, 0x30 # '0'
00017F04  lis       r12, 0x370
00017F08  stw       r12, -0x3FC4(r30)
00017F0C  lis       r30, 0x55CC
00017F10  ori       r30, r30, 0xAA33 # 0x55CCAA33
00017F14  lis       r31, 0x30 # '0'
00017F18  stw       r30, -0x3C80(r31)
00017F1C  mulli     r23, r0, 0x30 # '0'
00017F20  lwz       r11, -0x3D7C(r31)
00017F24  extrwi    r11, r11, 1,15
00017F28  cmpwi     r11, 0
00017F2C  beq       loc_17F1C
00017F30  lis       r31, 0x30 # '0'
00017F34  lwz       r11, -0x3D80(r31)
00017F38  extrwi    r11, r11, 1,12
00017F3C  lfs       f0, 0(r11)
00017F40  beq       loc_17F68
00017F44  li        r31, 1
00017F48  lis       r28, 0x30 # '0'
00017F4C  lwz       r0, -0x3D80(r28)
00017F50  insrwi    r0, r31, 1,15
00017F54  stw       r0, -0x3D80(r28)
00017F58  lis       r28, 0x30 # '0'
00017F5C  lhzu      r8, -0x3D80(r28)
00017F60  insrwi    r0, r31, 1,8
00017F64  stw       r0, -0x3D80(r28)
00017F68  lis       r31, 0x30 # '0'
00017F6C  lis       r11, 0x3361
00017F70  ori       r11, r11, 0xC700 # 0x3361C700
00017F74  stw       r11, -0x3D80(r31)
00017F78  lis       r31, 0x30 # '0'
00017F7C  lwzu      r6, -0x3C7C(r31)
00017F80  lis       r31, 0x30 # '0'
00017F84  lis       r12, 0x70 # 'p'
00017F88  ori       r12, r12, 0x80 # 0x700080
00017F8C  stw       r12, -0x3D7C(r31)
00017F90  lis       r31, 0x30 # '0'
00017F94  lwz       r11, -0x3D7C(r31)
00017F98  extrwi    r11, r11, 1,15
00017FA0  beq       loc_17F90
00017FA4  lis       r29, 0x30 # '0'
00017FA8  lis       r11, 0x3F61
00017FAC  ori       r11, r11, 0xC700 # 0x3F61C700
00017FB0  stw       r11, -0x3D80(r29)
00017FB4  lis       r29, 0x30 # '0'
00017FB8  li        r9, 0x80
00017FBC  lfs       f9, -0x3D74(r29)
00017FC0  li        r3, 0
00017FC4  mtdec     r3
00017FC8  lis       r29, 0x30 # '0'
00017FCC  stw       r30, -0x3D00(r29)
00017FD0  lis       r30, 0x30 # '0'
00017FD4  li        r9, 3
00017FD8  sth       r9, -0x3E00(r30)
00017FDC  sthu      r5, loc_556C
00017FE0  lis       r30, 0x30 # '0'
00017FE4  sth       r29, -0x3FF2(r30)
00017FE8  lis       r30, unk_AA39@h
00017FEC  ori       r30, r30, unk_AA39@l
00017FF0  lis       r31, 0x30 # '0'
00017FF4  sth       r30, -0x3FF2(r31)
00017FF8  lis       r31, 0x30 # '0'
00017FFC  rlwinm.   r0, r19, 0,14,20
00018000  ori       r11, r11, 0x7F8F
00018004  stw       r11, -0x3FFC(r31)
00018008  lis       r31, 0x30 # '0'
0001800C  sth       r29, -0x3FF2(r31)
00018010  lis       r29, 0x30 # '0'
00018014  sth       r30, -0x3FF2(r29)
00018018  lis       r30, 0x30 # '0'
0001801C  lis       r19, 0xB
00018020  stw       r11, -0x3F00(r30)
00018024  lis       r30, 0x30 # '0'
00018028  lis       r9, -0x20
0001802C  ori       r9, r9, 0x20 # ' ' # 0xFFE00020
00018030  stw       r9, -0x3EFC(r30)
00018034  lis       r30, 0x30 # '0'
00018038  lis       r11, 0x58 # 'X'
00018040  stw       r11, -0x3EF8(r30)
00018044  lis       r30, -2
00018048  ori       r30, r30, 0x10 # 0xFFFE0010
0001804C  lis       r29, 0x30 # '0'
00018050  stw       r30, -0x3EF4(r29)
00018054  lis       r29, 0x30 # '0'
00018058  lis       r11, 0x54 # 'T'
0001805C  lmw       r3, -0x3EF0(r29)
00018060  lis       r29, 0x30 # '0'
00018064  lis       r9, -2
00018068  ori       r9, r9, 0x30 # '0' # 0xFFFE0030
0001806C  stw       r9, -0x3EEC(r29)
00018070  lis       r29, 0x30 # '0'
00018074  lis       r11, 0x7FF8
00018078  ori       r11, r11, 3 # 0x7FF80003
0001807C  xori      r29, r11, 0xC118
00018080  lis       r29, 0x30 # '0'
00018084  stw       r30, -0x3EE4(r29)
00018088  lis       r27, 0x3F # '?'
0001808C  ori       r27, r27, 0x8000 # 0x3F8000
00018090  mtspr     mi_rba0, r27 # IMPU Region Base Address 0
00018094  li        r3, 0
00018098  mtspr     mi_rba1, r3 # IMPU Region Base Address 1
000181A0  lbz       r12, 0x70C6(r13)
000181A4  ori       r12, r12, 1
000181A8  stb       r12, 0x70C6(r13)
000181AC  lis       r30, 0x30 # '0'
000181B0  lis       r29, 0x30 # '0'
000181B4  lwz       r10, -0x3F00(r29)
000181B8  li        r9, -0x43
000181BC  oris      r10, r10, 0x4838
000181C0  stw       r10, -0x3F00(r30)
000181C4  lis       r12, word_1D350@ha
000181C8  addi      r12, r12, word_1D350@l
000181CC  mtlr      r12
000181D0  blrl
000181D4  lmw       r27, 0x20+var_14(r1)
000181D8  lwz       r0, 0x20+sender_lr(r1)
000181DC  stwu      r24, 0x3A6(r8)
000181E0  addi      r1, r1, 0x20
000181E4  blr
