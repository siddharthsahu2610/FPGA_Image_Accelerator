"""
main.py
-------

Golden Reference Driver for the FPGA Image Processing Accelerator.

Pipeline:
    Input Image
        ↓
    Select Kernel
        ↓
    Convolution Engine
        ↓
    Save Filtered Image
        ↓
    Display Results

Author : Siddharth Sahu
Project: FPGA Image Processing Accelerator
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

from filters import convolve
from kernels import KERNELS


# ==========================================================
# Project Paths
# ==========================================================

PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_IMAGE = PROJECT_ROOT / "images" / "output" / "grayscale_128.png"
OUTPUT_IMAGE = PROJECT_ROOT / "images" / "output" / "filtered.png"


# ==========================================================
# Display Available Kernels
# ==========================================================

def display_kernels():
    print("\n==============================================")
    print(" FPGA IMAGE PROCESSING ACCELERATOR")
    print(" Python Golden Reference Model")
    print("==============================================\n")

    print("Available Kernels:\n")

    names = list(KERNELS.keys())

    for index, kernel_name in enumerate(names, start=1):
        print(f"{index}. {kernel_name}")

    return names


# ==========================================================
# Kernel Selection
# ==========================================================

def select_kernel(kernel_names):

    while True:

        try:

            choice = int(input("\nSelect Kernel Number : "))

            if 1 <= choice <= len(kernel_names):
                return kernel_names[choice - 1]

            print("\nInvalid Selection.\n")

        except ValueError:

            print("\nPlease enter a valid integer.\n")


# ==========================================================
# Load Image
# ==========================================================

def load_image():

    if not INPUT_IMAGE.exists():
        raise FileNotFoundError(
            f"Input image not found:\n{INPUT_IMAGE}"
        )

    image = Image.open(INPUT_IMAGE).convert("L")

    return np.array(image, dtype=np.uint8)


# ==========================================================
# Save Output Image
# ==========================================================

def save_image(image_array):

    Image.fromarray(image_array).save(OUTPUT_IMAGE)


# ==========================================================
# Display Images
# ==========================================================

def display_results(original, filtered, kernel_name):

    plt.figure(figsize=(12, 5))

    plt.subplot(1, 2, 1)
    plt.imshow(original, cmap="gray")
    plt.title("Original Image")
    plt.axis("off")

    plt.subplot(1, 2, 2)
    plt.imshow(filtered, cmap="gray")
    plt.title(kernel_name)
    plt.axis("off")

    plt.tight_layout()
    plt.show()


# ==========================================================
# Main Program
# ==========================================================

def main():

    kernel_names = display_kernels()

    selected = select_kernel(kernel_names)

    config = KERNELS[selected]

    kernel = config["kernel"]
    divisor = config["divisor"]

    print("\n----------------------------------------------")
    print(f"Selected Kernel : {selected}")
    print("----------------------------------------------")

    image = load_image()

    filtered = convolve(
        image=image,
        kernel=kernel,
        divisor=divisor
    )

    save_image(filtered)

    display_results(
        original=image,
        filtered=filtered,
        kernel_name=selected
    )

    print("\n==============================================")
    print(" Processing Complete")
    print("==============================================")

    print(f"\nOutput Image : {OUTPUT_IMAGE}")


# ==========================================================
# Entry Point
# ==========================================================

if __name__ == "__main__":
    main()