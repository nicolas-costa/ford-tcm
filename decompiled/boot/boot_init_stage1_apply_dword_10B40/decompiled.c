/* boot_init_stage1_apply_dword_10B40 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00017D20 end=0x00017EDC size=444 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall boot_init_stage1_apply_dword_10B40(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8)
{
  int v8; // r31
  int v9; // r29
  int v10; // r28
  int v11; // r27
  int v12; // r26
  int v13; // r25
  int v14; // r24
  int v15; // r23
  int v16; // r22
  int v17; // r21
  int v18; // r20
  int v19; // r19
  int v20; // r18
  int v21; // r17
  int v22; // r16
  int v23; // r15
  int v24; // r14
  int v25; // r13
  int v26; // r12
  int v27; // r11
  _DWORD *v28; // r2

  v28[13] = a2;
  v28[14] = a3;
  v28[15] = a4;
  v28[16] = a5;
  v28[17] = a6;
  v28[18] = a7;
  v28[19] = a8;
  v28[20] = v27;
  v28[21] = v26;
  v28[22] = v25;
  v28[23] = v24;
  v28[24] = v23;
  v28[25] = v22;
  v28[26] = v21;
  v28[27] = v20;
  v28[28] = v19;
  v28[29] = v18;
  v28[30] = v17;
  v28[31] = v16;
  v28[32] = v15;
  v28[33] = v14;
  v28[34] = v13;
  v28[35] = v12;
  v28[36] = v11;
  v28[37] = v10;
  v28[38] = v9;
  v28[39] = a1;
  v28[40] = v8;
  memset_like_loc_1796C();
  __asm { mtspr     eid, r0 # External interrupt disable }
  JUMPOUT(0x17D7C);
}
