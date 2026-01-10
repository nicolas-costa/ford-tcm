/* init_immr_and_bootflags */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00017B78 end=0x00017BBC size=68 */
/* export_utc=2026-01-10T18:12:42Z */

int init_immr_and_bootflags()
{
  int v0; // r13
  int result; // r3

  *(_BYTE *)(v0 + 28870) = 0;
  __asm { mfspr     r3, immr # Internal Memory Mapping Register }
  *(_BYTE *)(v0 + 28870) |= 2u;
  return result;
}
