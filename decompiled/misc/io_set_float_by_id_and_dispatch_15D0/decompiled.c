/* io_set_float_by_id_and_dispatch_15D0 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0003BFCC end=0x0003C01C size=80 */
/* export_utc=2026-01-10T18:12:42Z */

// write access to const memory has been detected, the output may be wrong!
int __fastcall io_set_float_by_id_and_dispatch_15D0(
        int a1,
        double a2,
        double a3,
        double a4,
        double a5,
        int a6,
        int a7,
        int a8,
        int a9,
        int a10)
{
  int v10; // r13
  double v11; // fp28
  int v12; // r12

  v12 = *(_DWORD *)(v10 + 5584);                // Uses SDA r13+0x15D0 as base for per-ID entries; stores float (f4) to entry+4 then dispatches based on ID range (<0x64 / <0x97 / etc). Likely generic IO write-by-ID helper.
  *(float *)(v12 + 4) = a5;
  if ( *(unsigned __int8 *)(v12 + 16 * a1) < 0x64u )
    sub_233C4(a1, a6, *(unsigned __int8 *)(v12 + 16 * a1), a8, a9, a10);
  sub_C = v11;
  return ((int (__fastcall *)(double, double, double))loc_23748)(a2, a3, a4);
}
