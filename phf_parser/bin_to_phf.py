"""
BIN to PHF converter for SILVEROAK platform (Ford TCM).

Converts a flat 2MB binary image back to SILVEROAK PHF format,
using an original PHF file as template for the ASCII header.

PHF SILVEROAK record format (38 bytes):
  [0:2]   marker   0x3A 0x20
  [2:4]   offset   big-endian u16 — destination within 64KB block
  [4]     tag      always 0x00
  [5]     carry    byte 31 of the PREVIOUS record's 32-byte chunk
  [6:37]  data     bytes 0-30 of THIS record's 32-byte chunk
  [37]    csum     checksum: sum(all 38 bytes) & 0xFF == 0x3A

Block header (8 bytes):
  [0:2]   marker   0x3A 0x02
  [2:4]   fixed    0x00 0x00
  [4:5]   type     0x04
  [5:6]   fixed    0x00
  [6]     block_n  block number (0-31)
  [7]     csum     checksum: sum(all 8 bytes) & 0xFF == 0x3A

Footer: 3A 00 00 00 01 FF (6 bytes, constant)

Alignment: SILVEROAK stores data with a 3-byte preamble (00 00 02) that
precedes the actual firmware. The BIN extraction rotates left by 3 bytes;
this converter reverses that rotation before encoding.
"""

import logging
import struct
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

SILVEROAK_ALIGNMENT_SHIFT = 3
SILVEROAK_PREAMBLE = bytes([0x00, 0x00, 0x02])
SILVEROAK_FOOTER = bytes([0x3A, 0x00, 0x00, 0x00, 0x01, 0xFF])
SILVEROAK_INITIAL_CARRY = 0x48
SILVEROAK_IMAGE_SIZE = 2 * 1024 * 1024  # 2MB
SILVEROAK_BLOCK_SIZE = 0x10000  # 64KB
SILVEROAK_RECORDS_PER_BLOCK = SILVEROAK_BLOCK_SIZE // 32  # 2048
SILVEROAK_CHECKSUM_INVARIANT = 0x3A
SILVEROAK_FILE_CHECKSUM_BIAS = 0x03B2

MARKER_BLOCK = bytes([0x3A, 0x02])
MARKER_DATA = bytes([0x3A, 0x20])


def _record_checksum(record_bytes: bytearray) -> int:
    """Compute checksum byte so sum(all 38 bytes) & 0xFF == 0x3A."""
    return (SILVEROAK_CHECKSUM_INVARIANT - sum(record_bytes[0:37])) & 0xFF


def _block_header(block_num: int) -> bytes:
    """Build an 8-byte block header for the given block number."""
    hdr = bytearray(8)
    hdr[0:2] = MARKER_BLOCK
    hdr[2] = 0x00
    hdr[3] = 0x00
    hdr[4] = 0x04
    hdr[5] = 0x00
    hdr[6] = block_num & 0xFF
    hdr[7] = (SILVEROAK_CHECKSUM_INVARIANT - sum(hdr[0:7])) & 0xFF
    return bytes(hdr)


def _extract_phf_header(phf_path: str) -> bytes:
    """Extract the ASCII header from an existing PHF file (everything before
    the first 0x3A02 block marker)."""
    with open(phf_path, 'rb') as f:
        phf = f.read()
    first_block = phf.find(MARKER_BLOCK)
    if first_block == -1:
        raise ValueError(f"No block marker (0x3A02) found in {phf_path}")
    return phf[:first_block]


def _compute_file_checksum(bin_data: bytes) -> int:
    """Compute the SILVEROAK PHF FILE CHECKSUM for a decoded BIN image."""
    return (sum(bin_data) - SILVEROAK_FILE_CHECKSUM_BIAS) & 0xFFFF


def _update_file_checksum(phf_header: bytes, checksum: int) -> bytes:
    """Replace the fixed-width FILE CHECKSUM value in an ASCII PHF header."""
    field = b"FILE CHECKSUM"
    field_offset = phf_header.find(field)
    if field_offset == -1:
        raise ValueError("PHF template has no FILE CHECKSUM field")

    line_end = phf_header.find(b"\x00", field_offset)
    if line_end == -1:
        raise ValueError("PHF FILE CHECKSUM field is not null-terminated")

    separator = phf_header.find(b">", field_offset, line_end)
    if separator == -1:
        raise ValueError("PHF FILE CHECKSUM field has no value separator")

    value_start = separator + 1
    while value_start < line_end and phf_header[value_start:value_start + 1] == b" ":
        value_start += 1

    old_value = phf_header[value_start:line_end]
    new_value = f"0x{checksum:04X}".encode("ascii")
    if len(old_value) != len(new_value):
        raise ValueError(
            "PHF FILE CHECKSUM field is not fixed-width: "
            f"expected {len(new_value)} bytes, found {len(old_value)}"
        )

    updated = bytearray(phf_header)
    updated[value_start:line_end] = new_value
    return bytes(updated)


def _reverse_alignment(bin_data: bytearray) -> bytearray:
    """Reverse the alignment shift applied during PHF→BIN conversion.
    Prepends the 3-byte preamble and drops the last 3 bytes of the BIN."""
    shift = SILVEROAK_ALIGNMENT_SHIFT
    raw = bytearray(len(bin_data))
    raw[0:shift] = SILVEROAK_PREAMBLE
    raw[shift:] = bin_data[:len(bin_data) - shift]
    return raw


def _encode_blocks(raw: bytearray) -> bytearray:
    """Encode a raw 2MB image into SILVEROAK PHF block+record stream."""
    num_blocks = len(raw) // SILVEROAK_BLOCK_SIZE
    out = bytearray()

    for bi in range(num_blocks):
        out.extend(_block_header(bi))

        base = bi * SILVEROAK_BLOCK_SIZE

        for ri in range(SILVEROAK_RECORDS_PER_BLOCK):
            chunk_off = base + ri * 32
            chunk = raw[chunk_off:chunk_off + 32]
            offset = ri * 32

            if ri == 0 and bi == 0:
                carry = SILVEROAK_INITIAL_CARRY
            elif ri == 0:
                prev_base = (bi - 1) * SILVEROAK_BLOCK_SIZE
                carry = raw[prev_base + (SILVEROAK_RECORDS_PER_BLOCK - 1) * 32 + 31]
            else:
                carry = raw[base + (ri - 1) * 32 + 31]

            rec = bytearray(38)
            rec[0:2] = MARKER_DATA
            rec[2] = (offset >> 8) & 0xFF
            rec[3] = offset & 0xFF
            rec[4] = 0x00
            rec[5] = carry
            rec[6:37] = chunk[0:31]
            rec[37] = _record_checksum(rec)
            out.extend(rec)

    return out


def bin_to_phf(
    bin_path: str,
    output_path: str,
    template_phf_path: str,
    *,
    update_header_checksum: bool = True,
) -> None:
    """
    Convert a flat BIN file back to SILVEROAK PHF format.

    Args:
        bin_path: Path to the 2MB binary file
        output_path: Path for the output PHF file
        template_phf_path: Path to an original PHF file (used as header template)
        update_header_checksum: Recompute the FILE CHECKSUM field in the
                                ASCII header when True.
    """
    bin_data = bytearray(Path(bin_path).read_bytes())
    if len(bin_data) != SILVEROAK_IMAGE_SIZE:
        raise ValueError(
            f"BIN file is {len(bin_data)} bytes, expected {SILVEROAK_IMAGE_SIZE}"
        )

    phf_header = _extract_phf_header(template_phf_path)
    logger.info("PHF header: %d bytes from %s", len(phf_header), template_phf_path)
    if update_header_checksum:
        file_checksum = _compute_file_checksum(bin_data)
        phf_header = _update_file_checksum(phf_header, file_checksum)
        logger.info("Updated PHF FILE CHECKSUM to 0x%04X", file_checksum)

    raw = _reverse_alignment(bin_data)
    logger.info("Reversed alignment shift (%d bytes)", SILVEROAK_ALIGNMENT_SHIFT)

    encoded = _encode_blocks(raw)
    logger.info("Encoded %d blocks (%d bytes of record data)",
                SILVEROAK_IMAGE_SIZE // SILVEROAK_BLOCK_SIZE, len(encoded))

    out = bytearray()
    out.extend(phf_header)
    out.extend(encoded)
    out.extend(SILVEROAK_FOOTER)

    Path(output_path).write_bytes(out)
    logger.info("Wrote PHF: %s (%d bytes)", output_path, len(out))


def main():
    import argparse
    import sys

    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

    parser = argparse.ArgumentParser(
        description="Convert a flat 2MB BIN back to SILVEROAK PHF format."
    )
    parser.add_argument("bin_file", help="Input BIN file (2MB)")
    parser.add_argument("output_phf", help="Output PHF file")
    parser.add_argument(
        "--template",
        required=True,
        help="Original PHF file to use as header template",
    )
    args = parser.parse_args()

    try:
        bin_to_phf(args.bin_file, args.output_phf, args.template)
    except Exception as e:
        logger.error("Failed: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
