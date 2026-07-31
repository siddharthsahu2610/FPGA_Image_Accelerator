`timescale 1ns/1ps

module window_generator_tb;

    localparam WIDTH = 4;
    localparam PDATA = 8;

    //------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------
    reg clk;
    reg rst;
    reg pixel_valid;
    reg [PDATA-1:0] pixel_in;

    wire window_valid;

    wire [PDATA-1:0] w00, w01, w02;
    wire [PDATA-1:0] w10, w11, w12;
    wire [PDATA-1:0] w20, w21, w22;

    //------------------------------------------------------------
    // DUT Instance
    //------------------------------------------------------------
    window_generator #(
        .WIDTH(WIDTH),
        .PDATA(PDATA)
    ) dut (
        .clk(clk),
        .rst(rst),

        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),

        .window_valid(window_valid),

        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22)
    );

    //------------------------------------------------------------
    // Clock Generation (10ns Period / 100MHz)
    //------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //------------------------------------------------------------
    // Stimulus Block
    //------------------------------------------------------------
    integer i;

    initial begin
        rst         = 1'b1;
        pixel_valid = 1'b0;
        pixel_in    = 0;

        repeat(3) @(posedge clk);
        rst = 1'b0;

        // Drive inputs on negedge to keep setup/hold clean for posedge
        for (i = 0; i < 24; i = i + 1) begin
            @(negedge clk);
            pixel_valid = 1'b1;
            pixel_in    = i[7:0];
        end

        @(negedge clk);
        pixel_valid = 1'b0;

        repeat(5) @(posedge clk);
        $finish;
    end

    //------------------------------------------------------------
    // Debug Monitor (Sampled cleanly right after posedge updates)
    //------------------------------------------------------------
    integer cycle;

    always @(posedge clk) begin
        if (rst) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
        end
    end

    // Use $strobe to display state after all posedge updates settle
    always @(posedge clk) begin
        if (!rst) begin
            $strobe("\n================================================");
            $strobe("Cycle : %0d | Time: %0t ps", cycle, $time);
            $strobe("Pixel : %0d (0x%02h) | Valid: %b", pixel_in, pixel_in, pixel_valid);
            $strobe("Row   : %0d | Col : %0d", dut.row_count, dut.col_ptr);
            $strobe("WinVld: %b", window_valid);

            if (window_valid) begin
                $strobe("----------- 3x3 Window -----------");
                $strobe("  %3d  %3d  %3d", w00, w01, w02);
                $strobe("  %3d  %3d  %3d", w10, w11, w12);
                $strobe("  %3d  %3d  %3d", w20, w21, w22);
                $strobe("----------------------------------");
            end
        end
    end

endmodule
