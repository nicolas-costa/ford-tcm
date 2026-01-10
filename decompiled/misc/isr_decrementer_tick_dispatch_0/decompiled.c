/* isr_decrementer_tick_dispatch_0 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000396D0 end=0x00039E18 size=1864 */
/* export_utc=2026-01-10T18:12:42Z */

// write access to const memory has been detected, the output may be wrong!
void __fastcall isr_decrementer_tick_dispatch_0(unsigned __int8 *a1, int a2, int a3, int a4, int a5)
{
  int v5; // r23
  int v6; // r20
  int v7; // r13
  double v8; // fp28
  int (__fastcall *v9)(int, _DWORD, int, int, int); // lr
  int v13; // r3
  _DWORD *v15; // r13
  int v17; // r8
  int v18; // r11
  _DWORD *v20; // r28
  int v21; // r28
  int v22; // r30
  int sender_lr; // [sp+44h] [+4h]

  _R8 = sender_lr;
  *(_DWORD *)(v7 + 5576) = 0;
  __asm { dozi      r17, r8, 0x3A6 }
  v13 = v9((4 * a1[1]) & 0x3FC, 0, a3, a4, a5);
  v15[1393] = v13;
  __asm { mtspr     eid, r0 # External interrupt disable }
  v15[3841] = __ROL4__(a1, _R0) & 0x80000000;
  __asm { mfdec     r3 }
  v17 = v15[1391] - _R3;
  v18 = v5 ^ 0x3910;
  v15[1390] = v15[1390];
  v15[1391] = v17;
  _R3 = 0;
  __asm { mtdec     r3 }
  --v15[3841];
  if ( v15 == dword_3C04 )
  {
    __isync();
    __asm { mtspr     eie, r0 # External interrupt enable }
  }
  v20 = (_DWORD *)(v6 & 0xADCC0000);
  *v20 = 2000000;
  v20[1] = 2000000;
  v21 = 1;
  if ( *a1 > 1u )
  {
    do
    {
      v22 = *((_DWORD *)a1 + 1);
      *(_DWORD *)(v18 + 4154) = v6;
      if ( *(unsigned __int8 *)(v22 + v18 + 4154) <= 0xAu )
      {
        flt_420 = v8;
        JUMPOUT(0x397C0);
      }
      ++v21;
      v18 = *a1;
    }
    while ( v18 > v21 );
  }
  JUMPOUT(0x39DBC);
}
