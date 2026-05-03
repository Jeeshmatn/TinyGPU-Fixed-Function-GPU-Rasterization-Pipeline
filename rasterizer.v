
module rasterizer (
    input          clk,
    input          rst,
    input   [6:0]  ax, ay,
    input   [6:0]  bx, by,
    input   [6:0]  cx, cy,
    input          start,
    output reg         pixel_valid,
    output reg  [5:0]  pixel_x,
    output reg  [5:0]  pixel_y,
    output reg         done
);

    localparam IDLE        = 4'd0;
    localparam INIT        = 4'd1;
    localparam INIT_WAIT   = 4'd2;
    localparam INIT_WAIT2  = 4'd3;
    localparam SCAN_ROW    = 4'd4;
    localparam TEST        = 4'd5;
    localparam WRITE_PIXEL = 4'd6;
    localparam NEXT_COL    = 4'd7;
    localparam NEXT_ROW    = 4'd8;
    localparam DONE_ST     = 4'd9;

    reg [3:0] state, next_state;

    reg [6:0] x_min, x_max, y_min, y_max;
    reg [6:0] cur_x, cur_y;

    wire [6:0] xmin_w;
    wire [6:0] xmax_w;
    wire [6:0] ymin_w;
    wire [6:0] ymax_w;

    assign xmin_w = (ax<=bx && ax<=cx) ? ax : (bx<=cx ? bx : cx);
    assign xmax_w = (ax>=bx && ax>=cx) ? ax : (bx>=cx ? bx : cx);
    assign ymin_w = (ay<=by && ay<=cy) ? ay : (by<=cy ? by : cy);
    assign ymax_w = (ay>=by && ay>=cy) ? ay : (by>=cy ? by : cy);

    wire signed [7:0] bx_ax;
    wire signed [7:0] by_ay;
    wire signed [7:0] cx_bx;
    wire signed [7:0] cy_by;
    wire signed [7:0] ax_cx;
    wire signed [7:0] ay_cy;

    assign bx_ax = $signed({1'b0,bx}) - $signed({1'b0,ax});
    assign by_ay = $signed({1'b0,by}) - $signed({1'b0,ay});
    assign cx_bx = $signed({1'b0,cx}) - $signed({1'b0,bx});
    assign cy_by = $signed({1'b0,cy}) - $signed({1'b0,by});
    assign ax_cx = $signed({1'b0,ax}) - $signed({1'b0,cx});
    assign ay_cy = $signed({1'b0,ay}) - $signed({1'b0,cy});

    wire signed [14:0] E1_comb;
    wire signed [14:0] E2_comb;
    wire signed [14:0] E3_comb;

    assign E1_comb = bx_ax * ($signed({1'b0,cur_y}) - $signed({1'b0,ay}))
                   - by_ay * ($signed({1'b0,cur_x}) - $signed({1'b0,ax}));

    assign E2_comb = cx_bx * ($signed({1'b0,cur_y}) - $signed({1'b0,by}))
                   - cy_by * ($signed({1'b0,cur_x}) - $signed({1'b0,bx}));

    assign E3_comb = ax_cx * ($signed({1'b0,cur_y}) - $signed({1'b0,cy}))
                   - ay_cy * ($signed({1'b0,cur_x}) - $signed({1'b0,cx}));

    wire px_inside;
assign px_inside = ((E1_comb[14] == 1'b1) || (E1_comb == 15'd0)) &&
                   ((E2_comb[14] == 1'b1) || (E2_comb == 15'd0)) &&
                   ((E3_comb[14] == 1'b1) || (E3_comb == 15'd0));

    // Block 1: state register
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    // Block 2: datapath
    always @(posedge clk) begin
        if (rst) begin
            pixel_valid <= 1'b0;
            done        <= 1'b0;
            pixel_x     <= 6'd0;
            pixel_y     <= 6'd0;
            x_min <= 7'd0; x_max <= 7'd0;
            y_min <= 7'd0; y_max <= 7'd0;
            cur_x <= 7'd0; cur_y <= 7'd0;
        end
        else begin
            pixel_valid <= 1'b0;
            done        <= 1'b0;

            case (state)

                IDLE: begin
                end

                // Cycle 1: register bounding box from input wires
                INIT: begin
                    x_min <= xmin_w;
                    x_max <= xmax_w;
                    y_min <= ymin_w;
                    y_max <= ymax_w;
                end

                // Cycle 2: x_min/y_min registers now valid
                // write cur_x/cur_y from registered values
                INIT_WAIT: begin
                    cur_x <= x_min;
                    cur_y <= y_min;
                end

                // Cycle 3: cur_x/cur_y now valid
                // E1_comb/E2_comb/E3_comb now correct
                // nothing to write — just let combinational settle
                INIT_WAIT2: begin
                end

                // Reset cur_x to x_min at start of each row
                SCAN_ROW: begin
                    cur_x <= x_min;
                end

                TEST: begin
                end

                WRITE_PIXEL: begin
                    pixel_valid <= 1'b1;
                    pixel_x     <= cur_x[5:0];
                    pixel_y     <= cur_y[5:0];
                end

                NEXT_COL: begin
                    cur_x <= cur_x + 7'd1;
                end

                NEXT_ROW: begin
                    cur_y <= cur_y + 7'd1;
                end

                DONE_ST: begin
                    done <= 1'b1;
                end

                default: begin
                end

            endcase
        end
    end

    // Block 3: next state
    always @(*) begin
        next_state = state;

        case (state)
            IDLE:       next_state = start ? INIT : IDLE;

            // INIT registers x_min/y_min — wait for them
            INIT:       next_state = INIT_WAIT;

            // INIT_WAIT writes cur_x/cur_y — wait for them
            INIT_WAIT:  next_state = INIT_WAIT2;

            // INIT_WAIT2 does nothing — cur_x/cur_y now valid
            // E_comb now correct — go test first pixel
            INIT_WAIT2: next_state = TEST;

            TEST: begin
                if (px_inside)
                    next_state = WRITE_PIXEL;
                else begin
                    if (cur_x < x_max)
                        next_state = NEXT_COL;
                    else if (cur_y < y_max)
                        next_state = NEXT_ROW;
                    else
                        next_state = DONE_ST;
                end
            end

            WRITE_PIXEL: begin
                if (cur_x < x_max)
                    next_state = NEXT_COL;
                else if (cur_y < y_max)
                    next_state = NEXT_ROW;
                else
                    next_state = DONE_ST;
            end

            // cur_x incremented — wait one cycle then test
            NEXT_COL:  next_state = TEST;

            // cur_y incremented — reset cur_x then test
            NEXT_ROW:  next_state = SCAN_ROW;

            // cur_x reset to x_min — wait one cycle then test
            SCAN_ROW:  next_state = TEST;

            DONE_ST:   next_state = IDLE;
            default:   next_state = IDLE;
        endcase
    end

endmodule
