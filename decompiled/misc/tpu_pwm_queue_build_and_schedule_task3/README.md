## tpu_pwm_queue_build_and_schedule_task3

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x000395B4`
- **ea_end**: `0x000396D0`
- **size**: `284` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff07c0802a606c1000893e1000c900100143bc3000039800000998d15b03be00000895e0000660a000041820034809e0004898400002c0c002041800010898d15b0398c0001458d15b0388400103bff0001895e00007c0af8404181ffd8898d15b0558325360c8000004bfecbf9906d15ac894d15b055442536806d15ac38a000004bfecad5aae00000895e00002c0a000041820044819e000457eb20367d8c58ae2c0c0020a980001457e3063e389e00004bfe855d4800001057e3063e389e00004bfe8641daff0001897e00007c0bf8404181ffc493cd15a8898d15b02c0c0000418200143d60000338800001480007754800001038600003388000004800076583c10008e7e1000c800100147c0803a6382100104e800020
```

### Disasm (head, first 80 insns)

```text
000395B4  stwu      r1, back_chain(r1)
000395B8  mflr      r0
000395C0  stw       r31, 0x10+var_4(r1)
000395C4  stw       r0, 0x10+sender_lr(r1)
000395C8  addi      r30, r3, 0
000395CC  li        r12, 0
000395D0  stb       r12, 0x15B0(r13)
000395D4  li        r31, 0
000395D8  lbz       r10, 0(r30)
000395DC  oris      r10, r16, 0
000395E0  beq       loc_39614
000395E4  lwz       r4, 4(r30)
000395E8  lbz       r12, 0(r4)
000395EC  cmpwi     r12, 0x20 # ' '
000395F0  blt       loc_39600
000395F4  lbz       r12, 0x15B0(r13)
000395F8  addi      r12, r12, 1
00039600  addi      r4, r4, 0x10
00039604  addi      r31, r31, 1
00039608  lbz       r10, 0(r30)
0003960C  cmplw     r10, r31
00039610  bgt       loc_395E8
00039614  lbz       r12, 0x15B0(r13)
00039618  clrlslwi  r3, r12, 24,4
0003961C  tweqi     r0, 0
00039620  bl        loc_26218
00039624  stw       r3, 0x15AC(r13)
00039628  lbz       r10, 0x15B0(r13)
0003962C  clrlslwi  r4, r10, 24,4
00039630  lwz       r3, 0x15AC(r13)
00039634  li        r5, 0
00039638  bl        sub_2610C
0003963C  lha       r23, sub_0
00039640  lbz       r10, 0(r30)
00039644  cmpwi     r10, 0
00039648  beq       loc_3968C
0003964C  lwz       r12, 4(r30)
00039650  slwi      r11, r31, 4
00039654  lbzx      r12, r12, r11
00039658  cmpwi     r12, 0x20 # ' '
0003965C  lha       r12, loc_14
00039660  clrlwi    r3, r31, 24
00039664  addi      r4, r30, 0
00039668  bl        tpu_pwm_entry_apply_via_mios_305f58
0003966C  b         loc_3967C
00039670  clrlwi    r3, r31, 24
00039674  addi      r4, r30, 0
00039678  bl        tpu_pwm_entry_apply_via_tpu_regs
0003967C  stfd      f23, 1(r31)
00039680  lbz       r11, 0(r30)
00039684  cmplw     r11, r31
00039688  bgt       loc_3964C
0003968C  stw       r30, 0x15A8(r13)
00039690  lbz       r12, 0x15B0(r13)
00039694  cmpwi     r12, 0
00039698  beq       loc_396AC
0003969C  lis       r11, 3
000396A0  li        r4, 1
000396A4  bl        scheduler_post_or_arm_task
000396A8  b         loc_396B8
000396AC  li        r3, 3
000396B0  li        r4, 0
000396B4  bl        scheduler_post_or_arm_task
000396B8  lwz       r30, 0x10+var_8(r1)
000396BC  lfdp      f31, 0x10+var_4(r1)
000396C0  lwz       r0, 0x10+sender_lr(r1)
000396C4  mtlr      r0
000396C8  addi      r1, r1, 0x10
000396CC  blr
```
