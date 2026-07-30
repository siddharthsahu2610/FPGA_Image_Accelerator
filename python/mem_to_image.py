"""
mem_to_image.py
---------------

Converts an FPGA output memory file (.mem)
back into an image.

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

from pathlib import Path
import numpy as np
from PIL import Image

# ==========================================================
# Paths
# ==========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_MEM = PROJECT_ROOT / "images" / "test_vectors" / "image.mem"

OUTPUT_IMAGE = PROJECT_ROOT / "images" / "output" / "fpga_output.png"

IMAGE_WIDTH = 128
IMAGE_HEIGHT = 128


# ==========================================================
# Main
# ==========================================================

def main():

    if not INPUT_MEM.exists():
        raise FileNotFoundError(f"Memory file not found:\n{INPUT_MEM}")

    with open(INPUT_MEM, "r") as file:
        pixels = [
            int(line.strip(), 16)
            for line in file
            if line.strip()
        ]

    expected_pixels = IMAGE_WIDTH * IMAGE_HEIGHT

    if len(pixels) != expected_pixels:
        raise ValueError(
            f"Expected {expected_pixels} pixels but found {len(pixels)}"
        )

    image = np.array(
        pixels,
        dtype=np.uint8
    ).reshape(
        IMAGE_HEIGHT,
        IMAGE_WIDTH
    )

    Image.fromarray(image).save(OUTPUT_IMAGE)

    print("\nFPGA Output Image Generated Successfully")
    print(f"Saved to : {OUTPUT_IMAGE}")


if __name__ == "__main__":
    main()