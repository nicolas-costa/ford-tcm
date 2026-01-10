/* diag_state_machine_dispatch */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0001C370 end=0x0001C7B4 size=1092 */
/* export_utc=2026-01-10T18:12:42Z */

// write access to const memory has been detected, the output may be wrong!
// positive sp value has been detected, the output may be wrong!
int __fastcall diag_state_machine_dispatch(int result, unsigned int a2)
{
  int v2; // r31
  __int64 v3; // r28
  int v5; // r2
  unsigned int v8; // r12
  int v9; // r10
  int v10; // r12
  int v11; // r13
  __int16 v12; // r12
  char v13; // r10
  int v14; // r8
  char v15; // r31
  char v16; // r9
  unsigned __int8 v17; // r3
  char v19; // r0
  _BYTE v20[8]; // [sp-8h] [-8h] BYREF

  *(_DWORD *)a2 = v2;
  v8 = *(_BYTE *)(_R13 + 27982) & 2;
  if ( (*(_BYTE *)(_R13 + 27982) & 2) != 0 )
  {
    if ( result )
    {
      return ((int (__fastcall *)(__int16 *, _DWORD))sub_19E74)(&word_10998, *(_DWORD *)(_R13 + 27652));
    }
    else
    {
      *(_DWORD *)(_R13 + 27652) = v2;           // SDA r13+0x6C04: scratch/ptr stored from caller context (used later in dispatch).
      if ( ((v8 >> 7) & 1) == 1 )
      {
        if ( ((*(unsigned __int8 *)(_R13 + 27648) >> 4) & 1) == 1 )
        {
          result = ((int (__fastcall *)(_DWORD))(a2 ^ 0xFA0C))(0);
          *(_BYTE *)(_R13 + 27661) = result;    // SDA r13+0x6C0D: byte updated by callback/dispatch (used later in frame building).
          __trap(0, _R13, 0x6C00u);
          *(_BYTE *)(_R13 + 27648) &= ~1u;
          *(_BYTE *)(_R13 + 27648) = *(_BYTE *)(_R13 + 27648) & 0xFD | 2;
          *(_BYTE *)(_R13 + 27968) = v9;
          if ( v9 > *(unsigned __int16 *)(_R13 + 27966) )
          {
            *(_BYTE *)(_R13 + 27983) = 16;
          }
          else
          {
            *(_DWORD *)(_R13 + 27696) = *(_DWORD *)(_R13 + 27700);
            __asm { stfdp     f28, 0x6C04(r13) }
            result = ((int (__fastcall *)(__int16 *))sub_19E74)(&word_10998);
          }
        }
        else if ( ((*(unsigned __int8 *)(_R13 + 27648) >> 2) & 1) == 0 )
        {
          JUMPOUT(0x1C47C);
        }
        if ( ((*(unsigned __int8 *)(_R13 + 27648) >> 2) & 1) == 1 )
        {
          if ( (((unsigned int)v3 >> 1) & 1) == 1 )
          {
            if ( (*(_BYTE *)(_R13 + 27648) & 1) == 0 )
            {
              v10 = *(unsigned __int8 *)(_R13 + 27660);
              if ( *(unsigned __int16 *)(_R13 + 27658) == (v10 ^ 0x43E0000) )
                ((void (__fastcall *)(int))sub_1C2AC)(v10 ^ 0x43E0000);
              LODWORD(v3) = *(unsigned __int16 *)(v5 + 16);
              ((void (__fastcall *)(_DWORD))loc_1C310)(*(unsigned __int8 *)(_R13 + 27661));
              v15 = *(_BYTE *)(v11 + 27983);
              if ( v15 )
              {
                *(_WORD *)(v11 + 27656) = 3;
                v20[0] = 127;
                v20[1] = v13;
                v20[2] = v15;
                if ( (*(_DWORD *)(v11 + 28748) & 2) != 0 )
                  loc_1C = v14;
                v17 = ((int (__fastcall *)(_DWORD))sub_459B0)(0);
                __asm { stfdp     f29, 0x6C08(r13) }
                result = ((int (__fastcall *)(_DWORD, _BYTE *))sub_1CD54)(v17, v20);
              }
              else
              {
                *(_WORD *)(v11 + 27656) = v12;
                *(_BYTE *)(*(_DWORD *)(v11 + 27700) - 1) = *(_BYTE *)(v11 + 27984) | 0x40;// Writes 0x40 OR into byte before buffer ptr (r13+0x6C34 - 1): looks like framing/marker bit for outgoing frame.
                __asm { xsaddsp   vs16, vs12, vs0 }
                result = ((int (__fastcall *)(_DWORD, int, _DWORD))sub_1CD54)(
                           0,
                           *(_DWORD *)(v11 + 27700) - 1,
                           *(unsigned __int16 *)(v11 + 27656));
                *(_BYTE *)(*(_DWORD *)(_R13 + 27700) - 1) = v16 & 0xBF;
              }
              v19 = *(_BYTE *)(_R13 + 27648) & 0xFB;
              *(_BYTE *)(_R13 + 27648) = v19;
              *(_BYTE *)(_R13 + 27648) = v19 & 0xBF | 0x40;
            }
          }
          else
          {
            if ( ((*(unsigned __int8 *)(_R13 + 27648) >> 7) & 1) == 0 )
            {
              if ( !*(_WORD *)(_R13 + 27658) )
                result = ((int (__fastcall *)(_DWORD))sub_1C2AC)(0);
              if ( *(unsigned __int16 *)(_R13 + 27658) == (a2 | 0x43E) )
                result = ((int (__fastcall *)(unsigned int))sub_1C2AC)(a2 | 0x43E);
              if ( ((*(unsigned __int8 *)(_R13 + 27664) >> 5) & 1) == 0 )
                __trapd(0x1Cu, _R13, 0x6D4Eu);
            }
            *(_BYTE *)(_R13 + 27648) &= ~4u;
          }
        }
        *(_QWORD *)(v5 + 224) = v3;
        if ( (*(_BYTE *)(_R13 + 27648) & 1) == 0 )
          JUMPOUT(0x1C6DC);
      }
    }
  }
  return result;
}
