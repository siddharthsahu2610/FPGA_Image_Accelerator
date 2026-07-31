`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Project : FPGA Image Accelerator
// Module  : pixel_stream
//
// Description:
// Generates sequential addresses for streaming image pixels.
//
// Behavior:
//   Reset:
//      address = 0
//      valid   = 0
//
//   First clock after reset:
//      address = 0
//      valid   = 1
//
//   Following clocks:
//      address = 1,2,3...
//
//   After MAX_ADDRESS:
//      valid = 0
//////////////////////////////////////////////////////////////////////////////////

module pixel_stream #(
    parameter ADDR_WIDTH  = 14,
    parameter MAX_ADDRESS = 14'd16383
)(
    input  wire                  clk,
    input  wire                  reset,

    output reg [ADDR_WIDTH-1:0]  address,
    output reg                   valid
);

reg started;

always @(posedge clk) begin

    if (reset) begin
        address <= {ADDR_WIDTH{1'b0}};
        valid   <= 1'b0;
        started <= 1'b0;
    end

    else begin

        //--------------------------------------------
        // First valid pixel
        //--------------------------------------------

        if (!started) begin
            started <= 1'b1;
            valid   <= 1'b1;
        end

        //--------------------------------------------
        // Continue streaming
        //--------------------------------------------

        else if (address < MAX_ADDRESS) begin
            address <= address + 1'b1;
            valid   <= 1'b1;
        end

        //--------------------------------------------
        // End of Image
        //--------------------------------------------

        else begin
            valid <= 1'b0;
        end

    end

end
endmodule
