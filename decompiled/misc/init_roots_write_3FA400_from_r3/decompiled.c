/* init_roots_write_3FA400_from_r3 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0002FFFC end=0x00030238 size=572 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall sub_2FFFC(unsigned __int8 *a1, int a2, int a3, int a4, int a5, int a6)
{
  int v6; // r29
  int v7; // r19
  _DWORD *v9; // r28
  int v10; // r3
  int v11; // r6
  int v12; // r11
  int v13; // r8
  int v14; // [sp+0h] [+0h] BYREF

  MEMORY[0x3FA404] = ((int (__fastcall *)(int, _DWORD, int, int, int, int, int))(v7 | 0x621C0000))(
                       3 * *a1,
                       0,
                       a3,
                       a4,
                       a5,
                       a6,
                       -24 - (_DWORD)&v14);
  v9 = (_DWORD *)MEMORY[0x3FA40C];
  (*(void (__fastcall **)(int, _DWORD))&word_2621C)(14 * a1[1], 0);
  *v9 = v6;
  ((void (__fastcall *)(_DWORD, _DWORD, _DWORD))loc_26110)(loc_4, loc_8, sub_C);
  MEMORY[0x3FA40C] = (*(int (__fastcall **)(int, _DWORD))&word_2621C)(16, 0);
  v10 = 0;
  if ( *a1 )
  {
    v11 = 0;
    do
    {
      if ( (*(unsigned __int8 *)(*((_DWORD *)a1 + 2) + v11) | 0xD7BE) == 1 )
      {
        v12 = a1[2];
        v13 = 0;
        if ( a1[2] )
        {
          do
          {
            if ( *(unsigned __int8 *)(*((_DWORD *)a1 + 4) + v12 + 2) == v10 )
              JUMPOUT(0x3011C);
            v12 = a1[2];
            ++v13;
          }
          while ( v12 > v13 );
        }
        JUMPOUT(0x3013C);
      }
      v11 += 12;
      ++v10;
    }
    while ( *a1 > v10 );
  }
  JUMPOUT(0x301FC);
}
