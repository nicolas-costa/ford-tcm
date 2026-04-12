"""
PHF to BIN converter.

Converts PHF files to binary images, extracting and organizing data
according to the detected structure. Supports multiple platforms.
"""

import logging
from typing import Optional, Dict, Any
from pathlib import Path

from .models import PHFFile
from .exceptions import PHFError
from .read_phf import read_phf

logger = logging.getLogger(__name__)


def phf_to_bin(
    phf_file: PHFFile,
    output_path: str,
    fill_gaps: bool = True,
    gap_fill_byte: int = 0xFF,
    *,
    apply_alignment_fix: bool = True,
    output_path_unaligned: Optional[str] = None,
) -> None:
    """
    Convert a PHFFile to a binary image.
    
    This function extracts the binary data from the PHF file and organizes
    it into a flat binary image, similar to what PHF2BIN does but generic
    and supporting multiple platforms.
    
    Args:
        phf_file: PHFFile object to convert
        output_path: Path where the BIN file will be written
        fill_gaps: Whether to fill gaps with gap_fill_byte
        gap_fill_byte: Byte value to use for filling gaps (default: 0xFF)
        apply_alignment_fix: (SILVEROAK) Apply global alignment fix heuristic (default: True)
        output_path_unaligned: (SILVEROAK) If provided, also write the pre-alignment image here
    
    Raises:
        PHFError: If conversion fails
    """
    logger.info(f"Converting PHF to BIN: platform={phf_file.platform}")
    
    # Determine output size based on platform
    output_size = _get_output_size(phf_file)
    logger.debug(f"Output binary size: {output_size} bytes (0x{output_size:X})")
    
    # Create binary image
    binary_image = bytearray([gap_fill_byte] * output_size)
    
    # Extract data from sections
    written_regions = []
    
    for section in phf_file.sections:
        if section.address is not None:
            # Write at specified address
            addr = section.address
            data = section.raw_data
            
            if addr + len(data) <= output_size:
                binary_image[addr:addr + len(data)] = data
                written_regions.append((addr, len(data)))
                logger.debug(f"Written section at address 0x{addr:X}, size={len(data)}")
            else:
                logger.warning(f"Section at 0x{addr:X} exceeds output size, truncating")
                if addr < output_size:
                    truncate_size = output_size - addr
                    binary_image[addr:addr + truncate_size] = data[:truncate_size]
                    written_regions.append((addr, truncate_size))
        else:
            # No address specified - use sequential writing
            # This is a fallback for sections without address information
            # For SILVEROAK, we intentionally keep the raw stream as a single section
            # and parse it inside _extract_silveroak(). This warning is noise.
            if phf_file.platform != "SILVEROAK":
                logger.warning(f"Section at offset 0x{section.file_offset:X} has no address, skipping")
    
    # Platform-specific extraction
    if phf_file.platform == "SILVEROAK":
        _extract_silveroak(
            phf_file,
            binary_image,
            written_regions,
            apply_alignment_fix=apply_alignment_fix,
            output_path_unaligned=output_path_unaligned,
        )
    elif phf_file.platform in ["SPANISHOAK", "BOAK", "GOAK"]:
        _extract_oak_platform(phf_file, binary_image, written_regions)
    else:
        logger.warning(f"Unknown platform {phf_file.platform}, using generic extraction")
        _extract_generic(phf_file, binary_image, written_regions)
    
    # Write binary file
    output_path = Path(output_path)
    with open(output_path, 'wb') as f:
        f.write(binary_image)
    
    logger.info(f"Successfully wrote BIN file: {output_path} ({output_size} bytes)")
    logger.info(f"Written regions: {len(written_regions)}")


def _get_output_size(phf_file: PHFFile) -> int:
    """Determine output binary size based on platform."""
    platform = phf_file.platform
    
    # Default sizes based on PHF2BIN reference
    platform_sizes = {
        "SPANISHOAK": 1048576,   # 1MB
        "BOAK": 1572864,        # 1.5MB
        "GOAK": 1572864,        # 1.5MB
        "SILVEROAK": 2097152,    # 2MB (based on EPROM PART NO: 2048K)
    }
    
    # Try to get size from header
    if phf_file.header.eprom_part_no:
        # Parse "2048K" format
        eprom_str = phf_file.header.eprom_part_no.upper()
        if 'K' in eprom_str:
            try:
                size_k = int(eprom_str.split('K')[0].strip())
                return size_k * 1024
            except ValueError:
                pass
    
    # Fallback to platform defaults
    return platform_sizes.get(platform, 2097152)  # Default 2MB


def _extract_silveroak(
    phf_file: PHFFile,
    binary_image: bytearray,
    written_regions: list,
    *,
    apply_alignment_fix: bool,
    output_path_unaligned: Optional[str],
) -> None:
    """
    Extract binary data from SILVEROAK PHF.

    SILVEROAK record format (38 bytes each):
      [0:2]   marker   0x3A 0x20
      [2:4]   offset   big-endian u16 — destination offset within the 64 KB block
      [4]     tag_hi   always 0x00
      [5]     carry    byte 31 of the PREVIOUS record's 32-byte data chunk
      [6:37]  data     bytes 0–30 of THIS record's 32-byte data chunk (31 bytes)
      [37]    csum     checksum / metadata — NOT firmware data

    Byte 31 of each 32-byte chunk is therefore carried forward in position [5]
    of the NEXT record.  Cross-block carry: the first data record of block N+1
    carries byte 31 of the last record of block N.
    """
    logger.debug("Extracting SILVEROAK binary data")

    raw = b"".join(s.raw_data for s in phf_file.sections if s.raw_data)
    if not raw:
        return

    marker_block = b"\x3A\x02"
    marker_data = b"\x3A\x20"
    first_block = raw.find(marker_block)
    if first_block == -1:
        logger.warning("SILVEROAK: no 0x3A02 block markers found; falling back to sequential extraction")
        current_offset = 0
        for section in phf_file.sections:
            data = section.raw_data
            if not data:
                continue
            extract_size = min(len(data), len(binary_image) - current_offset)
            if extract_size > 0:
                binary_image[current_offset:current_offset + extract_size] = data[:extract_size]
                written_regions.append((current_offset, extract_size))
                current_offset += extract_size
        return

    block_size = 0x10000
    record_total_size = 38
    block_header_size = 8
    records_per_block = block_size // 32  # 2048
    expected_blocks = len(binary_image) // block_size

    # --- Two-pass extraction ---
    # Pass 1: parse all records, storing (offset, payload_31bytes, carry_byte)
    # Pass 2: resolve byte 31 for each record using the next record's carry byte

    all_blocks: list[list[tuple[int, bytes, int]]] = []
    pos = first_block
    block_index = -1

    while pos + block_header_size <= len(raw) and block_index + 1 < expected_blocks:
        if raw[pos:pos + 2] != marker_block:
            pos += 1
            continue

        block_index += 1
        pos += block_header_size

        block_recs: list[tuple[int, bytes, int]] = []
        for rec in range(records_per_block):
            if pos + record_total_size > len(raw):
                logger.warning(
                    "SILVEROAK: unexpected EOF while parsing block %d record %d (pos=0x%X)",
                    block_index, rec, pos,
                )
                all_blocks.append(block_recs)
                break

            if raw[pos:pos + 2] != marker_data:
                window = raw[pos:pos + 128]
                rel = window.find(marker_data)
                if rel == -1:
                    logger.warning(
                        "SILVEROAK: desync at block %d record %d (pos=0x%X); aborting structured parse",
                        block_index, rec, pos,
                    )
                    all_blocks.append(block_recs)
                    break
                pos += rel

            off = int.from_bytes(raw[pos + 2:pos + 4], "big")
            carry = raw[pos + 5]
            payload_31 = raw[pos + 6:pos + 6 + 31]
            block_recs.append((off, payload_31, carry))
            pos += record_total_size
        else:
            all_blocks.append(block_recs)

    total_records = sum(len(b) for b in all_blocks)

    # Pass 2: write data, resolving byte 31 via carry chain
    for bidx, block_recs in enumerate(all_blocks):
        base = bidx * block_size
        for i, (off, payload_31, _carry) in enumerate(block_recs):
            dst = base + off

            # bytes 0-30 from this record
            if dst + 31 <= len(binary_image):
                binary_image[dst:dst + 31] = payload_31

            # byte 31 from the NEXT record's carry field
            next_carry: Optional[int] = None
            if i + 1 < len(block_recs):
                next_carry = block_recs[i + 1][2]
            elif bidx + 1 < len(all_blocks) and all_blocks[bidx + 1]:
                next_carry = all_blocks[bidx + 1][0][2]

            if next_carry is not None and dst + 32 <= len(binary_image):
                binary_image[dst + 31] = next_carry

    # Optional: persist the pre-alignment image for auditability/reproducibility.
    # This is important because the alignment fix rotates the entire image (data included).
    if output_path_unaligned:
        try:
            out_unaligned = Path(output_path_unaligned)
            out_unaligned.parent.mkdir(parents=True, exist_ok=True)
            with open(out_unaligned, "wb") as f:
                f.write(binary_image)
            logger.info("SILVEROAK: wrote unaligned image: %s", out_unaligned)
        except Exception as e:
            logger.warning("SILVEROAK: failed to write unaligned image (%s): %s", output_path_unaligned, e)

    # Heuristic alignment fix:
    # Some SILVEROAK images show a constant byte shift where valid PPC instruction
    # patterns appear at (addr % 4) != 0 across the whole image. This makes
    # disassembly/decompilation extremely unreliable.
    #
    # We detect the dominant alignment of a common PPC prologue pattern (stwu r1, ...)
    # and rotate the whole image left by that amount (padding with 0xFF) to re-align
    # instructions on 4-byte boundaries.
    if apply_alignment_fix:
        try:
            stwu_pat = b"\x94\x21"
            hits = []
            # Scan a prefix for speed; enough to detect dominant modulo
            scan_len = min(len(binary_image), 0x40000)
            data = bytes(binary_image[:scan_len])
            off = 0
            while True:
                p = data.find(stwu_pat, off)
                if p == -1:
                    break
                hits.append(p & 3)
                off = p + 1
                if len(hits) >= 2000:
                    break

            if hits:
                # dominant mod
                dominant = max(set(hits), key=hits.count)
                if dominant != 0:
                    shift = dominant
                    logger.info("SILVEROAK: applying global alignment shift of %d bytes (stwu mod4=%d)", shift, dominant)
                    rotated = binary_image[shift:] + bytearray([0xFF] * shift)
                    binary_image[:] = rotated[:len(binary_image)]
        except Exception as e:
            logger.warning("SILVEROAK: alignment heuristic failed: %s", e)

    # Record a single contiguous written region
    written_regions.append((0, len(binary_image)))
    logger.info(
        "SILVEROAK: reconstructed %d blocks (%d records) into %d-byte image",
        block_index + 1, total_records, len(binary_image)
    )


def _extract_oak_platform(phf_file: PHFFile, binary_image: bytearray,
                         written_regions: list) -> None:
    """
    Extract binary data from SPANISHOAK/BOAK/GOAK PHF.
    
    Based on PHF2BIN reference implementation.
    """
    logger.debug(f"Extracting {phf_file.platform} binary data")
    
    # Find magic header
    magic_headers = {
        "SPANISHOAK": bytes([0x10, 0x60]),
        "BOAK": bytes([0x30, 0x60]),
        "GOAK": bytes([0x30, 0x60]),
    }
    
    magic = magic_headers.get(phf_file.platform)
    if not magic:
        logger.warning(f"No magic header known for {phf_file.platform}")
        return
    
    # Find magic header in data
    for section in phf_file.sections:
        data = section.raw_data
        magic_pos = data.find(magic)
        
        if magic_pos == -1:
            continue
        
        logger.debug(f"Found magic header at offset {magic_pos} in section")
        
        # Extract data following PHF2BIN logic:
        # - Skip 8-byte headers every 0x10000 bytes
        # - Skip 6-byte headers every 32 bytes
        # - Fill 0x8000-0x10000 with 0xFF
        
        index = 0
        i = magic_pos
        
        while i < len(data) and index < len(binary_image):
            # Skip 8-byte header every 0x10000 bytes
            if index % 0x10000 == 0 and index != 0:
                i += 8
                if i >= len(data):
                    break
            
            # Fill 0x8000-0x10000 with 0xFF (as per PHF2BIN)
            if 0x8000 <= index < 0x10000:
                binary_image[index] = 0xFF
                index += 1
                continue
            
            # Skip 6-byte header every 32 bytes
            if index % 32 == 0 and index != 0:
                i += 6
                if i >= len(data):
                    break
            
            if index >= len(binary_image):
                break
            
            binary_image[index] = data[i]
            i += 1
            index += 1
        
        written_regions.append((0, index))
        logger.debug(f"Extracted {index} bytes using PHF2BIN logic")
        break  # Process first section with magic header


def _extract_generic(phf_file: PHFFile, binary_image: bytearray,
                    written_regions: list) -> None:
    """Generic extraction for unknown platforms."""
    logger.debug("Using generic extraction method")
    
    current_offset = 0
    for section in phf_file.sections:
        data = section.raw_data
        size = min(len(data), len(binary_image) - current_offset)
        
        if size > 0:
            binary_image[current_offset:current_offset + size] = data[:size]
            written_regions.append((current_offset, size))
            current_offset += size


def convert_phf_file_to_bin(phf_path: str, output_path: str,
                            fill_gaps: bool = True, gap_fill_byte: int = 0xFF) -> None:
    """
    Convenience function to convert a PHF file directly to BIN.
    
    Args:
        phf_path: Path to PHF file
        output_path: Path for output BIN file
        fill_gaps: Whether to fill gaps
        gap_fill_byte: Byte value for gaps
    """
    phf_file = read_phf(phf_path)
    phf_to_bin(phf_file, output_path, fill_gaps, gap_fill_byte)

