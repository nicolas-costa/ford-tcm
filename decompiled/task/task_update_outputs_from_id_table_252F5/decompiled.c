/* task_update_outputs_from_id_table_252F5 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00042584 end=0x00042640 size=188 */
/* export_utc=2026-01-10T18:12:42Z */

// Task: iterates a small fixed list of IO IDs from ROM table byte_252F5 (stride 4) and calls io_set_float_by_id_and_dispatch_15D0(id, r4=0, f4/f.. as value). Strong candidate for periodic solenoid/actuator output update path.
// local variable allocation has failed, the output may be wrong!
int __fastcall task_update_outputs_from_id_table_252F5(int a1)
{
  int v1; // r30
  int v2; // r20
  int v3; // fp31 OVERLAPPED
  __int64 v4; // fp14
  int v5; // r8
  int v6; // r7
  int v7; // r6
  int v8; // r5
  double v9; // fp4
  double v10; // fp3
  double v11; // fp2
  double v12; // fp1
  int v13; // r13
  int v14; // r31
  int v15; // r6
  int v16; // r3
  int v17; // r0
  int sender_lr; // [sp+14h] [+4h]

  sub_4213C(a1);
  *(_QWORD *)sub_0 = v4;
  v14 = v13 + 6084;
  do
  {
    if ( (*(_BYTE *)(v14 + 12) & 2) != 0 )
    {
      *(_WORD *)(v2 & 0x20000) = sub_424FC((unsigned __int8)v1);
      *(_WORD *)((char *)&sub_C + (v2 & 0x20000) + 2) = ((int (__fastcall *)(int, int))loc_41DFC)(v15, v2 & 0x20000);
      JUMPOUT(0x425DC);
    }
    v16 = io_set_float_by_id_and_dispatch_15D0(LOBYTE(word_252F4[2 * v1]), v12, v11, v10, v9, 0, v8, v7, v6, v5);// ROM table byte_252F5 used as ID list with 4-byte stride (lbzx r3, base, 4*idx). Parse table to extract candidate actuator IDs.
    v14 += 20;
    v1 = *(unsigned __int8 *)(v1 + 1);
  }
  while ( v1 < 7 );
  v17 = sender_lr;
  __tdeqi(*(_QWORD *)(&v3 - 1), 0x20u);
  return sub_42640(v16);
}
