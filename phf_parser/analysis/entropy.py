"""
Entropy calculation for PHF file analysis.

Entropy analysis helps identify regions of code (high entropy, random-like)
vs calibration data (low entropy, structured patterns).
"""

import logging
import math
from typing import List, Tuple, Optional

logger = logging.getLogger(__name__)


def calculate_entropy(data: bytes, window_size: int = 256) -> float:
    """
    Calculate Shannon entropy of a byte sequence.
    
    Args:
        data: Byte sequence to analyze
        window_size: Size of sliding window (default: 256 bytes)
    
    Returns:
        Entropy value (0.0 to 8.0, where 8.0 = maximum randomness)
    """
    if not data:
        return 0.0
    
    # Count byte frequencies
    freq = [0] * 256
    for byte in data:
        freq[byte] += 1
    
    # Calculate entropy
    entropy = 0.0
    length = len(data)
    
    for count in freq:
        if count > 0:
            probability = count / length
            entropy -= probability * math.log2(probability)
    
    return entropy


def entropy_map(data: bytes, window_size: int = 256, step: int = 64) -> List[Tuple[int, float]]:
    """
    Generate entropy map using sliding window.
    
    Args:
        data: Byte sequence to analyze
        window_size: Size of sliding window
        step: Step size for sliding window (default: 64 bytes)
    
    Returns:
        List of tuples (offset, entropy) for each window position
    """
    entropy_values = []
    
    for offset in range(0, len(data) - window_size + 1, step):
        window_data = data[offset:offset + window_size]
        entropy = calculate_entropy(window_data, window_size)
        entropy_values.append((offset, entropy))
    
    # Handle remaining data if step doesn't align perfectly
    if len(data) % step != 0:
        remaining_start = (len(data) // step) * step
        if remaining_start < len(data) - window_size:
            window_data = data[remaining_start:remaining_start + window_size]
            entropy = calculate_entropy(window_data, window_size)
            entropy_values.append((remaining_start, entropy))
    
    return entropy_values


def classify_region_by_entropy(entropy: float) -> str:
    """
    Classify a region based on entropy value.
    
    Args:
        entropy: Entropy value (0.0 to 8.0)
    
    Returns:
        Classification string
    """
    if entropy < 2.0:
        return "very_low"  # Likely padding, zeros, or highly structured
    elif entropy < 4.0:
        return "low"      # Structured data, calibration tables
    elif entropy < 6.0:
        return "medium"   # Mixed content
    elif entropy < 7.5:
        return "high"     # Code or compressed data
    else:
        return "very_high"  # Encrypted or highly random


def find_entropy_transitions(entropy_map: List[Tuple[int, float]], threshold: float = 1.0) -> List[int]:
    """
    Find offsets where entropy changes significantly.
    
    Args:
        entropy_map: List of (offset, entropy) tuples
        threshold: Minimum entropy difference to consider a transition
    
    Returns:
        List of offsets where transitions occur
    """
    if len(entropy_map) < 2:
        return []
    
    transitions = []
    
    for i in range(1, len(entropy_map)):
        prev_entropy = entropy_map[i - 1][1]
        curr_entropy = entropy_map[i][1]
        diff = abs(curr_entropy - prev_entropy)
        
        if diff >= threshold:
            transitions.append(entropy_map[i][0])
    
    return transitions

