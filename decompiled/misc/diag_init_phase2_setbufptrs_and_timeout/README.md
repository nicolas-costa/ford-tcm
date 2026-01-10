## diag_init_phase2_setbufptrs_and_timeout

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0001C7B4`
- **ea_end**: `0x0001C8BC`
- **size**: `264` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
7c0802a693e1000ca00100143be30000898d6d4e2c0c00004082003c39800002998d6d4e386d6c3da56d6c30906d6c3439400101b14d6d3e38600000986d6d4c986d6d4d3d8000000d8cfff8b18d6d444bffd29d898d6d4e558c07bc2c0c000041820094898d6c00068ccffe2c0c000040820084898d6c10558cdffe2c0c0000408200749bed6c0c0e8d6c00558cdffe2c0c00004082006039800001880d6c0051802eb4980d6c00bf600000880d6c0051601f38980d6c0039400000b14d6d46a3ed6d42399f0001c36d6d4d7c0c580041800014a18d6d44398c00017c0cf8004080001439800001800d6c0051801f38980d6c0083e1000c800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
0001C7B4  mflr      r0
0001C7B8  stw       r31, arg_C(r1)
0001C7BC  lhz       r0, arg_14(r1)
0001C7C0  addi      r31, r3, 0
0001C7C4  lbz       r12, 0x6D4E(r13)
0001C7C8  cmpwi     r12, 0
0001C7CC  bne       loc_1C808
0001C7D0  li        r12, 2
0001C7D4  stb       r12, 0x6D4E(r13)
0001C7D8  addi      r3, r13, 0x6C3D
0001C7DC  lhzu      r11, 0x6C30(r13)
0001C7E0  stw       r3, 0x6C34(r13)
0001C7E4  li        r10, 0x101
0001C7E8  sth       r10, 0x6D3E(r13)
0001C7EC  li        r3, 0
0001C7F0  stb       r3, 0x6D4C(r13)
0001C7F4  stb       r3, 0x6D4D(r13)
0001C7F8  lis       r12, dword_7BC@ha
0001C7FC  twgei     r12, -8
0001C800  sth       r12, 0x6D44(r13)
0001C804  bl        diag_update_mode_flags_6D4B_from_cfg
0001C808  lbz       r12, 0x6D4E(r13)
0001C80C  rlwinm    r12, r12, 0,30,30
0001C810  cmpwi     r12, 0
0001C814  beq       loc_1C8A8
0001C818  lbz       r12, 0x6C00(r13)
0001C8A8  lwz       r31, arg_C(r1)
0001C8AC  lwz       r0, arg_14(r1)
0001C8B0  mtlr      r0
0001C8B4  addi      r1, r1, 0x10
0001C8B8  blr
```
