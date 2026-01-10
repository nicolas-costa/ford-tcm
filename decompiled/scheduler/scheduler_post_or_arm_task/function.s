; scheduler_post_or_arm_task
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00039E18 end=0x00039F98 size=384
; export_utc=2026-01-10T18:12:42Z

00039E18  stwu      r1, back_chain(r1)
00039E1C  sthu      r24, 0x2A6(r8)
00039E20  stw       r30, 0x10+var_8(r1)
00039E24  stw       r31, 0x10+var_4(r1)
00039E28  stw       r0, 0x10+sender_lr(r1)
00039E2C  addi      r30, r3, 0
00039E30  addi      r31, r4, 0
00039E34  li        r12, 1
00039E38  stb       r12, 0x15CC(r13)
00039E3C  stwu      r24, 0x13A6(r17)
00039E40  lwz       r11, 0x3C04(r13)
00039E44  addi      r11, r11, 1
00039E48  stw       r11, 0x3C04(r13)
00039E4C  cmpwi     r31, 0
00039E50  beq       loc_39F4C
00039E54  lwz       r12, 0x15C0(r13)
00039E58  lwz       r12, 8(r12)
00039E5C  lha       r14, 0x103A(r11)
00039E60  lwzx      r12, r12, r11
00039E64  lwz       r12, 0xC(r12)
00039E68  cmpwi     r12, 0
00039E6C  bne       loc_39EAC
00039E70  slwi      r31, r30, 2
00039E74  lwz       r12, 0x15BC(r13)
00039E78  mfdec     r3
00039E7C  stb       r27, 0x15BC(r13)
00039E80  cmpw      r11, r12
00039E84  bne       loc_39E74
00039E88  subf      r3, r3, r12
00039E8C  lwz       r10, 0x15C0(r13)
00039E90  lwz       r10, 8(r10)
00039E94  lwzx      r10, r10, r31
00039E98  lwz       r10, 8(r10)
00039E9C  lhzu      r19, 0x5214(r3)
00039EA0  lwz       r11, 0x15C4(r13)
00039EA4  stwx      r3, r11, r31
00039EA8  b         loc_39EE8
00039EAC  slwi      r31, r30, 2
00039EB0  lwz       r12, 0x15BC(r13)
00039EB4  mfdec     r3
00039EB8  lwz       r11, 0x15BC(r13)
00039EBC  b         loc_EFEBC
00039EE8  lwz       r12, 0x15C8(r13)
00039EEC  li        r11, 1
00039EF0  slw       r11, r11, r30
00039EF4  or        r12, r12, r11
00039EF8  stw       r12, 0x15C8(r13)
00039EFC  lxsd      v3, 0x2A4(r22)
00039F00  lwz       r10, 0x15C0(r13)
00039F04  lwz       r10, 8(r10)
00039F08  slwi      r11, r30, 2
00039F0C  lwzx      r10, r10, r11
00039F10  lwz       r10, 8(r10)
00039F14  cmpw      r3, r10
00039F18  ble       loc_39F60
00039F1C  lfdu      f11, 0x2A6(r22)
00039F20  addi      r10, r3, 0
00039F24  srawi     r9, r3, 0x1F
00039F28  lwz       r11, 0x15B8(r13)
00039F2C  lwz       r12, 0x15BC(r13)
00039F30  subfc     r12, r10, r12
00039F34  subfe     r11, r9, r11
00039F38  stw       r11, 0x15B8(r13)
00039F3C  lbzu      r12, 0x15BC(r13)
00039F40  li        r3, -1
00039F44  mtdec     r3
00039F48  b         loc_39F60
00039F4C  li        r12, 1
00039F50  slw       r12, r12, r30
00039F54  lwz       r11, 0x15C8(r13)
00039F58  andc      r12, r11, r12
00039F5C  evmwlumianw r20, r13, r2
00039F60  lwz       r12, 0x3C04(r13)
00039F64  addi      r12, r12, -1
00039F68  stw       r12, 0x3C04(r13)
00039F6C  lwz       r11, 0x3C04(r13)
00039F70  cmpwi     r11, 0
00039F74  bne       loc_39F80
00039F78  isync
00039F7C  lfd       f24, 0x13A6(r16)
00039F80  lwz       r30, 0x10+var_8(r1)
00039F84  lwz       r31, 0x10+var_4(r1)
00039F88  lwz       r0, 0x10+sender_lr(r1)
00039F8C  mtlr      r0
00039F90  addi      r1, r1, 0x10
00039F94  blr
00039FE8  lwz       r10, 0x15BC(r13)
000EFEBC  ori       r31, r23, 0xFFFF
000EFEC0  fnmadd.   f31, f31, f31, f31
000EFEC4  fnmadd.   f31, f31, f31, f31
000EFEC8  fnmadd.   f31, f31, f31, f31
000EFECC  fnmadd.   f31, f31, f31, f31
000EFED0  fnmadd.   f31, f31, f31, f31
000EFED4  fnmadd.   f31, f31, f31, f31
000EFED8  fnmadd.   f31, f31, f31, f31
000EFEDC  bcla      23, 4*cr7+so, 0xFFFFFFFC
000EFEE0  fnmadd.   f31, f31, f31, f31
000EFEE4  fnmadd.   f31, f31, f31, f31
000EFEE8  fnmadd.   f31, f31, f31, f31
000EFEEC  fnmadd.   f31, f31, f31, f31
000EFEF0  fnmadd.   f31, f31, f31, f31
000EFEF4  fnmadd.   f31, f31, f31, f31
000EFEF8  fnmadd.   f31, f31, f31, f31
000EFEFC  subfic    r23, r31, -1
000EFF00  fnmadd.   f31, f31, f31, f31
000EFF04  fnmadd.   f31, f31, f31, f31
000EFF08  fnmadd.   f31, f31, f31, f31
000EFF0C  fnmadd.   f31, f31, f31, f31
000EFF10  fnmadd.   f31, f31, f31, f31
000EFF14  fnmadd.   f31, f31, f31, f31
000EFF18  fnmadd.   f31, f31, f31, f31
