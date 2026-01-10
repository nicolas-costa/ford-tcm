/* tpu_pwm_entry_apply_via_tpu_regs */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00021CB8 end=0x00021F74 size=700 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
void __fastcall tpu_pwm_entry_apply_via_tpu_regs(int a1, int a2, int a3, int a4, int a5, int a6)
{
  ((void (__fastcall *)(_DWORD, int, int, int, int, int))sub_339B4)(
    *(unsigned __int8 *)(*(_DWORD *)(a2 + 4) + 16 * a1),
    a1,
    a3 + 7872,
    a4,
    a5,
    a6 + 678);
  JUMPOUT(0x21CFC);
}
