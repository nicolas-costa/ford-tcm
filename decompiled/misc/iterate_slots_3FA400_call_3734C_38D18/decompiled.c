/* iterate_slots_3FA400_call_3734C_38D18 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000317A8 end=0x0003185C size=180 */
/* export_utc=2026-01-10T18:12:42Z */

void iterate_slots_3FA400_call_3734C_38D18()
{
  int v0; // r14
  unsigned int v1; // r30

  v1 = v0 & 0xA4000000;
  if ( *(_BYTE *)(*(_DWORD *)(v0 & 0xA4000000) + 2) )
  {
    ((void (__fastcall *)(_DWORD))loc_3734C)(*(unsigned __int16 *)*(unsigned __int16 *)(*(_DWORD *)v1 + 16));
    sub_38D18(**(unsigned __int16 **)(*(_DWORD *)v1 + 16), 0);
  }
}
