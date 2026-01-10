/* timing_delay_or_measure */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00041C88 end=0x00041CFC size=116 */
/* export_utc=2026-01-10T18:12:42Z */

unsigned int __fastcall timing_delay_or_measure(int a1, int a2)
{
  int v2; // r13
  int v3; // r12
  unsigned int v6; // r31
  unsigned int result; // r3

  do
  {
    v2 += 5564;
    *(_WORD *)v2 = v3;
    __asm { mfdec     r3 }
  }
  while ( *(_DWORD *)(v2 + 5564) != v3 );
  *(_DWORD *)((char *)&loc_5B94 + 1000 * a1 + 2) = a2;
  v6 = v3 - _R3 + 1000 * a1 + 4;
  do
    __asm { mfdec     r3 }
  while ( result < v6 );
  return result;
}
