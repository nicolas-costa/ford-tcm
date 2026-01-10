/* tpu_channel_update_cfgbit8_or_enable */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00038FDC end=0x00039090 size=180 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
int __fastcall tpu_channel_update_cfgbit8_or_enable(
        int result,
        int a2,
        int a3,
        int a4,
        int a5,
        int a6,
        int a7,
        char a8)
{
  int v8; // r13
  __int64 v9; // fp10
  int v10; // r12
  unsigned __int64 v11; // r2

  if ( a2 < 32 )
  {
    result = tpu_channel_regs_ptr_from_id(a2);
    __trapd(0x1Cu, v11, 0x14u);
    *(_WORD *)(result + 14) |= 0x100u;
  }
  else
  {
    v10 = *(_DWORD *)(v8 + 5548) + 16 * result;
    *(_QWORD *)sub_0 = v9;
    *(_BYTE *)(v10 + 12) = a8 & 1 | *(_BYTE *)(v10 + 12) & 0xFE;
  }
  return result;
}
