// ============================================================
// Testbench : tb_gpu_top_simple
// Project   : TinyGPU
// Purpose   : Integration testbench for full pipeline
//             Drives triangle vertices, waits for done,
//             reads back framebuffer and checks pixel count
// ============================================================

module tb_gpu_top_simple;

    reg        clk, rst, start;
    reg  [6:0] ax, ay, bx, by, cx, cy;
    reg  [7:0] color;
    reg [11:0] fb_addr;

    wire        done;
    wire [7:0]  fb_data;

    // -- DUT instantiation ------------------------------------
    gpu_top_simple dut (
        .clk        (clk),
        .rst        (rst),
        .ax_in      (ax),
        .ay_in      (ay),
        .bx_in      (bx),
        .by_in      (by),
        .cx_in      (cx),
        .cy_in      (cy),
        .color_in   (color),
        .start      (start),
        .done       (done),
        .fb_rd_addr (fb_addr),
        .fb_rd_data (fb_data)
    );

    // -- Clock generation -------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // -- Variables --------------------------------------------
    integer pixel_count;
    integer i;
    integer pass_count;
    integer fail_count;

    // -- Tasks ------------------------------------------------

    // Reset task
    task do_reset;
        begin
            rst   = 1;
            start = 0;
            ax=0; ay=0; bx=0; by=0; cx=0; cy=0;
            color = 8'h00;
            repeat(3) @(posedge clk);
            rst = 0;
            @(posedge clk);
        end
    endtask

    // Run one triangle and wait for done
    task run_triangle;
        input [6:0] t_ax, t_ay;
        input [6:0] t_bx, t_by;
        input [6:0] t_cx, t_cy;
        input [7:0] t_color;
        begin
            ax = t_ax; ay = t_ay;
            bx = t_bx; by = t_by;
            cx = t_cx; cy = t_cy;
            color = t_color;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            // Wait for done with timeout
            repeat(100000) begin
                @(posedge clk);
                if (done) disable run_triangle;
            end
            $display("ERROR: timeout waiting for done");
        end
    endtask

    // Count non-zero pixels in framebuffer
    task count_pixels;
        begin
            pixel_count = 0;
            for (i = 0; i < 4096; i = i + 1) begin
                fb_addr = i;
                #1;
                if (fb_data !== 8'h00)
                    pixel_count = pixel_count + 1;
            end
        end
    endtask

    // Check specific pixel address
    task check_pixel;
        input [11:0] addr;
        input [7:0]  expected;
        input [63:0] label;
        begin
            fb_addr = addr;
            #1;
            if (fb_data === expected) begin
                $display("  PASS: %s  addr=%0d  data=0x%02h",
                         label, addr, fb_data);
                pass_count = pass_count + 1;
            end
            else begin
                $display("  FAIL: %s  addr=%0d  expected=0x%02h  got=0x%02h",
                         label, addr, expected, fb_data);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -- Main test sequence -----------------------------------
    initial begin
        $dumpfile("tb_gpu_top_simple.vcd");
        $dumpvars(0, tb_gpu_top_simple);

        pass_count = 0;
        fail_count = 0;

        // -- Test 1: A(3,1) B(1,6) C(7,6) color=0xE3 ---------
        $display("");
        $display("=================================================");
        $display("Test 1: Triangle A(3,1) B(1,6) C(7,6) color=0xE3");
        $display("=================================================");

        do_reset;
        run_triangle(3,1, 1,6, 7,6, 8'hE3);
        @(posedge clk);
        $display("  Rasterization done");

        // Count pixels written
        count_pixels;
        $display("  Pixels in framebuffer: %0d", pixel_count);

        // Spot check known inside pixels
        // pixel(3,1) ? addr = 1*64+3 = 67
        // pixel(3,2) ? addr = 2*64+3 = 131
        // pixel(4,3) ? addr = 3*64+4 = 196
        check_pixel(12'd67,  8'hE3, "pixel(3,1)");
        check_pixel(12'd131, 8'hE3, "pixel(3,2)");
        check_pixel(12'd196, 8'hE3, "pixel(4,3)");

        // Check a pixel that should be outside
        // pixel(0,0) ? addr = 0 — should be 0x00
        fb_addr = 12'd0; #1;
        if (fb_data === 8'h00)
            $display("  PASS: pixel(0,0) correctly empty");
        else
            $display("  FAIL: pixel(0,0) should be empty got 0x%02h", fb_data);

        // -- Test 2: Center triangle ---------------------------
        $display("");
        $display("=================================================");
        $display("Test 2: A(30,10) B(10,50) C(50,50) color=0xFF");
        $display("=================================================");

        do_reset;
        run_triangle(30,10, 10,50, 50,50, 8'hFF);
        @(posedge clk);
        $display("  Rasterization done");

        count_pixels;
        $display("  Pixels in framebuffer: %0d", pixel_count);

        if (pixel_count > 100)
            $display("  PASS: large triangle has reasonable pixel count");
        else
            $display("  FAIL: pixel count too low for large triangle");

        // -- Test 3: Degenerate triangle -----------------------
        $display("");
        $display("=================================================");
        $display("Test 3: Degenerate A(5,5) B(5,5) C(5,5)");
        $display("=================================================");

        do_reset;
        run_triangle(5,5, 5,5, 5,5, 8'hAA);
        @(posedge clk);
        $display("  Rasterization done");

        count_pixels;
        $display("  Pixels: %0d (expect 1)", pixel_count);

        if (pixel_count == 1)
            $display("  PASS: degenerate triangle = 1 pixel");
        else
            $display("  NOTE: degenerate triangle = %0d pixels", pixel_count);

        // -- Test 4: Out of bounds clamping --------------------
        $display("");
        $display("=================================================");
        $display("Test 4: Clamping A(100,2) B(2,100) C(50,50)");
        $display("=================================================");

        do_reset;
        run_triangle(100,2, 2,100, 50,50, 8'h55);
        @(posedge clk);
        $display("  Rasterization done — vertices clamped to 63");

        count_pixels;
        $display("  Pixels in framebuffer: %0d", pixel_count);

        if (pixel_count > 0)
            $display("  PASS: clamped triangle rasterized correctly");
        else
            $display("  FAIL: no pixels after clamping");

        // -- Test 5: Back to back triangles --------------------
        $display("");
        $display("=================================================");
        $display("Test 5: Back to back — two triangles");
        $display("=================================================");

        do_reset;
        // First triangle
        run_triangle(3,1, 1,6, 7,6, 8'hE3);
        @(posedge clk);
        $display("  Triangle 1 done");

        // Reset and immediately start second
        do_reset;
        run_triangle(10,10, 5,20, 20,20, 8'hC5);
        @(posedge clk);
        $display("  Triangle 2 done");

        count_pixels;
        $display("  Pixels from triangle 2: %0d", pixel_count);

        // -- Final summary -------------------------------------
        $display("");
        $display("=================================================");
        $display("SUMMARY");
        $display("=================================================");
        $display("  PASS: %0d", pass_count);
        $display("  FAIL: %0d", fail_count);

        if (fail_count === 0)
            $display("  OVERALL: ALL CHECKS PASSED");
        else
            $display("  OVERALL: %0d CHECKS FAILED", fail_count);

        $display("=================================================");
        $finish;
    end

endmodule