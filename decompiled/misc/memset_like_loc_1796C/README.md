## memset_like_loc_1796C

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0001796C`
- **ea_end**: `0x00017A70`
- **size**: `260` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
7c0802a6bf61000c7c9e2379900100242c630000418200dc280400034081006c3be5000050bf402e576b07be57fc043e950b0001387c00005383801e3b830000418200182c0b0002418200202c0b0003788200244800002898bb0000b3fb00013bc4fffd48000018b3fb00003bc4fffe4900000c98bb00003bc4ffff399b0003559f003a480000083bfb00002c1e00030b7e0000408100203bdefffd3bfffffc37defffc979f00044181fff83bff0004447e00032c03000040810038546c07ff3b830000418200143783ffff98bf0000fbff00014182001c579cf87e3bfffffe7f8903a69cbf000298bf00014200fff8cd0100247c0803a6387b0000bb61000c38210020
```

### Disasm (head, first 80 insns)

```text
0001796C  mflr      r0
00017970  stmw      r27, arg_C(r1)
00017974  mr.       r30, r4
00017978  stw       r0, arg_24(r1)
00017980  beq       loc_17A5C
00017984  cmplwi    r4, 3
00017988  ble       loc_179F4
0001798C  addi      r31, r5, 0
00017990  insrwi    r31, r5, 24,0
00017994  clrlwi    r11, r27, 30
00017998  clrlwi    r28, r31, 16
0001799C  stwu      r8, 1(r11)
000179A0  addi      r3, r28, 0
000179A4  insrwi    r3, r28, 16,0
000179A8  addi      r28, r3, 0
000179AC  beq       loc_179C4
000179B0  cmpwi     r11, 2
000179B4  beq       loc_179D4
000179B8  cmpwi     r11, 3
000179BC  clrrdi    r2, r4, 31
000179C0  b         loc_179E8
000179C4  stb       r5, 0(r27)
000179C8  sth       r31, 1(r27)
000179CC  addi      r30, r4, -3
000179D0  b         loc_179E8
000179D4  sth       r31, 0(r27)
000179D8  addi      r30, r4, -2
000179DC  b         0x10179E8
000179E0  stb       r5, 0(r27)
000179E4  addi      r30, r4, -1
000179E8  addi      r12, r27, 3
000179EC  clrrwi    r31, r12, 2
000179F0  b         loc_179F8
000179F4  addi      r31, r27, 0
000179F8  cmpwi     r30, 3
000179FC  tdi       27, r30, 0
00017A00  ble       loc_17A20
00017A04  addi      r30, r30, -3
00017A08  addi      r31, r31, -4
00017A0C  addic.    r30, r30, -4
00017A10  stwu      r28, 4(r31)
00017A14  bgt       loc_17A0C
00017A18  addi      r31, r31, 4
00017A20  cmpwi     r3, 0
00017A24  ble       loc_17A5C
00017A28  clrlwi.   r12, r3, 31
00017A2C  addi      r28, r3, 0
00017A30  beq       loc_17A44
00017A34  addic.    r28, r3, -1
00017A38  stb       r5, 0(r31)
00017A3C  stdu      r31, 0(r31)
00017A40  beq       loc_17A5C
00017A44  srwi      r28, r28, 1
00017A48  addi      r31, r31, -2
00017A4C  mtctr     r28
00017A50  stbu      r5, 2(r31)
00017A54  stb       r5, 1(r31)
00017A58  bdnz      loc_17A50
00017A5C  lfdu      f8, arg_24(r1)
00017A60  mtlr      r0
00017A64  addi      r3, r27, 0
00017A68  lmw       r27, arg_C(r1)
00017A6C  addi      r1, r1, 0x20 # ' '
```
