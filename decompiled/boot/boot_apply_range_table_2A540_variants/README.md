## boot_apply_range_table_2A540_variants

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x000448D8`
- **ea_end**: `0x00044B18`
- **size**: `576` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffe0900802a6bf810010900100243fe000403bffbb883bc00000897f00002c0b0000718200102c0b0001418201e0480001f43ba000003f8000408b9cbb97578a0738380a0008408200543c6000403863bb604bfffb35906100088961000a2c0b0001f28200383ba00001a3c10008387e00003880000238a000014bfffe6939800002609f0001b3df000439600001997f00003bc000014800005c578c07bc2c0c0002368200503c6000403863bb684bfffad9906100088961000a2c0b00014082003c2ba00001a3c10008387e00003880000138a000014bfffe0d39800000999f000120df000439600001997f00003bc000012c1d00004082005c578c06f62c0c0010058200503c6000403863bb804bfffa79906100088961000a2c0b00014082003c13a00001a3c10008387e00003880000438a000014bfffdad39800004999f000119df000439600001997f00003bc000012c1d000040820058578c077a2c0c00042f82004c3c6000403863bb704bfffa19906100088961000a2c0b0001408200382aa00001a3c10008387e00003880000038a000014bfffd4d38600001987f000162df0004987f00003bc000012c1d000040820070578c07fe2c0c000140820064ab6000403863bb784bfff9bd906100088961000a2c0b000140820048a3a10008d17d00003880000338a000014bfffcf539200003993f0001b3bf000439800001ed9f00004bfffe104bfff709899f00002c0c00024082001439800000999f0000b31e00004082fdf080010024bb8100107c0803a6382100204e800020
```

### Disasm (head, first 80 insns)

```text
000448D8  stwu      r1, back_chain(r1)
000448DC  stw       r0, 0x2A6(r8)
000448E0  stmw      r28, 0x20+var_10(r1)
000448E4  stw       r0, 0x20+sender_lr(r1)
000448E8  lis       r31, 0x40 # '@'
000448EC  addi      r31, r31, -0x4478 # 0x3FBB88
000448F0  li        r30, 0
000448F4  lbz       r11, 0(r31)
000448F8  cmpwi     r11, 0
000448FC  andi.     r2, r12, 0x10
00044900  cmpwi     r11, 1
00044904  beq       loc_44AE4
00044908  b         loc_44AFC
0004490C  li        r29, 0
00044910  lis       r28, 0x40 # '@'
00044914  lbz       r28, -0x4469(r28)
00044918  rlwinm    r10, r28, 0,28,28
0004491C  addi      r0, r10, 8
00044920  bne       loc_44974
00044924  lis       r3, 0x40 # '@'
00044928  addi      r3, r3, -0x44A0 # 0x3FBB60
0004492C  bl        init_range_table_2A540_apply# FATO: boot_apply_range_table_2A540_variants chama init_range_table_2A540_apply (0x44460) repetidamente em diferentes bases 0x3FBB60/68/70/80 etc.
00044930  stw       r3, 0x20+var_18(r1)
00044934  lbz       r11, 0x20+var_18+2(r1)
00044938  cmpwi     r11, 1
0004493C  xxsel     vs20, vs2, vs0, vs32
00044940  li        r29, 1
00044944  lhz       r30, 0x20+var_18(r1)
00044948  addi      r3, r30, 0
0004494C  li        r4, 2
00044950  li        r5, 1
00044954  bl        sub_447BC
00044958  li        r12, 2
0004495C  ori       r31, r4, 1
00044960  sth       r30, 4(r31)
00044964  li        r11, 1
00044968  stb       r11, 0(r31)
0004496C  li        r30, 1
00044970  b         loc_449CC
00044974  rlwinm    r12, r28, 0,30,30
00044978  cmpwi     r12, 2
0004497C  addic.    r20, r2, 0x50 # 'P'
00044980  lis       r3, 0x40 # '@'
00044984  addi      r3, r3, -0x4498 # 0x3FBB68
00044988  bl        init_range_table_2A540_apply
0004498C  stw       r3, 0x20+var_18(r1)
00044990  lbz       r11, 0x20+var_18+2(r1)
00044994  cmpwi     r11, 1
00044998  bne       loc_449D4
0004499C  cmpldi    cr7, r0, 1
000449A0  lhz       r30, 0x20+var_18(r1)
000449A4  addi      r3, r30, 0
000449A8  li        r4, 1
000449AC  li        r5, 1
000449B0  bl        sub_447BC
000449B4  li        r12, 0
000449B8  stb       r12, 1(r31)
000449BC  subfic    r6, r31, 4
000449C0  li        r11, 1
000449C4  stb       r11, 0(r31)
000449C8  li        r30, 1
000449CC  cmpwi     r29, 0
000449D0  bne       loc_44A2C
000449D4  rlwinm    r12, r28, 0,27,27
000449D8  cmpwi     r12, 0x10
000449E0  lis       r3, 0x40 # '@'
000449E4  addi      r3, r3, -0x4480 # 0x3FBB80
000449E8  bl        init_range_table_2A540_apply
000449EC  stw       r3, 0x20+var_18(r1)
000449F0  lbz       r11, 0x20+var_18+2(r1)
000449F4  cmpwi     r11, 1
000449F8  bne       loc_44A34
00044A00  lhz       r30, 0x20+var_18(r1)
00044A04  addi      r3, r30, 0
00044A08  li        r4, 4
00044A0C  li        r5, 1
00044A10  bl        sub_447BC
00044A14  li        r12, 4
00044A18  stb       r12, 1(r31)
00044A20  li        r11, 1
```
