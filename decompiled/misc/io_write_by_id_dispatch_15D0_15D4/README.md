## io_write_by_id_dispatch_15D0_15D4

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0003C16C`
- **ea_end**: `0x0003C444`
- **size**: `728` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421ffd87c0802a6bf0100089001002c59c300003b84000057db2036816d15d083ab00047f5dd8ae7d9dda148b0c00025218067e3b7800002c1a00644080004c387a00004bff79f53ba30000570c077af70c000441820014819d000c558c17fe2c0c000041820014801d000c538070a28f1d000c480002505784043e387e00004bfe7125480002402c1a009740800054bf6c077a2c0c00044182001c818d15d457cb18387d8c582e558c07fe2c0c0000a9820020818d15d457cb18387d8c5a14800c00005380103a900c0000480001f8b57e0000389c00004bfe7461480001e8576c077a2c0c00044182001c832d15d40dcb18387d79582e556b07fe2c0b000041820020818d15d457cb18387d8c5a14110c00005380103a900c0000480001a8574c18383d600030616b5ba07fac5a14481b07be5783043e4bfe77393b0300003d600003396b8928570c0dfc7f4b622e39ca18387d595214a14a00047d4ad1d6555c9b7e576c063e2c0c000241820010766c063e2c0c0003408200087f9cd050a19d0002578b043ea15d00007d6b5214470c58004182011c5799043e57db20367c1113a6818d3c04398c0001918d3c04eb6d15d0816b00047d6bda14896b00012c0b000841810024418200442c0b00050782002c2c0b0006418200542c0b00074182003c480000742c0b0009418200504e0b000a41820058480000603fe000303bdf0000a3fe6030480000503fe0003038df0000a3fe60b0480000403fe000303bdf0000a3fe6c46480000303fe00030c7df0000a3fe6c46480000203fe000303bdf0000a3fe6c46480000103fe0003045df0000a3fe6c46a19d00027febd038556b043e7d8b60502c0c000141820010789d00007d9c6214b19d0002818d3c04398cffff918d3c04816d3c042c0b00004c82000c4c00012c7c1013a6a19d0002a17d00007d795a147c0c58004082fef43a9d0006558c0436570b063e7d8c5a14b19d0006bb0100088001002c7c0803a68e2100284e800020
```

### Disasm (head, first 80 insns)

```text
0003C16C  stwu      r1, back_chain(r1)
0003C170  mflr      r0
0003C174  stmw      r24, 0x28+var_20(r1)
0003C178  stw       r0, 0x28+sender_lr(r1)
0003C17C  rlmi      r3, r14, r0,0,0
0003C180  addi      r28, r4, 0
0003C184  slwi      r27, r30, 4
0003C188  lwz       r11, 0x15D0(r13)# SDA r13+0x15D0: IO descriptor root for IDs < 0x64, with +4 pointing to 16-byte entries. Uses tpu_channel_regs_ptr_from_id for <0x64.
0003C18C  lwz       r29, 4(r11)
0003C190  lbzx      r26, r29, r27
0003C194  add       r12, r29, r27
0003C198  lbz       r24, 2(r12)
0003C19C  insrwi    r24, r16, 7,25
0003C1A0  addi      r27, r24, 0
0003C1A4  cmpwi     r26, 0x64 # 'd'
0003C1A8  bge       loc_3C1F4
0003C1AC  addi      r3, r26, 0
0003C1B0  bl        tpu_channel_regs_ptr_from_id# Maps IO ID -> TPU channel register block pointer: IDs 0..15 -> 0x304000+0x100+16*id; IDs 16..31 -> 0x304400+0x100+16*(id-16).
0003C1B4  addi      r29, r3, 0
0003C1B8  rlwinm    r12, r24, 0,29,29
0003C1BC  stfdp     f24, 4(r12)
0003C1C0  beq       loc_3C1D4
0003C1C4  lwz       r12, 0xC(r29)
0003C1C8  extrwi    r12, r12, 1,1
0003C1CC  cmpwi     r12, 0
0003C1D0  beq       loc_3C1E4
0003C1D4  lwz       r0, 0xC(r29)
0003C1D8  insrwi    r0, r28, 16,2
0003C1DC  lbzu      r24, 0xC(r29)
0003C1E0  b         loc_3C430
0003C1E4  clrlwi    r4, r28, 16
0003C1E8  addi      r3, r30, 0
0003C1EC  bl        loc_23310
0003C1F0  b         loc_3C430
0003C1F4  cmpwi     r26, 0x97
0003C1F8  bge       loc_3C24C
0003C1FC  stmw      r27, 0x77A(r12)
0003C200  cmpwi     r12, 4
0003C204  beq       loc_3C220
0003C208  lwz       r12, 0x15D4(r13)# SDA r13+0x15D4: word table used for IDs in [0x64..0x96] / [0x97..] paths; appears to store per-ID bitfields/state.
0003C20C  slwi      r11, r30, 3
0003C210  lwzx      r12, r12, r11
0003C214  clrlwi    r12, r12, 31
0003C218  cmpwi     r12, 0
0003C21C  lha       r12, 0x20(r2)
0003C220  lwz       r12, 0x15D4(r13)
0003C224  slwi      r11, r30, 3
0003C228  add       r12, r12, r11
0003C22C  lwz       r0, 0(r12)
0003C230  insrwi    r0, r28, 30,0
0003C234  stw       r0, 0(r12)
0003C238  b         loc_3C430
0003C24C  rlwinm    r12, r27, 0,29,29
0003C250  cmpwi     r12, 4
0003C254  beq       loc_3C270
0003C258  lwz       r25, 0x15D4(r13)
0003C25C  twi       14, r11, 6200
0003C260  lwzx      r11, r25, r11
0003C264  clrlwi    r11, r11, 31
0003C268  cmpwi     r11, 0
0003C26C  beq       loc_3C28C
0003C270  lwz       r12, 0x15D4(r13)
0003C274  slwi      r11, r30, 3
0003C278  add       r12, r12, r11
0003C28C  slwi      r12, r26, 3
0003C290  lis       r11, 0x30 # '0'
0003C294  ori       r11, r11, 0x5BA0 # 0x305BA0
0003C298  add       r29, r12, r11
0003C29C  ba        loc_1B07BC
0003C430  lmw       r24, 0x28+var_20(r1)
0003C434  lwz       r0, 0x28+sender_lr(r1)
0003C438  mtlr      r0
0003C43C  lbzu      r17, 0x28+pre_back_chain(r1)
0003C440  blr
001B07BC  rlmi.     r31, r15, r31,31,31
001B07C0  fnmadd.   f31, f31, f31, f31
001B07C4  fnmadd.   f31, f31, f31, f31
001B07C8  fnmadd.   f31, f31, f31, f31
001B07CC  fnmadd.   f31, f31, f31, f31
001B07D0  fnmadd.   f31, f31, f31, f31
```
