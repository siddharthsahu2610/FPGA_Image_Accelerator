`timescale 1ns/1ps

module pixel_stream_tb;

localparam ADDR_WIDTH  = 14;
localparam MAX_ADDRESS = 14'd16383;

//------------------------------------------------------------
// DUT Signals
//------------------------------------------------------------

reg clk;
reg reset;

wire [ADDR_WIDTH-1:0] address;
wire                  valid;

//------------------------------------------------------------
// DUT
//------------------------------------------------------------

pixel_stream #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .MAX_ADDRESS(MAX_ADDRESS)
)
dut (
    .clk(clk),
    .reset(reset),
    .address(address),
    .valid(valid)
);

//------------------------------------------------------------
// Clock
//------------------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

//------------------------------------------------------------
// Test Variables
//------------------------------------------------------------

integer expected_addr;
integer errors;

//------------------------------------------------------------
// Test
//------------------------------------------------------------

initial begin

    errors = 0;

    $display("");
    $display("====================================");
    $display(" Pixel Stream Testbench");
    $display("====================================");

    //------------------------------------------
    // Apply Reset
    //------------------------------------------

    reset = 1'b1;

    repeat(2) @(posedge clk);

    reset = 1'b0;

    //------------------------------------------
    // First Valid Address (0)
    //------------------------------------------

    @(posedge clk);

    //------------------------------------------
    // Verify First 20 Addresses
    //------------------------------------------

    for (expected_addr = 0;
         expected_addr < 20;
         expected_addr = expected_addr + 1)
    begin

        if (address !== expected_addr[ADDR_WIDTH-1:0]) begin

            $display("--------------------------------");
            $display("ERROR");
            $display("Expected : %0d", expected_addr);
            $display("Received : %0d", address);

            errors = errors + 1;

        end

        if (valid !== 1'b1) begin

            $display("--------------------------------");
            $display("ERROR : VALID should be HIGH");

            errors = errors + 1;

        end

        $display("Address = %0d   Valid = %0b",
                 address,
                 valid);

        @(posedge clk);

    end

    //------------------------------------------
    // Summary
    //------------------------------------------

    $display("");

    if(errors == 0)
        $display("********** TEST PASSED **********");
    else
        $display("********** TEST FAILED **********");

    $finish;

end
endmodule

