/* init_fpu_flags */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00017BBC end=0x00017BE8 size=44 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
__int64 init_fpu_flags()
{
  int v0; // ctr
  __int64 result; // r4

  if ( v0 != 1 )
    JUMPOUT(0x17BB4);
  result = 4LL;
  __asm
  {
    mtfsfi    6, 0
    mtfsfi    7, 4
  }
  return result;
}
