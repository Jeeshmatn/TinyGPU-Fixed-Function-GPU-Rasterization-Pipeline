WIDTH  = 64
HEIGHT = 64

def clamp(val, lo, hi):
    return max(lo, min(hi, val))

def edge_function(ax, ay, bx, by, px, py):
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)

def rasterize(ax, ay, bx, by, cx, cy, color=0xE3):
    ax = clamp(ax, 0, 63)
    ay = clamp(ay, 0, 63)
    bx = clamp(bx, 0, 63)
    by = clamp(by, 0, 63)
    cx = clamp(cx, 0, 63)
    cy = clamp(cy, 0, 63)
    x_min = min(ax, bx, cx)
    x_max = max(ax, bx, cx)
    y_min = min(ay, by, cy)
    y_max = max(ay, by, cy)
    framebuffer = [[0] * WIDTH for _ in range(HEIGHT)]
    pixels = []
    for y in range(y_min, y_max + 1):
        for x in range(x_min, x_max + 1):
            e1 = edge_function(ax, ay, bx, by, x, y)
            e2 = edge_function(bx, by, cx, cy, x, y)
            e3 = edge_function(cx, cy, ax, ay, x, y)
            if e1 <= 0 and e2 <= 0 and e3 <= 0:
                framebuffer[y][x] = color
                pixels.append((x, y, color))
    return pixels, framebuffer

def print_framebuffer(fb, x_min, x_max, y_min, y_max):
    print("  Framebuffer:")
    for y in range(y_min, y_max + 1):
        row = ""
        for x in range(x_min, x_max + 1):
            row += "# " if fb[y][x] != 0 else ". "
        print("  y=%2d: %s" % (y, row))

def verify_against_rtl(golden_pixels, rtl_pixel_log):
    golden_set = set((p[0], p[1]) for p in golden_pixels)
    rtl_set    = set((p[0], p[1]) for p in rtl_pixel_log)
    missing = golden_set - rtl_set
    extra   = rtl_set - golden_set
    print("  Golden pixel count : %d" % len(golden_set))
    print("  RTL pixel count    : %d" % len(rtl_set))
    if not missing and not extra:
        print("  RESULT: PASS - RTL matches golden reference exactly")
        return True
    else:
        print("  RESULT: FAIL")
        if missing:
            print("  Missing: %s" % sorted(missing))
        if extra:
            print("  Extra:   %s" % sorted(extra))
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("TinyGPU Golden Reference")
    print("=" * 50)
    print("\n--- Test 1: A(3,1) B(1,6) C(7,6) ---")
    pixels, fb = rasterize(3, 1, 1, 6, 7, 6, color=0xE3)
    print("  Total pixels: %d" % len(pixels))
    for p in pixels:
        print("  PIXEL (%2d, %2d)" % (p[0], p[1]))
    print_framebuffer(fb, 1, 7, 1, 6)
    print("\n--- Test 2: A(30,10) B(10,50) C(50,50) ---")
    pixels2, fb2 = rasterize(30, 10, 10, 50, 50, 50, color=0xFF)
    print("  Total pixels: %d" % len(pixels2))
    print("\n--- Test 3: Degenerate A(5,5) B(5,5) C(5,5) ---")
    pixels3, _ = rasterize(5, 5, 5, 5, 5, 5)
    print("  Total pixels: %d (expect 1)" % len(pixels3))
    print("\n" + "=" * 50)
    print("Golden reference complete")
    print("=" * 50)
