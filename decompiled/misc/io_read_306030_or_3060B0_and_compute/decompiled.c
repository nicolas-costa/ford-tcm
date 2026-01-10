/* io_read_306030_or_3060B0_and_compute */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000245E8 end=0x00024834 size=588 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall io_read_306030_or_3060B0_and_compute(int a1)
{
  __int16 v1; // r28
  __int16 v2; // r20
  int v3; // r13
  int v6; // r30
  int v8; // r13
  int v9; // r4
  int v10; // ctr
  unsigned int v12; // r31
  unsigned __int16 v14; // [sp+Eh] [-1Ah]
  int v15; // [sp+14h] [-14h]
  unsigned int v16; // [sp+18h] [-10h]

  v6 = *(_DWORD *)(v3 + 5408) + 20 * a1;
  v16 = *(_DWORD *)(*(_DWORD *)(*(_DWORD *)(v3 + 5404) + 4) + 4);
  ((void (__fastcall *)(int))loc_2447C)(a1);
  v9 = *(_DWORD *)(v8 + 5404);
  if ( v10 != 1 )
  {
    __asm { dozi      r27, r10, 0x1D78 }
    v15 = *(_DWORD *)(_R10 + 3170392);
    v12 = *(_BYTE *)(v6 + 18) & 0x7F;
    if ( v12 >= 2 )
    {
      if ( v12 <= 2 && *(_WORD *)(v6 + 8) )
        JUMPOUT(0x246FC);
      if ( v14 > v16 )
        *(_WORD *)0xFFFFFFFF = v1;
    }
    else
    {
      *(_WORD *)sub_0 = v2;
    }
    if ( v12 )
    {
      if ( *(unsigned __int16 *)(v6 + 6) < 2u )
        JUMPOUT(0x2477C);
      _R9 = HIWORD(v15);
      __asm { stfdp     f26, 0x5050(r9) }
      JUMPOUT(0x247DC);
    }
    ((void (__fastcall *)(int, int, int))loc_2447C)(a1, v9, 1);
    JUMPOUT(0x24834);
  }
  JUMPOUT(0x24050);
}
