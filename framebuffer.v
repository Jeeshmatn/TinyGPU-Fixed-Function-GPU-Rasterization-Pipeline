// Code your design here
// ============================================================
// Module  : framebuffer
// Project : TinyGPU
// Purpose : 64x64 dual-port SRAM
//           Write port — from rasterizer pipeline
//           Read port  — async, for testbench / AXI-Stream
// ============================================================

module framebuffer (
    input          clk,

    // Write port
    input          wr_en,
    input   [11:0] wr_addr,   // y*64 + x, max = 4095
    input   [7:0]  wr_data,   // RGB 3:3:2

    // Read port (async)
    input   [11:0] rd_addr,
    output  [7:0]  rd_data
);

    // 4096 x 8-bit memory array
    reg [7:0] mem [0:4095];

    // Synchronous write
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    // Asynchronous read
    assign rd_data = mem[rd_addr];

endmodule