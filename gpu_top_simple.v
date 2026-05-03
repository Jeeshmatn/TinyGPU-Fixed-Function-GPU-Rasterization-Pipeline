// ============================================================
// Module  : gpu_top_simple
// Project : TinyGPU
// Purpose : Top level — parallel register interface
//           Use this for basic simulation and verification
// ============================================================

module gpu_top_simple (
    input          clk,
    input          rst,

    // Vertex inputs (direct wires)
    input   [6:0]  ax_in, ay_in,
    input   [6:0]  bx_in, by_in,
    input   [6:0]  cx_in, cy_in,

    // Color
    input   [7:0]  color_in,

    // Control
    input          start,
    output         done,

    // Framebuffer read port
    input   [11:0] fb_rd_addr,
    output  [7:0]  fb_rd_data
);

    // -- Wires between modules --------------------------------
    wire [6:0]  ax_c, ay_c;
    wire [6:0]  bx_c, by_c;
    wire [6:0]  cx_c, cy_c;

    wire        pixel_valid;
    wire [5:0]  pixel_x, pixel_y;

    wire        frag_valid;
    wire [5:0]  frag_x, frag_y;
    wire [7:0]  frag_color;

    wire        wr_en;
    wire [11:0] wr_addr;
    wire [7:0]  wr_data;

    // -- Module instantiations --------------------------------

    vertex_unit u_vertex (
        .ax_in (ax_in), .ay_in (ay_in),
        .bx_in (bx_in), .by_in (by_in),
        .cx_in (cx_in), .cy_in (cy_in),
        .ax    (ax_c),  .ay    (ay_c),
        .bx    (bx_c),  .by    (by_c),
        .cx    (cx_c),  .cy    (cy_c)
    );

    rasterizer u_rast (
        .clk         (clk),
        .rst         (rst),
        .ax          (ax_c),  .ay (ay_c),
        .bx          (bx_c),  .by (by_c),
        .cx          (cx_c),  .cy (cy_c),
        .start       (start),
        .pixel_valid (pixel_valid),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .done        (done)
    );

    fragment_unit u_frag (
        .pixel_valid (pixel_valid),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .color_reg   (color_in),
        .frag_valid  (frag_valid),
        .frag_x      (frag_x),
        .frag_y      (frag_y),
        .frag_color  (frag_color)
    );

    // Framebuffer write address = y*64 + x
    assign wr_en   = frag_valid;
    assign wr_addr = {frag_y, frag_x};  // y[5:0],x[5:0] = 12 bits
    assign wr_data = frag_color;

    framebuffer u_fb (
        .clk     (clk),
        .wr_en   (wr_en),
        .wr_addr (wr_addr),
        .wr_data (wr_data),
        .rd_addr (fb_rd_addr),
        .rd_data (fb_rd_data)
    );

endmodule