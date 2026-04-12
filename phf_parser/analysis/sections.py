"""
Section boundary detection for PHF files.

Detects boundaries between different sections in the binary data.
"""

import logging
from typing import List, Optional
from dataclasses import dataclass

from .entropy import entropy_map, find_entropy_transitions, classify_region_by_entropy
from .patterns import detect_patterns, PatternType

logger = logging.getLogger(__name__)


@dataclass
class SectionBoundary:
    """Represents a detected boundary between sections."""
    offset: int
    confidence: float
    reason: str
    entropy_before: Optional[float] = None
    entropy_after: Optional[float] = None
    
    def __str__(self) -> str:
        return f"Boundary @ 0x{self.offset:X} (conf={self.confidence:.2f}, reason={self.reason})"


def detect_sections(data: bytes, start_offset: int = 0, 
                   window_size: int = 256, step: int = 64) -> List[SectionBoundary]:
    """
    Detect section boundaries in binary data.
    
    Uses multiple heuristics:
    - Entropy transitions
    - Pattern detection (headers, footers)
    - Alignment boundaries
    
    Args:
        data: Byte sequence to analyze
        start_offset: Starting offset in the file
        window_size: Size of entropy analysis window
        step: Step size for entropy analysis
    
    Returns:
        List of detected section boundaries
    """
    boundaries = []
    
    # Method 1: Entropy transitions
    entropy_data = entropy_map(data, window_size, step)
    entropy_transitions = find_entropy_transitions(entropy_data, threshold=1.0)
    
    for trans_offset in entropy_transitions:
        # Get entropy values around transition
        before_entropy = None
        after_entropy = None
        
        for i, (offset, entropy) in enumerate(entropy_data):
            if offset >= trans_offset:
                if i > 0:
                    before_entropy = entropy_data[i - 1][1]
                if i < len(entropy_data):
                    after_entropy = entropy_data[i][1]
                break
        
        boundaries.append(SectionBoundary(
            offset=start_offset + trans_offset,
            confidence=0.7,
            reason="entropy_transition",
            entropy_before=before_entropy,
            entropy_after=after_entropy
        ))
    
    # Method 2: Pattern-based detection (headers, footers)
    patterns = detect_patterns(data, start_offset)
    
    for pattern in patterns:
        if pattern.pattern_type in [PatternType.HEADER, PatternType.FOOTER]:
            boundaries.append(SectionBoundary(
                offset=pattern.offset,
                confidence=pattern.confidence,
                reason=f"{pattern.pattern_type.value}_detected"
            ))
    
    # Method 3: Alignment boundaries (common section sizes)
    # Common boundaries: 0x1000, 0x10000, 0x8000, etc.
    common_boundaries = [0x1000, 0x2000, 0x4000, 0x8000, 0x10000]
    
    for boundary_size in common_boundaries:
        for offset in range(boundary_size, len(data), boundary_size):
            file_offset = start_offset + offset
            if file_offset % boundary_size == 0:
                boundaries.append(SectionBoundary(
                    offset=file_offset,
                    confidence=0.5,
                    reason=f"alignment_{hex(boundary_size)}"
                ))
    
    # Sort boundaries
    boundaries = sorted(boundaries, key=lambda b: b.offset)
    
    # Merge boundaries that are very close (< 16 bytes apart)
    merged = []
    seen_offsets = set()
    for boundary in boundaries:
        # Deduplicate by offset (within 16 bytes)
        if not merged:
            merged.append(boundary)
            seen_offsets.add(boundary.offset)
        else:
            # Check if this boundary is too close to previous ones
            too_close = any(abs(boundary.offset - seen) < 16 for seen in seen_offsets)
            if not too_close:
                merged.append(boundary)
                seen_offsets.add(boundary.offset)
            else:
                # Merge: keep the one with higher confidence
                for i, existing in enumerate(merged):
                    if abs(boundary.offset - existing.offset) < 16:
                        if boundary.confidence > existing.confidence:
                            merged[i] = boundary
                        break
    
    return merged

