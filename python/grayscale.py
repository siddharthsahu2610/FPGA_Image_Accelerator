"""
grayscale.py
------------

Convert an RGB image into a 128×128 grayscale image.

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

from pathlib import Path
from PIL import Image

# ---------------------------------------------------------
# Project Paths
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_IMAGE = PROJECT_ROOT / "images" / "input" / "input.png"
OUTPUT_DIR = PROJECT_ROOT / "images" / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_IMAGE = OUTPUT_DIR / "grayscale_128.png"

WIDTH = 128
HEIGHT = 128


def preprocess_image():

    image = Image.open(INPUT_IMAGE)

    image = image.convert("L")

    image = image.resize((WIDTH, HEIGHT))

    image.save(OUTPUT_IMAGE)

    print("===================================")
    print("Image Preprocessing Complete")
    print("===================================")
    print(f"Output : {OUTPUT_IMAGE}")
    print(f"Size   : {WIDTH} x {HEIGHT}")
if __name__ == "__main__":
    preprocess_image()