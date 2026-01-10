/* task_wrapper_guard_1650_output_cycle */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0002144C end=0x00021470 size=36 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall __noreturn task_wrapper_guard_1650_output_cycle(
        double a1,
        double a2,
        double a3,
        double a4,
        double a5,
        double a6,
        double a7)
{
  int v7; // r13

  *(_DWORD *)(v7 + 5712) = 20;                  // SDA r13+0x1650 temporarily set to 0x14 around the output cycle; likely a scheduler guard/priority/deadline field for this task.
  sub_325FC(a1, a2, a3, a4, a5, a6, a7);
  task_group_output_update_cycle();
}
