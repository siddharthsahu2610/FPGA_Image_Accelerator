`timescale 1ns/1ps

module line_buffer #(
    parameter PIXEL_WIDTH = 8,
    parameter IMG_WIDTH   = 640
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   pixel_valid,
    input  wire [PIXEL_WIDTH-1:0] pixel_in,

    output wire [PIXEL_WIDTH-1:0] row0_out, // Oldest row (N-2)
    output wire [PIXEL_WIDTH-1:0] row1_out, // Middle row (N-1)
    output wire [PIXEL_WIDTH-1:0] row2_out  // Current row (N)
);

    // Modulo Column Address Pointer
    // $clog2(640) = 10 bits address space
    localparam ADDR_WIDTH = $clog2(IMG_WIDTH);
    reg [ADDR_WIDTH-1:0] col_ptr;

    // Dual BRAM Arrays
    reg [PIXEL_WIDTH-1:0] bram0 [0:IMG_WIDTH-1];
    reg [PIXEL_WIDTH-1:0] bram1 [0:IMG_WIDTH-1];

    // Internal Read Buffers
    reg [PIXEL_WIDTH-1:0] rdata0;
    reg [PIXEL_WIDTH-1:0] rdata1;

    // Column Pointer Counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            col_ptr <= {ADDR_WIDTH{1'b0}};
        end else if (pixel_valid) begin
            if (col_ptr == IMG_WIDTH - 1)
                col_ptr <= {ADDR_WIDTH{1'b0}};
            else
                col_ptr <= col_ptr + 1'b1;
        end
    end

    // Simple Dual-Port BRAM Access (Infers Block RAM on Artix-7)
    always @(posedge clk) begin
        if (pixel_valid) begin
            // Read old pixels first
            rdata0 <= bram0[col_ptr];
            rdata1 <= bram1[col_ptr];

            // Write incoming pixels into line buffers
            bram0[col_ptr] <= bram1[col_ptr]; // Line 0 gets pixel from Line 1
            bram1[col_ptr] <= pixel_in;      // Line 1 gets incoming Pixel
        end
    end

    // Drive Output Rows
    assign row0_out = rdata0;
    assign row1_out = rdata1;
    assign row2_out = pixel_in;

endmodule
