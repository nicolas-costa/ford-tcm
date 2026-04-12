"""
State machine detection for TCM firmware analysis.

Detects candidates for state machine structures, including:
- Gear state variables
- Shift control functions
- TCC control
- RTOS task scheduler loops
"""

import logging
import struct
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class StateMachineCandidate:
    """Represents a detected state machine candidate."""
    offset: int
    candidate_type: str  # "gear_state", "shift_control", "tcc_control", "rtos_loop", etc.
    confidence: float
    description: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __str__(self) -> str:
        return f"{self.candidate_type} @ 0x{self.offset:08X} (conf={self.confidence:.2f})"


def detect_state_machine_candidates(data: bytes, start_offset: int = 0,
                                   memory_map: Optional[Any] = None,
                                   functions: Optional[List[Any]] = None) -> List[StateMachineCandidate]:
    """
    Detect state machine candidates in firmware.
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
        memory_map: Optional memory map for context
    
    Returns:
        List of StateMachineCandidate objects
    """
    logger.info("Detecting state machine candidates...")
    
    candidates = []
    
    # Method 1: Search for gear-related strings and patterns
    gear_candidates = _detect_gear_state(data, start_offset)
    candidates.extend(gear_candidates)
    
    # Method 2: Search for shift control patterns
    shift_candidates = _detect_shift_control(data, start_offset)
    candidates.extend(shift_candidates)
    
    # Method 3: Search for TCC control
    tcc_candidates = _detect_tcc_control(data, start_offset)
    candidates.extend(tcc_candidates)
    
    # Method 4: Detect RTOS task scheduler loops
    rtos_candidates = _detect_rtos_loops(data, start_offset)
    candidates.extend(rtos_candidates)
    
    # Method 5: Detect torque phase control
    torque_candidates = _detect_torque_control(data, start_offset)
    candidates.extend(torque_candidates)
    
    # Method 6: Use function analysis to refine candidates
    if functions:
        function_candidates = _detect_from_functions(functions, data, start_offset)
        candidates.extend(function_candidates)
    
    # Method 7: Analyze call patterns
    if functions:
        call_pattern_candidates = _detect_from_call_patterns(functions, data, start_offset)
        candidates.extend(call_pattern_candidates)
    
    logger.info(f"Detected {len(candidates)} state machine candidates")
    return sorted(candidates, key=lambda c: c.offset)


def _detect_gear_state(data: bytes, start_offset: int) -> List[StateMachineCandidate]:
    """Detect gear state variables and functions."""
    candidates = []
    
    # Search for gear-related strings
    gear_strings = [
        b"gear",
        b"Gear",
        b"GEAR",
        b"gear_current",
        b"gear_target",
        b"current_gear",
        b"target_gear",
    ]
    
    for string in gear_strings:
        offset = 0
        while True:
            pos = data.find(string, offset)
            if pos == -1:
                break
            
            # Look for state-like patterns around the string
            # State variables are often near string references
            search_start = max(0, pos - 0x100)
            search_end = min(len(data), pos + 0x100)
            
            # Check for state-like values (0-8 for gears, typically)
            for i in range(search_start, search_end - 3, 4):
                val = struct.unpack('>I', data[i:i+4])[0]
                # Gear values are typically 0-8 (P, R, N, D, 1, 2, 3, 4, 5)
                if 0 <= val <= 8:
                    candidates.append(StateMachineCandidate(
                        offset=start_offset + i,
                        candidate_type="gear_state",
                        confidence=0.6,
                        description=f"Gear state candidate near '{string.decode('ascii', errors='ignore')}' reference",
                        metadata={
                            "gear_value": val,
                            "string_offset": start_offset + pos
                        }
                    ))
            
            offset = pos + 1
    
    return candidates


def _detect_shift_control(data: bytes, start_offset: int) -> List[StateMachineCandidate]:
    """Detect shift control functions and state machines."""
    candidates = []
    
    # Search for shift-related strings
    shift_strings = [
        b"shift",
        b"Shift",
        b"SHIFT",
        b"shift_in_progress",
        b"shift_state",
        b"upshift",
        b"downshift",
    ]
    
    for string in shift_strings:
        pos = data.find(string)
        if pos != -1:
            # Look for function-like patterns (PowerPC function prologue)
            # Typical prologue: stwu r1, -XX(r1) or mflr r0
            search_start = max(0, pos - 0x200)
            search_end = min(len(data), pos + 0x200)
            
            for i in range(search_start, search_end - 3, 4):
                inst = struct.unpack('>I', data[i:i+4])[0]
                primary_opcode = (inst >> 26) & 0x3F
                
                # stwu r1, -XX(r1) - function prologue
                if primary_opcode == 0x25:  # stwu
                    ra = (inst >> 16) & 0x1F
                    if ra == 1:  # r1 (stack pointer)
                        candidates.append(StateMachineCandidate(
                            offset=start_offset + i,
                            candidate_type="shift_control",
                            confidence=0.7,
                            description=f"Shift control function candidate (prologue near '{string.decode('ascii', errors='ignore')}')",
                            metadata={
                                "string_offset": start_offset + pos,
                                "function_prologue": True
                            }
                        ))
                        break
    
    return candidates


def _detect_tcc_control(data: bytes, start_offset: int) -> List[StateMachineCandidate]:
    """Detect TCC (Torque Converter Clutch) control."""
    candidates = []
    
    # Search for TCC-related strings
    tcc_strings = [
        b"TCC",
        b"tcc",
        b"torque_converter",
        b"TorqueConverter",
        b"tcc_mode",
        b"tcc_apply",
        b"tcc_release",
    ]
    
    for string in tcc_strings:
        pos = data.find(string)
        if pos != -1:
            # Look for control patterns
            search_start = max(0, pos - 0x100)
            search_end = min(len(data), pos + 0x100)
            
            # TCC control often uses state values (0=off, 1=apply, 2=release, etc.)
            for i in range(search_start, search_end - 3, 4):
                val = struct.unpack('>I', data[i:i+4])[0]
                if 0 <= val <= 4:  # Typical TCC states
                    candidates.append(StateMachineCandidate(
                        offset=start_offset + i,
                        candidate_type="tcc_control",
                        confidence=0.6,
                        description=f"TCC control candidate near '{string.decode('ascii', errors='ignore')}'",
                        metadata={
                            "tcc_state": val,
                            "string_offset": start_offset + pos
                        }
                    ))
    
    return candidates


def _detect_rtos_loops(data: bytes, start_offset: int) -> List[StateMachineCandidate]:
    """Detect RTOS task scheduler loops."""
    candidates = []
    
    # RTOS loops typically have:
    # - Infinite loops (b . or bl .)
    # - Function calls (bl)
    # - Task switching patterns
    
    # Look for infinite loop patterns
    # PowerPC: b . (branch to self) = 0x48000000 (opcode 0x12, LI=0, AA=0)
    loop_pattern = struct.pack('>I', 0x48000000)
    
    offset = 0
    while True:
        pos = data.find(loop_pattern, offset)
        if pos == -1:
            break
        
        # Check if this is part of a loop structure
        # Look for surrounding instructions that suggest RTOS loop
        context_start = max(0, pos - 0x40)
        context_end = min(len(data), pos + 0x40)
        context = data[context_start:context_end]
        
        # Count function calls (bl instructions) in context
        bl_count = 0
        for i in range(0, len(context) - 3, 4):
            inst = struct.unpack('>I', context[i:i+4])[0]
            primary_opcode = (inst >> 26) & 0x3F
            if primary_opcode == 0x13:  # bl
                bl_count += 1
        
        # RTOS loops typically have multiple function calls
        if bl_count >= 2:
            candidates.append(StateMachineCandidate(
                offset=start_offset + pos,
                candidate_type="rtos_loop",
                confidence=0.7,
                description=f"RTOS task scheduler loop candidate (infinite loop with {bl_count} function calls)",
                metadata={
                    "bl_count": bl_count,
                    "loop_pattern": True
                }
            ))
        
        offset = pos + 1
    
    return candidates


def _detect_torque_control(data: bytes, start_offset: int) -> List[StateMachineCandidate]:
    """Detect torque phase control functions."""
    candidates = []
    
    # Search for torque-related strings
    torque_strings = [
        b"torque",
        b"Torque",
        b"TORQUE",
        b"torque_phase",
        b"torque_control",
    ]
    
    for string in torque_strings:
        pos = data.find(string)
        if pos != -1:
            # Look for function patterns
            search_start = max(0, pos - 0x200)
            search_end = min(len(data), pos + 0x200)
            
            for i in range(search_start, search_end - 3, 4):
                inst = struct.unpack('>I', data[i:i+4])[0]
                primary_opcode = (inst >> 26) & 0x3F
                
                # Function prologue
                if primary_opcode == 0x25:  # stwu
                    candidates.append(StateMachineCandidate(
                        offset=start_offset + i,
                        candidate_type="torque_control",
                        confidence=0.6,
                        description=f"Torque control function candidate near '{string.decode('ascii', errors='ignore')}'",
                        metadata={
                            "string_offset": start_offset + pos
                        }
                    ))
                    break
    
    return candidates


def _detect_from_functions(functions: List[Any], data: bytes,
                          start_offset: int) -> List[StateMachineCandidate]:
    """Detect state machine candidates from function analysis."""
    candidates = []
    
    # Look for functions with high fan-out (likely control functions)
    for func in functions:
        if func.fan_out >= 5:  # Functions that call many others
            # Check if function is in shift/TCC related segments
            if func.function_type.value in ["shift_control", "tcc_control", "pressure_control"]:
                candidates.append(StateMachineCandidate(
                    offset=func.start,
                    candidate_type=func.function_type.value,
                    confidence=0.8,
                    description=f"State machine candidate: {func.function_type.value} function with {func.fan_out} calls",
                    metadata={
                        "function_start": func.start,
                        "function_end": func.end,
                        "fan_out": func.fan_out,
                        "fan_in": func.fan_in
                    }
                ))
    
    return candidates


def _detect_from_call_patterns(functions: List[Any], data: bytes,
                               start_offset: int) -> List[StateMachineCandidate]:
    """Detect state machine candidates from call patterns."""
    candidates = []
    
    # Look for functions that are called by many others (likely state variables or shared logic)
    for func in functions:
        if func.fan_in >= 3:  # Functions called by many others
            # Check if it's a small function (likely state machine helper)
            if func.size < 0x200:  # Less than 512 bytes
                candidates.append(StateMachineCandidate(
                    offset=func.start,
                    candidate_type="state_helper",
                    confidence=0.6,
                    description=f"State machine helper candidate: called by {func.fan_in} functions, size={func.size} bytes",
                    metadata={
                        "function_start": func.start,
                        "function_end": func.end,
                        "fan_in": func.fan_in,
                        "size": func.size
                    }
                ))
    
    return candidates

