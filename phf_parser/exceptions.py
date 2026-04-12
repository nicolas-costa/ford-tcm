"""
Custom exceptions for PHF parsing operations.
"""


class PHFError(Exception):
    """Base exception for all PHF-related errors."""
    pass


class PHFParseError(PHFError):
    """Raised when parsing a PHF file fails."""
    pass


class PHFWriteError(PHFError):
    """Raised when writing a PHF file fails."""
    pass


class PHFValidationError(PHFError):
    """Raised when PHF file validation fails."""
    pass

