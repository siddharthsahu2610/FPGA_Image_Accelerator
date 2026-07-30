"""
image_to_mem.py
---------------

Convert a grayscale PNG into a hexadecimal memory
initialization file.

This file will later be loaded into FPGA BRAM using
$readmemh().

Author : Siddharth Sahu
"""

from pathlib import Path
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_IMAGE = PROJECT_ROOT / "images" / "output" / "grayscale_128.png"

OUTPUT_DIR = PROJECT_ROOT / "images" / "test_vectors"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_MEM = OUTPUT_DIR / "image.mem"


def generate_memory_file():

    image = Image.open(INPUT_IMAGE).convert("L")

    pixels = list(image.getdata())

    with open(OUTPUT_MEM, "w") as file:

        for pixel in pixels:

            file.write(f"{pixel:02X}\n")

    print("===================================")
    print("Memory File Generated")
    print("===================================")
    print(f"Pixels : {len(pixels)}")
    print(f"Output : {OUTPUT_MEM}")


if __name__ == "__main__":
    generate_memory_file()