/* task_group_output_update_cycle */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0004A60C end=0x0004A668 size=92 */
/* export_utc=2026-01-10T18:12:42Z */

// write access to const memory has been detected, the output may be wrong!
void __noreturn task_group_output_update_cycle()
{
  __int64 v0; // r19
  int v1; // r3
  int v2; // r3
  int updated; // r3

  v1 = ((int (*)(void))loc_41C1C)();
  loc_30 = v0;
  *(_DWORD *)(v1 - 16368) = *(_DWORD *)(v1 - 16368) & 0xDFFFFFFF | 0x20000000;
  v2 = task_prepare_output_cycle_from_table_252F4();// Calls sub_42674 then task_update_outputs_from_id_table_252F5 then sub_41050. This wrapper is a scheduled cycle; good anchor to find who schedules output updates.
  updated = task_update_outputs_from_id_table_252F5(v2);
  task_update_output_cycle_snapshot_18A8(updated);
  sub_257C0();
}
