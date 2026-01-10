/* tpu_pwm_run_entry_callbacks_high_count_15B0 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00021A08 end=0x00021ACC size=196 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall tpu_pwm_run_entry_callbacks_high_count_15B0(int a1)
{
  int v1; // r13
  int (__fastcall *v2)(int); // r0

  __asm { xsaddsp   vs14, vs0, vs0 }
  if ( *(_BYTE *)(v1 + 5552) )
    JUMPOUT(0x21A3C);
  return v2(a1);
}
