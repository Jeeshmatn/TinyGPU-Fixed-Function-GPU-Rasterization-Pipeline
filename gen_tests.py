import random, sys

def clamp(val, lo, hi):
    return max(lo, min(hi, val))

def edge_function(ax, ay, bx, by, px, py):
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)

def rasterize(ax, ay, bx, by, cx, cy):
    ax = clamp(ax, 0, 63); ay = clamp(ay, 0, 63)
    bx = clamp(bx, 0, 63); by = clamp(by, 0, 63)
    cx = clamp(cx, 0, 63); cy = clamp(cy, 0, 63)
    x_min = min(ax, bx, cx); x_max = max(ax, bx, cx)
    y_min = min(ay, by, cy); y_max = max(ay, by, cy)
    pixels = []
    for y in range(y_min, y_max + 1):
        for x in range(x_min, x_max + 1):
            e1 = edge_function(ax, ay, bx, by, x, y)
            e2 = edge_function(bx, by, cx, cy, x, y)
            e3 = edge_function(cx, cy, ax, ay, x, y)
            if e1 <= 0 and e2 <= 0 and e3 <= 0:
                pixels.append((x, y))
    return pixels

def generate_tests():
    random.seed(42)
    tests = []
    for _ in range(20):
        tests.append(("small", random.randint(5,30), random.randint(5,30),
                      random.randint(5,30), random.randint(5,30),
                      random.randint(5,30), random.randint(5,30)))
    for _ in range(20):
        tests.append(("large", random.randint(0,63), random.randint(0,63),
                      random.randint(0,63), random.randint(0,63),
                      random.randint(0,63), random.randint(0,63)))
    for _ in range(20):
        ax = random.randint(10,50); ay = random.randint(5,20)
        by = random.randint(30,60); cy = by
        bx = random.randint(5,30);  cx = random.randint(30,60)
        tests.append(("flat_bot", ax, ay, bx, by, cx, cy))
    for _ in range(20):
        ax = random.randint(5,30);  ay = random.randint(5,20)
        bx = random.randint(30,60); by = ay
        cx = random.randint(10,50); cy = random.randint(30,60)
        tests.append(("flat_top", ax, ay, bx, by, cx, cy))
    tests.append(("degen",    5,  5,  5,  5,  5,  5))
    tests.append(("degen",   10, 10, 10, 10, 10, 10))
    tests.append(("boundary",  0,  0, 63,  0,  0, 63))
    tests.append(("boundary",  0,  0, 63, 63,  0, 63))
    tests.append(("boundary",  0,  0, 31, 63, 63,  0))
    for _ in range(15):
        v = random.randint(0, 63)
        tests.append(("edge", random.randint(0,63), v,
                      random.randint(0,63), v,
                      random.randint(0,63), random.randint(0,63)))
    return tests[:100]

def write_testbench(tests, filename):
    lines = []
    lines.append("module tb_rasterizer_100;")
    lines.append("    reg clk, rst, start;")
    lines.append("    reg [6:0] ax, ay, bx, by, cx, cy;")
    lines.append("    wire pixel_valid, done;")
    lines.append("    wire [5:0] pixel_x, pixel_y;")
    lines.append("    integer pixel_count, test_num;")
    lines.append("    rasterizer dut (")
    lines.append("        .clk(clk), .rst(rst),")
    lines.append("        .ax(ax), .ay(ay), .bx(bx), .by(by), .cx(cx), .cy(cy),")
    lines.append("        .start(start), .pixel_valid(pixel_valid),")
    lines.append("        .pixel_x(pixel_x), .pixel_y(pixel_y), .done(done));")
    lines.append("    initial clk = 0;")
    lines.append("    always #5 clk = ~clk;")
    lines.append("    always @(posedge clk) begin")
    lines.append("        if (pixel_valid) begin")
    lines.append("            pixel_count = pixel_count + 1;")
    lines.append('            $display("PIXEL_%0d (%0d, %0d)", test_num, pixel_x, pixel_y);')
    lines.append("        end")
    lines.append("    end")
    lines.append("    task do_reset;")
    lines.append("        begin")
    lines.append("            rst=1; start=0;")
    lines.append("            ax=0; ay=0; bx=0; by=0; cx=0; cy=0;")
    lines.append("            repeat(3) @(posedge clk);")
    lines.append("            rst=0; @(posedge clk);")
    lines.append("        end")
    lines.append("    endtask")
    lines.append("    initial begin")
    lines.append('        $dumpfile("tb_rasterizer_100.vcd");')
    lines.append("        $dumpvars(0, tb_rasterizer_100);")
    lines.append("        pixel_count = 0; test_num = 0;")
    for i, (cat, tax, tay, tbx, tby, tcx, tcy) in enumerate(tests):
        n = i + 1
        lines.append("        do_reset; pixel_count=0; test_num=%d;" % n)
        lines.append("        ax=%d; ay=%d; bx=%d; by=%d; cx=%d; cy=%d;" % (tax,tay,tbx,tby,tcx,tcy))
        lines.append("        @(posedge clk); start=1; @(posedge clk); start=0;")
        lines.append("        wait(done===1'b1); @(posedge clk);")
        lines.append('        $display("TEST_%d_DONE pixels=%%0d", pixel_count);' % n)
    lines.append('        $display("ALL_100_DONE");')
    lines.append("        $finish;")
    lines.append("    end")
    lines.append("endmodule")
    with open(filename, "w") as f:
        f.write("\n".join(lines))
    print("Written: %s" % filename)

def parse_rtl_log(filename):
    results = {}
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("PIXEL_"):
                try:
                    parts = line.split()
                    num = int(parts[0].replace("PIXEL_", ""))
                    coords = line.split("(")[1].replace(")", "").split(",")
                    x = int(coords[0].strip())
                    y = int(coords[1].strip())
                    if num not in results:
                        results[num] = set()
                    results[num].add((x, y))
                except:
                    pass
    return results

def run_comparison(tests, rtl_log_file):
    print("=" * 60)
    print("TinyGPU 100-Test Comparison")
    print("=" * 60)
    rtl_results = parse_rtl_log(rtl_log_file)
    pass_count = 0
    fail_count = 0
    fail_list = []
    for i, (cat, tax, tay, tbx, tby, tcx, tcy) in enumerate(tests):
        test_num = i + 1
        golden = set(rasterize(tax, tay, tbx, tby, tcx, tcy))
        rtl    = rtl_results.get(test_num, set())
        if golden == rtl:
            pass_count += 1
        else:
            fail_count += 1
            fail_list.append((test_num, cat, tax, tay, tbx, tby, tcx, tcy,
                               len(golden), len(rtl), golden - rtl, rtl - golden))
    print("Results:")
    print("  PASS: %d / 100" % pass_count)
    print("  FAIL: %d / 100" % fail_count)
    if fail_list:
        print("Failed tests:")
        for f in fail_list[:10]:
            print("  Test %d (%s): A(%d,%d) B(%d,%d) C(%d,%d) golden=%d rtl=%d" % (
                  f[0],f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9]))
            if f[10]: print("    Missing: %s" % sorted(f[10])[:5])
            if f[11]: print("    Extra:   %s" % sorted(f[11])[:5])
    else:
        print("  ALL 100 TESTS PASSED!")
    print("=" * 60)
    return fail_count == 0

if __name__ == "__main__":
    tests = generate_tests()
    if len(sys.argv) >= 2:
        run_comparison(tests, sys.argv[1])
    else:
        write_testbench(tests, "tb_rasterizer_100.v")
        print("Generated %d test cases" % len(tests))
        print("Run: make run_100")
import random, sys

def clamp(val, lo, hi):
    return max(lo, min(hi, val))

def edge_function(ax, ay, bx, by, px, py):
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)

def rasterize(ax, ay, bx, by, cx, cy):
    ax = clamp(ax, 0, 63); ay = clamp(ay, 0, 63)
    bx = clamp(bx, 0, 63); by = clamp(by, 0, 63)
    cx = clamp(cx, 0, 63); cy = clamp(cy, 0, 63)
    x_min = min(ax, bx, cx); x_max = max(ax, bx, cx)
    y_min = min(ay, by, cy); y_max = max(ay, by, cy)
    pixels = []
    for y in range(y_min, y_max + 1):
        for x in range(x_min, x_max + 1):
            e1 = edge_function(ax, ay, bx, by, x, y)
            e2 = edge_function(bx, by, cx, cy, x, y)
            e3 = edge_function(cx, cy, ax, ay, x, y)
            if e1 <= 0 and e2 <= 0 and e3 <= 0:
                pixels.append((x, y))
    return pixels

def generate_tests():
    random.seed(42)
    tests = []
    for _ in range(20):
        tests.append(("small", random.randint(5,30), random.randint(5,30),
                      random.randint(5,30), random.randint(5,30),
                      random.randint(5,30), random.randint(5,30)))
    for _ in range(20):
        tests.append(("large", random.randint(0,63), random.randint(0,63),
                      random.randint(0,63), random.randint(0,63),
                      random.randint(0,63), random.randint(0,63)))
    for _ in range(20):
        ax = random.randint(10,50); ay = random.randint(5,20)
        by = random.randint(30,60); cy = by
        bx = random.randint(5,30);  cx = random.randint(30,60)
        tests.append(("flat_bot", ax, ay, bx, by, cx, cy))
    for _ in range(20):
        ax = random.randint(5,30);  ay = random.randint(5,20)
        bx = random.randint(30,60); by = ay
        cx = random.randint(10,50); cy = random.randint(30,60)
        tests.append(("flat_top", ax, ay, bx, by, cx, cy))
    tests.append(("degen",    5,  5,  5,  5,  5,  5))
    tests.append(("degen",   10, 10, 10, 10, 10, 10))
    tests.append(("boundary",  0,  0, 63,  0,  0, 63))
    tests.append(("boundary",  0,  0, 63, 63,  0, 63))
    tests.append(("boundary",  0,  0, 31, 63, 63,  0))
    for _ in range(15):
        v = random.randint(0, 63)
        tests.append(("edge", random.randint(0,63), v,
                      random.randint(0,63), v,
                      random.randint(0,63), random.randint(0,63)))
    return tests[:100]

def write_testbench(tests, filename):
    lines = []
    lines.append("module tb_rasterizer_100;")
    lines.append("    reg clk, rst, start;")
    lines.append("    reg [6:0] ax, ay, bx, by, cx, cy;")
    lines.append("    wire pixel_valid, done;")
    lines.append("    wire [5:0] pixel_x, pixel_y;")
    lines.append("    integer pixel_count, test_num;")
    lines.append("    rasterizer dut (")
    lines.append("        .clk(clk), .rst(rst),")
    lines.append("        .ax(ax), .ay(ay), .bx(bx), .by(by), .cx(cx), .cy(cy),")
    lines.append("        .start(start), .pixel_valid(pixel_valid),")
    lines.append("        .pixel_x(pixel_x), .pixel_y(pixel_y), .done(done));")
    lines.append("    initial clk = 0;")
    lines.append("    always #5 clk = ~clk;")
    lines.append("    always @(posedge clk) begin")
    lines.append("        if (pixel_valid) begin")
    lines.append("            pixel_count = pixel_count + 1;")
    lines.append('            $display("PIXEL_%0d (%0d, %0d)", test_num, pixel_x, pixel_y);')
    lines.append("        end")
    lines.append("    end")
    lines.append("    task do_reset;")
    lines.append("        begin")
    lines.append("            rst=1; start=0;")
    lines.append("            ax=0; ay=0; bx=0; by=0; cx=0; cy=0;")
    lines.append("            repeat(3) @(posedge clk);")
    lines.append("            rst=0; @(posedge clk);")
    lines.append("        end")
    lines.append("    endtask")
    lines.append("    initial begin")
    lines.append('        $dumpfile("tb_rasterizer_100.vcd");')
    lines.append("        $dumpvars(0, tb_rasterizer_100);")
    lines.append("        pixel_count = 0; test_num = 0;")
    for i, (cat, tax, tay, tbx, tby, tcx, tcy) in enumerate(tests):
        n = i + 1
        lines.append("        do_reset; pixel_count=0; test_num=%d;" % n)
        lines.append("        ax=%d; ay=%d; bx=%d; by=%d; cx=%d; cy=%d;" % (tax,tay,tbx,tby,tcx,tcy))
        lines.append("        @(posedge clk); start=1; @(posedge clk); start=0;")
        lines.append("        wait(done===1'b1); @(posedge clk);")
        lines.append('        $display("TEST_%d_DONE pixels=%%0d", pixel_count);' % n)
    lines.append('        $display("ALL_100_DONE");')
    lines.append("        $finish;")
    lines.append("    end")
    lines.append("endmodule")
    with open(filename, "w") as f:
        f.write("\n".join(lines))
    print("Written: %s" % filename)

def parse_rtl_log(filename):
    results = {}
    with open(filename, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("PIXEL_"):
                try:
                    parts = line.split()
                    num = int(parts[0].replace("PIXEL_", ""))
                    coords = line.split("(")[1].replace(")", "").split(",")
                    x = int(coords[0].strip())
                    y = int(coords[1].strip())
                    if num not in results:
                        results[num] = set()
                    results[num].add((x, y))
                except:
                    pass
    return results

def run_comparison(tests, rtl_log_file):
    print("=" * 60)
    print("TinyGPU 100-Test Comparison")
    print("=" * 60)
    rtl_results = parse_rtl_log(rtl_log_file)
    pass_count = 0
    fail_count = 0
    fail_list = []
    for i, (cat, tax, tay, tbx, tby, tcx, tcy) in enumerate(tests):
        test_num = i + 1
        golden = set(rasterize(tax, tay, tbx, tby, tcx, tcy))
        rtl    = rtl_results.get(test_num, set())
        if golden == rtl:
            pass_count += 1
        else:
            fail_count += 1
            fail_list.append((test_num, cat, tax, tay, tbx, tby, tcx, tcy,
                               len(golden), len(rtl), golden - rtl, rtl - golden))
    print("Results:")
    print("  PASS: %d / 100" % pass_count)
    print("  FAIL: %d / 100" % fail_count)
    if fail_list:
        print("Failed tests:")
        for f in fail_list[:10]:
            print("  Test %d (%s): A(%d,%d) B(%d,%d) C(%d,%d) golden=%d rtl=%d" % (
                  f[0],f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9]))
            if f[10]: print("    Missing: %s" % sorted(f[10])[:5])
            if f[11]: print("    Extra:   %s" % sorted(f[11])[:5])
    else:
        print("  ALL 100 TESTS PASSED!")
    print("=" * 60)
    return fail_count == 0

if __name__ == "__main__":
    tests = generate_tests()
    if len(sys.argv) >= 2:
        run_comparison(tests, sys.argv[1])
    else:
        write_testbench(tests, "tb_rasterizer_100.v")
        print("Generated %d test cases" % len(tests))
        print("Run: make run_100")
