"""
kernels.py
-----------

Collection of 3×3 convolution kernels used by the
FPGA Image Processing Accelerator.

These kernels act as the software reference for the
Kernel Register File that will later be implemented
inside the FPGA.

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

import numpy as np


# ==========================================================
# Kernel Definitions
# ==========================================================

IDENTITY = np.array([
    [0, 0, 0],
    [0, 1, 0],
    [0, 0, 0]
], dtype=np.int32)


BOX_BLUR = np.array([
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 1]
], dtype=np.int32)


GAUSSIAN_BLUR = np.array([
    [1, 2, 1],
    [2, 4, 2],
    [1, 2, 1]
], dtype=np.int32)


SHARPEN = np.array([
    [0, -1, 0],
    [-1, 5, -1],
    [0, -1, 0]
], dtype=np.int32)


EDGE = np.array([
    [-1, -1, -1],
    [-1,  8, -1],
    [-1, -1, -1]
], dtype=np.int32)


SOBEL_X = np.array([
    [-1, 0, 1],
    [-2, 0, 2],
    [-1, 0, 1]
], dtype=np.int32)


SOBEL_Y = np.array([
    [-1, -2, -1],
    [ 0,  0,  0],
    [ 1,  2,  1]
], dtype=np.int32)


EMBOSS = np.array([
    [-2, -1, 0],
    [-1,  1, 1],
    [ 0,  1, 2]
], dtype=np.int32)

# ==========================================================
# Kernel Database
# ==========================================================

KERNELS = {

    "identity": {
        "kernel": IDENTITY,
        "divisor": 1
    },

    "box_blur": {
        "kernel": BOX_BLUR,
        "divisor": 9
    },

    "gaussian_blur": {
        "kernel": GAUSSIAN_BLUR,
        "divisor": 16
    },

    "sharpen": {
        "kernel": SHARPEN,
        "divisor": 1
    },

    "edge": {
        "kernel": EDGE,
        "divisor": 1
    },

    "sobel_x": {
        "kernel": SOBEL_X,
        "divisor": 1
    },

    "sobel_y": {
        "kernel": SOBEL_Y,
        "divisor": 1
    },
    "emboss": {
        "kernel": EMBOSS,
        "divisor": 1
    }
}
