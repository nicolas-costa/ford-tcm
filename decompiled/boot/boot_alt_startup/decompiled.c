/* boot_alt_startup */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000182C4 end=0x00018310 size=76 */
/* export_utc=2026-01-10T18:12:42Z */

void __noreturn boot_alt_startup()
{
  __int64 inited; // r4
  int v1; // r10
  int v2; // r9
  int v3; // r8
  int v4; // r7
  int v5; // r6
  int v6; // r5
  int v7; // r4

  sub_1992C();
  init_immr_and_bootflags();
  early_hw_init_loop();
  inited = init_fpu_flags();
  init_copy_or_zero_ranges(SHIDWORD(inited));
  init_early_io_or_flash();
  boot_mode_select_and_jump();
  boot_init_stage1_apply_dword_10B40(0, v7, v6, v5, v4, v3, v2, v1);
  while ( 1 )
    ;
}
