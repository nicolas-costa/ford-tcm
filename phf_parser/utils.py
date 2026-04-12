"""
Utility functions for PHF parsing operations.
"""

import logging
from typing import Tuple, Optional

logger = logging.getLogger(__name__)


def find_bytes(haystack: bytes, needle: bytes, start: int = 0, limit: Optional[int] = None) -> int:
    """
    Find a byte sequence in another byte sequence.
    
    Args:
        haystack: The bytes to search in
        needle: The bytes to find
        start: Starting offset for search
        limit: Maximum offset to search (None = no limit)
    
    Returns:
        Offset where needle is found, or -1 if not found
    """
    if not needle:
        return -1
    
    search_limit = len(haystack) - len(needle)
    if limit is not None:
        search_limit = min(search_limit, start + limit)
    
    for i in range(start, search_limit + 1):
        if haystack[i:i+len(needle)] == needle:
            return i
    
    return -1


def parse_header_field(line: bytes) -> Tuple[Optional[str], Optional[str]]:
    """
    Parse a header field line.
    
    Format: "  FIELD NAME  > VALUE"
    
    Returns:
        Tuple of (field_name, value) or (None, None) if not a valid field
    """
    line_str = line.decode('ascii', errors='ignore').strip()
    
    if '>' not in line_str:
        return None, None
    
    parts = line_str.split('>', 1)
    if len(parts) != 2:
        return None, None
    
    field_name = parts[0].strip()
    value = parts[1].strip()
    
    return field_name, value


def detect_platform(data: bytes, search_limit: int = 0x1000) -> Optional[str]:
    """
    Detect the platform type from PHF file data.
    
    Args:
        data: PHF file bytes
        search_limit: Maximum offset to search
    
    Returns:
        Platform name ("SILVEROAK", "SPANISHOAK", "BOAK", "GOAK") or None
    """
    platforms = {
        b"SPANISHOAK": "SPANISHOAK",
        b"BOAK": "BOAK",
        b"GOAK": "GOAK",
        b"SILVEROAK": "SILVEROAK",
    }
    
    for pattern, name in platforms.items():
        if find_bytes(data, pattern, 0, search_limit) != -1:
            return name
    
    return None


def hex_dump(data: bytes, offset: int = 0, length: Optional[int] = None, width: int = 16) -> str:
    """
    Generate a hex dump string.
    
    Args:
        data: Bytes to dump
        offset: Starting offset
        length: Number of bytes to dump (None = all)
        width: Bytes per line
    
    Returns:
        Hex dump string
    """
    if length is None:
        length = len(data) - offset
    
    result = []
    for i in range(0, length, width):
        chunk = data[offset + i:offset + i + width]
        hex_str = ' '.join(f'{b:02X}' for b in chunk)
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        result.append(f"{offset + i:08X}  {hex_str:<48}  {ascii_str}")
    
    return '\n'.join(result)


def compare_bytes(data1: bytes, data2: bytes) -> list:
    """
    Compare two byte sequences and return list of differences.
    
    Returns:
        List of tuples (offset, byte1, byte2) for each difference
    """
    differences = []
    min_len = min(len(data1), len(data2))
    
    for i in range(min_len):
        if data1[i] != data2[i]:
            differences.append((i, data1[i], data2[i]))
    
    if len(data1) != len(data2):
        # Different lengths
        for i in range(min_len, max(len(data1), len(data2))):
            if i < len(data1):
                differences.append((i, data1[i], None))
            else:
                differences.append((i, None, data2[i]))
    
    return differences

