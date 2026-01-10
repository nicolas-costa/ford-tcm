; diag_init_phase2_setbufptrs_and_timeout
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x0001C7B4 end=0x0001C8BC size=264
; export_utc=2026-01-10T18:12:42Z

0001C7B4  mflr      r0
0001C7B8  stw       r31, arg_C(r1)
0001C7BC  lhz       r0, arg_14(r1)
0001C7C0  addi      r31, r3, 0
0001C7C4  lbz       r12, 0x6D4E(r13)
0001C7C8  cmpwi     r12, 0
0001C7CC  bne       loc_1C808
0001C7D0  li        r12, 2
0001C7D4  stb       r12, 0x6D4E(r13)
0001C7D8  addi      r3, r13, 0x6C3D
0001C7DC  lhzu      r11, 0x6C30(r13)
0001C7E0  stw       r3, 0x6C34(r13)
0001C7E4  li        r10, 0x101
0001C7E8  sth       r10, 0x6D3E(r13)
0001C7EC  li        r3, 0
0001C7F0  stb       r3, 0x6D4C(r13)
0001C7F4  stb       r3, 0x6D4D(r13)
0001C7F8  lis       r12, dword_7BC@ha
0001C7FC  twgei     r12, -8
0001C800  sth       r12, 0x6D44(r13)
0001C804  bl        diag_update_mode_flags_6D4B_from_cfg
0001C808  lbz       r12, 0x6D4E(r13)
0001C80C  rlwinm    r12, r12, 0,30,30
0001C810  cmpwi     r12, 0
0001C814  beq       loc_1C8A8
0001C818  lbz       r12, 0x6C00(r13)
0001C8A8  lwz       r31, arg_C(r1)
0001C8AC  lwz       r0, arg_14(r1)
0001C8B0  mtlr      r0
0001C8B4  addi      r1, r1, 0x10
0001C8B8  blr
