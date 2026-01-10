## task_service_pwm_queue_and_housekeeping

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0004A264`
- **ea_end**: `0x0004A288`
- **size**: `36` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff87c0802a69001000c480763554bfef2554bfeebc9d8ff27454bff32294bff03f1
```

### Disasm (head, first 80 insns)

```text
0004A264  stwu      r1, back_chain(r1)
0004A268  mflr      r0
0004A26C  stw       r0, 8+sender_lr(r1)
0004A270  bl        nullsub_6
0004A274  bl        tpu_pwm_queue_service_15A8
0004A278  bl        loc_38E40
0004A27C  stfd      f7, 0x2745(r31)
0004A280  bl        loc_3D4A8
0004A284  bl        sub_3A674
```
