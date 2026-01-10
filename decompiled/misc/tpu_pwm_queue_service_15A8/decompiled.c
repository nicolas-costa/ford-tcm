/* tpu_pwm_queue_service_15A8 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x000394C8 end=0x000395B4 size=236 */
/* export_utc=2026-01-10T18:12:42Z */

void __fastcall tpu_pwm_queue_service_15A8(double a1, double a2, double a3, double a4)
{                                               // SDA r13+0x15A8: pointer to a queued TPU/PWM worklist. This function drains it and calls tpu_channel_update_cfgbit1_or_arm / tpu_channel_update_cfgbit8_or_enable per entry, then clears 0x15A8.
  int v4; // r30
  int v5; // r13
  __int64 v6; // fp23
  char v7; // r10
  int v8; // r9
  int v9; // r8
  int v10; // r7
  int v11; // r6
  int v12; // r5
  int v15; // r13

  if ( **(_BYTE **)(v5 + 5544) )
  {
    *(_QWORD *)(*(_DWORD *)(*(_DWORD *)(v5 + 5544) + 4) + 22702) = v6;
    tpu_channel_update_cfgbit1_or_arm(v4, 0, a1, a2, a3, a4);// Calls TPU channel config helpers (likely PWM/solenoid channel updates). Strong candidate for solenoid PWM periodic servicing.
    tpu_channel_update_cfgbit8_or_enable(v4, 0, v12, v11, v10, v9, v8, v7);
    __asm { dozi      r12, r0, 0x44 # 'D' }
    tpu_pwm_post_apply_dispatch_and_callbacks(v4, *(_DWORD *)(v15 + 5544), 0);
    JUMPOUT(0x3953C);
  }
  *(_DWORD *)(v5 + 5544) = 0;
  __asm { xsmaddasp vs14, vs1, vs0 }
}
