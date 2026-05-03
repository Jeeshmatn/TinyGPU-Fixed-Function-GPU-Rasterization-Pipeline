// Code your testbench here
// or browse Examples
module tb_framebuffer;

    reg        clk;
    reg        wr_en;
    reg [11:0] wr_addr;
    reg [7:0]  wr_data;
    reg [11:0] rd_addr;
    wire [7:0] rd_data;

    framebuffer dut (
        .clk     (clk),
        .wr_en   (wr_en),
        .wr_addr (wr_addr),
        .wr_data (wr_data),
        .rd_addr (rd_addr),
        .rd_data (rd_data)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    initial begin
        $dumpfile("tb_framebuffer.vcd");
        $dumpvars(0, tb_framebuffer);

        wr_en = 0; wr_addr = 0; wr_data = 0; rd_addr = 0;
        @(posedge clk);

        // Test 1: write pixel at (3, 2) ? addr = 2*64+3 = 131
        wr_en = 1;
        wr_addr = 12'd131;
        wr_data = 8'hAB;
        @(posedge clk);
        wr_en = 0;

        // Read it back immediately
        rd_addr = 12'd131;
        #1;  // small delay for async read to settle
        if (rd_data === 8'hAB)
            $display("PASS: pixel(3,2) = 0xAB");
        else
            $display("FAIL: expected 0xAB got %0h", rd_data);

        // Test 2: write pixel at (63, 63) ? addr = 63*64+63 = 4095
        wr_en = 1;
        wr_addr = 12'd4095;
        wr_data = 8'hFF;
        @(posedge clk);
        wr_en = 0;
        rd_addr = 12'd4095;
        #1;
        if (rd_data === 8'hFF)
            $display("PASS: pixel(63,63) = 0xFF");
        else
            $display("FAIL: expected 0xFF got %0h", rd_data);

        // Test 3: address 0
        wr_en = 1;
        wr_addr = 12'd0;
        wr_data = 8'h55;
        @(posedge clk);
        wr_en = 0;
        rd_addr = 12'd0;
        #1;
        if (rd_data === 8'h55)
            $display("PASS: pixel(0,0) = 0x55");
        else
            $display("FAIL: expected 0x55 got %0h", rd_data);

        $display("framebuffer test complete");
        $finish;
    end

endmodule