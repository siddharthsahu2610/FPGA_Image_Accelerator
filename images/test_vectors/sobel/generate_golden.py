from pathlib import Path

WIDTH = 128
HEIGHT = 128

INPUT_FILE = Path("../image.mem")
OUTPUT_FILE = Path("golden_sobel_x.mem")

# ------------------------------------------------------------
# Load 8-bit grayscale pixels
# ------------------------------------------------------------

values = [
    int(x.strip(), 16)
    for x in INPUT_FILE.read_text().splitlines()
    if x.strip()
]

assert len(values) == WIDTH * HEIGHT, (
    f"Expected {WIDTH*HEIGHT} pixels, got {len(values)}"
)

image = [
    values[r * WIDTH:(r + 1) * WIDTH]
    for r in range(HEIGHT)
]

# ------------------------------------------------------------
# Sobel-X kernel
#
# -1   0  +1
# -2   0  +2
# -1   0  +1
# ------------------------------------------------------------

output = []

for r in range(HEIGHT - 2):
    for c in range(WIDTH - 2):

        p00 = image[r][c]
        p02 = image[r][c + 2]

        p10 = image[r + 1][c]
        p12 = image[r + 1][c + 2]

        p20 = image[r + 2][c]
        p22 = image[r + 2][c + 2]

        acc = (
            -p00 + p02
            - 2 * p10 + 2 * p12
            - p20 + p22
        )

        # Same saturation behavior as RTL
        if acc < 0:
            result = 0
        elif acc > 255:
            result = 255
        else:
            result = acc

        output.append(result)

# ------------------------------------------------------------
# Write hexadecimal memory file
# ------------------------------------------------------------

OUTPUT_FILE.write_text(
    "\n".join(f"{x:02X}" for x in output) + "\n"
)

print("==============================================")
print("SOBEL-X GOLDEN MODEL GENERATED")
print("==============================================")
print(f"Input dimensions  : {WIDTH} x {HEIGHT}")
print(f"Input pixels      : {WIDTH * HEIGHT}")
print(f"Output dimensions : {WIDTH-2} x {HEIGHT-2}")
print(f"Output pixels     : {(WIDTH-2) * (HEIGHT-2)}")
print(f"Output file       : {OUTPUT_FILE}")
print("==============================================")

print("\nFirst 32 golden pixels:")
print(output[:32])

print("\nStatistics:")
print(f"Minimum output    : {min(output)}")
print(f"Maximum output    : {max(output)}")
print(f"Unique values     : {len(set(output))}")
