`timescale 1ns/1ps

module tb_sobel_accelerator;

    localparam integer DATA_WIDTH = 8;
    localparam integer IMG_WIDTH  = 128;
    localparam integer IMG_HEIGHT = 128;

    localparam integer TOTAL_IN  = IMG_WIDTH * IMG_HEIGHT;
    localparam integer TOTAL_OUT = (IMG_WIDTH - 2) * (IMG_HEIGHT - 2);

    reg clk;
    reg rst;

    // ------------------------------------------------------------
    // Input stream
    // ------------------------------------------------------------

    reg                  s_axis_valid;
    reg  [DATA_WIDTH-1:0] s_axis_data;

    // ------------------------------------------------------------
    // Output stream
    // ------------------------------------------------------------

    wire                  m_axis_valid;
    wire [DATA_WIDTH-1:0] m_axis_data;

    // ------------------------------------------------------------
    // Test vectors
    // ------------------------------------------------------------

    reg [DATA_WIDTH-1:0] input_mem  [0:TOTAL_IN-1];
    reg [DATA_WIDTH-1:0] golden_mem [0:TOTAL_OUT-1];

    integer i;
    integer out_index;
    integer match_count;
    integer mismatch_count;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    sobel_accelerator_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH (IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) dut (
        .clk          (clk),
        .rst          (rst),

        .s_axis_valid (s_axis_valid),
        .s_axis_data  (s_axis_data),

        .m_axis_valid (m_axis_valid),
        .m_axis_data  (m_axis_data)
    );

    // ------------------------------------------------------------
    // Clock: 100 MHz
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Load vectors
    // ------------------------------------------------------------

    initial begin

        $readmemh("images/input_image_128.hex", input_mem);
        $readmemh("images/golden_output_128.hex", golden_mem);

        clk            = 1'b0;
        rst            = 1'b1;
        s_axis_valid   = 1'b0;
        s_axis_data    = 8'd0;

        out_index      = 0;
        match_count    = 0;
        mismatch_count = 0;

        $display("==============================================");
        $display("STARTING 128x128 SOBEL-X GOLDEN MODEL TEST");
        $display("==============================================");

        $display("Input pixels  : %0d", TOTAL_IN);
        $display("Output pixels : %0d", TOTAL_OUT);

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        #30;
        rst = 1'b0;

        // --------------------------------------------------------
        // Stream complete image
        // --------------------------------------------------------

        for (i = 0; i < TOTAL_IN; i = i + 1) begin

            @(posedge clk);

            s_axis_valid <= 1'b1;
            s_axis_data  <= input_mem[i];

        end

        @(posedge clk);

        s_axis_valid <= 1'b0;
        s_axis_data  <= 8'd0;

        // --------------------------------------------------------
        // Wait for final pipeline outputs
        // --------------------------------------------------------

        wait (out_index == TOTAL_OUT);

        #20;

        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("GOLDEN MODEL VERIFICATION SUMMARY");
        $display("==============================================");

        $display("Input pixels accepted : %0d", TOTAL_IN);
        $display("Expected outputs      : %0d", TOTAL_OUT);
        $display("Outputs received      : %0d", out_index);
        $display("Matched outputs       : %0d", match_count);
        $display("Mismatches            : %0d", mismatch_count);

        $display("----------------------------------------------");

        if ((out_index == TOTAL_OUT) &&
            (match_count == TOTAL_OUT) &&
            (mismatch_count == 0)) begin

            $display("STATUS: PIXEL-ACCURATE PASS");
            $display("==============================================");

        end else begin

            $display("STATUS: FAIL");
            $display("==============================================");

        end

        $finish;
    end

    // ------------------------------------------------------------
    // Output checker
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (!rst && m_axis_valid) begin

            if (out_index < TOTAL_OUT) begin

                if (m_axis_data === golden_mem[out_index]) begin

                    match_count = match_count + 1;

                end else begin

                    mismatch_count = mismatch_count + 1;

                    $display(
                        "[MISMATCH] Pixel %0d | Expected: 0x%02h | Got: 0x%02h",
                        out_index,
                        golden_mem[out_index],
                        m_axis_data
                    );

                end

                out_index = out_index + 1;

            end

        end

    end

endmodule
