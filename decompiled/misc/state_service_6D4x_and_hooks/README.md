## state_service_6D4x_and_hooks

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00046380`
- **ea_end**: `0x00046478`
- **size**: `248` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff87c0802a69001000c3d800002818cf81c7d8803a6a06d6d444e80001438a0000a38c0000a4e80002138600000b06d6d42388d6c3d908d6c30b38d6c3439200101b12d6d3eb06d6c008001000c7c0803a6382100084e8000208a21fff87c0802a69001000c3d800002818cf81c7d8803a6a06d6d443880001410a0000a38c0000a4e80002138600000b06d6d42388d6c3d908d6c30908d6c3461200101b12d6d3e39800000918d6c04b06d6c008001000c7c0803a6382100088d8000209421fff87c0802a69001000c39800000998d6c0d3d600002816bf838c66803a6386000004e8000218001000c7c0803a6382100084e800020
```

### Disasm (head, first 80 insns)

```text
00046380  stwu      r1, back_chain(r1)
00046384  mflr      r0
00046388  stw       r0, 8+sender_lr(r1)
0004638C  lis       r12, dword_1F81C@ha
00046390  lwz       r12, dword_1F81C@l(r12)
00046394  mtlr      r12
00046398  lhz       r3, 0x6D44(r13)
000463A0  li        r5, 0xA
000463A4  li        r6, 0xA
000463A8  blrl
000463AC  li        r3, 0
000463B0  sth       r3, 0x6D42(r13)
000463B4  addi      r4, r13, 0x6C3D
000463B8  stw       r4, 0x6C30(r13)
000463BC  sth       r28, 0x6C34(r13)
000463C0  li        r9, 0x101
000463C4  sth       r9, 0x6D3E(r13)
000463C8  sth       r3, 0x6C00(r13)
000463CC  lwz       r0, 8+sender_lr(r1)
000463D0  mtlr      r0
000463D4  addi      r1, r1, 8
000463D8  blr
000463DC  lbz       r17, back_chain(r1)
000463E0  mflr      r0
000463E4  stw       r0, arg_C(r1)
000463E8  lis       r12, dword_1F81C@ha
000463EC  lwz       r12, dword_1F81C@l(r12)
000463F0  mtlr      r12
000463F4  lhz       r3, 0x6D44(r13)
000463F8  li        r4, 0x14
00046400  li        r6, 0xA
00046404  blrl
00046408  li        r3, 0
0004640C  sth       r3, 0x6D42(r13)
00046410  addi      r4, r13, 0x6C3D
00046414  stw       r4, 0x6C30(r13)
00046418  stw       r4, 0x6C34(r13)
0004641C  ori       r0, r9, 0x101
00046420  sth       r9, 0x6D3E(r13)
00046424  li        r12, 0
00046428  stw       r12, 0x6C04(r13)
0004642C  sth       r3, 0x6C00(r13)
00046430  lwz       r0, arg_C(r1)
00046434  mtlr      r0
00046438  addi      r1, r1, 8
0004643C  lbzu      r12, loc_20
00046440  stwu      r1, -8+pre_back_chain(r1)
00046444  mflr      r0
00046448  stw       r0, arg_C(r1)
0004644C  li        r12, 0
00046450  stb       r12, 0x6C0D(r13)
00046454  lis       r11, dword_1F838@ha
00046458  lwz       r11, dword_1F838@l(r11)
0004645C  lfsu      f19, 0x3A6(r8)
00046460  li        r3, 0
00046464  blrl
00046468  lwz       r0, arg_C(r1)
0004646C  mtlr      r0
00046470  addi      r1, r1, 8
00046474  blr
```
