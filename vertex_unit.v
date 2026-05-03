// ============================================================
// Module  : vertex_unit
// Project : TinyGPU
// Purpose : Clamps raw vertex coordinates to screen boundary
//           Ensures rasterizer always receives valid 0-63 range
//           Purely combinational — no FSM needed
// ============================================================

module vertex_unit (
    // Raw inputs (from register interface)
    input   [6:0] ax_in, ay_in,
    input   [6:0] bx_in, by_in,
    input   [6:0] cx_in, cy_in,

    // Clamped outputs (to rasterizer)
    output  [6:0] ax, ay,
    output  [6:0] bx, by,
    output  [6:0] cx, cy
);

    // Clamp each coordinate to max value 63
    // If input > 63, output = 63, else output = input
    // 7-bit input range is 0-127, screen is 0-63

    assign ax = (ax_in > 7'd63) ? 7'd63 : ax_in;
    assign ay = (ay_in > 7'd63) ? 7'd63 : ay_in;

    assign bx = (bx_in > 7'd63) ? 7'd63 : bx_in;
    assign by = (by_in > 7'd63) ? 7'd63 : by_in;

    assign cx = (cx_in > 7'd63) ? 7'd63 : cx_in;
    assign cy = (cy_in > 7'd63) ? 7'd63 : cy_in;

endmodule