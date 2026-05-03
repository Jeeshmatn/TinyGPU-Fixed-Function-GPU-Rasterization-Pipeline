import sys
from golden_ref import rasterize, verify_against_rtl

def parse_rtl_log(filename):
    pixels = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith("PIXEL"):
                line = line.replace("PIXEL", "").strip()
                line = line.replace("(", "").replace(")", "")
                parts = line.split(",")
                if len(parts) == 2:
                    x = int(parts[0].strip())
                    y = int(parts[1].strip())
                    pixels.append((x, y))
    return pixels

if __name__ == "__main__":
    print("=" * 50)
    print("TinyGPU RTL vs Golden Comparison")
    print("=" * 50)
    if len(sys.argv) < 2:
        print("Usage: python3 compare.py rtl_pixels.txt")
        sys.exit(1)
    print("\n--- Test 1: A(3,1) B(1,6) C(7,6) ---")
    golden_pixels, _ = rasterize(3, 1, 1, 6, 7, 6)
    rtl_pixels = parse_rtl_log(sys.argv[1])
    verify_against_rtl(golden_pixels, rtl_pixels)
    print("\n" + "=" * 50)
