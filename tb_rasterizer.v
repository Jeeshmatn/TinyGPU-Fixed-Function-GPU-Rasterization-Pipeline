module tb_rasterizer;

    reg        clk, rst, start;
    reg  [6:0] ax, ay, bx, by, cx, cy;

    wire       pixel_valid, done;
    wire [5:0] pixel_x, pixel_y;

    integer pixel_count;

    rasterizer dut (
        .clk(clk), .rst(rst),
        .ax(ax), .ay(ay),
        .bx(bx), .by(by),
        .cx(cx), .cy(cy),
        .start(start),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Print each valid pixel — format must match compare.py
    always @(posedge clk) begin
        if (pixel_valid)
            $display("PIXEL (%0d, %0d)", pixel_x, pixel_y);
    end

    // Count pixels
    always @(posedge clk) begin
        if (pixel_valid)
            pixel_count = pixel_count + 1;
    end

    task do_reset;
        begin
            rst=1; start=0;
            ax=0; ay=0; bx=0; by=0; cx=0; cy=0;
            repeat(3) @(posedge clk);
            rst=0;
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_rasterizer.vcd");
        $dumpvars(0, tb_rasterizer);

        pixel_count = 0;

        $display("=== Test 1: A(3,1) B(1,6) C(7,6) ===");
        do_reset;
        pixel_count = 0;
        ax=3; ay=1; bx=1; by=6; cx=7; cy=6;
        @(posedge clk);
        start=1; @(posedge clk);
        start=0;
        wait(done===1'b1);
        @(posedge clk);
        $display("Total pixels: %0d", pixel_count);

        $display("=== Test 3: Degenerate A(5,5) B(5,5) C(5,5) ===");
        do_reset;
        pixel_count = 0;
        ax=5; ay=5; bx=5; by=5; cx=5; cy=5;
        @(posedge clk);
        start=1; @(posedge clk);
        start=0;
        wait(done===1'b1);
        @(posedge clk);
        $display("Total pixels: %0d (expect 1)", pixel_count);

        $finish;
    end

endmodule