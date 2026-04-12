"""
Structural analysis module for PHF files.

This module provides tools for analyzing PHF file structure:
- Entropy calculation
- Pattern detection
- Section boundary detection
- Platform-specific heuristics
"""

from .entropy import calculate_entropy, entropy_map, classify_region_by_entropy
from .patterns import detect_patterns, PatternType, DetectedPattern
from .sections import detect_sections, SectionBoundary
from .silveroak import analyze_silveroak_structure, SilverOakSection

__all__ = [
    'calculate_entropy',
    'entropy_map',
    'classify_region_by_entropy',
    'detect_patterns',
    'PatternType',
    'DetectedPattern',
    'detect_sections',
    'SectionBoundary',
    'analyze_silveroak_structure',
    'SilverOakSection',
]

