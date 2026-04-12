"""
Function-to-table mapping for firmware analysis.

Maps which functions access which calibration tables.
"""

import logging
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)


@dataclass
class FunctionTableMapping:
    """Represents a mapping between a function and a table."""
    function_start: int
    table_start: int
    distance: int
    confidence: float
    access_type: str = "proximity"  # "proximity", "direct", "indirect"
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __str__(self) -> str:
        return f"Function 0x{self.function_start:08X} ↔ Table 0x{self.table_start:08X} (distance: {self.distance:X}, conf: {self.confidence:.2f})"


def map_functions_to_tables(functions: List[Any], tables: List[Any],
                            max_distance: int = 0x1000) -> List[FunctionTableMapping]:
    """
    Map functions to nearby tables based on proximity.
    
    Args:
        functions: List of Function objects
        tables: List of TableCandidate objects
        max_distance: Maximum distance to consider a relationship
    
    Returns:
        List of FunctionTableMapping objects
    """
    mappings = []
    
    # Create table lookup by start address
    table_map = {table.start: table for table in tables}
    
    for func in functions:
        # Find tables within max_distance
        for table in tables:
            # Calculate distance (minimum distance between function and table)
            if func.end < table.start:
                distance = table.start - func.end
            elif func.start > table.end:
                distance = func.start - table.end
            else:
                # Overlap or adjacent
                distance = 0
            
            if distance <= max_distance:
                # Calculate confidence based on distance
                if distance == 0:
                    confidence = 0.9  # Overlap or adjacent
                elif distance < 0x100:
                    confidence = 0.8  # Very close
                elif distance < 0x400:
                    confidence = 0.6  # Close
                elif distance < 0x1000:
                    confidence = 0.4  # Within range
                else:
                    confidence = 0.2  # Far but within max_distance
                
                mapping = FunctionTableMapping(
                    function_start=func.start,
                    table_start=table.start,
                    distance=distance,
                    confidence=confidence,
                    access_type="proximity",
                    metadata={
                        "function_type": func.function_type.value if hasattr(func, 'function_type') else "unknown",
                        "table_type": table.table_type,
                        "table_size": table.size
                    }
                )
                mappings.append(mapping)
    
    return sorted(mappings, key=lambda m: (m.function_start, m.distance))


def get_function_table_map(functions: List[Any], tables: List[Any],
                           mappings: List[FunctionTableMapping]) -> Dict[int, List[int]]:
    """
    Get a dictionary mapping function addresses to list of table addresses.
    
    Returns:
        Dictionary: function_start -> [table_start1, table_start2, ...]
    """
    result = {}
    for mapping in mappings:
        if mapping.function_start not in result:
            result[mapping.function_start] = []
        result[mapping.function_start].append(mapping.table_start)
    return result


def get_table_function_map(functions: List[Any], tables: List[Any],
                          mappings: List[FunctionTableMapping]) -> Dict[int, List[int]]:
    """
    Get a dictionary mapping table addresses to list of function addresses.
    
    Returns:
        Dictionary: table_start -> [function_start1, function_start2, ...]
    """
    result = {}
    for mapping in mappings:
        if mapping.table_start not in result:
            result[mapping.table_start] = []
        result[mapping.table_start].append(mapping.function_start)
    return result


def classify_table_by_function_context(table: Any, functions: List[Any],
                                      mappings: List[FunctionTableMapping]) -> Tuple[str, float]:
    """
    Classify a table based on which functions access it.
    
    Returns:
        Tuple of (classification, confidence)
    """
    # Find functions that access this table
    accessing_functions = [
        f for f in functions
        if any(m.table_start == table.start for m in mappings if m.function_start == f.start)
    ]
    
    if not accessing_functions:
        return ("UNKNOWN", 0.0)
    
    # Check function types
    shift_functions = [f for f in accessing_functions if hasattr(f, 'function_type') and f.function_type.value == "shift_control"]
    tcc_functions = [f for f in accessing_functions if hasattr(f, 'function_type') and f.function_type.value == "tcc_control"]
    pressure_functions = [f for f in accessing_functions if hasattr(f, 'function_type') and f.function_type.value == "pressure_control"]
    
    if shift_functions:
        return ("SHIFT_SCHEDULE", 0.7)
    elif tcc_functions:
        return ("TCC_APPLY_RELEASE", 0.7)
    elif pressure_functions:
        return ("LINE_PRESSURE", 0.7)
    else:
        return ("CALIBRATION", 0.5)

