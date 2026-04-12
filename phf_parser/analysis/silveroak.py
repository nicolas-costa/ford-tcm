"""
SILVEROAK-specific structural analysis.

Heuristics and patterns specific to SILVEROAK platform PHF files.
"""

import logging
from typing import List, Optional, Dict, Any
from dataclasses import dataclass

from .patterns import detect_patterns, PatternType, DetectedPattern
from .entropy import entropy_map, classify_region_by_entropy

logger = logging.getLogger(__name__)


@dataclass
class SilverOakSection:
    """Represents a detected section in SILVEROAK PHF."""
    offset: int
    size: int
    section_type: str  # "header", "data", "padding", "unknown"
    confidence: float
    metadata: Dict[str, Any]
    
    def __str__(self) -> str:
        return f"SilverOakSection @ 0x{self.offset:X} size={self.size} type={self.section_type}"


def analyze_silveroak_structure(data: bytes, start_offset: int = 0) -> List[SilverOakSection]:
    """
    Analyze SILVEROAK PHF structure and detect sections.
    
    Based on observations:
    - Records start with 0x3A 0x20 (": ")
    - Data appears to be in structured records
    - May have periodic headers
    
    Args:
        data: Byte sequence to analyze
        start_offset: Starting offset in the file
    
    Returns:
        List of detected sections
    """
    sections = []
    
    # Detect record markers (0x3A 0x20 = ": ")
    record_markers = []
    offset = 0
    while True:
        pos = data.find(b'\x3A\x20', offset)
        if pos == -1:
            break
        record_markers.append(start_offset + pos)
        offset = pos + 1
    
    logger.debug(f"Found {len(record_markers)} record markers (0x3A 0x20)")
    
    # Analyze structure between markers
    if record_markers:
        for i in range(len(record_markers)):
            section_start = record_markers[i]
            section_end = record_markers[i + 1] if i + 1 < len(record_markers) else start_offset + len(data)
            
            section_data_start = section_start - start_offset
            section_data_end = section_end - start_offset
            
            if section_data_start < len(data):
                section_data = data[section_data_start:min(section_data_end, len(data))]
                
                # Classify section
                section_type = _classify_silveroak_section(section_data)
                
                sections.append(SilverOakSection(
                    offset=section_start,
                    size=section_end - section_start,
                    section_type=section_type,
                    confidence=0.7,
                    metadata={
                        "has_record_marker": True,
                        "data_size": len(section_data)
                    }
                ))
    
    # Detect patterns
    patterns = detect_patterns(data, start_offset)
    
    # Group patterns into sections
    for pattern in patterns:
        if pattern.pattern_type == PatternType.HEADER:
            # Try to find associated data
            pattern_end = min(pattern.offset + 0x100, start_offset + len(data))
            
            sections.append(SilverOakSection(
                offset=pattern.offset,
                size=pattern_end - pattern.offset,
                section_type="header_data",
                confidence=pattern.confidence,
                metadata={
                    "pattern": pattern.description,
                    "header_bytes": pattern.data.hex()
                }
            ))
    
    return sorted(sections, key=lambda s: s.offset)


def _classify_silveroak_section(data: bytes) -> str:
    """Classify a SILVEROAK section based on its content."""
    if not data:
        return "unknown"
    
    # Check for padding
    if data[:min(16, len(data))] == b'\xFF' * min(16, len(data)):
        return "padding"
    
    if data[:min(16, len(data))] == b'\x00' * min(16, len(data)):
        return "padding"
    
    # Check for structured data (low entropy)
    from .entropy import calculate_entropy
    entropy = calculate_entropy(data[:min(256, len(data))])
    
    if entropy < 3.0:
        return "calibration"  # Likely calibration data
    elif entropy < 6.0:
        return "data"  # Mixed data
    else:
        return "code"  # Likely code or compressed data


def find_silveroak_record_boundaries(data: bytes) -> List[int]:
    """
    Find boundaries of SILVEROAK records.
    
    Records appear to start with 0x3A 0x20 (": ")
    
    Returns:
        List of offsets where records start
    """
    boundaries = []
    offset = 0
    
    while True:
        pos = data.find(b'\x3A\x20', offset)
        if pos == -1:
            break
        boundaries.append(pos)
        offset = pos + 1
    
    return boundaries

