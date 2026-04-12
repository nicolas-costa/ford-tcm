"""
Firmware analysis module for deep reverse engineering of PHF files.

This module provides tools for:
- ISA/architecture detection
- Memory map generation
- Firmware segmentation
- Calibration table detection and classification
"""

from .detect_isa import detect_isa, ISACandidate, ArchitectureInfo, find_reset_vector, _calculate_ppc_instruction_density
from .detect_memory_map import detect_memory_map, MemoryRegion, MemoryMap
from .segment_firmware import segment_firmware, FirmwareSegment, SegmentType
from .detect_tables import detect_tables, TableCandidate
from .classify_tables import classify_tables, TableType, TableClassification
from .detect_state_machine_candidates import detect_state_machine_candidates, StateMachineCandidate
from .function_table_mapping import (
    map_functions_to_tables, FunctionTableMapping,
    get_function_table_map, get_table_function_map, classify_table_by_function_context
)
from .function_analysis import (
    detect_functions, Function, FunctionType,
    get_function_statistics, find_functions_by_type, find_functions_in_range,
    detect_main_loops, find_hub_functions
)

__all__ = [
    'detect_isa',
    'ISACandidate',
    'ArchitectureInfo',
    'find_reset_vector',
    '_calculate_ppc_instruction_density',
    'detect_memory_map',
    'MemoryRegion',
    'MemoryMap',
    'segment_firmware',
    'FirmwareSegment',
    'SegmentType',
    'detect_tables',
    'TableCandidate',
    'classify_tables',
    'TableType',
    'TableClassification',
    'detect_state_machine_candidates',
    'StateMachineCandidate',
    'detect_functions',
    'Function',
    'FunctionType',
    'get_function_statistics',
    'find_functions_by_type',
    'find_functions_in_range',
    'detect_main_loops',
    'find_hub_functions',
    'import_validated_functions',
    'map_functions_to_tables',
    'FunctionTableMapping',
    'get_function_table_map',
    'get_table_function_map',
    'classify_table_by_function_context',
]

