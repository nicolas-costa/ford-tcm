"""
Pattern detection for PHF file analysis.

Detects common patterns like:
- Headers and footers
- Checksums
- Address pointers
- Repeated sequences
- Magic numbers
"""

import logging
import struct
from enum import Enum
from typing import List, Optional, Tuple
from dataclasses import dataclass

logger = logging.getLogger(__name__)


class PatternType(Enum):
    """Types of patterns that can be detected."""
    HEADER = "header"
    FOOTER = "footer"
    CHECKSUM = "checksum"
    ADDRESS = "address"
    MAGIC_NUMBER = "magic_number"
    REPEATED_SEQUENCE = "repeated_sequence"
    ALIGNMENT = "alignment"
    UNKNOWN = "unknown"


@dataclass
class DetectedPattern:
    """Represents a detected pattern in the data."""
    pattern_type: PatternType
    offset: int
    size: int
    data: bytes
    confidence: float = 0.5  # 0.0 to 1.0
    description: str = ""
    
    def __str__(self) -> str:
        return f"{self.pattern_type.value} @ 0x{self.offset:X} (size={self.size}, conf={self.confidence:.2f})"


def detect_patterns(data: bytes, start_offset: int = 0) -> List[DetectedPattern]:
    """
    Detect patterns in byte data.
    
    Args:
        data: Byte sequence to analyze
        start_offset: Starting offset in the file (for reporting)
    
    Returns:
        List of detected patterns
    """
    patterns = []
    
    # Detect magic numbers / signatures
    patterns.extend(_detect_magic_numbers(data, start_offset))
    
    # Detect repeated sequences
    patterns.extend(_detect_repeated_sequences(data, start_offset))
    
    # Detect potential headers (aligned, structured)
    patterns.extend(_detect_headers(data, start_offset))
    
    # Detect potential addresses/pointers
    patterns.extend(_detect_addresses(data, start_offset))
    
    # Detect alignment patterns
    patterns.extend(_detect_alignments(data, start_offset))
    
    return sorted(patterns, key=lambda p: p.offset)


def _detect_magic_numbers(data: bytes, start_offset: int) -> List[DetectedPattern]:
    """Detect known magic numbers and signatures."""
    patterns = []
    
    # Known magic numbers for PHF/Oak platforms
    magic_numbers = {
        b'\x10\x60': (PatternType.HEADER, "SPANISHOAK header"),
        b'\x30\x60': (PatternType.HEADER, "BOAK/GOAK header"),
        b'\x3A\x20': (PatternType.HEADER, "SILVEROAK record marker"),
        b'\xFF\xFF\xFF\xFF': (PatternType.ALIGNMENT, "Padding/erased"),
    }
    
    for magic, (pattern_type, desc) in magic_numbers.items():
        offset = 0
        while True:
            pos = data.find(magic, offset)
            if pos == -1:
                break
            patterns.append(DetectedPattern(
                pattern_type=pattern_type,
                offset=start_offset + pos,
                size=len(magic),
                data=magic,
                confidence=0.9,
                description=desc
            ))
            offset = pos + 1
    
    return patterns


def _detect_repeated_sequences(data: bytes, start_offset: int, min_repeats: int = 3) -> List[DetectedPattern]:
    """Detect repeated byte sequences."""
    patterns = []
    
    # Look for sequences of 2-16 bytes that repeat
    for seq_len in range(2, 17):
        i = 0
        while i < len(data) - seq_len * min_repeats:
            seq = data[i:i + seq_len]
            repeats = 1
            
            # Count consecutive repeats
            j = i + seq_len
            while j + seq_len <= len(data) and data[j:j + seq_len] == seq:
                repeats += 1
                j += seq_len
            
            if repeats >= min_repeats:
                patterns.append(DetectedPattern(
                    pattern_type=PatternType.REPEATED_SEQUENCE,
                    offset=start_offset + i,
                    size=seq_len * repeats,
                    data=seq * repeats,
                    confidence=0.7,
                    description=f"Repeated {seq_len}-byte sequence ({repeats} times)"
                ))
                # Skip ahead to avoid duplicate detections
                i = j
            else:
                i += 1
    
    return patterns


def _detect_headers(data: bytes, start_offset: int) -> List[DetectedPattern]:
    """Detect potential header structures."""
    patterns = []
    
    # Look for structured headers (aligned, with common patterns)
    # Common header sizes: 2, 4, 6, 8 bytes
    for header_size in [2, 4, 6, 8]:
        for i in range(0, len(data) - header_size, header_size):
            header = data[i:i + header_size]
            
            # Check if it looks structured (not all zeros, not all 0xFF)
            if header == b'\x00' * header_size or header == b'\xFF' * header_size:
                continue
            
            # Check for alignment
            if (start_offset + i) % header_size == 0:
                patterns.append(DetectedPattern(
                    pattern_type=PatternType.HEADER,
                    offset=start_offset + i,
                    size=header_size,
                    data=header,
                    confidence=0.5,
                    description=f"Potential {header_size}-byte header"
                ))
    
    return patterns


def _detect_addresses(data: bytes, start_offset: int) -> List[DetectedPattern]:
    """Detect potential memory addresses (32-bit big-endian)."""
    patterns = []
    
    # Look for addresses in reasonable ranges
    # Common flash ranges: 0x00000000 - 0x00200000 (2MB)
    max_address = 0x00200000
    
    for i in range(0, len(data) - 3, 4):
        # Try big-endian 32-bit
        addr_be = struct.unpack('>I', data[i:i+4])[0]
        
        # Check if it looks like a valid address
        if 0x00000000 <= addr_be <= max_address and (addr_be % 4 == 0):
            patterns.append(DetectedPattern(
                pattern_type=PatternType.ADDRESS,
                offset=start_offset + i,
                size=4,
                data=data[i:i+4],
                confidence=0.6,
                description=f"Potential address: 0x{addr_be:08X}"
            ))
    
    return patterns


def _detect_alignments(data: bytes, start_offset: int) -> List[DetectedPattern]:
    """Detect alignment patterns (zeros, 0xFF padding)."""
    patterns = []
    
    # Look for padding sequences
    for padding_byte in [0x00, 0xFF]:
        i = 0
        while i < len(data):
            if data[i] == padding_byte:
                start = i
                # Count consecutive padding bytes
                while i < len(data) and data[i] == padding_byte:
                    i += 1
                padding_len = i - start
                
                # Only report significant padding (>= 4 bytes)
                if padding_len >= 4:
                    patterns.append(DetectedPattern(
                        pattern_type=PatternType.ALIGNMENT,
                        offset=start_offset + start,
                        size=padding_len,
                        data=bytes([padding_byte]) * padding_len,
                        confidence=0.8,
                        description=f"Padding: {padding_len} bytes of 0x{padding_byte:02X}"
                    ))
            else:
                i += 1
    
    # Detect calibration block alignment (256-byte blocks based on 5M5P analysis)
    # Look for regions that are likely calibration blocks
    for offset in range(0, len(data) - 256, 256):
        # Check if this 256-byte block is aligned and has characteristics of calibration
        block = data[offset:offset + 256]
        # Skip if it's all padding
        if all(b == 0xFF or b == 0x00 for b in block):
            continue
        
        # Check alignment
        if (start_offset + offset) % 0x100 == 0:
            patterns.append(DetectedPattern(
                pattern_type=PatternType.ALIGNMENT,
                offset=start_offset + offset,
                size=256,
                data=block,
                confidence=0.5,
                description=f"Potential 256-byte calibration block (aligned at 0x{start_offset + offset:08X})"
            ))
    
    return patterns

