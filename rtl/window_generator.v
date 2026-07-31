`timescale 1ns/1ps

module window_generator #(
    parameter WIDTH  = 4,
    parameter HEIGHT = 6,  // Total rows per frame (24 pixels = 6 rows x 4 cols)
    parameter PDATA  = 8
)(
    input                   clk,
    input                   rst,

    input                   pixel_valid,
    input  [PDATA-1:0]      pixel_in,

    output reg              window_valid,

    output reg [PDATA-1:0]  w00, w01, w02,
    output reg [PDATA-1:0]  w10, w11, w12,
    output reg [PDATA-1:0]  w20, w21, w22
);

    //------------------------------------------------------------
    // Line Buffers
    //------------------------------------------------------------
    reg [PDATA-1:0] line_buf1 [0:WIDTH-1];
    reg [PDATA-1:0] line_buf2 [0:WIDTH-1];

    reg [$clog2(WIDTH)-1:0]  col_ptr;
    reg [$clog2(HEIGHT)-1:0] row_count;
    reg                      buffer_primed; // Latched once initial 2 rows + 2 cols arrive

    wire [PDATA-1:0] lb1_out = line_buf1[col_ptr];
    wire [PDATA-1:0] lb2_out = line_buf2[col_ptr];

    // BRAM / Shift Writes
    always @(posedge clk) begin
        if (pixel_valid) begin
            line_buf1[col_ptr] <= pixel_in;
            line_buf2[col_ptr] <= lb1_out;
        end
    end

    //------------------------------------------------------------
    // Coordinate Tracking (Real Image Row & Column Counters)
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            col_ptr       <= 0;
            row_count     <= 0;
            buffer_primed <= 1'b0;
        end else if (pixel_valid) begin
            
            // Track when the initial 3x3 window is primed (Row 2, Col 2)
            if (row_count >= 2 && col_ptr >= 2) begin
                buffer_primed <= 1'b1;
            end

            // Column and Row Counter Logic
            if (col_ptr == ($clog2(WIDTH))'(WIDTH - 1)) begin
                col_ptr <= 0;
                
                // Row increment / Frame rollover
                if (row_count == ($clog2(HEIGHT))'(HEIGHT - 1)) begin
                    row_count     <= 0;      // New frame starting!
                    buffer_primed <= 1'b0;   // Reset priming for next frame
                end else begin
                    row_count <= row_count + 1'b1;
                end

            end else begin
                col_ptr <= col_ptr + 1'b1;
            end
        end
    end

    //------------------------------------------------------------
    // Continuous 3x3 Window Shift Registers
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            w00 <= 0; w01 <= 0; w02 <= 0;
            w10 <= 0; w11 <= 0; w12 <= 0;
            w20 <= 0; w21 <= 0; w22 <= 0;
        end else if (pixel_valid) begin
            {w20, w21, w22} <= {w21, w22, pixel_in};
            {w10, w11, w12} <= {w11, w12, lb1_out};
            {w00, w01, w02} <= {w01, w02, lb2_out};
        end
    end

    //------------------------------------------------------------
    // Window Valid Output Gating
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            window_valid <= 1'b0;
        end else begin
            window_valid <= pixel_valid && (buffer_primed || (row_count >= 2 && col_ptr >= 2));
        end
    end

endmodule
