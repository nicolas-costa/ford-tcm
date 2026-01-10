/* diag_update_mode_flags_6D4B_from_cfg */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00019AA0 end=0x00019AE4 size=68 */
/* export_utc=2026-01-10T18:12:42Z */

void sub_19AA0()
{
  int v0; // r13

  *(_BYTE *)(v0 + 27979) = 3;                   // SDA r13+0x6D4B: flags/mode byte set from cfg bytes (byte_BD38/byte_1FC00) — diag/comms mode.
  JUMPOUT(0x19ADC);
}
