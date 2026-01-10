/* init_early_io_or_flash */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00017BE8 end=0x00017CC4 size=220 */
/* export_utc=2026-01-10T18:12:42Z */

// local variable allocation has failed, the output may be wrong!
int sub_17BE8()
{
  char v0; // r23
  __int64 v1; // r19 OVERLAPPED
  int v2; // r13
  unsigned int v3; // r11
  int result; // r3

  if ( ((v3 >> 12) & 1) != 0 )
  {
    MEMORY[0xFFFFAA39] = 0;
    MEMORY[0x2FC004] = 61439887;
    MEMORY[0x2FC00C] = *(_OWORD *)&v1;
    result = 3145728;
    MEMORY[0x2FC00E] = 0;
  }
  else
  {
    MEMORY[0xFFFFAA39] = v0;
    MEMORY[0x2FC004] = 61439887;
    MEMORY[0x2FC00E] = MEMORY[0x2FC040];
    __asm
    {
      mfdec     r3
      mfdec     r3
    }
    *(_BYTE *)(v2 + 28870) |= 4u;
  }
  return result;
}
