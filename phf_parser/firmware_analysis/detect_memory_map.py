"""
Memory map detection for firmware analysis.

Maps different regions of the firmware:
- Bootloader
- RTOS/task scheduler
- Vector table
- CAN/UDS handlers
- TCM strategy area
- Data constants
- Calibration blocks
"""

import logging
from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


class RegionType(Enum):
    """Types of memory regions."""
    UNKNOWN = "unknown"
    BOOTLOADER = "bootloader"
    RTOS = "rtos"
    VECTOR_TABLE = "vector_table"
    CAN_HANDLER = "can_handler"
    UDS_HANDLER = "uds_handler"
    TCM_STRATEGY = "tcm_strategy"
    CODE = "code"
    DATA = "data"
    CALIBRATION = "calibration"
    CONSTANTS = "constants"
    PADDING = "padding"


@dataclass
class MemoryRegion:
    """Represents a memory region."""
    start: int
    end: int
    region_type: RegionType
    confidence: float
    description: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    @property
    def size(self) -> int:
        return self.end - self.start
    
    def __str__(self) -> str:
        return f"{self.region_type.value} @ 0x{self.start:08X}-0x{self.end:08X} ({self.size} bytes)"


@dataclass
class MemoryMap:
    """Complete memory map of the firmware."""
    regions: List[MemoryRegion] = field(default_factory=list)
    base_address: int = 0
    
    def get_region_at(self, address: int) -> Optional[MemoryRegion]:
        """Get region containing the given address."""
        for region in self.regions:
            if region.start <= address < region.end:
                return region
        return None
    
    def to_summary(self) -> Dict[str, Any]:
        """Generate summary of memory map."""
        summary = {
            "base_address": hex(self.base_address),
            "num_regions": len(self.regions),
            "regions_by_type": {}
        }
        
        for region in self.regions:
            rtype = region.region_type.value
            if rtype not in summary["regions_by_type"]:
                summary["regions_by_type"][rtype] = []
            summary["regions_by_type"][rtype].append({
                "start": hex(region.start),
                "end": hex(region.end),
                "size": region.size,
                "confidence": region.confidence
            })
        
        return summary


def detect_memory_map(data: bytes, start_offset: int = 0,
                     calibration_regions: Optional[List[tuple]] = None) -> MemoryMap:
    """
    Detect memory map of the firmware.
    
    Args:
        data: Firmware binary data
        start_offset: Starting offset in the file
        calibration_regions: List of (start, end) tuples for known calibration regions
    
    Returns:
        MemoryMap with detected regions
    """
    logger.info("Detecting memory map...")
    
    memory_map = MemoryMap(base_address=start_offset)
    
    # Detect bootloader (typically first few KB)
    bootloader = _detect_bootloader(data, start_offset)
    if bootloader:
        memory_map.regions.append(bootloader)
    
    # Detect vector table
    vector_table = _detect_vector_table(data, start_offset)
    if vector_table:
        memory_map.regions.append(vector_table)
    
    # Detect RTOS/task scheduler
    rtos = _detect_rtos(data, start_offset)
    if rtos:
        memory_map.regions.append(rtos)
    
    # Detect CAN/UDS handlers (by string patterns)
    can_handler = _detect_can_handler(data, start_offset)
    if can_handler:
        memory_map.regions.append(can_handler)
    
    uds_handler = _detect_uds_handler(data, start_offset)
    if uds_handler:
        memory_map.regions.append(uds_handler)
    
    # Detect TCM strategy area
    tcm_strategy = _detect_tcm_strategy(data, start_offset)
    if tcm_strategy:
        memory_map.regions.append(tcm_strategy)
    
    # Add known calibration regions
    if calibration_regions:
        for cal_start, cal_end in calibration_regions:
            memory_map.regions.append(MemoryRegion(
                start=cal_start,
                end=cal_end,
                region_type=RegionType.CALIBRATION,
                confidence=0.8,
                description="Calibration region (from comparison analysis)"
            ))
    
    # Sort regions by start address
    memory_map.regions.sort(key=lambda r: r.start)
    
    logger.info(f"Detected {len(memory_map.regions)} memory regions")
    return memory_map


def _detect_bootloader(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect bootloader region (typically first 4-8KB)."""
    # Bootloader is usually at the start, has initialization code
    # Look for common bootloader patterns
    
    bootloader_size = 0x2000  # 8KB typical
    
    return MemoryRegion(
        start=start_offset,
        end=start_offset + min(bootloader_size, len(data)),
        region_type=RegionType.BOOTLOADER,
        confidence=0.6,
        description="Bootloader (assumed first 8KB)"
    )


def _detect_vector_table(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect vector table."""
    # Vector tables are typically arrays of function pointers
    # Look for aligned addresses that point to code
    
    # TODO: Implement proper vector table detection
    return None


def _detect_rtos(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect RTOS/task scheduler."""
    # Look for RTOS-related strings or patterns
    rtos_strings = [b"task", b"scheduler", b"RTOS", b"OS", b"mutex", b"semaphore"]
    
    for string in rtos_strings:
        pos = data.find(string)
        if pos != -1:
            # Assume RTOS region around found string
            region_start = max(0, pos - 0x1000)
            region_end = min(len(data), pos + 0x1000)
            
            return MemoryRegion(
                start=start_offset + region_start,
                end=start_offset + region_end,
                region_type=RegionType.RTOS,
                confidence=0.5,
                description=f"RTOS region (found '{string.decode('ascii', errors='ignore')}')"
            )
    
    return None


def _detect_can_handler(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect CAN handler."""
    can_strings = [b"CAN", b"can", b"CANbus", b"CAN bus"]
    
    for string in can_strings:
        pos = data.find(string)
        if pos != -1:
            region_start = max(0, pos - 0x500)
            region_end = min(len(data), pos + 0x500)
            
            return MemoryRegion(
                start=start_offset + region_start,
                end=start_offset + region_end,
                region_type=RegionType.CAN_HANDLER,
                confidence=0.5,
                description=f"CAN handler (found '{string.decode('ascii', errors='ignore')}')"
            )
    
    return None


def _detect_uds_handler(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect UDS handler."""
    uds_strings = [b"UDS", b"uds", b"diagnostic", b"Diagnostic"]
    
    for string in uds_strings:
        pos = data.find(string)
        if pos != -1:
            region_start = max(0, pos - 0x500)
            region_end = min(len(data), pos + 0x500)
            
            return MemoryRegion(
                start=start_offset + region_start,
                end=start_offset + region_end,
                region_type=RegionType.UDS_HANDLER,
                confidence=0.5,
                description=f"UDS handler (found '{string.decode('ascii', errors='ignore')}')"
            )
    
    return None


def _detect_tcm_strategy(data: bytes, start_offset: int) -> Optional[MemoryRegion]:
    """Detect TCM strategy area."""
    # TCM strategy typically contains shift logic, pressure control, etc.
    # Look for related strings
    
    strategy_strings = [b"shift", b"Shift", b"gear", b"Gear", b"pressure", b"Pressure",
                       b"EPC", b"TCC", b"solenoid", b"Solenoid", b"transmission",
                       b"Transmission", b"clutch", b"Clutch"]
    
    found_positions = []
    found_strings = []
    for string in strategy_strings:
        offset = 0
        while True:
            pos = data.find(string, offset)
            if pos == -1:
                break
            found_positions.append(pos)
            found_strings.append(string.decode('ascii', errors='ignore'))
            offset = pos + 1
    
    if found_positions:
        # Create region covering all found strings
        min_pos = min(found_positions)
        max_pos = max(found_positions)
        
        region_start = max(0, min_pos - 0x2000)
        region_end = min(len(data), max_pos + 0x2000)
        
        # Count unique strings found
        unique_strings = set(found_strings)
        
        return MemoryRegion(
            start=start_offset + region_start,
            end=start_offset + region_end,
            region_type=RegionType.TCM_STRATEGY,
            confidence=min(0.9, 0.5 + len(unique_strings) * 0.05),
            description=f"TCM strategy area (found {len(unique_strings)} strategy-related strings: {', '.join(sorted(unique_strings)[:5])})",
            metadata={
                "strings_found": list(unique_strings),
                "string_count": len(found_positions)
            }
        )
    
    return None

