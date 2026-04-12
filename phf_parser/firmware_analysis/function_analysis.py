"""
Function analysis for firmware reverse engineering.

Extracts and analyzes functions, including:
- Function detection (prologues/epilogues)
- Call graph extraction
- Function statistics (size, fans-in/fans-out)
- Relationship with semantic segments
"""

import logging
import struct
from typing import List, Optional, Dict, Any, Set, Tuple
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class FunctionType(Enum):
    """Types of functions."""
    UNKNOWN = "unknown"
    MAIN_LOOP = "main_loop"
    SHIFT_CONTROL = "shift_control"
    TCC_CONTROL = "tcc_control"
    PRESSURE_CONTROL = "pressure_control"
    TORQUE_CALC = "torque_calc"
    RTOS_TASK = "rtos_task"
    DIAGNOSTIC = "diagnostic"
    CALIBRATION_READ = "calibration_read"


@dataclass
class Function:
    """Represents a detected function."""
    start: int
    end: int
    function_type: FunctionType = FunctionType.UNKNOWN
    confidence: float = 0.0
    description: str = ""
    callers: List[int] = field(default_factory=list)  # Addresses of functions that call this
    callees: List[int] = field(default_factory=list)  # Addresses of functions called by this
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def size(self) -> int:
        return self.end - self.start
    
    @property
    def fan_in(self) -> int:
        return len(self.callers)
    
    @property
    def fan_out(self) -> int:
        return len(self.callees)
    
    def __str__(self) -> str:
        return f"{self.function_type.value} @ 0x{self.start:08X}-0x{self.end:08X} ({self.size} bytes, fan_in={self.fan_in}, fan_out={self.fan_out})"


def detect_functions(data: bytes, start_offset: int = 0,
                    memory_map: Optional[Any] = None) -> List[Function]:
    """
    Detect functions in firmware by analyzing PowerPC prologues.
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
        memory_map: Optional memory map for context
    
    Returns:
        List of Function objects
    """
    logger.info("Detecting functions...")
    
    functions = []
    
    # PowerPC function prologue patterns:
    # - stwu r1, -XX(r1)  (store word with update - stack frame)
    # - mflr r0           (move from link register)
    # - stw r0, XX(r1)    (save link register)
    
    # Scan for function prologues
    # PowerPC function prologues typically have:
    # 1. stwu r1, -XX(r1) - stack frame setup
    # 2. mflr r0 - save link register
    # 3. stw r0, XX(r1) - store link register
    
    for offset in range(0, len(data) - 15, 4):
        if offset + 3 >= len(data):
            break
        
        instruction = struct.unpack('>I', data[offset:offset+4])[0]
        primary_opcode = (instruction >> 26) & 0x3F
        
        # stwu instruction (opcode 0x25) - stack frame setup
        if primary_opcode == 0x25:
            ra = (instruction >> 16) & 0x1F
            rb = (instruction >> 11) & 0x1F
            
            # Check if it's stwu r1, -XX(r1) OR stwu r1, XX(r1) (typical function prologue)
            # Also accept stwu with other registers but r1 as base
            if ra == 1 or (rb == 1 and ra != 0):  # More lenient: r1 involved
                # Check if next instruction is mflr (optional but common)
                is_prologue = True
                if offset + 7 < len(data):
                    next_inst = struct.unpack('>I', data[offset+4:offset+8])[0]
                    next_opcode = (next_inst >> 26) & 0x3F
                    # mflr is X-form (opcode 0x1F, extended 0x000)
                    if next_opcode == 0x1F:
                        ext_opcode = (next_inst >> 1) & 0x3FF
                        if ext_opcode == 0x000:  # mflr
                            is_prologue = True
                
                if is_prologue:
                    # This looks like a function prologue
                    func_start = start_offset + offset
                    
                    # Try to find function end (look for blr or return pattern)
                    func_end = _find_function_end(data, offset, start_offset)
                    
                    if func_end > func_start and func_end - func_start < 0x10000:  # Reasonable size limit
                        func = Function(
                            start=func_start,
                            end=func_end,
                            function_type=FunctionType.UNKNOWN,
                            confidence=0.7,
                            description="PowerPC function (detected by prologue)",
                            metadata={
                                "prologue_offset": offset,
                                "stack_frame_size": _extract_stack_frame_size(instruction)
                            }
                        )
                        functions.append(func)
    
    # Remove overlapping functions (keep the one that starts first)
    functions = _remove_overlapping_functions(functions)
    
    # Analyze function types based on context
    functions = _classify_functions(functions, data, start_offset, memory_map)
    
    # Extract call graph
    functions = _extract_call_graph(functions, data, start_offset)
    
    logger.info(f"Detected {len(functions)} functions")
    return sorted(functions, key=lambda f: f.start)


def _find_function_end(data: bytes, start_offset: int, base_offset: int) -> int:
    """
    Find the end of a function by looking for return instructions.
    
    PowerPC return instructions:
    - blr (branch to link register) - opcode 0x4E, extended opcode 0x020
    """
    # Look ahead up to 0x1000 bytes for return instruction
    search_limit = min(start_offset + 0x1000, len(data))
    
    for offset in range(start_offset + 4, search_limit, 4):
        if offset + 3 >= len(data):
            break
        
        instruction = struct.unpack('>I', data[offset:offset+4])[0]
        primary_opcode = (instruction >> 26) & 0x3F
        
        # Check for blr (branch to link register)
        if primary_opcode == 0x1F:  # X-form
            extended_opcode = (instruction >> 1) & 0x3FF
            if extended_opcode == 0x020:  # blr
                return base_offset + offset + 4
    
    # If no return found, assume function ends at next function or limit
    return base_offset + min(start_offset + 0x1000, len(data))


def _extract_stack_frame_size(instruction: int) -> int:
    """Extract stack frame size from stwu instruction."""
    # stwu rA, d(rB)
    # d is a 16-bit signed immediate
    d = instruction & 0xFFFF
    # Sign extend
    if d & 0x8000:
        d = d - 0x10000
    return abs(d)


def _remove_overlapping_functions(functions: List[Function]) -> List[Function]:
    """Remove overlapping functions, keeping the one that starts first."""
    if not functions:
        return functions
    
    # Sort by start address
    functions = sorted(functions, key=lambda f: f.start)
    
    result = []
    for func in functions:
        # Check if this function overlaps with any already added
        overlaps = False
        for existing in result:
            if not (func.end <= existing.start or func.start >= existing.end):
                overlaps = True
                break
        
        if not overlaps:
            result.append(func)
    
    return result


def _classify_functions(functions: List[Function], data: bytes,
                       start_offset: int, memory_map: Optional[Any]) -> List[Function]:
    """Classify functions based on context and patterns."""
    for func in functions:
        func_rel_start = func.start - start_offset
        func_rel_end = func.end - start_offset
        
        if func_rel_start < 0 or func_rel_end > len(data):
            continue
        
        func_data = data[func_rel_start:func_rel_end]
        
        # Check if function is in semantic segments
        if memory_map:
            region = memory_map.get_region_at(func.start)
            if region:
                if region.region_type.value == "tcm_strategy":
                    # Check for shift-related strings
                    if b"shift" in func_data.lower() or b"gear" in func_data.lower():
                        func.function_type = FunctionType.SHIFT_CONTROL
                        func.confidence = 0.8
                        func.description = "Shift control function (in TCM strategy area)"
                    elif b"tcc" in func_data.lower() or b"torque" in func_data.lower():
                        func.function_type = FunctionType.TCC_CONTROL
                        func.confidence = 0.8
                        func.description = "TCC control function (in TCM strategy area)"
                    elif b"pressure" in func_data.lower() or b"epc" in func_data.lower():
                        func.function_type = FunctionType.PRESSURE_CONTROL
                        func.confidence = 0.8
                        func.description = "Pressure control function (in TCM strategy area)"
                elif region.region_type.value == "rtos":
                    func.function_type = FunctionType.RTOS_TASK
                    func.confidence = 0.7
                    func.description = "RTOS task function"
                elif region.region_type.value in ["can_handler", "uds_handler"]:
                    func.function_type = FunctionType.DIAGNOSTIC
                    func.confidence = 0.7
                    func.description = "Diagnostic handler function"
        
        # Check for main loop patterns (infinite loops with function calls)
        if _is_main_loop(func_data):
            func.function_type = FunctionType.MAIN_LOOP
            func.confidence = 0.8
            func.description = "Main control loop (infinite loop with function calls)"
        
        # Check for calibration read patterns
        if _has_calibration_read_patterns(func_data):
            func.function_type = FunctionType.CALIBRATION_READ
            func.confidence = 0.6
            func.description = "Calibration table read function"
    
    return functions


def _is_main_loop(func_data: bytes) -> bool:
    """Check if function looks like a main loop."""
    # Main loops typically have:
    # - Infinite loop (b . or bl .)
    # - Multiple function calls (bl instructions)
    
    bl_count = 0
    loop_pattern = False
    
    for i in range(0, len(func_data) - 3, 4):
        if i + 3 >= len(func_data):
            break
        
        instruction = struct.unpack('>I', func_data[i:i+4])[0]
        primary_opcode = (instruction >> 26) & 0x3F
        
        # Count bl instructions
        if primary_opcode == 0x13:  # bl
            bl_count += 1
        
        # Check for infinite loop (b .)
        if primary_opcode == 0x12:  # b
            # Check if it's a branch to self (LI=0, AA=0)
            li = (instruction >> 2) & 0x3FFFFFF
            if li == 0:
                loop_pattern = True
    
    return loop_pattern and bl_count >= 3


def _has_calibration_read_patterns(func_data: bytes) -> bool:
    """Check if function has patterns suggesting calibration table reads."""
    # Calibration reads often have:
    # - Load instructions (lwz, lhz, lbz)
    # - Address calculations (addis, ori)
    # - Table indexing patterns
    
    load_count = 0
    addr_calc_count = 0
    
    for i in range(0, len(func_data) - 3, 4):
        if i + 3 >= len(func_data):
            break
        
        instruction = struct.unpack('>I', func_data[i:i+4])[0]
        primary_opcode = (instruction >> 26) & 0x3F
        
        # Count load instructions
        if primary_opcode in [0x20, 0x21, 0x22, 0x23]:  # lwz, lwzu, lbz, lbzu
            load_count += 1
        
        # Count address calculation instructions
        if primary_opcode in [0x0E, 0x14]:  # addis, ori
            addr_calc_count += 1
    
    return load_count >= 5 and addr_calc_count >= 2


def _extract_call_graph(functions: List[Function], data: bytes,
                        start_offset: int) -> List[Function]:
    """
    Extract call graph by finding bl (branch and link) and bctrl instructions.
    
    Updates functions with callers and callees.
    """
    # Create address to function mapping
    func_map = {func.start: func for func in functions}
    
    # Also create a map for approximate matching (within 4 bytes)
    func_map_approx = {}
    for func in functions:
        for offset in range(-4, 5, 4):
            addr = func.start + offset
            if addr not in func_map_approx:
                func_map_approx[addr] = func
    
    for func in functions:
        func_rel_start = func.start - start_offset
        func_rel_end = func.end - start_offset
        
        if func_rel_start < 0 or func_rel_end > len(data):
            continue
        
        func_data = data[func_rel_start:func_rel_end]
        
        # Find all call instructions in this function
        for i in range(0, len(func_data) - 3, 4):
            if i + 3 >= len(func_data):
                break
            
            instruction = struct.unpack('>I', func_data[i:i+4])[0]
            primary_opcode = (instruction >> 26) & 0x3F
            
            target_addr = None
            
            # bl (branch and link) - direct call
            if primary_opcode == 0x13:  # bl
                # Extract target address
                # LI field (bits 6-29) is a 24-bit signed offset
                li = (instruction >> 2) & 0x3FFFFFF
                # Sign extend
                if li & 0x2000000:
                    li = li - 0x4000000
                
                # Calculate target address
                call_site = func.start + i
                target_addr = call_site + (li * 4)
            
            # bctrl (branch to count register and link) - indirect call
            elif primary_opcode == 0x1F:  # X-form
                extended_opcode = (instruction >> 1) & 0x3FF
                if extended_opcode == 0x10A:  # bctrl
                    # Indirect call - we can't resolve statically
                    # But we can mark it as an indirect call
                    func.metadata.setdefault("indirect_calls", []).append(func.start + i)
                    continue
            
            # Try to find target function
            if target_addr is not None:
                # Exact match
                if target_addr in func_map:
                    callee = func_map[target_addr]
                    if target_addr not in func.callees:
                        func.callees.append(target_addr)
                    if func.start not in callee.callers:
                        callee.callers.append(func.start)
                # Approximate match (within 4 bytes)
                elif target_addr in func_map_approx:
                    callee = func_map_approx[target_addr]
                    target_addr_exact = callee.start
                    if target_addr_exact not in func.callees:
                        func.callees.append(target_addr_exact)
                    if func.start not in callee.callers:
                        callee.callers.append(func.start)
    
    return functions


def get_function_statistics(functions: List[Function]) -> Dict[str, Any]:
    """Get statistics about detected functions."""
    if not functions:
        return {}
    
    sizes = [f.size for f in functions]
    fan_ins = [f.fan_in for f in functions]
    fan_outs = [f.fan_out for f in functions]
    
    by_type = {}
    for func in functions:
        ftype = func.function_type.value
        if ftype not in by_type:
            by_type[ftype] = []
        by_type[ftype].append(func)
    
    return {
        "total_functions": len(functions),
        "size_stats": {
            "min": min(sizes),
            "max": max(sizes),
            "avg": sum(sizes) / len(sizes),
            "median": sorted(sizes)[len(sizes) // 2]
        },
        "fan_in_stats": {
            "min": min(fan_ins),
            "max": max(fan_ins),
            "avg": sum(fan_ins) / len(fan_ins),
            "median": sorted(fan_ins)[len(fan_ins) // 2]
        },
        "fan_out_stats": {
            "min": min(fan_outs),
            "max": max(fan_outs),
            "avg": sum(fan_outs) / len(fan_outs),
            "median": sorted(fan_outs)[len(fan_outs) // 2]
        },
        "by_type": {ftype: len(funcs) for ftype, funcs in by_type.items()}
    }


def find_functions_by_type(functions: List[Function],
                           function_type: FunctionType) -> List[Function]:
    """Find functions of a specific type."""
    return [f for f in functions if f.function_type == function_type]


def find_functions_in_range(functions: List[Function],
                           start: int, end: int) -> List[Function]:
    """Find functions in a specific address range."""
    return [f for f in functions if f.start >= start and f.end <= end]


def detect_main_loops(functions: List[Function], data: bytes,
                      start_offset: int, memory_map: Optional[Any] = None) -> List[Function]:
    """
    Detect main control loops based on:
    - Frequency of calls
    - Position in call graph
    - Relation with RTOS/SHIFT_STRATEGY segments
    """
    main_loop_candidates = []
    
    for func in functions:
        score = 0.0
        
        # Criterion 1: High fan-out (calls many functions)
        if func.fan_out >= 5:
            score += 0.3
        
        # Criterion 2: Called by many functions (central hub)
        if func.fan_in >= 3:
            score += 0.2
        
        # Criterion 3: Has loop pattern (infinite loop with function calls)
        func_rel_start = func.start - start_offset
        func_rel_end = func.end - start_offset
        if func_rel_start >= 0 and func_rel_end <= len(data):
            func_data = data[func_rel_start:func_rel_end]
            if _is_main_loop(func_data):
                score += 0.4
        
        # Criterion 4: In RTOS or SHIFT_STRATEGY segment
        if memory_map:
            region = memory_map.get_region_at(func.start)
            if region:
                if region.region_type.value == "rtos":
                    score += 0.2
                elif region.region_type.value == "tcm_strategy":
                    score += 0.2
        
        # Criterion 5: Large function (likely main loop)
        if func.size > 0x200:  # > 512 bytes
            score += 0.1
        
        if score >= 0.5:  # Threshold for main loop
            func.function_type = FunctionType.MAIN_LOOP
            func.confidence = min(1.0, score)
            func.description = f"Main control loop candidate (score: {score:.2f})"
            main_loop_candidates.append(func)
    
    return sorted(main_loop_candidates, key=lambda f: f.confidence, reverse=True)


def find_hub_functions(functions: List[Function], min_fan_in: int = 3,
                       min_fan_out: int = 5) -> List[Function]:
    """
    Find hub functions (dispatchers) that are called by many and call many.
    """
    return [
        f for f in functions
        if f.fan_in >= min_fan_in and f.fan_out >= min_fan_out
    ]


def import_validated_functions(functions: List[Function],
                               validated_data: Dict[str, Any],
                               base_address: int = 0) -> List[Function]:
    """
    Import validated function data from IDA/Ghidra and update function list.
    
    Args:
        functions: List of detected functions
        validated_data: Dictionary with validated function data (from JSON)
        base_address: Base address used in validated data
    
    Returns:
        Updated list of functions with validated information
    """
    # Create function map by address
    func_map = {f.start: f for f in functions}
    
    # Parse validated functions
    validated_funcs = validated_data.get("functions", [])
    
    for vfunc in validated_funcs:
        # Extract address
        if isinstance(vfunc.get("address"), str):
            addr_str = vfunc["address"]
            if addr_str.startswith("0x"):
                addr = int(addr_str, 16)
            else:
                addr = int(addr_str)
        else:
            addr = vfunc.get("address", 0)
        
        # Adjust for base address
        if addr >= base_address:
            addr = addr - base_address
        
        # Find matching function
        if addr in func_map:
            func = func_map[addr]
            # Update with validated data
            if "size" in vfunc:
                func.end = func.start + vfunc["size"]
            if "type" in vfunc:
                try:
                    func.function_type = FunctionType[vfunc["type"].upper()]
                except (KeyError, AttributeError):
                    pass
            if "confidence" in vfunc:
                func.confidence = vfunc["confidence"]
            if "description" in vfunc:
                func.description = vfunc["description"]
            func.metadata["validated"] = True
            func.metadata["validation_source"] = vfunc.get("source", "IDA/Ghidra")
        else:
            # Create new function from validated data
            size = vfunc.get("size", 0)
            try:
                func_type = FunctionType[vfunc.get("type", "unknown").upper()]
            except (KeyError, AttributeError):
                func_type = FunctionType.UNKNOWN
            
            new_func = Function(
                start=addr,
                end=addr + size,
                function_type=func_type,
                confidence=vfunc.get("confidence", 1.0),
                description=vfunc.get("description", "Validated function"),
                metadata={
                    "validated": True,
                    "validation_source": vfunc.get("source", "IDA/Ghidra")
                }
            )
            functions.append(new_func)
    
    return sorted(functions, key=lambda f: f.start)

