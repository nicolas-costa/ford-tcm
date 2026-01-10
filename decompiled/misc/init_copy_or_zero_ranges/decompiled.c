/* init_copy_or_zero_ranges */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00017AE8 end=0x00017B78 size=144 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall init_copy_or_zero_ranges(int result)
{
  int v1; // r30
  unsigned int i; // r31

  for ( i = 0; i < 0x3F9000; ++i )
  {
    _R29 = *(_DWORD *)(v1 + 4);
    v1 += 8;
    __trap(3u, _R29, 0);
    memset_like_loc_1796C();
  }
  __asm { rlmi      r1, r29, r0,0,6 }
}
