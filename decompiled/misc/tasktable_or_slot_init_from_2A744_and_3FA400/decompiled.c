/* tasktable_or_slot_init_from_2A744_and_3FA400 */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00031594 end=0x00031698 size=260 */
/* export_utc=2026-01-10T18:12:42Z */

// positive sp value has been detected, the output may be wrong!
__int16 *tasktable_or_slot_init_from_2A744_and_3FA400()
{
  __int64 v0; // fp24
  __int16 *result; // r3

  result = &word_2A744;
  if ( (_UNKNOWN *)((unsigned int)&word_2A744 & 0xFFFF) != &unk_FFFF )
    JUMPOUT(0x315DC);
  *(_QWORD *)sub_0 = v0;
  return result;
}
