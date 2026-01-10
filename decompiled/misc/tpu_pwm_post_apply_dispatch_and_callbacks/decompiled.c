/* tpu_pwm_post_apply_dispatch_and_callbacks */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00021ACC end=0x00021BC4 size=248 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall tpu_pwm_post_apply_dispatch_and_callbacks(int result, int a2, int a3)
{
  int v3; // r19
  int v4; // r12
  double v5; // fp30
  int v6; // r6
  char v7; // r4

  v6 = (unsigned __int8)(*(_BYTE *)(v4 + 16 * result) - 32);
  v7 = *(&loc_3050 + 1) + 11;
  if ( a3 == 1 )
  {
    if ( (unsigned __int8)(*(_BYTE *)(v4 + 16 * result) - 32) >= 0x10u )
      *(_WORD *)(result + 27716) = *(_WORD *)((char *)&unk_6C44 + (v3 & 0x80000000)) | (1 << v7);
    else
      *(_WORD *)(result + 27652) = MEMORY[0x306C04] | (1 << v7);
    JUMPOUT(0x21B5C);
  }
  if ( (unsigned __int8)(*(_BYTE *)(v4 + 16 * result) - 32) >= 0x10u )
    JUMPOUT(0x1C91B9C);
  MEMORY[0x300000] = v5;
  *(_WORD *)(v6 + 27652) = MEMORY[0x306C04] & ~(1 << v7);
  return result;
}
