"""
Data models for representing PHF file structure.

These models preserve all bytes from the original file, including
padding, checksums, and unknown fields, to enable lossless roundtrip.
"""

import logging
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)


@dataclass
class PHFHeader:
    """
    Represents the ASCII header section of a PHF file.
    
    This class stores both the parsed fields and the raw bytes
    to ensure exact reconstruction.
    """
    # Raw header bytes (preserved for exact reconstruction)
    raw_bytes: bytes = field(default_factory=bytes)
    
    # Parsed fields (for convenience, but raw_bytes takes precedence)
    eprom_part_no: Optional[str] = None
    copyright_year: Optional[str] = None
    application: Optional[str] = None
    file_type: Optional[str] = None  # e.g., "SILVEROAK-Siemens", "SPANISHOAK", "BOAK"
    file_name: Optional[str] = None
    release_date: Optional[str] = None
    module_type: Optional[str] = None
    vehicle_calibration: Optional[str] = None
    vehicle_application: Optional[str] = None
    engine_size: Optional[str] = None
    production_module_part_number: Optional[str] = None
    catchword: Optional[str] = None
    wers_notice: Optional[str] = None
    design_transmittal: Optional[str] = None
    cal_id: Optional[str] = None
    last_data_address: Optional[str] = None
    comments: Optional[str] = None
    released_by: Optional[str] = None
    mask_number: Optional[str] = None
    module_name: Optional[str] = None
    module_id: Optional[str] = None
    download_format: Optional[str] = None
    file_checksum: Optional[str] = None
    flash_indicator: Optional[str] = None
    flash_erase_sectors: Optional[str] = None
    omit_from_service_tool_flash: Optional[str] = None
    address_append: Optional[str] = None
    software_partnumber: Optional[str] = None
    
    # Additional fields that might exist
    extra_fields: Dict[str, str] = field(default_factory=dict)
    
    def get_field(self, name: str) -> Optional[str]:
        """Get a header field by name."""
        return getattr(self, name.lower().replace(' ', '_'), None) or self.extra_fields.get(name)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert header to dictionary representation."""
        result = {}
        for field_name in [
            'eprom_part_no', 'copyright_year', 'application', 'file_type',
            'file_name', 'release_date', 'module_type', 'vehicle_calibration',
            'vehicle_application', 'engine_size', 'production_module_part_number',
            'catchword', 'wers_notice', 'design_transmittal', 'cal_id',
            'last_data_address', 'comments', 'released_by', 'mask_number',
            'module_name', 'module_id', 'download_format', 'file_checksum',
            'flash_indicator', 'flash_erase_sectors', 'omit_from_service_tool_flash',
            'address_append', 'software_partnumber'
        ]:
            value = getattr(self, field_name)
            if value is not None:
                result[field_name] = value
        result.update(self.extra_fields)
        return result


@dataclass
class PHFSubSection:
    """
    Represents a sub-section within a larger PHF section.
    
    Used for detailed structural analysis while preserving parent section integrity.
    """
    parent_offset: int  # Offset within parent section
    size: int
    section_type: str
    confidence: float
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class PHFPattern:
    """
    Represents a detected pattern in the PHF file.
    
    Patterns are non-destructive annotations about the data structure.
    """
    pattern_type: str  # "header", "footer", "checksum", "address", etc.
    offset: int
    size: int
    data: bytes
    confidence: float
    description: str = ""


@dataclass
class PHFSection:
    """
    Represents a section/block of data in the PHF file.
    
    This preserves all bytes including headers, padding, and checksums.
    """
    # Offset in the original PHF file where this section starts
    file_offset: int
    
    # Raw bytes of this section (preserved exactly)
    raw_data: bytes
    
    # Optional: parsed information about the section
    address: Optional[int] = None  # Memory address if known
    size: Optional[int] = None     # Size if known
    section_type: Optional[str] = None  # Type of section if identified
    
    # Metadata
    has_header: bool = False  # Whether this section has a header prefix
    header_bytes: bytes = field(default_factory=bytes)  # Header bytes if present
    
    # Structural analysis (non-destructive)
    sub_sections: List[PHFSubSection] = field(default_factory=list)  # Sub-sections detected
    patterns: List[PHFPattern] = field(default_factory=list)  # Patterns detected
    entropy: Optional[float] = None  # Average entropy of this section
    estimated_type: Optional[str] = None  # "code", "calibration", "data", "padding"
    
    def __len__(self) -> int:
        """Return the size of this section."""
        return len(self.raw_data)
    
    @property
    def total_size(self) -> int:
        """Total size including header if present."""
        return len(self.header_bytes) + len(self.raw_data)


@dataclass
class PHFFile:
    """
    Complete representation of a PHF file.
    
    This class preserves the entire file structure to enable
    lossless roundtrip conversion.
    """
    # Header section
    header: PHFHeader
    
    # Data sections
    sections: List[PHFSection] = field(default_factory=list)
    
    # Any padding or unknown bytes between sections
    inter_section_padding: List[bytes] = field(default_factory=list)
    
    # Trailing bytes after last section
    trailing_bytes: bytes = field(default_factory=bytes)
    
    # Original file size
    original_size: int = 0
    
    # Platform detection
    platform: Optional[str] = None  # "SILVEROAK", "SPANISHOAK", "BOAK", "GOAK"
    
    # Structural analysis metadata (non-destructive)
    structural_analysis: Dict[str, Any] = field(default_factory=dict)
    
    def get_total_size(self) -> int:
        """Calculate total size of all components."""
        size = len(self.header.raw_bytes)
        for section in self.sections:
            size += section.total_size
        for padding in self.inter_section_padding:
            size += len(padding)
        size += len(self.trailing_bytes)
        return size
    
    def get_section_at_offset(self, offset: int) -> Optional[PHFSection]:
        """Find section that contains the given file offset."""
        current_offset = len(self.header.raw_bytes)
        for section in self.sections:
            if current_offset <= offset < current_offset + section.total_size:
                return section
            current_offset += section.total_size
        return None
    
    def to_summary(self) -> Dict[str, Any]:
        """Generate a summary of the file structure."""
        return {
            "platform": self.platform,
            "header_size": len(self.header.raw_bytes),
            "num_sections": len(self.sections),
            "sections": [
                {
                    "file_offset": s.file_offset,
                    "size": len(s.raw_data),
                    "total_size": s.total_size,
                    "address": hex(s.address) if s.address else None,
                    "type": s.section_type,
                }
                for s in self.sections
            ],
            "inter_section_padding_count": len(self.inter_section_padding),
            "trailing_bytes_size": len(self.trailing_bytes),
            "original_size": self.original_size,
            "calculated_size": self.get_total_size(),
        }

