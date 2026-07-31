`timescale 1ns/1ps

module image_memory_tb;

    //------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------

    localparam IMAGE_SIZE = 16384;
    localparam ADDR_WIDTH = 14;
    localparam DATA_WIDTH = 8;

    //------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------

    reg clk;

    reg  [ADDR_WIDTH-1:0] address;
    wire [DATA_WIDTH-1:0] pixel_out;

    //------------------------------------------------------------
    // Instantiate DUT
    //------------------------------------------------------------

    image_memory #(
        .IMAGE_SIZE(IMAGE_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .address(address),
        .pixel_out(pixel_out)
    );

    //------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //------------------------------------------------------------
    // Test Procedure
    //------------------------------------------------------------

    reg[13:0] i;

    initial begin

        $display("");
        $display("=========================================");
        $display(" Image Memory Testbench");
        $display("=========================================");

        address = 0;

        // wait for memory initialization
        @(posedge clk);

        //--------------------------------------------------------
        // Read first 16 pixels
        //--------------------------------------------------------

        for(i = 0; i < 16; i = i + 1)
        begin
            address = i;

            @(posedge clk);

            $display("Address = %0d    Pixel = 0x%02h (%0d)",
                     address,
                     pixel_out,
                     pixel_out);
        end

        //--------------------------------------------------------
        // Random Reads
        //--------------------------------------------------------

        $display("");

        address = 128;
        @(posedge clk);
        $display("Address = %0d Pixel = %02h",address,pixel_out);

        address = 512;
        @(posedge clk);
        $display("Address = %0d Pixel = %02h",address,pixel_out);

        address = 4096;
        @(posedge clk);
        $display("Address = %0d Pixel = %02h",address,pixel_out);

        address = 16383;
        @(posedge clk);
        $display("Address = %0d Pixel = %02h",address,pixel_out);

        $display("");
        $display("=========================================");
        $display(" TEST COMPLETED ");
        $display("=========================================");

        $finish;

    end

endmodule
