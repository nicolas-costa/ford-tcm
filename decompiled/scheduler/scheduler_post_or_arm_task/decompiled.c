/* scheduler_post_or_arm_task */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00039E18 end=0x00039F98 size=384 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall scheduler_post_or_arm_task(int result, int a2, int a3, int a4, int a5, int a6)
{
  char v6; // r27
  int v7; // r24
  int v9; // r17
  int v12; // r30
  int v13; // r11
  int v14; // r12

  *(_WORD *)(a6 + 678) = v7;
  v12 = result;
  *(_BYTE *)(_R13 + 5580) = 1;
  *(_DWORD *)(v9 + 5030) = v7;
  v13 = *(_DWORD *)(_R13 + 15364) + 1;
  *(_DWORD *)(_R13 + 15364) = v13;
  if ( a2 )
  {
    if ( *(_DWORD *)(*(_DWORD *)(*(_DWORD *)(*(_DWORD *)(_R13 + 5568) + 8) + v13) + 12) )
    {
      __asm { mfdec     r3 }
      MEMORY[0xFFFFFFFC](_R3, a2, a3, a4, a5);
      JUMPOUT(0xEFF1C);
    }
    do
    {
      v14 = *(_DWORD *)(_R13 + 5564);
      __asm { mfdec     r3 }
      *(_BYTE *)(_R13 + 5564) = v6;
    }
    while ( v13 != v14 );
    result = v14 - _R3 + 21012;
    *(_DWORD *)(*(_DWORD *)(_R13 + 5572) + 4 * v12) = result;
    *(_DWORD *)(_R13 + 5576) |= 1 << v12;
    __asm { lxsd      v3, 0x2A4(r22) }
    if ( result > *(_DWORD *)(*(_DWORD *)(*(_DWORD *)(*(_DWORD *)(_R13 + 5568) + 8) + 4 * v12) + 8) )
    {
      *(_DWORD *)(_R13 + 5560) = (unsigned __int64)(*(_QWORD *)(_R13 + 5560) - result) >> 32;
      _R13 += 5564;
      result = -1;
      __asm { mtdec     r3 }
    }
  }
  else
  {
    __asm { evmwlumianw r20, r13, r2 }
  }
  if ( !--*(_DWORD *)(_R13 + 15364) )
    __isync();
  return result;
}
