"""
PHF Parser - Lossless parser for Ford PHF (Packed Hex File) format.

This module provides functionality to read, analyze, and write PHF files
while preserving all bytes exactly, including padding, checksums, and
unknown fields.
"""

from .models import PHFHeader, PHFSection, PHFFile, PHFSubSection, PHFPattern
from .read_phf import read_phf
from .write_phf import write_phf
from .phf_to_bin import phf_to_bin, convert_phf_file_to_bin
from .bin_to_phf import bin_to_phf
from .exceptions import PHFError, PHFParseError, PHFWriteError

__version__ = "0.3.0"
__all__ = [
    "PHFHeader",
    "PHFSection",
    "PHFSubSection",
    "PHFPattern",
    "PHFFile",
    "read_phf",
    "write_phf",
    "phf_to_bin",
    "convert_phf_file_to_bin",
    "bin_to_phf",
    "PHFError",
    "PHFParseError",
    "PHFWriteError",
]

