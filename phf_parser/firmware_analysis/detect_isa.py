"""
ISA/Architecture detection for firmware analysis.

Detects the processor architecture by analyzing:
- Reset vectors
- Instruction patterns
- Endianness
- Known architecture signatures
"""

import logging
import struct
from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


class ISACandidate(Enum):
    """Possible ISA candidates."""
    UNKNOWN = "unknown"
    HCS12 = "HCS12"  # Freescale/Motorola 68HC12
    POWERPC = "PowerPC"  # PowerPC (various)
    RENESAS = "Renesas"  # Renesas (SH, RX, etc.)
    TRICORE = "Tricore"  # Infineon Tricore
    V850 = "V850"  # Renesas V850
    ARM = "ARM"  # ARM (less likely for automotive)
    M68K = "M68K"  # Motorola 68000 family


@dataclass
class ArchitectureInfo:
    """Information about detected architecture."""
    isa: ISACandidate
    confidence: float  # 0.0 to 1.0
    endianness: str  # "big" or "little"
    base_address: Optional[int] = None
    reset_vector: Optional[int] = None
    word_size: int = 4  # bytes
    evidence: List[str] = field(default_factory=list)
    
    def __str__(self) -> str:
        return f"{self.isa.value} (confidence={self.confidence:.2f}, endian={self.endianness})"


def detect_isa(data: bytes, start_offset: int = 0) -> ArchitectureInfo:
    """
    Detect the ISA/architecture of the firmware.
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
    
    Returns:
        ArchitectureInfo with detected architecture
    """
    logger.info("Detecting ISA/architecture...")
    
    # Try different detection methods
    candidates = []
    
    # Method 1: Reset vector analysis
    reset_info = _analyze_reset_vectors(data, start_offset)
    if reset_info:
        candidates.append(reset_info)
    
    # Method 2: Instruction pattern analysis (PowerPC density)
    instruction_info = _analyze_instruction_patterns(data, start_offset)
    if instruction_info:
        candidates.append(instruction_info)
    
    # Method 5: Reset vector search
    reset_vector_info = find_reset_vector(data, start_offset)
    if reset_vector_info:
        vector_offset, base_addr = reset_vector_info
        reset_info = ArchitectureInfo(
            isa=ISACandidate.POWERPC,
            confidence=0.7,
            endianness="big",
            base_address=base_addr,
            reset_vector=base_addr,
            evidence=[f"Reset vector found at offset 0x{vector_offset:X}, base address: 0x{base_addr:08X}"]
        )
        candidates.append(reset_info)
    
    # Method 3: Endianness detection
    endianness = _detect_endianness(data, start_offset)
    
    # Method 4: Known signatures
    signature_info = _detect_known_signatures(data, start_offset)
    if signature_info:
        candidates.append(signature_info)
    
    # Combine evidence
    if not candidates:
        return ArchitectureInfo(
            isa=ISACandidate.UNKNOWN,
            confidence=0.0,
            endianness=endianness,
            evidence=["No architecture detected"]
        )
    
    # Select best candidate
    if candidates:
        best = max(candidates, key=lambda c: c.confidence)
        best.endianness = endianness
        
        # If we have multiple candidates, combine evidence
        if len(candidates) > 1:
            all_evidence = []
            for c in candidates:
                all_evidence.extend(c.evidence)
            best.evidence = all_evidence
            # Boost confidence if multiple methods agree
            if len([c for c in candidates if c.isa == best.isa]) > 1:
                best.confidence = min(0.95, best.confidence + 0.1)
        
        logger.info(f"Detected: {best}")
        return best
    
    # Fallback: return unknown
    return ArchitectureInfo(
        isa=ISACandidate.UNKNOWN,
        confidence=0.0,
        endianness=endianness,
        evidence=["No architecture detected"]
    )


def _analyze_reset_vectors(data: bytes, start_offset: int) -> Optional[ArchitectureInfo]:
    """Analyze reset vectors to detect architecture."""
    # Common reset vector locations
    # HCS12: typically at 0xFFFE-0xFFFF (16-bit address)
    # PowerPC: typically at 0x00000100 or 0xFFF00100
    # Tricore: typically at 0xA0000000 or 0x80000020
    
    # Look for potential reset vectors in first 1KB
    search_limit = min(0x1000, len(data))
    
    for offset in range(0, search_limit - 3, 4):
        # Try big-endian 32-bit
        try:
            addr_be = struct.unpack('>I', data[offset:offset+4])[0]
            
            # Check for common reset vector addresses
            if addr_be in [0x00000100, 0xFFF00100, 0x80000020, 0xA0000000]:
                return ArchitectureInfo(
                    isa=ISACandidate.POWERPC if addr_be in [0x00000100, 0xFFF00100] else ISACandidate.TRICORE,
                    confidence=0.6,
                    endianness="big",
                    reset_vector=addr_be,
                    evidence=[f"Reset vector candidate at 0x{start_offset + offset:X}: 0x{addr_be:08X}"]
                )
        except:
            pass
        
        # Try little-endian 32-bit
        try:
            addr_le = struct.unpack('<I', data[offset:offset+4])[0]
            if addr_le in [0x00000100, 0xFFF00100]:
                return ArchitectureInfo(
                    isa=ISACandidate.POWERPC,
                    confidence=0.5,
                    endianness="little",
                    reset_vector=addr_le,
                    evidence=[f"Reset vector candidate (LE) at 0x{start_offset + offset:X}: 0x{addr_le:08X}"]
                )
        except:
            pass
    
    return None


def _analyze_instruction_patterns(data: bytes, start_offset: int) -> Optional[ArchitectureInfo]:
    """
    Analyze instruction patterns to detect architecture.
    
    Implements PowerPC instruction pattern matching by analyzing opcodes.
    """
    ppc_density = _calculate_ppc_instruction_density(data, start_offset)
    
    if ppc_density['valid_ratio'] > 0.3:  # More than 30% valid PPC instructions
        return ArchitectureInfo(
            isa=ISACandidate.POWERPC,
            confidence=min(0.9, 0.5 + ppc_density['valid_ratio']),
            endianness="big",
            evidence=[
                f"PowerPC instruction density: {ppc_density['valid_ratio']:.2%}",
                f"Valid instructions: {ppc_density['valid_count']}/{ppc_density['total_count']}",
                f"Common patterns found: {', '.join(ppc_density['patterns_found'])}"
            ]
        )
    
    return None


def _calculate_ppc_instruction_density(data: bytes, start_offset: int,
                                       window_size: int = 0x1000) -> Dict[str, Any]:
    """
    Calculate PowerPC instruction density using sliding window.
    
    Returns:
        Dictionary with density metrics and detected patterns
    """
    valid_count = 0
    total_count = 0
    patterns_found = set()
    
    # PowerPC instruction opcodes (6-bit primary opcode, bits 0-5)
    # Common instructions to detect:
    ppc_opcodes = {
        # D-form instructions (opcode in bits 0-5)
        0x0E: 'addis',   # Add Immediate Shifted
        0x0C: 'addi',    # Add Immediate
        0x14: 'ori',     # OR Immediate
        0x15: 'oris',    # OR Immediate Shifted
        0x18: 'xori',    # XOR Immediate
        0x1C: 'andi',    # AND Immediate
        0x1D: 'andis',   # AND Immediate Shifted
        
        # X-form instructions (opcode in bits 0-5, extended opcode in bits 21-30)
        # For X-form, we check primary opcode and extended opcode
        0x1F: 'X-form',  # Extended opcode instructions
        
        # I-form instructions (branch)
        0x12: 'b',       # Branch
        0x13: 'bl',      # Branch and Link
        
        # Load/Store instructions
        0x20: 'lwz',     # Load Word and Zero
        0x21: 'lwzu',    # Load Word and Zero with Update
        0x22: 'lbz',     # Load Byte and Zero
        0x23: 'lbzu',    # Load Byte and Zero with Update
        0x24: 'stw',     # Store Word
        0x25: 'stwu',    # Store Word with Update
        0x26: 'stb',     # Store Byte
        0x27: 'stbu',    # Store Byte with Update
        
        # Other common instructions
        0x13: 'bl',      # Branch and Link
    }
    
    # Extended opcodes for X-form (when primary opcode is 0x1F)
    xform_extended = {
        0x000: 'mflr',   # Move From Link Register
        0x020: 'mtlr',   # Move To Link Register
        0x009: 'mtctr',  # Move To Count Register
        0x021: 'mflr',   # Move From Link Register (alternative)
        0x10A: 'bctrl',  # Branch to Count Register and Link
        0x210: 'rlwinm', # Rotate Left Word Immediate then AND with Mask
        0x192: 'crxor',  # CR XOR
    }
    
    # Analyze instructions in windows
    for window_start in range(0, len(data) - 3, window_size // 4):
        window_end = min(window_start + window_size, len(data) - 3)
        
        for offset in range(window_start, window_end, 4):
            if offset + 3 >= len(data):
                break
            
            total_count += 1
            instruction = struct.unpack('>I', data[offset:offset+4])[0]
            
            # Extract primary opcode (bits 0-5)
            primary_opcode = (instruction >> 26) & 0x3F
            
            # Check if it's a known PowerPC instruction
            if primary_opcode in ppc_opcodes:
                valid_count += 1
                pattern = ppc_opcodes[primary_opcode]
                patterns_found.add(pattern)
            
            # Check X-form instructions (primary opcode 0x1F)
            elif primary_opcode == 0x1F:
                # Extract extended opcode (bits 21-30)
                extended_opcode = (instruction >> 1) & 0x3FF
                if extended_opcode in xform_extended:
                    valid_count += 1
                    pattern = xform_extended[extended_opcode]
                    patterns_found.add(pattern)
            
            # Check branch instructions (I-form)
            elif primary_opcode in [0x12, 0x13]:  # b, bl
                # Validate: AA bit (bit 30) and LK bit (bit 31) are valid
                # LI field (bits 6-29) should be reasonable
                valid_count += 1
                patterns_found.add('branch')
    
    valid_ratio = valid_count / total_count if total_count > 0 else 0.0
    
    return {
        'valid_count': valid_count,
        'total_count': total_count,
        'valid_ratio': valid_ratio,
        'patterns_found': sorted(patterns_found)
    }


def find_reset_vector(data: bytes, start_offset: int = 0) -> Optional[tuple]:
    """
    Find reset vector and determine base address.
    
    Returns:
        Tuple of (reset_vector_address, base_address) or None
    """
    logger.info("Searching for reset vector...")
    
    # PowerPC reset vectors are typically at:
    # - 0x00000100 (exception vector)
    # - 0xFFF00100 (alternate)
    # - Or in vector table at start of firmware
    
    # Method 1: Look for exception vector table at start
    # PowerPC exception vectors are typically at 0x00000000, 0x00000100, etc.
    
    # Check first 0x1000 bytes for vector table
    search_limit = min(0x1000, len(data))
    
    for offset in range(0, search_limit - 3, 4):
        # Try to find a valid address that points to code
        addr = struct.unpack('>I', data[offset:offset+4])[0]
        
        # Check if address is in reasonable range and points to valid code
        if 0x00000000 <= addr < 0x00200000 and addr % 4 == 0:
            # Check if the target address contains valid PowerPC instructions
            target_offset = addr - start_offset
            if 0 <= target_offset < len(data) - 3:
                # Check if target looks like valid code (has valid PPC instructions)
                target_inst = struct.unpack('>I', data[target_offset:target_offset+4])[0]
                primary_opcode = (target_inst >> 26) & 0x3F
                
                # Common first instructions: addis, ori, bl, b
                if primary_opcode in [0x0E, 0x0C, 0x14, 0x12, 0x13]:
                    logger.info(f"Found potential reset vector at 0x{start_offset + offset:X} pointing to 0x{addr:08X}")
                    return (start_offset + offset, addr)
    
    # Method 2: Look for common reset vector addresses in data
    common_vectors = [0x00000100, 0xFFF00100, 0x80000020]
    
    for vector_addr in common_vectors:
        # Check if this address appears in the data
        vector_bytes = struct.pack('>I', vector_addr)
        pos = data.find(vector_bytes)
        if pos != -1:
            logger.info(f"Found reset vector address 0x{vector_addr:08X} at offset 0x{start_offset + pos:X}")
            return (start_offset + pos, vector_addr)
    
    return None


def _detect_endianness(data: bytes, start_offset: int) -> str:
    """Detect endianness by analyzing data patterns."""
    # Look for addresses or pointers that would indicate endianness
    # If we find values that look like addresses, check alignment
    
    big_endian_score = 0
    little_endian_score = 0
    
    # Sample some 32-bit values and check if they look like addresses
    for offset in range(0, min(0x1000, len(data) - 3), 4):
        val_be = struct.unpack('>I', data[offset:offset+4])[0]
        val_le = struct.unpack('<I', data[offset:offset+4])[0]
        
        # Check if value looks like a valid address (aligned, in reasonable range)
        if 0x00000000 <= val_be <= 0x00200000 and val_be % 4 == 0:
            big_endian_score += 1
        if 0x00000000 <= val_le <= 0x00200000 and val_le % 4 == 0:
            little_endian_score += 1
    
    if big_endian_score > little_endian_score * 1.5:
        return "big"
    elif little_endian_score > big_endian_score * 1.5:
        return "little"
    else:
        # Default to big-endian for automotive (most common)
        return "big"


def _detect_known_signatures(data: bytes, start_offset: int) -> Optional[ArchitectureInfo]:
    """Detect known architecture signatures."""
    # Look for known strings, magic numbers, or patterns
    
    # HCS12: Often has "HC12" or "HCS12" strings
    if b"HC12" in data[:0x1000] or b"HCS12" in data[:0x1000]:
        return ArchitectureInfo(
            isa=ISACandidate.HCS12,
            confidence=0.7,
            endianness="big",
            evidence=["Found HCS12 signature string"]
        )
    
    # PowerPC: May have PPC-related strings
    if b"PPC" in data[:0x1000] or b"PowerPC" in data[:0x1000]:
        return ArchitectureInfo(
            isa=ISACandidate.POWERPC,
            confidence=0.7,
            endianness="big",
            evidence=["Found PowerPC signature string"]
        )
    
    # Tricore: May have Tricore-related strings
    if b"Tricore" in data[:0x1000] or b"TC" in data[:0x1000]:
        return ArchitectureInfo(
            isa=ISACandidate.TRICORE,
            confidence=0.7,
            endianness="big",
            evidence=["Found Tricore signature string"]
        )
    
    return None

