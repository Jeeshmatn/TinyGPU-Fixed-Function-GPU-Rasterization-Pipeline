// ============================================================
// Module  : fragment_unit
// Project : TinyGPU
// Purpose : Takes valid pixel coordinates from rasterizer
//           Outputs flat RGB color for that pixel
//           (Barycentric shading is a planned enhancement)
// ============================================================

module fragment_unit (
    // From rasterizer
    input         pixel_valid,
    input   [5:0] pixel_x,
    input   [5:0] pixel_y,

    // Programmable flat color (RGB 3:3:2)
    input   [7:0] color_reg,

    // To framebuffer
    output        frag_valid,
    output  [5:0] frag_x,
    output  [5:0] frag_y,
    output  [7:0] frag_color
);

    // Pass pixel coordinates through unchanged
    assign frag_valid = pixel_valid;
    assign frag_x     = pixel_x;
    assign frag_y     = pixel_y;

    // Output flat color only when pixel is valid
    assign frag_color = pixel_valid ? color_reg : 8'h00;

endmodule