## boot_entry_orchestrator_43E88

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00043E88`
- **ea_end**: `0x00043EFC`
- **size**: `116` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff87c0802a69001000c3860000448000749ed63063e2c0300004182004848000c713c6000403863b345896300002c0b00007682000c3980000199830000386000004bffff054800000848000c4538600000d70007055463063e2c0300004182ffec8001000c7c0803a6382100084bfff9d4
```

### Disasm (head, first 80 insns)

```text
00043E88  stwu      r1, back_chain(r1)
00043E8C  mflr      r0
00043E90  stw       r0, 8+sender_lr(r1)
00043E94  li        r3, 4
00043E98  bl        loc_445E0
00043E9C  fnmadds   f11, f3, f24, f0
00043EA0  cmpwi     r3, 0
00043EA4  beq       loc_43EEC
00043EA8  bl        boot_mode_or_selftest_driver# FATO: boot_entry_orchestrator_43E88 chama boot_mode_or_selftest_driver (0x44B18), que por sua vez chama boot_apply_range_table_2A540_variants -> init_range_table_2A540_apply (0x44460).
00043EAC  lis       r3, 0x40 # '@'
00043EB0  addi      r3, r3, -0x4CBB # 0x3FB345
00043EB4  lbz       r11, 0(r3)
00043EB8  cmpwi     r11, 0
00043EBC  andis.    r2, r20, 0xC
00043EC0  li        r12, 1
00043EC4  stb       r12, 0(r3)
00043EC8  li        r3, 0
00043ECC  bl        sub_43DD0
00043ED0  b         loc_43ED8
00043ED4  bl        boot_mode_or_selftest_driver
00043ED8  li        r3, 0
00043EDC  stfsu     f24, flt_705
00043EE0  clrlwi    r3, r3, 24
00043EE4  cmpwi     r3, 0
00043EE8  beq       loc_43ED4
00043EEC  lwz       r0, 8+sender_lr(r1)
00043EF0  mtlr      r0
00043EF4  addi      r1, r1, 8
00043EF8  b         loc_438CC
000438CC  b         unk_4399C
```
