"""
Advanced firmware segmentation.

Segments firmware based on:
- Entropy analysis
- Pattern detection
- Alignment (256-byte blocks)
- Repeated structures
- Organized tables
"""

import logging
from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

from ..analysis import entropy_map, detect_patterns, classify_region_by_entropy

logger = logging.getLogger(__name__)


class SegmentType(Enum):
    """Types of firmware segments."""
    CODE = "code"
    DATA = "data"
    CALIBRATION = "calibration"
    CONSTANTS = "constants"
    PADDING = "padding"
    UNKNOWN = "unknown"
    MIXED = "mixed"
    # Semantic categories (Fase 3.1)
    BOOT = "boot"
    RTOS = "rtos"
    DIAGNOSTICS = "diagnostics"
    TCC_CONTROL = "tcc_control"
    SHIFT_STRATEGY = "shift_strategy"


@dataclass
class FirmwareSegment:
    """Represents a firmware segment."""
    start: int
    end: int
    segment_type: SegmentType
    confidence: float
    entropy: float
    description: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def size(self) -> int:
        return self.end - self.start
    
    def __str__(self) -> str:
        return f"{self.segment_type.value} @ 0x{self.start:08X}-0x{self.end:08X} ({self.size} bytes, entropy={self.entropy:.2f})"


def segment_firmware(data: bytes, start_offset: int = 0,
                    window_size: int = 256, step: int = 64,
                    memory_map: Optional[Any] = None,
                    ppc_density_map: Optional[Dict[int, float]] = None) -> List[FirmwareSegment]:
    """
    Segment firmware using multiple criteria.
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
        window_size: Size of entropy analysis window
        step: Step size for entropy analysis
    
    Returns:
        List of FirmwareSegment objects
    """
    logger.info("Segmenting firmware...")
    
    segments = []
    
    # Get entropy map
    entropy_data = entropy_map(data, window_size, step)
    
    # Cluster segments based on entropy and patterns
    current_segment_start = start_offset
    current_entropy = None
    current_type = None
    
    for offset, entropy in entropy_data:
        file_offset = start_offset + offset
        classification = classify_region_by_entropy(entropy)
        
        # Determine segment type from entropy
        if classification == "very_high" or classification == "high":
            seg_type = SegmentType.CODE
        elif classification == "very_low":
            seg_type = SegmentType.PADDING
        elif classification == "low":
            seg_type = SegmentType.CALIBRATION
        else:
            seg_type = SegmentType.MIXED
        
        # Check if we should start a new segment
        if current_type is None:
            current_type = seg_type
            current_entropy = entropy
        elif seg_type != current_type or abs(entropy - current_entropy) > 1.0:
            # End current segment, start new one
            if current_segment_start < file_offset:
                segments.append(FirmwareSegment(
                    start=current_segment_start,
                    end=file_offset,
                    segment_type=current_type,
                    confidence=0.7,
                    entropy=current_entropy or 0.0,
                    description=f"Segment based on entropy analysis"
                ))
            
            current_segment_start = file_offset
            current_type = seg_type
            current_entropy = entropy
    
    # Add final segment
    if current_segment_start < start_offset + len(data):
        segments.append(FirmwareSegment(
            start=current_segment_start,
            end=start_offset + len(data),
            segment_type=current_type or SegmentType.UNKNOWN,
            confidence=0.7,
            entropy=current_entropy or 0.0,
            description="Final segment"
        ))
    
    # Refine segments using pattern detection
    patterns = detect_patterns(data, start_offset)
    
    # Mark calibration blocks (256-byte aligned)
    for pattern in patterns:
        if pattern.pattern_type.value == "alignment" and pattern.size == 256:
            # Check if this aligns with a calibration segment
            for segment in segments:
                if segment.start <= pattern.offset < segment.end:
                    if segment.segment_type == SegmentType.MIXED:
                        segment.segment_type = SegmentType.CALIBRATION
                        segment.confidence = 0.8
                        segment.description = "256-byte calibration block"
    
    # Apply semantic classification using memory map and PPC density
    if memory_map or ppc_density_map:
        segments = _apply_semantic_classification(segments, memory_map, ppc_density_map, data, start_offset)
    
    logger.info(f"Created {len(segments)} segments")
    return segments


def _apply_semantic_classification(segments: List[FirmwareSegment],
                                   memory_map: Optional[Any],
                                   ppc_density_map: Optional[Dict[int, float]],
                                   data: bytes, start_offset: int) -> List[FirmwareSegment]:
    """
    Apply semantic classification to segments.
    
    Uses memory map and PPC instruction density to classify segments semantically.
    """
    import struct
    
    for segment in segments:
        # Check if segment is in bootloader region
        if memory_map:
            region = memory_map.get_region_at(segment.start)
            if region:
                if region.region_type.value == "bootloader":
                    segment.segment_type = SegmentType.BOOT
                    segment.confidence = max(segment.confidence, 0.8)
                    segment.description = "Bootloader segment"
                elif region.region_type.value == "rtos":
                    segment.segment_type = SegmentType.RTOS
                    segment.confidence = max(segment.confidence, 0.7)
                    segment.description = "RTOS segment"
                elif region.region_type.value == "tcm_strategy":
                    # Further classify TCM strategy
                    if _has_shift_patterns(data, segment.start - start_offset, segment.end - start_offset):
                        segment.segment_type = SegmentType.SHIFT_STRATEGY
                        segment.description = "Shift strategy segment"
                    elif _has_tcc_patterns(data, segment.start - start_offset, segment.end - start_offset):
                        segment.segment_type = SegmentType.TCC_CONTROL
                        segment.description = "TCC control segment"
                elif region.region_type.value in ["can_handler", "uds_handler"]:
                    segment.segment_type = SegmentType.DIAGNOSTICS
                    segment.confidence = max(segment.confidence, 0.7)
                    segment.description = "Diagnostics handler segment"
        
        # Use PPC density to refine CODE segments
        if ppc_density_map and segment.segment_type == SegmentType.CODE:
            # Check PPC instruction density in this segment
            segment_start_rel = segment.start - start_offset
            segment_end_rel = segment.end - start_offset
            
            # Sample density at segment start
            if segment_start_rel in ppc_density_map:
                density = ppc_density_map[segment_start_rel]
                if density > 0.5:  # High PPC instruction density
                    segment.confidence = min(1.0, segment.confidence + 0.2)
                    segment.description = f"Code segment (PPC density: {density:.2%})"
    
    return segments


def _has_shift_patterns(data: bytes, start: int, end: int) -> bool:
    """Check if segment has shift-related patterns."""
    segment_data = data[start:end]
    shift_strings = [b"shift", b"Shift", b"gear", b"Gear"]
    return any(s in segment_data for s in shift_strings)


def _has_tcc_patterns(data: bytes, start: int, end: int) -> bool:
    """Check if segment has TCC-related patterns."""
    segment_data = data[start:end]
    tcc_strings = [b"TCC", b"tcc", b"torque_converter", b"TorqueConverter"]
    return any(s in segment_data for s in tcc_strings)


def cluster_segments(segments: List[FirmwareSegment], 
                     similarity_threshold: float = 0.8) -> List[FirmwareSegment]:
    """
    Cluster similar segments together.
    
    Args:
        segments: List of segments to cluster
        similarity_threshold: Threshold for considering segments similar
    
    Returns:
        Clustered list of segments
    """
    if not segments:
        return []
    
    clustered = []
    current_cluster = [segments[0]]
    
    for segment in segments[1:]:
        # Check similarity with current cluster
        last_segment = current_cluster[-1]
        
        similar = (
            segment.segment_type == last_segment.segment_type and
            abs(segment.entropy - last_segment.entropy) < 0.5 and
            segment.start - last_segment.end < 0x1000  # Close together
        )
        
        if similar:
            current_cluster.append(segment)
        else:
            # Merge current cluster
            if len(current_cluster) > 1:
                merged = FirmwareSegment(
                    start=current_cluster[0].start,
                    end=current_cluster[-1].end,
                    segment_type=current_cluster[0].segment_type,
                    confidence=sum(s.confidence for s in current_cluster) / len(current_cluster),
                    entropy=sum(s.entropy for s in current_cluster) / len(current_cluster),
                    description=f"Merged {len(current_cluster)} similar segments"
                )
                clustered.append(merged)
            else:
                clustered.append(current_cluster[0])
            
            current_cluster = [segment]
    
    # Add final cluster
    if current_cluster:
        if len(current_cluster) > 1:
            merged = FirmwareSegment(
                start=current_cluster[0].start,
                end=current_cluster[-1].end,
                segment_type=current_cluster[0].segment_type,
                confidence=sum(s.confidence for s in current_cluster) / len(current_cluster),
                entropy=sum(s.entropy for s in current_cluster) / len(current_cluster),
                description=f"Merged {len(current_cluster)} similar segments"
            )
            clustered.append(merged)
        else:
            clustered.append(current_cluster[0])
    
    return clustered

