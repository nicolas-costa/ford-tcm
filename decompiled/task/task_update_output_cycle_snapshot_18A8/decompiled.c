/* task_update_output_cycle_snapshot_18A8 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00041050 end=0x000410CC size=124 */
/* export_utc=2026-01-10T18:12:42Z */

// Post-step for output cycle: calls sub_42640 for indices 0..6 and stores into SDA 0x18A8..0x18B4; likely a debug/telemetry snapshot or derived scalars for the output cycle.
void __fastcall task_update_output_cycle_snapshot_18A8(int a1)
{
  unsigned int v1; // r0
  __int16 v2; // r3
  int v3; // r13
  __int16 v4; // r3
  int v5; // r13
  __int16 v6; // r3
  int v7; // r13
  __int16 v8; // r3
  int v9; // r13
  __int16 v10; // r3
  int v11; // r13

  __trap(0x1Bu, v1, 0);
  v2 = sub_42640(a1);
  *(_WORD *)(v3 + 6312) = v2;
  v4 = sub_42640(1);
  *(_WORD *)(v5 + 6314) = v4;
  sub_42640(2);
  v6 = sub_42640(3);
  *(_WORD *)(v7 + 6318) = v6;
  v8 = sub_42640(4);
  *(_WORD *)(v9 + 6320) = v8;
  *(_WORD *)(v9 + 6322) = 5;
  v10 = sub_42640(6);
  *(_WORD *)(v11 + 6324) = v10;
  ((void (__fastcall *)(int))loc_40D10)(9);
  __asm { lfdp      f16, 0xC(r1) }
  JUMPOUT(0x40D10);
}
