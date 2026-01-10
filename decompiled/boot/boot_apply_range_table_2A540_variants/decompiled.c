/* boot_apply_range_table_2A540_variants */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000448D8 end=0x00044B18 size=576 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall boot_apply_range_table_2A540_variants(int a1, int a2, int a3, int a4, int a5, int a6)
{
  __int16 v6; // r24
  int v7; // r0
  bool v8; // cr34
  int result; // r3

  *(_DWORD *)(a6 + 678) = v7;
  do
  {
    v8 = MEMORY[0x3FBB88] == 1;
    if ( MEMORY[0x3FBB88] == 1 )
    {
      result = ((int (*)(void))loc_441EC)();
      v8 = MEMORY[0x3FBB88] == 2;
      if ( MEMORY[0x3FBB88] != 2 )
        return result;
      MEMORY[0x3FBB88] = 0;
    }
    *(_WORD *)sub_0 = v6;
  }
  while ( !v8 );
  return result;
}
