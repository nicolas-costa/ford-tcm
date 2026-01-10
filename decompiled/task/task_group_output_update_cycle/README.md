## task_group_output_update_cycle

### Metadata

- **idb**: `5U75-14C337-AA.rebuilt.aligned.bin`
- **ea_start**: `0x0004A60C`
- **ea_end**: `0x0004A668`
- **size**: `92` bytes
- **export_utc**: `2026-01-10T18:12:42Z`
- **hexrays_ok**: `True`

### Files

- `decompiled.c`: Hex-Rays pseudocode (conveniência)
- `function.s`: disassembly completa (evidência)
- `README.md`: metadata + bytes (evidência)

### Bytes (full, hex)

```text
9421fff87c0802a69001000c4bff7605fa6000308003c010396000015160e8849003c0108001000c7c0803a638210008c68000209421fff87c0802a69001000c4bff80294bff7f354bff69fd8001000c690803a6382100084bfdb15c
```

### Disasm (head, first 80 insns)

```text
0004A60C  stwu      r1, back_chain(r1)
0004A610  mflr      r0
0004A614  stw       r0, 8+sender_lr(r1)
0004A618  bl        loc_41C1C
0004A61C  std       r19, 0x30(r0)
0004A620  lwz       r0, -0x3FF0(r3)
0004A624  li        r11, 1
0004A628  insrwi    r0, r11, 1,2
0004A62C  stw       r0, -0x3FF0(r3)
0004A630  lwz       r0, 8+sender_lr(r1)
0004A634  mtlr      r0
0004A638  addi      r1, r1, 8
0004A63C  lfsu      f20, loc_20
0004A640  stwu      r1, back_chain(r1)
0004A644  mflr      r0
0004A648  stw       r0, 8+sender_lr(r1)
0004A64C  bl        task_prepare_output_cycle_from_table_252F4# Calls sub_42674 then task_update_outputs_from_id_table_252F5 then sub_41050. This wrapper is a scheduled cycle; good anchor to find who schedules output updates.
0004A650  bl        task_update_outputs_from_id_table_252F5# Task: iterates a small fixed list of IO IDs from ROM table byte_252F5 (stride 4) and calls io_set_float_by_id_and_dispatch_15D0(id, r4=0, f4/f.. as value). Strong candidate for periodic solenoid/actuator output update path.
0004A654  bl        task_update_output_cycle_snapshot_18A8# Post-step for output cycle: calls sub_42640 for indices 0..6 and stores into SDA 0x18A8..0x18B4; likely a debug/telemetry snapshot or derived scalars for the output cycle.
0004A658  lwz       r0, 8+sender_lr(r1)
0004A65C  xori      r8, r8, 0x3A6
0004A660  addi      r1, r1, 8
0004A664  b         sub_257C0
```
