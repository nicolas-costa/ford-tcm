/* task_prepare_output_cycle_from_table_252F4 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00042674 end=0x000426E4 size=112 */
/* export_utc=2026-01-10T18:12:42Z */

// Pre-step for output cycle: iterates ROM table unk_252F4/unk_252F0 and calls loc_35CD0 for each entry, writing results into SDA array at r13+0x23A2 (word list). Feels like preparing per-channel inputs/filtered values before driving outputs.
// write access to const memory has been detected, the output may be wrong!
int task_prepare_output_cycle_from_table_252F4()
{
  int v0; // r28
  int v1; // r13
  _WORD *v2; // r29
  unsigned __int8 *v4; // r31
  int result; // r3
  float v7; // [sp+8h] [-10h]

  v2 = (_WORD *)(v1 + 9122);
  _R30 = v1 + 6066;
  v4 = (unsigned __int8 *)&unk_252F0;
  *(double *)((char *)&loc_4 + 3) = v7;
  do
  {
    v4 += 4;
    result = ((int (__fastcall *)(_DWORD))loc_35CD0)(*v4);
    ++v2;
    __asm { dozi      r12, r30, 0x14 }
    *v2 = result;
    --v0;
  }
  while ( v0 );
  return result;
}
