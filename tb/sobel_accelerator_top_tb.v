`timescale 1ns/1ps

module sobel_accelerator_top_tb;

    // =========================================================
    // Parameters
    // =========================================================

    localparam integer DATA_WIDTH = 8;
    localparam integer IMG_WIDTH  = 128;
    localparam integer IMG_HEIGHT = 128;

    localparam integer TOTAL_IN  = IMG_WIDTH * IMG_HEIGHT;
    localparam integer TOTAL_OUT = (IMG_WIDTH - 2) * (IMG_HEIGHT - 2);

    // =========================================================
    // DUT Interface
    // =========================================================

    reg clk;
    reg rst;

    reg                  s_axis_valid;
    reg  [DATA_WIDTH-1:0] s_axis_data;

    wire                 m_axis_valid;
    wire [DATA_WIDTH-1:0] m_axis_data;

    // =========================================================
    // Input / Golden Memory
    // =========================================================

    reg [DATA_WIDTH-1:0] input_mem  [0:TOTAL_IN-1];
    reg [DATA_WIDTH-1:0] golden_mem [0:TOTAL_OUT-1];

    // =========================================================
    // Verification Counters
    // =========================================================

    integer i;
    integer r;
    integer c;

    integer input_count;
    integer output_count;
    integer match_count;
    integer mismatch_count;

    // =========================================================
    // DUT
    // =========================================================

    sobel_accelerator_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .IMG_WIDTH  (IMG_WIDTH),
        .IMG_HEIGHT (IMG_HEIGHT)
    ) dut (
        .clk          (clk),
        .rst          (rst),

        .s_axis_valid (s_axis_valid),
        .s_axis_data  (s_axis_data),

        .m_axis_valid (m_axis_valid),
        .m_axis_data  (m_axis_data)
    );

    // =========================================================
    // Clock
    // 100 MHz
    // =========================================================

    always #5 clk = ~clk;

    // =========================================================
    // Golden Sobel-X Model
    //
    // Kernel:
    //
    //       -1   0  +1
    //       -2   0  +2
    //       -1   0  +1
    //
    // Explicit 32-bit signed arithmetic is used so that

    function [7:0] sobel_x;

        input integer r;
        input integer c;

        reg [7:0] p00;
        reg [7:0] p01;
        reg [7:0] p02;

        reg [7:0] p10;
        reg [7:0] p12;

        reg [7:0] p20;
        reg [7:0] p21;
        reg [7:0] p22;

        reg signed [31:0] sp00;
        reg signed [31:0] sp02;
        reg signed [31:0] sp10;
        reg signed [31:0] sp12;
        reg signed [31:0] sp20;
        reg signed [31:0] sp22;

        reg signed [31:0] result;

        begin

            // -------------------------------------------------
            // Read 3x3 neighborhood
            // -------------------------------------------------

            p00 = input_mem[(r    )*IMG_WIDTH + (c    )];
            p01 = input_mem[(r    )*IMG_WIDTH + (c + 1)];
            p02 = input_mem[(r    )*IMG_WIDTH + (c + 2)];

            p10 = input_mem[(r + 1)*IMG_WIDTH + (c    )];
            p12 = input_mem[(r + 1)*IMG_WIDTH + (c + 2)];

            p20 = input_mem[(r + 2)*IMG_WIDTH + (c    )];
            p21 = input_mem[(r + 2)*IMG_WIDTH + (c + 1)];
            p22 = input_mem[(r + 2)*IMG_WIDTH + (c + 2)];

            // -------------------------------------------------
            // Explicit zero-extension:
            //
            // 8-bit unsigned pixel
            //          ↓
            // 32-bit signed positive value
            // -------------------------------------------------

            sp00 = {24'd0, p00};
            sp02 = {24'd0, p02};

            sp10 = {24'd0, p10};
            sp12 = {24'd0, p12};

            sp20 = {24'd0, p20};
            sp22 = {24'd0, p22};

            // -------------------------------------------------
            // Sobel-X convolution
            // -------------------------------------------------

            result =
                  -sp00
                  + sp02
                  - (32'sd2 * sp10)
                  + (32'sd2 * sp12)
                  - sp20
                  + sp22;

            // -------------------------------------------------
            // Saturation
            // -------------------------------------------------

            if (result < 0)
                sobel_x = 0;

            else if (result > 255)
                sobel_x = 255;

            else
                sobel_x = result[7:0];

        end

    endfunction

    // =========================================================
    // Testbench
    // =========================================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        s_axis_valid = 1'b0;
        s_axis_data  = 8'd0;

        input_count  = 0;
        output_count = 0;
        match_count  = 0;
        mismatch_count = 0;

        // -----------------------------------------------------
        // Generate deterministic test image
        //
        // Pixel value = lower 8 bits of linear pixel index.
        // -----------------------------------------------------

        for (i = 0; i < TOTAL_IN; i = i + 1) begin
            input_mem[i] = i[7:0];
        end

        // -----------------------------------------------------
        // Generate golden Sobel-X reference image
        //
        // Only valid 3x3 positions are produced.
        // Therefore:
        //
        // 128x128 input
        //       ↓
        // 126x126 valid output
        //       ↓
        // 15876 output pixels
        // -----------------------------------------------------

        for (r = 0; r < IMG_HEIGHT - 2; r = r + 1) begin

            for (c = 0; c < IMG_WIDTH - 2; c = c + 1) begin

                golden_mem[
                    r * (IMG_WIDTH - 2) + c
                ] = sobel_x(r, c);

            end

        end

        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------

        #30;

        rst = 1'b0;

        #10;

        $display("==============================================");
        $display("STARTING 128x128 SOBEL-X GOLDEN MODEL TEST");
        $display("==============================================");

        $display("Input pixels  : %0d", TOTAL_IN);
        $display("Output pixels : %0d", TOTAL_OUT);

        // -----------------------------------------------------
        // Stream complete image
        // -----------------------------------------------------

        for (i = 0; i < TOTAL_IN; i = i + 1) begin

            @(posedge clk);

            s_axis_valid = 1'b1;
            s_axis_data  = input_mem[i];

            input_count = input_count + 1;

        end

        // -----------------------------------------------------
        // Stop input stream
        // -----------------------------------------------------

        @(posedge clk);

        s_axis_valid = 1'b0;
        s_axis_data  = 8'd0;

        // -----------------------------------------------------
        // Wait until every expected output arrives
        // -----------------------------------------------------

        wait (output_count == TOTAL_OUT);

        // Allow final signal settling
        #20;

        // -----------------------------------------------------
        // Final verification summary
        // -----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("GOLDEN MODEL VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "Input pixels accepted : %0d",
            input_count
        );

        $display(
            "Expected outputs      : %0d",
            TOTAL_OUT
        );

        $display(
            "Outputs received      : %0d",
            output_count
        );

        $display(
            "Matched outputs       : %0d",
            match_count
        );

        $display(
            "Mismatches            : %0d",
            mismatch_count
        );

        $display("----------------------------------------------");

        if ((input_count == TOTAL_IN) &&
            (output_count == TOTAL_OUT) &&
            (match_count == TOTAL_OUT) &&
            (mismatch_count == 0)) begin

            $display("STATUS: PIXEL-ACCURATE PASS");

        end
        else begin

            $display("STATUS: FAIL");

        end

        $display("==============================================");

        $finish;

    end

    // =========================================================
    // Output Checker
    //
    // The DUT produces valid output after its internal
    // pipeline latency.
    //
    // Every valid output is compared against the corresponding
    // golden-model pixel.
    // =========================================================

    always @(posedge clk) begin

        if (!rst && m_axis_valid) begin

            if (output_count < TOTAL_OUT) begin

                if (m_axis_data === golden_mem[output_count]) begin

                    match_count = match_count + 1;

                end
                else begin

                    mismatch_count = mismatch_count + 1;

                    $display(
                        "[MISMATCH] Pixel %0d | Expected: 0x%02h | Got: 0x%02h",
                        output_count,
                        golden_mem[output_count],
                        m_axis_data
                    );

                end

                output_count = output_count + 1;

            end

        end

    end

endmodule

