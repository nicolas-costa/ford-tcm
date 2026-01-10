/* tpu_channel_regs_ptr_from_id */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00033BA4 end=0x00033BD8 size=52 */
/* export_utc=2026-01-10T18:12:42Z */

// Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
int __fastcall sub_33BA4(int a1)
{
  int v1; // r4

  if ( a1 >= 16 )
  {
    v1 = 3145728;
    a1 = (unsigned __int8)(a1 - 16);
  }
  else
  {
    v1 = 3162112;
  }
  return v1 + 16 * a1 + 256;
}
