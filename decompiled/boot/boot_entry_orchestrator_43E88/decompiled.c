/* boot_entry_orchestrator_43E88 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00043E88 end=0x00043EFC size=116 */
/* export_utc=2026-01-10T18:12:42Z */

// write access to const memory has been detected, the output may be wrong!
void boot_entry_orchestrator_43E88()
{
  double v0; // fp24
  int v1; // r7
  int v2; // r6
  int v3; // r5
  int v4; // r4
  int v5; // r3
  int v6; // r7
  int v7; // r6
  int v8; // r5
  int v9; // r4

  v5 = ((int (__fastcall *)(int))loc_445E0)(4);
  if ( v5 )
  {
    boot_mode_or_selftest_driver(v5, v4, v3, v2, v1);// FATO: boot_entry_orchestrator_43E88 chama boot_mode_or_selftest_driver (0x44B18), que por sua vez chama boot_apply_range_table_2A540_variants -> init_range_table_2A540_apply (0x44460).
    MEMORY[0x3FB345] = 1;
    sub_43DD0(0);
    while ( 1 )
    {
      flt_705 = v0;
      boot_mode_or_selftest_driver(0, v9, v8, v7, v6);
    }
  }
  JUMPOUT(0x4399C);
}
