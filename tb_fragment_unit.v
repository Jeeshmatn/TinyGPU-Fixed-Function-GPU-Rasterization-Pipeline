module tb_fragment_unit;

    reg        pixel_valid;
    reg  [5:0] pixel_x, pixel_y;
    reg  [7:0] color_reg;

    wire       frag_valid;
    wire [5:0] frag_x, frag_y;
    wire [7:0] frag_color;

    fragment_unit dut (
        .pixel_valid (pixel_valid),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .color_reg   (color_reg),
        .frag_valid  (frag_valid),
        .frag_x      (frag_x),
        .frag_y      (frag_y),
        .frag_color  (frag_color)
    );

    initial begin
        $dumpfile("tb_fragment_unit.vcd");
        $dumpvars(0, tb_fragment_unit);

        // Test 1: valid pixel — color should pass through
        pixel_valid = 1;
        pixel_x     = 6'd10;
        pixel_y     = 6'd20;
        color_reg   = 8'hE3;  // some color
        #5;
        if (frag_valid === 1 && frag_x === 10 &&
            frag_y === 20 && frag_color === 8'hE3)
            $display("PASS: valid pixel, color=0xE3");
        else
            $display("FAIL: valid pixel test");

        // Test 2: invalid pixel — color should be 0
        pixel_valid = 0;
        pixel_x     = 6'd5;
        pixel_y     = 6'd5;
        color_reg   = 8'hE3;
        #5;
        if (frag_valid === 0 && frag_color === 8'h00)
            $display("PASS: invalid pixel, color=0x00");
        else
            $display("FAIL: invalid pixel test");

        // Test 3: different color
        pixel_valid = 1;
        pixel_x     = 6'd63;
        pixel_y     = 6'd63;
        color_reg   = 8'hFF;
        #5;
        if (frag_valid === 1 && frag_color === 8'hFF)
            $display("PASS: corner pixel, color=0xFF");
        else
            $display("FAIL: corner pixel test");

        $display("fragment_unit test complete");
        $finish;
    end

endmodule