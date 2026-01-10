/* io_update_masks_and_outputs_30xx */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0003BB10 end=0x0003BFCC size=1212 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
void __fastcall io_update_masks_and_outputs_30xx(int a1, unsigned __int8 a2, int a3, int a4, int a5, __int16 a6)
{
  unsigned __int8 v6; // r29
  int v9; // r14
  double v13; // fp29
  __int64 v15; // fp16
  unsigned __int8 v18; // r29
  int v19; // r13
  int v21; // r5
  bool v22; // cr34
  int v23; // r12

  *(float *)(*(_DWORD *)(_R13[1396] + 4) + 22702) = v13;
  if ( v6 >= 0x64u )
  {
    if ( v6 >= 0x97u )
    {
      if ( v6 < 0xA7u )
      {
        MEMORY[0x306C04] = 1 << (v6 + 116);
        *(_DWORD *)(_R13[1397] + 8 * a1) = (2 * a2) & 2 | *(_DWORD *)(_R13[1397] + 8 * a1) & 0xFFFFFFFD;
        JUMPOUT(0x3BE5C);
      }
      JUMPOUT(0x3BEFC);
    }
    v19 = *(_DWORD *)((char *)&loc_63C + v6 + 2);
    if ( v6 + 1598 >= 116 )
    {
      MEMORY[0x306C44] = _R0 & ~(unsigned __int16)(1 << (v6 + (a2 | 0x8C)));
      *(_QWORD *)(*(_DWORD *)(v19 + 5588) + 18734) = v15;
      if ( !a2 )
        __asm { stfdp     f12, 0x214(r2) }
      _R12 = MEMORY[0x306C44];
      __asm { evstwwemx r20, r12, r11 }
    }
    else
    {
      __asm { rlmi.     r0, r18, r0,0,0 }
      MEMORY[0x306C04] &= ~(unsigned __int16)(v6 << (v6 - 100));
      v21 = *(_DWORD *)(v19 + 5588);
      *(_DWORD *)(v21 + v6 + 65436) = (2 * a2) & 2 | *(_DWORD *)(v21 + v6 + 65436) & 0xFFFFFFFD;
      v22 = a2 == 0;
      if ( a2 || (v23 = *(_DWORD *)(v21 + (v9 ^ 0x18380000)) & 1, v22 = v23 == 0, v23) )
      {
        *(_WORD *)(*(_DWORD *)(v21 + 8 * a1) & 1) = a6;
        if ( v22 )
          JUMPOUT(0x3BCFC);
        MEMORY[0x306C04] |= (16 * (_WORD)a1) << (v6 - 100);
      }
    }
  }
  else
  {
    if ( v6 < 0x10u )
      JUMPOUT(0x3BB5C);
    v18 = v6 - 16;
    __asm
    {
      mtspr     eid, r0 # External interrupt disable
      stfdp     f20, 0x3C04(r13)
    }
    MEMORY[0x30440A] &= ~(1 << v18);
    if ( !_R13[3841] )
    {
      __isync();
      __asm { mtspr     eie, r0 # External interrupt enable }
    }
    tpu_channel_regs_ptr_from_id(v18);
    MEMORY[0x30440C] = (a2 << 31) | MEMORY[0x30440C] & 0x7FFFFFFF;
    if ( a2 )
      JUMPOUT(0x3BBDC);
  }
  JUMPOUT(0x3BFBC);
}
