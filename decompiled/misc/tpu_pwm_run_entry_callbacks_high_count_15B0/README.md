## tpu_pwm_run_entry_callbacks_high_count_15B0

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00021A08`
- **ea_end**: `0x00021ACC`
- **size**: `196` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693c1000893e1000c90010014f1c00000896d15b02c0b00004182008c818d15ac57cb20367c6c5a14a1430008e123000a7c0a4800408000603be30008a17f0000396b0001b17f0000a1430008c383000a7c0a6000418000408983000c558c07fe2c0c000140820030818d15a85d8c000457cb20367d8c5a1483ec000c2c1f000041820014819f00047d8803a6d77f00004e8000213bde0001896d15b07c0bf0404181ff7c83c1000883e1000cfb0100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00021A08  stwu      r1, back_chain(r1)
00021A0C  mflr      r0
00021A10  stw       r30, 0x10+var_8(r1)
00021A14  stw       r31, 0x10+var_4(r1)
00021A18  stw       r0, 0x14(r1)
00021A1C  xsaddsp   vs14, vs0, vs0
00021A20  lbz       r11, 0x15B0(r13)
00021A24  cmpwi     r11, 0
00021A28  beq       loc_21AB4
00021A2C  lwz       r12, 0x15AC(r13)
00021A30  slwi      r11, r30, 4
00021A34  add       r3, r12, r11
00021A38  lhz       r10, 8(r3)
00021A78  lwz       r12, 0x15A8(r13)
00021A7C  rlwnm     r12, r12, r0,0,2
00021A80  slwi      r11, r30, 4
00021A84  add       r12, r12, r11
00021A88  lwz       r31, 0xC(r12)
00021A8C  cmpwi     r31, 0
00021A90  beq       loc_21AA4
00021A94  lwz       r12, 4(r31)
00021A98  mtlr      r12
00021A9C  stfsu     f27, 0(r31)
00021AA0  blrl
00021AA4  addi      r30, r30, 1
00021AA8  lbz       r11, 0x15B0(r13)
00021AAC  cmplw     r11, r30
00021AB0  bgt       loc_21A2C
00021AB4  lwz       r30, 0x10+var_8(r1)
00021AB8  lwz       r31, 0x10+var_4(r1)
00021ABC  std       r24, 0x14(r1)
00021AC0  mtlr      r0
00021AC4  addi      r1, r1, 0x10
00021AC8  blr
```
