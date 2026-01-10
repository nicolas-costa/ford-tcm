/* diag_update_status_from_rx_header */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0001B318 end=0x0001B53C size=548 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall diag_update_status_from_rx_header(int a1, __int16 a2)
{
  __int16 v2; // r24
  int v3; // r13
  unsigned int v4; // r12
  int v5; // r3
  bool v6; // cr34
  unsigned __int8 *v7; // r3
  int v8; // r11

  v4 = *(unsigned __int16 *)(v3 + 27968);
  if ( v4 == 5 )
  {
    v4 = *(_DWORD *)(v3 + 28748) & 2;
    v5 = *(unsigned __int8 *)(v3 + 28279);
    v6 = v5 == 0;
    if ( !*(_BYTE *)(v3 + 28279) || (v6 = v5 == 5) )
    {
      v7 = *(unsigned __int8 **)(v3 + 27696);
      v2 = *(_WORD *)((char *)&loc_A8 + v7[1] + 2);
      if ( v6 )
      {
        v4 = v7[2];
        if ( v4 == 195 )
        {
          v4 = v7[3];
          if ( v4 == 85 )
            goto LABEL_9;
        }
      }
    }
  }
  *(_WORD *)(v3 + 27648) = a2;                  // SDA r13+0x6C00: 16-bit/byte flag word used as state/flags; this write stores input word.
  v4 = (v4 >> 7) & 1;
  if ( v4 == 1 || (v4 = (*(unsigned __int8 *)(v3 + 27664) >> 5) & 1) != 0 )
  {
LABEL_9:
    *(_DWORD *)sub_0 = v4;
    *(_BYTE *)(v3 + 27983) = v4;                // SDA r13+0x6D4F: status/result code byte (set to 0x11 often; set earlier on success path).
    v8 = **(unsigned __int8 **)(v3 + 27696);
    if ( v8 == 1 )
    {
      *(_BYTE *)(*(_BYTE *)(v3 + 27979) & 2) = v2;
      *(_BYTE *)(v3 + 27983) = 17;
    }
  }
  else
  {
    *(_BYTE *)(v3 + 27983) = 17;
  }
}
