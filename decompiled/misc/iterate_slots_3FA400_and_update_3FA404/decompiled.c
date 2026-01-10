/* iterate_slots_3FA400_and_update_3FA404 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00031698 end=0x000317A8 size=272 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall iterate_slots_3FA400_and_update_3FA404(int a1, int a2, int a3, int a4)
{
  unsigned int v4; // r30
  double v5; // fp16
  int v6; // r31
  char v7; // cr33
  int v8; // r29
  __int16 v9; // r3

  v6 = 0;
  *(float *)*(unsigned __int8 *)(MEMORY[0x3FA400] + 2) = v5;
  if ( v7 )
  {
    do
    {
      v8 = 3 * v4;
      if ( *(_BYTE *)(MEMORY[0x3FA404] + 3 * v4 + 2) )
      {
        v4 = a4 & 0xFE000000;
        if ( *(_BYTE *)(*(_DWORD *)(MEMORY[0x3FA400] + 8) + (a4 & 0xFE000000)) >> 6 == 1 )
        {
          v9 = *(_WORD *)(*(_DWORD *)(MEMORY[0x3FA400] + 16) + 8 * v6);
          if ( (_BYTE)v9 )
          {
            __asm { xsaddsp   vs8, vs12, vs0 }
            MEMORY[0x3FA404] = (*(unsigned __int8 *)(*(_DWORD *)(MEMORY[0x3FA400] + 8) + v4) >> 4) & 3;
            *(_BYTE *)(MEMORY[0x3FA404] + v8 + 2) = 0;
            JUMPOUT(0x3177C);
          }
        }
      }
      ++v6;
    }
    while ( *(unsigned __int8 *)(MEMORY[0x3FA400] + 2) > v6 );
  }
  JUMPOUT(0x3179C);
}
