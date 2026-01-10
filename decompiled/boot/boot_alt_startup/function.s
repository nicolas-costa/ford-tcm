; boot_alt_startup
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x000182C4 end=0x00018310 size=76
; export_utc=2026-01-10T18:12:42Z

000182C4  li        r0, 0
000182C8  lis       r11, 0x3F # '?'
000182CC  ori       r1, r11, 0x8F00 # 0x3F8F00
000182D0  lis       r13, 0x3F # '?'
000182D4  ori       r13, r13, 0x8F00 # 0x3F8F00
000182D8  lis       r2, word_10480@ha
000182DC  lhau      r2, word_10480@l(r2)
000182E0  stwu      r0, back_chain(r1)
000182E4  bl        sub_1992C
000182E8  bl        init_immr_and_bootflags
000182EC  bl        early_hw_init_loop
000182F0  bl        init_fpu_flags
000182F4  bl        init_copy_or_zero_ranges
000182F8  bl        init_early_io_or_flash
000182FC  lhz       r7, -0x877(r31)
00018300  bl        boot_mode_select_and_jump
00018304  li        r3, 0
00018308  bl        boot_init_stage1_apply_dword_10B40
0001830C  b         loc_1830C
