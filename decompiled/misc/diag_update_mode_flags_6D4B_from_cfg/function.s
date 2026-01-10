; diag_update_mode_flags_6D4B_from_cfg
; idb=5U75-14C337-AA.rebuilt.aligned.bin
; start=0x00019AA0 end=0x00019AE4 size=68
; export_utc=2026-01-10T18:12:42Z

00019AA0  lis       r12, byte_BD38@ha
00019AA4  lbz       r12, byte_BD38@l(r12)
00019AA8  cmpwi     r12, 0xFF
00019AAC  bne       loc_19ABC
00019AB0  li        r12, 3
00019AB4  stb       r12, 0x6D4B(r13)# SDA r13+0x6D4B: flags/mode byte set from cfg bytes (byte_BD38/byte_1FC00) — diag/comms mode.
00019AB8  b         loc_19AC4
00019ABC  stdu      r12, 0(r0)
00019AC0  stb       r12, 0x6D4B(r13)
00019AC4  lis       r12, byte_1FC00@ha
00019AC8  lbz       r12, byte_1FC00@l(r12)
00019ACC  cmpwi     r12, 0xFF
00019AD0  bne       locret_19AE0
00019AD4  lbz       r12, 0x6D4B(r13)
00019AD8  ori       r12, r12, 0xC
00019AE0  blr
