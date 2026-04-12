"""
Table classification for detected calibration tables.

Classifies tables by:
- Type (2D, 3D, 1D)
- Purpose (speed, load, throttle, temperature, pressure, etc.)
- Structure (axes, lookup, map)
"""

import logging
from enum import Enum
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field

from .detect_tables import TableCandidate

logger = logging.getLogger(__name__)


class TableType(Enum):
    """Types of calibration tables."""
    UNKNOWN = "unknown"
    SPEED_MAP = "speed_map"
    LOAD_MAP = "load_map"
    THROTTLE_MAP = "throttle_map"
    TEMPERATURE_MAP = "temperature_map"
    PRESSURE_MAP = "pressure_map"
    EPC_PRESSURE = "epc_pressure"
    TCC_APPLY = "tcc_apply"
    TCC_RELEASE = "tcc_release"
    SHIFT_THRESHOLD = "shift_threshold"
    TORQUE_MAP = "torque_map"
    LOOKUP_TABLE = "lookup_table"


@dataclass
class TableClassification:
    """Classification of a calibration table."""
    table: TableCandidate
    table_type: TableType
    purpose: str
    confidence: float
    axes: Optional[Dict[str, Any]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __str__(self) -> str:
        return f"{self.table_type.value} @ 0x{self.table.start:08X} ({self.purpose}, conf={self.confidence:.2f})"


def classify_tables(tables: List[TableCandidate],
                   context: Optional[Dict[str, Any]] = None) -> List[TableClassification]:
    """
    Classify detected tables by purpose and type.
    
    Args:
        tables: List of detected table candidates
        context: Optional context (memory map, segments, etc.)
    
    Returns:
        List of TableClassification objects
    """
    logger.info(f"Classifying {len(tables)} tables...")
    
    classifications = []
    
    for table in tables:
        classification = _classify_single_table(table, context)
        classifications.append(classification)
    
    logger.info(f"Classified {len(classifications)} tables")
    return classifications


def _classify_single_table(table: TableCandidate,
                          context: Optional[Dict[str, Any]]) -> TableClassification:
    """Classify a single table."""
    # For now, use heuristics based on:
    # - Table size
    # - Dimensions
    # - Location in memory
    # - Entropy
    
    # Default classification
    table_type = TableType.UNKNOWN
    purpose = "Unknown calibration table"
    confidence = 0.3
    
    # Classify by size and dimensions
    if table.dimensions:
        rows, cols = table.dimensions
        
        # Common 16x16 tables are often speed/load maps
        if rows == 16 and cols == 16:
            table_type = TableType.SPEED_MAP
            purpose = "Speed/Load map (16x16)"
            confidence = 0.6
        
        # 8x16 or 16x8 tables
        elif (rows == 8 and cols == 16) or (rows == 16 and cols == 8):
            table_type = TableType.LOOKUP_TABLE
            purpose = "Lookup table (8x16 or 16x8)"
            confidence = 0.5
    
    # Classify by location (if context provides memory map)
    if context and "memory_map" in context:
        memory_map = context["memory_map"]
        region = memory_map.get_region_at(table.start)
        
        if region:
            # If in TCM strategy area, likely shift/pressure related
            if region.region_type.value == "tcm_strategy":
                if table.size == 256:
                    table_type = TableType.SHIFT_THRESHOLD
                    purpose = "Shift threshold table (in TCM strategy area)"
                    confidence = 0.7
                elif "pressure" in region.description.lower():
                    table_type = TableType.EPC_PRESSURE
                    purpose = "EPC pressure table"
                    confidence = 0.7
    
    # Classify by entropy and structure
    if 3.0 <= table.entropy <= 4.5:
        # Medium entropy suggests structured calibration data
        if table.table_type == "2d":
            if table_type == TableType.UNKNOWN:
                table_type = TableType.LOOKUP_TABLE
                purpose = "2D lookup table"
                confidence = 0.5
    
    return TableClassification(
        table=table,
        table_type=table_type,
        purpose=purpose,
        confidence=confidence,
        metadata={
            "size": table.size,
            "entropy": table.entropy,
            "dimensions": table.dimensions
        }
    )

