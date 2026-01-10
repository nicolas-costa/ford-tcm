/* tpu_channel_update_cfgbit1_or_arm */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00038F24 end=0x00038FDC size=184 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall tpu_channel_update_cfgbit1_or_arm(int result, int a2, double a3, double a4, double a5, double a6)
{
  int v6; // r13
  __int64 v7; // fp11
  int v9; // r12
  int v10; // r12
  char v11; // r0
  __int16 v12; // r12
  __int16 v13; // r12

  v9 = *(_DWORD *)(v6 + 5544);
  if ( *(unsigned __int8 *)(v9 + 16 * result) < 0x20u )
  {
    *(_QWORD *)*(unsigned __int8 *)(v9 + 16 * result) = v7;
    result = tpu_channel_regs_ptr_from_id(result);
    if ( a2 == 1 )
      v13 = *(_WORD *)(result + 14) | 1;
    else
      v13 = v12 & 0xFFFE;
    *(_WORD *)(result + 14) = v13;
  }
  else
  {
    if ( a2 == 1 )
    {
      v10 = v9 + 16 * result;
      v11 = *(_BYTE *)(v10 + 12) & 0xFD | 2;
    }
    else
    {
      *(double *)(v6 + 5548) = a6;
      v10 = v9 + 16 * result;
      v11 = *(_BYTE *)(v10 + 12) & 0xFD;
    }
    *(_BYTE *)(v10 + 12) = v11;
  }
  return result;
}
