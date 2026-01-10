/* init_immr_mmio_window_30xx */
/* idb=5U75-14C337-AA.rebuilt.aligned.bin start=0x00008124 end=0x000081A4 size=128 */
/* export_utc=2026-01-10T18:12:42Z */

// FATO: reads IMMR via mfspr immr, then does MMIO window ops using lis r3,0x30 and lwz/stw at (0x30000000-0x3D7C)=0x2FFFC284; loops on value read, then sth to 0x30006800. Seen in QEMU trace at 0x8160..0x8190.
int sub_8124()
{
  int result; // r3
  _DWORD back_chain[4]; // [sp+0h] [-10h] BYREF

  __asm { mfspr     r3, immr # Internal Memory Mapping Register }
  back_chain[2] = _R3;
  MEMORY[0x2FC284] = MEMORY[0x2FC284] & 0xFFFFF | 0x900000;// FATO: MMIO access: lwz/stw r0, -0x3D7C(r3) with r3=0x30000000 => EA 0x2FFFC284.
  while ( !MEMORY[0x2FC284] )
    ;
  result = 3145728;
  MEMORY[0x306800] = 1;                         // FATO: MMIO access: sth r11, 0x6800(r3) with r3=0x30000000 => EA 0x30006800.
  __trap(9u, (unsigned int)back_chain, 0x10u);
  return result;
}
