"""
Lossless PHF file reader.

This module reads PHF files while preserving all bytes exactly,
including padding, checksums, and unknown fields.
"""

import logging
from typing import Optional
from pathlib import Path

from .models import PHFHeader, PHFSection, PHFFile
from .exceptions import PHFParseError
from .utils import find_bytes, parse_header_field, detect_platform

logger = logging.getLogger(__name__)


def read_phf(filepath: str, verbose: bool = False) -> PHFFile:
    """
    Read a PHF file and return a PHFFile object.
    
    This function preserves all bytes exactly to enable lossless roundtrip.
    
    Args:
        filepath: Path to the PHF file
        verbose: Enable verbose logging
    
    Returns:
        PHFFile object containing the parsed structure
    
    Raises:
        PHFParseError: If the file cannot be parsed
    """
    filepath = Path(filepath)
    
    if not filepath.exists():
        raise PHFParseError(f"File not found: {filepath}")
    
    logger.info(f"Reading PHF file: {filepath}")
    
    # Read entire file
    with open(filepath, 'rb') as f:
        data = f.read()
    
    original_size = len(data)
    logger.debug(f"File size: {original_size} bytes ({original_size:08X} hex)")
    
    # Detect platform
    platform = detect_platform(data)
    logger.info(f"Detected platform: {platform}")
    
    # Parse header (ASCII section ending with '$')
    header_end = find_bytes(data, b'$')
    if header_end == -1:
        raise PHFParseError("Could not find header terminator '$'")
    
    header_end += 1  # Include the '$' character
    header_bytes = data[:header_end]
    logger.debug(f"Header ends at offset: 0x{header_end:X} ({header_end} bytes)")
    
    # Parse header fields
    header = _parse_header(header_bytes, verbose)
    header.raw_bytes = header_bytes
    
    # Remaining data starts after header
    data_offset = header_end
    remaining_data = data[data_offset:]
    
    logger.debug(f"Data section starts at offset: 0x{data_offset:X}")
    logger.debug(f"Remaining data size: {len(remaining_data)} bytes")
    
    # Parse data sections
    # For now, we'll preserve everything as a single section
    # This can be refined later based on better understanding of the format
    sections = []
    inter_section_padding = []
    trailing_bytes = b''
    
    if remaining_data:
        # Try to identify section boundaries
        # Based on PHF2BIN analysis, there might be patterns like:
        # - Headers every 0x10000 bytes (8 bytes)
        # - Headers every 32 bytes (6 bytes)
        # But for lossless parsing, we'll preserve everything
        
        # For SILVEROAK, we need to understand the structure better
        # For now, store everything as raw data
        section = PHFSection(
            file_offset=data_offset,
            raw_data=remaining_data,
            section_type="data"
        )
        sections.append(section)
        
        logger.debug(f"Created data section: offset=0x{data_offset:X}, size={len(remaining_data)}")
    
    # Create PHFFile object
    phf_file = PHFFile(
        header=header,
        sections=sections,
        inter_section_padding=inter_section_padding,
        trailing_bytes=trailing_bytes,
        original_size=original_size,
        platform=platform
    )
    
    logger.info(f"Successfully parsed PHF file: {len(sections)} sections, "
                f"total size={phf_file.get_total_size()} bytes")
    
    return phf_file


def _parse_header(header_bytes: bytes, verbose: bool = False) -> PHFHeader:
    """
    Parse the ASCII header section.
    
    Args:
        header_bytes: Raw header bytes (including terminator)
        verbose: Enable verbose logging
    
    Returns:
        PHFHeader object
    """
    header = PHFHeader()
    
    # Split into lines
    lines = header_bytes.split(b'\x00')  # Null-terminated lines
    
    for line in lines:
        if not line.strip():
            continue
        
        field_name, value = parse_header_field(line)
        
        if not field_name:
            continue
        
        if verbose:
            logger.debug(f"Header field: {field_name} = {value}")
        
        # Map common field names
        field_mapping = {
            'EPROM PART NO.': 'eprom_part_no',
            'COPYRIGHT CALENDAR YR': 'copyright_year',
            'APPLICATION': 'application',
            'FILE TYPE': 'file_type',
            'FILE NAME': 'file_name',
            'RELEASE DATE': 'release_date',
            'MODULE TYPE': 'module_type',
            'VEHICLE CALIBRATION': 'vehicle_calibration',
            'VEHICLE APPLICATION': 'vehicle_application',
            'ENGINE SIZE': 'engine_size',
            'PRODUCTION MODULE PART NUMBER': 'production_module_part_number',
            'CATCHWORD': 'catchword',
            'WERS NOTICE': 'wers_notice',
            'DESIGN TRANSMITTAL': 'design_transmittal',
            'CAL ID': 'cal_id',
            'LAST DATA ADDRESS': 'last_data_address',
            'COMMENTS': 'comments',
            'RELEASED BY': 'released_by',
            'MASK NUMBER': 'mask_number',
            'MODULE NAME': 'module_name',
            'MODULE ID': 'module_id',
            'DOWNLOAD FORMAT': 'download_format',
            'FILE CHECKSUM': 'file_checksum',
            'FLASH INDICATOR': 'flash_indicator',
            'FLASH ERASE SECTORS': 'flash_erase_sectors',
            'OMIT FROM SERVICE TOOL FLASH': 'omit_from_service_tool_flash',
            'ADDRESS APPEND': 'address_append',
            'SOFTWARE PARTNUMBER': 'software_partnumber',
        }
        
        attr_name = field_mapping.get(field_name.upper())
        if attr_name:
            setattr(header, attr_name, value)
        else:
            # Store unknown fields
            header.extra_fields[field_name] = value
            if verbose:
                logger.debug(f"Unknown header field: {field_name} = {value}")
    
    return header

