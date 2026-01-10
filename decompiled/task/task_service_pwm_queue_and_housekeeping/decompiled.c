/* task_service_pwm_queue_and_housekeeping */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x0004A264 end=0x0004A288 size=36 */
/* export_utc=2026-01-10T18:12:42Z */

void __noreturn sub_4A264()
{
  int v0; // r31
  double v1; // fp1
  double v2; // fp4
  double v3; // fp3
  double v4; // fp2
  int v5; // r3
  __int64 v6; // fp7
  int v7; // r3

  v1 = nullsub_6();
  tpu_pwm_queue_service_15A8(v1, v4, v3, v2);
  v5 = ((int (*)(void))loc_38E40)();
  *(_QWORD *)(v0 + 10053) = v6;
  v7 = ((int (__fastcall *)(int))loc_3D4A8)(v5);
  sub_3A674(v7);
}
