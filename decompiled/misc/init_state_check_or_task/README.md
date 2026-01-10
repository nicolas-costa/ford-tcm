## init_state_check_or_task

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00019AE4`
- **ea_end**: `0x00019BB8`
- **size**: `212` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a693c1000893e1000c90010014818d704c7f8c07bc2c0c00004182008c3bc00000b3cd6d42b3cd6d4639600001996d6d4e62cd6c104bffff813be000009bed6d4a9bed6e619bed6d4c9bed6d4d3d200000ce29fff8b12d6d44386d6c3d906d6c30906d6c3439600101b16d6d3eb3cd6d48d84d6d4b914d6c24392d6d4f912d6c2839800003998d6c204bfff7b1b3cd6c0079600000616bffffb16d6c0a9bed6d4e480000143d800003818cfa087d8803a6ae80002183c1000883e1000c800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
00019AE4  stwu      r1, back_chain(r1)
00019AE8  mflr      r0
00019AEC  stw       r30, 0x10+var_8(r1)
00019AF0  stw       r31, 0x10+var_4(r1)
00019AF4  stw       r0, 0x10+sender_lr(r1)
00019AF8  lwz       r12, 0x704C(r13)
00019B00  cmpwi     r12, 0
00019B04  beq       loc_19B90
00019B08  li        r30, 0
00019B0C  sth       r30, 0x6D42(r13)
00019B10  sth       r30, 0x6D46(r13)
00019B14  li        r11, 1
00019B18  stb       r11, 0x6D4E(r13)
00019B1C  ori       r13, r22, 0x6C10
00019B20  bl        diag_update_mode_flags_6D4B_from_cfg
00019B24  li        r31, 0
00019B28  stb       r31, 0x6D4A(r13)
00019B2C  stb       r31, 0x6E61(r13)
00019B30  stb       r31, 0x6D4C(r13)
00019B34  stb       r31, 0x6D4D(r13)
00019B38  lis       r9, 0
00019B3C  lfdu      f17, -8(r9)
00019B40  sth       r9, 0x6D44(r13)
00019B44  addi      r3, r13, 0x6C3D
00019B48  stw       r3, 0x6C30(r13)# SDA r13+0x6C30: ptr into RX/TX buffer (base = r13+0x6C3D).
00019B4C  stw       r3, 0x6C34(r13)# SDA r13+0x6C34: ptr into RX/TX buffer (often same base at init).
00019B50  li        r11, 0x101
00019B54  sth       r11, 0x6D3E(r13)# SDA r13+0x6D3E: 0x101 constant used as limit/state (likely length/threshold).
00019B58  sth       r30, 0x6D48(r13)
00019B5C  stfd      f2, 0x6D4B(r13)
00019B60  stw       r10, 0x6C24(r13)
00019B64  addi      r9, r13, 0x6D4F
00019B68  stw       r9, 0x6C28(r13)
00019B6C  li        r12, 3
00019B70  stb       r12, 0x6C20(r13)
00019B74  bl        sub_19324
00019B78  sth       r30, 0x6C00(r13)
00019B7C  clrldi    r0, r11, 0
00019B80  ori       r11, r11, 0xFFFF
00019B84  sth       r11, 0x6C0A(r13)
00019B88  stb       r31, 0x6D4E(r13)
00019B8C  b         loc_19BA0
00019B90  lis       r12, off_2FA08@ha
00019B94  lwz       r12, off_2FA08@l(r12)# unk_45974
00019B98  mtlr      r12
00019B9C  lhau      r20, loc_20+1
00019BA0  lwz       r30, 0x10+var_8(r1)
00019BA4  lwz       r31, 0x10+var_4(r1)
00019BA8  lwz       r0, 0x10+sender_lr(r1)
00019BAC  mtlr      r0
00019BB0  addi      r1, r1, 0x10
00019BB4  blr
```
