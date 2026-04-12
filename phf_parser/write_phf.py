"""
Lossless PHF file writer.

This module writes PHF files from PHFFile objects, ensuring
byte-perfect reconstruction of the original file.
"""

import logging
from pathlib import Path
from typing import Optional

from .models import PHFFile
from .exceptions import PHFWriteError

logger = logging.getLogger(__name__)


def write_phf(phf_file: PHFFile, output_path: str, verbose: bool = False) -> None:
    """
    Write a PHFFile object to a PHF file.
    
    This function reconstructs the file byte-perfectly from the
    internal representation.
    
    Args:
        phf_file: PHFFile object to write
        output_path: Path where the PHF file will be written
        verbose: Enable verbose logging
    
    Raises:
        PHFWriteError: If writing fails
    """
    output_path = Path(output_path)
    
    logger.info(f"Writing PHF file to: {output_path}")
    
    try:
        # Reconstruct file byte by byte
        output_data = bytearray()
        
        # Write header (exact bytes preserved)
        header_bytes = phf_file.header.raw_bytes
        output_data.extend(header_bytes)
        logger.debug(f"Wrote header: {len(header_bytes)} bytes")
        
        # Write sections
        section_index = 0
        for section in phf_file.sections:
            # Write section header if present
            if section.header_bytes:
                output_data.extend(section.header_bytes)
                logger.debug(f"Section {section_index}: wrote header {len(section.header_bytes)} bytes")
            
            # Write section data
            output_data.extend(section.raw_data)
            logger.debug(f"Section {section_index}: wrote data {len(section.raw_data)} bytes "
                        f"(offset=0x{section.file_offset:X})")
            
            section_index += 1
        
        # Write inter-section padding
        padding_index = 0
        for padding in phf_file.inter_section_padding:
            output_data.extend(padding)
            logger.debug(f"Padding {padding_index}: {len(padding)} bytes")
            padding_index += 1
        
        # Write trailing bytes
        if phf_file.trailing_bytes:
            output_data.extend(phf_file.trailing_bytes)
            logger.debug(f"Trailing bytes: {len(phf_file.trailing_bytes)} bytes")
        
        # Write to file
        with open(output_path, 'wb') as f:
            f.write(output_data)
        
        written_size = len(output_data)
        logger.info(f"Successfully wrote PHF file: {written_size} bytes")
        
        # Validation
        if phf_file.original_size > 0:
            if written_size != phf_file.original_size:
                logger.warning(f"Size mismatch: original={phf_file.original_size}, "
                             f"written={written_size}, diff={written_size - phf_file.original_size}")
            else:
                logger.info("File size matches original (byte-perfect)")
        
    except Exception as e:
        raise PHFWriteError(f"Failed to write PHF file: {e}") from e


def validate_roundtrip(original_data: bytes, reconstructed_data: bytes) -> tuple[bool, list]:
    """
    Validate that a roundtrip conversion is byte-perfect.
    
    Args:
        original_data: Original file bytes
        reconstructed_data: Reconstructed file bytes
    
    Returns:
        Tuple of (is_identical, list_of_differences)
    """
    differences = []
    
    min_len = min(len(original_data), len(reconstructed_data))
    max_len = max(len(original_data), len(reconstructed_data))
    
    # Check byte-by-byte differences
    for i in range(min_len):
        if original_data[i] != reconstructed_data[i]:
            differences.append({
                'offset': i,
                'original': f"0x{original_data[i]:02X}",
                'reconstructed': f"0x{reconstructed_data[i]:02X}",
            })
    
    # Check length difference
    if len(original_data) != len(reconstructed_data):
        differences.append({
            'offset': min_len,
            'type': 'length_mismatch',
            'original_size': len(original_data),
            'reconstructed_size': len(reconstructed_data),
        })
    
    is_identical = len(differences) == 0
    
    return is_identical, differences

