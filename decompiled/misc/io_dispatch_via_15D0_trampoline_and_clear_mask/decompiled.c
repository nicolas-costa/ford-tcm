/* io_dispatch_via_15D0_trampoline_and_clear_mask */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00023F38 end=0x0002405C size=292 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall io_dispatch_via_15D0_trampoline_and_clear_mask(unsigned __int64 a1, int a2, int a3, int a4)
{
  int v4; // r20
  int v5; // r13
  int v6; // r2
  int v7; // r0
  unsigned __int8 v8; // r30
  int v9; // r8
  int v10; // r12
  int v11; // r31

  v8 = BYTE3(a1);
  v9 = -951 - v7;
  if ( ((*(_DWORD *)((char *)&sub_C + BYTE3(a1)) >> 30) & 1) != 0 )
  {
    *(_DWORD *)((char *)&sub_C + BYTE3(a1)) = *(_DWORD *)((char *)&sub_C + BYTE3(a1));
    sub_233C4(a1, *(unsigned __int16 *)((char *)&loc_8 + BYTE3(a1) + 2), a2, a3, a4, v9);
  }
  *(_BYTE *)(v6 + 60) = a1;
  v10 = *(_DWORD *)(*(_DWORD *)(v5 + 5584) + 4) + 16 * a1;// SDA r13+0x15D0: per-ID 16-byte trampoline table. Code sets LR=r12 (entry address) and blrl; entry+0xC is a context pointer.
  v11 = *(_DWORD *)(v10 + 12);
  if ( v11 )
  {
    *(_DWORD *)(v11 + 4) = v4;
    ((void (__fastcall *)(int, _DWORD, int, int, int, int))v10)(v11, a1, a2, a3, a4, v9);
  }
  HIDWORD(a1) = v8;
  return tpu_clear_channel_mask_4020_4420(a1);
}
