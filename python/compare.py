"""
compare.py
----------

Compares Python Golden Output
with FPGA Output.

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

from pathlib import Path
from PIL import Image
import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent

PYTHON_IMAGE = PROJECT_ROOT / "images" / "output" / "embossed.png"

FPGA_IMAGE = PROJECT_ROOT / "images" / "output" / "fpga_output.png"


def main():

    python_img = np.array(Image.open(PYTHON_IMAGE))
    fpga_img = np.array(Image.open(FPGA_IMAGE))

    if python_img.shape != fpga_img.shape:
        raise ValueError("Image dimensions do not match.")

    total_pixels = python_img.size

    differences = np.where(python_img != fpga_img)

    mismatch_count = len(differences[0])

    accuracy = (
        (total_pixels - mismatch_count)
        / total_pixels
    ) * 100

    print("\n========== Verification Report ==========\n")

    print(f"Total Pixels     : {total_pixels}")
    print(f"Mismatched Pixels: {mismatch_count}")
    print(f"Accuracy         : {accuracy:.2f}%")

    if mismatch_count == 0:

        print("\nPASS")
        print("Python Golden Model == FPGA Output")

    else:

        print("\nFAIL")

        print("\nFirst 20 mismatches:\n")

        for i in range(min(20, mismatch_count)):

            r = differences[0][i]
            c = differences[1][i]

            print(
                f"({r:3d},{c:3d})  "
                f"Python={python_img[r,c]:3d}  "
                f"FPGA={fpga_img[r,c]:3d}"
            )

if __name__ == "__main__":
    main()