"""
filters.py
----------

Generic 3×3 convolution engine.

This software implementation acts as the
Golden Reference Model for the FPGA DSP MAC Engine.

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

import numpy as np

# ==========================================================
# Utility Functions
# ==========================================================

def clip_pixel(value: int) -> np.uint8:
    """
    Saturate a pixel into the valid grayscale range.

    Parameters
    ----------
    value : int

    Returns
    -------
    np.uint8
    """

    return np.uint8(np.clip(value, 0, 255))


# ==========================================================
# Convolution Engine
# ==========================================================

def convolve(
    image: np.ndarray,
    kernel: np.ndarray,
    divisor: int = 1
) -> np.ndarray:
    """
    Perform a generic 3×3 convolution.

    Parameters
    ----------
    image : np.ndarray
        Grayscale input image.

    kernel : np.ndarray
        3×3 convolution kernel.

    divisor : int
        Kernel normalization factor.

    Returns
    -------
    np.ndarray
        Filtered image.
    """

    height, width = image.shape

    output = np.zeros_like(image, dtype=np.uint8)

    padded = np.pad(
        image,
        pad_width=1,
        mode="constant",
        constant_values=0
    )

    for row in range(height):

        for col in range(width):

            window = padded[row:row+3, col:col+3]

            accumulator = int(
                np.sum(
                    window.astype(np.int32) * kernel
                )
            )

            accumulator //= divisor

            output[row, col] = clip_pixel(accumulator)
    return output