/* diag_dispatch_or_submit_frame */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0001C8BC end=0x0001CAE8 size=556 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall diag_dispatch_or_submit_frame(int a1, int a2, int a3, int a4)
{
  int v4; // r13
  int v6; // r12
  bool v7; // cr34
  unsigned int v8; // r13

  v6 = *(unsigned __int8 *)(v4 + 27982);
  v7 = v6 == 0;
  if ( !*(_BYTE *)(v4 + 27982) )
  {
    *(_BYTE *)(v4 + 27982) = v6;
    *(_DWORD *)(v4 + 27696) = v4 + 27709;
    *(_DWORD *)(v4 + 27700) = v4 + 27709;
    *(_WORD *)(v4 + 27966) = 257;
    v8 = __ROL4__(0, v4) & 0xFE0007FF;
    *(_BYTE *)(v8 + 27981) = 0;
    *(_WORD *)(v8 + 27972) = (unsigned __int16)&loc_FFF6 + 2;
    diag_update_mode_flags_6D4B_from_cfg();
  }
  if ( !v7 && ((*(unsigned __int8 *)(v4 + 27648) >> 7) & 1) == 0 )
    JUMPOUT(0xDC93C);
  return sub_1CCE4(a1);
}
