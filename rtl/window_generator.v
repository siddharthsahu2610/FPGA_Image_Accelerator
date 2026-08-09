`timescale 1ns/1ps

module window_generator #(
    parameter integer WIDTH  = 4,
    parameter integer HEIGHT = 6,
    parameter integer PDATA  = 8
)(
    input  wire             clk,
    input  wire             rst,

    input  wire             pixel_valid,
    input  wire [PDATA-1:0] pixel_in,

    output reg              window_valid,

    output reg [PDATA-1:0]  w00,
    output reg [PDATA-1:0]  w01,
    output reg [PDATA-1:0]  w02,

    output reg [PDATA-1:0]  w10,
    output reg [PDATA-1:0]  w11,
    output reg [PDATA-1:0]  w12,

    output reg [PDATA-1:0]  w20,
    output reg [PDATA-1:0]  w21,
    output reg [PDATA-1:0]  w22
);

    //============================================================
    // Counter widths
    //============================================================

    localparam integer COL_W = (WIDTH <= 1)  ? 1 : $clog2(WIDTH);
    localparam integer ROW_W = (HEIGHT <= 1) ? 1 : $clog2(HEIGHT);

    // Explicitly sized terminal values.
    // SystemVerilog sized cast prevents Verilator width warnings.
    localparam logic [COL_W-1:0] COL_LAST = COL_W'(WIDTH - 1);
    localparam logic [ROW_W-1:0] ROW_LAST = ROW_W'(HEIGHT - 1);

    //============================================================
    // Two line buffers
    //============================================================

    reg [PDATA-1:0] line_buf1 [0:WIDTH-1];
    reg [PDATA-1:0] line_buf2 [0:WIDTH-1];

    //============================================================
    // Image coordinates
    //============================================================

    reg [COL_W-1:0] col_ptr;
    reg [ROW_W-1:0] row_count;

    //============================================================
    // Line-buffer read values
    //============================================================

    wire [PDATA-1:0] lb1_out;
    wire [PDATA-1:0] lb2_out;

    assign lb1_out = line_buf1[col_ptr];
    assign lb2_out = line_buf2[col_ptr];

    //============================================================
    // Line buffer update
    //
    // line_buf1 receives current row.
    // line_buf2 receives previous row.
    //============================================================

    always @(posedge clk) begin

        if (pixel_valid) begin

            line_buf1[col_ptr] <= pixel_in;
            line_buf2[col_ptr] <= lb1_out;

        end

    end

    //============================================================
    // Row / column tracking
    //============================================================

    always @(posedge clk) begin

        if (rst) begin

            col_ptr   <= '0;
            row_count <= '0;

        end
        else if (pixel_valid) begin

            if (col_ptr == COL_LAST) begin

                col_ptr <= '0;

                if (row_count == ROW_LAST)
                    row_count <= '0;
                else
                    row_count <= row_count + 1'b1;

            end
            else begin

                col_ptr <= col_ptr + 1'b1;

            end

        end

    end

    //============================================================
    // 3x3 shift registers
    //
    //       w00 w01 w02
    //       w10 w11 w12
    //       w20 w21 w22
    //
    // Top    = two rows behind
    // Middle = previous row
    // Bottom = current row
    //============================================================

    always @(posedge clk) begin

        if (rst) begin

            w00 <= '0;
            w01 <= '0;
            w02 <= '0;

            w10 <= '0;
            w11 <= '0;
            w12 <= '0;

            w20 <= '0;
            w21 <= '0;
            w22 <= '0;

        end
        else if (pixel_valid) begin

            // Two rows ago
            w00 <= w01;
            w01 <= w02;
            w02 <= lb2_out;

            // Previous row
            w10 <= w11;
            w11 <= w12;
            w12 <= lb1_out;

            // Current row
            w20 <= w21;
            w21 <= w22;
            w22 <= pixel_in;

        end

    end

    //============================================================
    // Window valid
    //
    // Current pixel completes a 3x3 window when:
    //
    //     row >= 2
    //     col >= 2
    //
    // There is deliberately NO persistent "primed" flag.
    //============================================================

    always @(posedge clk) begin

        if (rst) begin

            window_valid <= 1'b0;

        end
        else begin

            window_valid <= pixel_valid &&
                            (row_count >= 2) &&
                            (col_ptr >= 2);

        end

    end

endmodule

