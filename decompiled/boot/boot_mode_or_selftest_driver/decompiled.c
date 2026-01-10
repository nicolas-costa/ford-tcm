/* boot_mode_or_selftest_driver */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00044B18 end=0x00044C6C size=340 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall boot_mode_or_selftest_driver(int result, int a2, int a3, int a4, int a5)
{
  int v5; // r31
  __int16 v6; // r28
  int v7; // r24
  char v8; // r15
  int v9; // r2
  int v10; // r11

  v10 = MEMORY[0x3FBB95];
  if ( MEMORY[0x3FBB95] == 1 )
  {
    *(_BYTE *)(v5 - 1603) = v8;
    return 0;
  }
  else
  {
    *(_WORD *)(v9 + 108) = v6;
    if ( v10 == 3 )
    {
      return boot_apply_range_table_2A540_variants(result, a2, a3, a4, a5, v7 & 0xFFE00000);
    }
    else if ( v10 == 4 )
    {
      JUMPOUT(0x164A1A8);
    }
  }
  return result;
}
