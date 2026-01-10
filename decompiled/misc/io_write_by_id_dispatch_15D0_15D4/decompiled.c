/* io_write_by_id_dispatch_15D0_15D4 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0003C16C end=0x0003C444 size=728 */
/* export_utc=2026-01-10T18:12:42Z */

int __fastcall io_write_by_id_dispatch_15D0_15D4(int a1, int a2)
{
  int v2; // r31
  int v3; // r30
  char v4; // r16
  int v7; // r13
  int result; // r3
  unsigned __int16 v10; // r28
  unsigned int v11; // r11
  int v12; // r29
  unsigned __int8 *v13; // r12
  char v14; // r24
  char v16; // cr34
  int v17; // r25

  __asm { rlmi      r3, r14, r0,0,0 }
  v10 = a2;
  v11 = *(_DWORD *)(v7 + 5584);                 // SDA r13+0x15D0: IO descriptor root for IDs < 0x64, with +4 pointing to 16-byte entries. Uses tpu_channel_regs_ptr_from_id for <0x64.
  v12 = *(_DWORD *)(v11 + 4);
  v13 = (unsigned __int8 *)(v12 + 16 * v3);
  v14 = v4 & 0x7F | v13[2] & 0x80;
  if ( *v13 >= 0x64u )
  {
    if ( *(unsigned __int8 *)(v12 + 16 * v3) >= 0x97u )
    {
      if ( (v4 & 4) == 4
        || (v17 = *(_DWORD *)(v7 + 5588), __trap(0xEu, v11, 0x1838u), (*(_DWORD *)(v17 + v11) & 1) != 0) )
      {
        JUMPOUT(0x3C27C);
      }
      __asm { rlmi.     r31, r15, r31,31,31 }
      JUMPOUT(0x1B07FC);
    }
    *(_DWORD *)(v13 + 1914) = v4 & 0x7F | v13[2] & 0x80;// SDA r13+0x15D4: word table used for IDs in [0x64..0x96] / [0x97..] paths; appears to store per-ID bitfields/state.
    *(_DWORD *)(v13 + 1918) = a2;
    *(_DWORD *)(v13 + 1922) = v12;
    *(_DWORD *)(v13 + 1926) = v3;
    *(_DWORD *)(v13 + 1930) = v2;
    *(_DWORD *)(*(_DWORD *)(v7 + 5588) + 8 * v3) = (4 * a2) | *(_DWORD *)(*(_DWORD *)(v7 + 5588) + 8 * v3) & 3;
  }
  else
  {
    result = tpu_channel_regs_ptr_from_id(*(unsigned __int8 *)(v12 + 16 * v3));
    _R12 = v14 & 4;
    __asm { stfdp     f24, 4(r12) }
    if ( !v16 && ((*(_DWORD *)(result + 12) >> 30) & 1) == 0 )
      return ((int (__fastcall *)(int, _DWORD))loc_23310)(v3, v10);
  }
  return result;
}
