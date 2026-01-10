/* tpu_clear_channel_mask_4020_4420 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000343E8 end=0x00034444 size=92 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall sub_343E8(unsigned __int64 a1)
{
  LODWORD(a1) = 3145728;
  if ( BYTE3(a1) >= 0x10u )
  {
    __trapd(3u, a1, 0x4420u);
    MEMORY[0x304420] = ~(1 << ((char)&MEMORY[0xFFF0] + BYTE3(a1)));
  }
  else
  {
    MEMORY[0x304020] = ~(1 << SBYTE3(a1));
  }
  return HIDWORD(a1);
}
