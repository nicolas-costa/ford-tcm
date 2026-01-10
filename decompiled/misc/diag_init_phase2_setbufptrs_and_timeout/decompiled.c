/* diag_init_phase2_setbufptrs_and_timeout */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0001C7B4 end=0x0001C8BC size=264 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
void diag_init_phase2_setbufptrs_and_timeout()
{
  int v0; // r13
  int v1; // r3
  int v2; // r13

  if ( !*(_BYTE *)(v0 + 27982) )
  {
    *(_BYTE *)(v0 + 27982) = 2;
    v1 = v0 + 27709;
    v2 = v0 + 27696;
    *(_DWORD *)(v2 + 27700) = v1;
    *(_WORD *)(v2 + 27966) = 257;
    *(_BYTE *)(v2 + 27980) = 0;
    *(_BYTE *)(v2 + 27981) = 0;
    __twgei((unsigned int)sub_0, 0xFFFFFFF8);
    *(_WORD *)(v2 + 27972) = (unsigned __int16)sub_0;
    diag_update_mode_flags_6D4B_from_cfg();
  }
  if ( (*(_BYTE *)(v0 + 27982) & 2) != 0 )
    JUMPOUT(0x1C81C);
}
