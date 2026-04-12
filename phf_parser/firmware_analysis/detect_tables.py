"""
Calibration table detection for SILVEROAK firmware.

Detects tables using heuristics learned from Phase 2.1:
- 256-byte aligned blocks
- Medium entropy (2.5-5.0)
- Differences between revisions
- Alignment in multiples of 0x100
"""

import logging
import struct
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

from ..analysis import calculate_entropy

logger = logging.getLogger(__name__)


@dataclass
class TableCandidate:
    """Represents a detected table candidate."""
    start: int
    end: int
    size: int
    confidence: float
    table_type: str = "unknown"  # "2d", "3d", "1d", etc.
    dimensions: Optional[tuple] = None  # (rows, cols) for 2D, (x, y, z) for 3D
    data_type: str = "unknown"  # "float", "int16", "int32", "uint16", etc.
    entropy: float = 0.0
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __str__(self) -> str:
        dims_str = f"{self.dimensions}" if self.dimensions else "unknown"
        return f"Table @ 0x{self.start:08X}-0x{self.end:08X} ({self.size} bytes, {self.table_type}, {dims_str}, conf={self.confidence:.2f})"


def detect_tables(data: bytes, start_offset: int = 0,
                 calibration_regions: Optional[List[tuple]] = None) -> List[TableCandidate]:
    """
    Detect calibration tables in firmware.
    
    Uses heuristics from Phase 2.1:
    - 256-byte aligned blocks
    - Medium entropy
    - Structured data patterns
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
        calibration_regions: List of (start, end) tuples for known calibration regions
    
    Returns:
        List of TableCandidate objects
    """
    logger.info("Detecting calibration tables...")
    
    candidates = []
    
    # If calibration regions provided, focus search there
    search_regions = calibration_regions if calibration_regions else [(start_offset, start_offset + len(data))]
    
    for region_start, region_end in search_regions:
        region_data_start = region_start - start_offset
        region_data_end = region_end - start_offset
        
        if region_data_start < 0 or region_data_end > len(data):
            continue
        
        region_data = data[region_data_start:region_data_end]
        
        # Look for 256-byte aligned blocks
        for offset in range(0, len(region_data) - 256, 256):
            block_start = region_start + offset
            block_end = block_start + 256
            
            # Check alignment
            if block_start % 0x100 != 0:
                continue
            
            block = region_data[offset:offset + 256]
            
            # Skip if all padding
            if all(b == 0xFF or b == 0x00 for b in block):
                continue
            
            # Calculate entropy
            entropy = calculate_entropy(block)
            
            # Check if entropy is in calibration range (2.5-5.0)
            if 2.5 <= entropy <= 5.0:
                # Try to determine table structure
                table_type, dimensions = _analyze_table_structure(block)
                
                candidate = TableCandidate(
                    start=block_start,
                    end=block_end,
                    size=256,
                    confidence=0.7,
                    table_type=table_type,
                    dimensions=dimensions,
                    entropy=entropy,
                    metadata={
                        "aligned": True,
                        "entropy_range": "calibration"
                    }
                )
                candidates.append(candidate)
    
    # Also look for larger tables (512, 1024 bytes)
    for table_size in [512, 1024, 2048]:
        for offset in range(0, len(data) - table_size, 256):
            block_start = start_offset + offset
            block_end = block_start + table_size
            
            if block_start % 0x100 != 0:
                continue
            
            block = data[offset:offset + table_size]
            entropy = calculate_entropy(block)
            
            if 2.5 <= entropy <= 5.0:
                table_type, dimensions = _analyze_table_structure(block)
                
                candidate = TableCandidate(
                    start=block_start,
                    end=block_end,
                    size=table_size,
                    confidence=0.6,
                    table_type=table_type,
                    dimensions=dimensions,
                    entropy=entropy,
                    metadata={
                        "aligned": True,
                        "entropy_range": "calibration",
                        "large_table": True
                    }
                )
                candidates.append(candidate)
    
    logger.info(f"Detected {len(candidates)} table candidates")
    return candidates


def _analyze_table_structure(data: bytes) -> tuple:
    """
    Analyze table structure to determine type and dimensions.
    
    Returns:
        Tuple of (table_type, dimensions)
    """
    size = len(data)
    
    # Try to detect common table sizes
    # 2D tables: Nx16 (256 bytes = 16x16 if 1 byte, 8x16 if 2 bytes, 4x16 if 4 bytes)
    # 3D tables: NxMxK
    
    # Check if data looks like floats (4 bytes)
    float_count = 0
    for i in range(0, size - 3, 4):
        try:
            val = struct.unpack('>f', data[i:i+4])[0]
            if -1000.0 <= val <= 1000.0 and not (val != val):  # Valid float range, not NaN
                float_count += 1
        except:
            pass
    
    if float_count > size // 8:  # More than 1/8 are valid floats
        # Likely float table
        num_floats = size // 4
        # Try common dimensions
        if num_floats == 64:  # 8x8 or 16x4
            return ("2d", (8, 8))
        elif num_floats == 128:  # 16x8
            return ("2d", (16, 8))
        elif num_floats == 256:  # 16x16
            return ("2d", (16, 16))
        else:
            return ("2d", (num_floats // 16, 16))
    
    # Check if data looks like int16
    int16_count = 0
    for i in range(0, size - 1, 2):
        try:
            val = struct.unpack('>h', data[i:i+2])[0]
            if -32768 <= val <= 32767:
                int16_count += 1
        except:
            pass
    
    if int16_count > size // 4:
        num_ints = size // 2
        if num_ints == 128:  # 16x8
            return ("2d", (16, 8))
        elif num_ints == 256:  # 16x16
            return ("2d", (16, 16))
        else:
            return ("2d", (num_ints // 16, 16))
    
    # Default: unknown structure
    return ("unknown", None)

