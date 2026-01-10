## tasktable_or_slot_init_from_2A744_and_3FA400

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x00031594`
- **ea_end**: `0x00031698`
- **size**: `260` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffe07c0802a6a6410008900100243b8000013f400000635affff3f6000033b7ba744387b000082006c15547d043e7c1dd000418200b0386000013fc000403bdea400813e0000ffe00000892900022c090000408100942c0300004182008c809e000080a40010c2ea18387d45522e7c0ae8004082005857ec18387d85621488ac0002816400084145000c7d6b50ae556be7be2c0b00004082001c3d800003398c0ec47d8803a6d7e3063e4e800021480000183d800003398c099c7d8803a657e3063e4e80002178600000817e00003bff0001896b00027c0bf8004181ff7c480000083b800000db1c00004082ff3880010024bb4100087c0803a6382100204e800020
```

### Disasm (head, first 80 insns)

```text
00031594  stwu      r1, back_chain(r1)
00031598  mflr      r0
0003159C  lhzu      r18, 0x20+var_18(r1)
000315A0  stw       r0, 0x20+sender_lr(r1)
000315A4  li        r28, 1
000315A8  lis       r26, unk_FFFF@h
000315AC  ori       r26, r26, unk_FFFF@l
000315B0  lis       r27, word_2A744@ha
000315B4  addi      r27, r27, word_2A744@l
000315B8  addi      r3, r27, 0
000315BC  lwz       r16, loc_6C14+1
000315C0  clrlwi    r29, r3, 16
000315C4  cmpw      r29, r26
000315C8  beq       loc_31678
000315CC  li        r3, 1
000315D0  lis       r30, 0x40 # '@'
000315D4  addi      r30, r30, -0x5C00 # 0x3FA400
000315D8  lwz       r9, 0(r30)
000315E0  lbz       r9, 2(r9)
000315E4  cmpwi     r9, 0
000315E8  ble       loc_3167C
000315EC  cmpwi     r3, 0
000315F0  beq       loc_3167C
000315F4  lwz       r4, 0(r30)
000315F8  lwz       r5, 0x10(r4)
000315FC  lfs       f23, 0x1838(r10)
00031600  lhzx      r10, r5, r10
00031604  cmpw      r10, r29
00031608  bne       loc_31660
0003160C  slwi      r12, r31, 3
00031610  add       r12, r5, r12
00031614  lbz       r5, 2(r12)
00031618  lwz       r11, 8(r4)
0003161C  bdzt      4*cr1+gt, loc_31628
00031620  lbzx      r11, r11, r10
00031624  extrwi    r11, r11, 2,26
00031628  cmpwi     r11, 0
0003162C  bne       loc_31648
00031630  lis       r12, 3
00031634  addi      r12, r12, 0xEC4 # 0x30EC4
00031638  mtlr      r12
0003163C  stfsu     f31, 0x63E(r3)
00031640  blrl
00031644  b         loc_3165C
00031648  lis       r12, loc_3099C@ha
0003164C  addi      r12, r12, loc_3099C@l
00031650  mtlr      r12
00031654  clrlwi    r3, r31, 24
00031658  blrl
0003165C  clrldi    r0, r3, 0
00031660  lwz       r11, 0(r30)
00031664  addi      r31, r31, 1
00031668  lbz       r11, 2(r11)
0003166C  cmpw      r11, r31
00031670  bgt       loc_315EC
00031674  b         loc_3167C
00031678  li        r28, 0
0003167C  stfd      f24, 0(r28)
00031680  bne       loc_315B8
00031684  lwz       r0, 0x18+arg_C(r1)
00031688  lmw       r26, 0x18+var_10(r1)
0003168C  mtlr      r0
00031690  addi      r1, r1, 0x20
00031694  blr
```
