`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Module : image_memory
// Description:
//   Synchronous ROM used to store grayscale image pixels.
//   Pixel data is initialized from a hexadecimal memory file.
//
// Features:
//   - FPGA BRAM inference
//   - Verilator compatible
//   - 1-cycle synchronous read latency
//////////////////////////////////////////////////////////////////////////////////

module image_memory #(
    parameter IMAGE_SIZE = 16384,
    parameter ADDR_WIDTH = 14,
    parameter DATA_WIDTH = 8,
    parameter MEM_FILE = "images/test_vectors/image.mem"
)(
    input  wire                     clk,
    input  wire [ADDR_WIDTH-1:0]    address,
    output reg  [DATA_WIDTH-1:0]    pixel_out
);

    //------------------------------------------------------------
    // Memory Array
    //------------------------------------------------------------

    reg [DATA_WIDTH-1:0] memory [0:IMAGE_SIZE-1];

    //------------------------------------------------------------
    // Memory Initialization
    //------------------------------------------------------------

    initial begin
        $display("------------------------------------------------");
        $display("Loading Image Memory...");
        $display("Memory File : %s", MEM_FILE);

        $readmemh(MEM_FILE, memory);

        $display("Image Memory Loaded Successfully.");
        $display("------------------------------------------------");
    end

    //------------------------------------------------------------
    // Synchronous Read
    //------------------------------------------------------------

    always @(posedge clk) begin
        pixel_out <= memory[address];
    end

endmodule
