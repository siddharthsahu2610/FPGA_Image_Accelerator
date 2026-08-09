`timescale 1ns/1ps

module tb_window_generator;

    //============================================================
    // Parameters
    //============================================================

    parameter integer WIDTH  = 4;
    parameter integer HEIGHT = 6;
    parameter integer PDATA  = 8;

    //============================================================
    // Signals
    //============================================================

    reg clk;
    reg rst;

    reg pixel_valid;
    reg [PDATA-1:0] pixel_in;

    wire window_valid;

    wire [PDATA-1:0] w00;
    wire [PDATA-1:0] w01;
    wire [PDATA-1:0] w02;

    wire [PDATA-1:0] w10;
    wire [PDATA-1:0] w11;
    wire [PDATA-1:0] w12;

    wire [PDATA-1:0] w20;
    wire [PDATA-1:0] w21;
    wire [PDATA-1:0] w22;

    //============================================================
    // DUT
    //============================================================

    window_generator #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PDATA(PDATA)
    ) dut (
        .clk(clk),
        .rst(rst),

        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),

        .window_valid(window_valid),

        .w00(w00),
        .w01(w01),
        .w02(w02),

        .w10(w10),
        .w11(w11),
        .w12(w12),

        .w20(w20),
        .w21(w21),
        .w22(w22)
    );

    //============================================================
    // Clock
    //============================================================

    always #5 clk = ~clk;

    //============================================================
    // VCD
    //============================================================

    initial begin

        $dumpfile("window_generator.vcd");
        $dumpvars(0, tb_window_generator);

    end

    //============================================================
    // Test variables
    //============================================================

    integer i;
    integer row;
    integer col;

    integer pixel_count;
    integer window_count;
    integer error_count;
    integer cycle_count;

    integer expected_value;

    reg expected_valid;

    reg [PDATA-1:0] expected [0:8];

    //============================================================
    // Set expected PDATA-bit value
    //============================================================

    task set_expected;

        input integer index;
        input integer value;

        begin

            expected[index] = PDATA'(value);

        end

    endtask

    //============================================================
    // Check complete 3x3 window
    //============================================================

    task check_window;

        input integer base_row;
        input integer base_col;

        begin

            // Top row
            set_expected(
                0,
                base_row * WIDTH + base_col
            );

            set_expected(
                1,
                base_row * WIDTH + base_col + 1
            );

            set_expected(
                2,
                base_row * WIDTH + base_col + 2
            );

            // Middle row
            set_expected(
                3,
                (base_row + 1) * WIDTH + base_col
            );

            set_expected(
                4,
                (base_row + 1) * WIDTH + base_col + 1
            );

            set_expected(
                5,
                (base_row + 1) * WIDTH + base_col + 2
            );

            // Bottom row
            set_expected(
                6,
                (base_row + 2) * WIDTH + base_col
            );

            set_expected(
                7,
                (base_row + 2) * WIDTH + base_col + 1
            );

            set_expected(
                8,
                (base_row + 2) * WIDTH + base_col + 2
            );

            //================================================
            // Compare
            //================================================

            if ((w00 !== expected[0]) ||
                (w01 !== expected[1]) ||
                (w02 !== expected[2]) ||
                (w10 !== expected[3]) ||
                (w11 !== expected[4]) ||
                (w12 !== expected[5]) ||
                (w20 !== expected[6]) ||
                (w21 !== expected[7]) ||
                (w22 !== expected[8])) begin

                $display("");
                $display("ERROR: Window %0d FAILED", window_count);

                $display(
                    "Top-left = row %0d col %0d",
                    base_row,
                    base_col
                );

                $display("Expected:");
                $display(
                    "%02h %02h %02h",
                    expected[0],
                    expected[1],
                    expected[2]
                );

                $display(
                    "%02h %02h %02h",
                    expected[3],
                    expected[4],
                    expected[5]
                );

                $display(
                    "%02h %02h %02h",
                    expected[6],
                    expected[7],
                    expected[8]
                );

                $display("Actual:");
                $display(
                    "%02h %02h %02h",
                    w00,
                    w01,
                    w02
                );

                $display(
                    "%02h %02h %02h",
                    w10,
                    w11,
                    w12
                );

                $display(
                    "%02h %02h %02h",
                    w20,
                    w21,
                    w22
                );

                error_count = error_count + 1;

            end
            else begin

                $display(
                    "PASS: Window %0d | top-left = (%0d,%0d)",
                    window_count,
                    base_row,
                    base_col
                );

                $display(
                    "     %02h %02h %02h",
                    w00,
                    w01,
                    w02
                );

                $display(
                    "     %02h %02h %02h",
                    w10,
                    w11,
                    w12
                );

                $display(
                    "     %02h %02h %02h",
                    w20,
                    w21,
                    w22
                );

            end

            window_count = window_count + 1;

        end

    endtask

    //============================================================
    // Main test
    //============================================================

    initial begin

        //========================================================
        // Initial state
        //========================================================

        clk = 1'b0;
        rst = 1'b1;

        pixel_valid = 1'b0;
        pixel_in = '0;

        pixel_count = 0;
        window_count = 0;
        error_count = 0;
        cycle_count = 0;

        //========================================================
        // Header
        //========================================================

        $display("");
        $display("==============================================");
        $display("FPGA IMAGE ACCELERATOR");
        $display("WINDOW GENERATOR VERIFICATION");
        $display("==============================================");

        $display("WIDTH  = %0d", WIDTH);
        $display("HEIGHT = %0d", HEIGHT);
        $display("PDATA  = %0d", PDATA);

        $display(
            "Expected windows = %0d",
            (WIDTH - 2) * (HEIGHT - 2)
        );

        $display("");

        //========================================================
        // RESET
        //========================================================

        $display("Applying reset...");

        repeat (3) begin

            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            if (window_valid !== 1'b0) begin

                $display(
                    "ERROR: window_valid asserted during reset."
                );

                error_count = error_count + 1;

            end

        end

        rst = 1'b0;

        $display("Reset released.");
        $display("");

        //========================================================
        // STREAM IMAGE
        //
        // Pixel values:
        //
        // 00 01 02 03
        // 04 05 06 07
        // 08 09 0A 0B
        // 0C 0D 0E 0F
        // 10 11 12 13
        // 14 15 16 17
        //========================================================

        for (i = 0; i < WIDTH * HEIGHT; i = i + 1) begin

            row = i / WIDTH;
            col = i % WIDTH;

            // Present input before rising edge.
            @(negedge clk);

            pixel_in = PDATA'(i);
            pixel_valid = 1'b1;

            // Pixel accepted by DUT.
            @(posedge clk);

            #1;

            cycle_count = cycle_count + 1;
            pixel_count = pixel_count + 1;

            //====================================================
            // Expected valid
            //====================================================

            if ((row >= 2) && (col >= 2))
                expected_valid = 1'b1;
            else
                expected_valid = 1'b0;

            //====================================================
            // Check valid signal
            //====================================================

            if (window_valid !== expected_valid) begin

                $display("");
                $display("ERROR: window_valid mismatch");
                $display("Pixel index = %0d", i);
                $display("Row = %0d", row);
                $display("Column = %0d", col);
                $display("Expected = %0b", expected_valid);
                $display("Actual = %0b", window_valid);

                error_count = error_count + 1;

            end

            //====================================================
            // Check window
            //====================================================

            if (window_valid === 1'b1) begin

                check_window(
                    row - 2,
                    col - 2
                );

            end

        end

        //========================================================
        // Stop stream
        //========================================================

        @(negedge clk);

        pixel_valid = 1'b0;
        pixel_in = '0;

        //========================================================
        // Verify no delayed windows
        //========================================================

        repeat (3) begin

            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

            if (window_valid !== 1'b0) begin

                $display(
                    "ERROR: Unexpected window after stream ended."
                );

                error_count = error_count + 1;

            end

        end

        //========================================================
        // Pixel count check
        //========================================================

        if (pixel_count != WIDTH * HEIGHT) begin

            $display("");
            $display("ERROR: Pixel count mismatch.");

            $display(
                "Expected = %0d",
                WIDTH * HEIGHT
            );

            $display(
                "Actual = %0d",
                pixel_count
            );

            error_count = error_count + 1;

        end

        //========================================================
        // Window count check
        //========================================================

        if (window_count != (WIDTH - 2) * (HEIGHT - 2)) begin

            $display("");
            $display("ERROR: Window count mismatch.");

            $display(
                "Expected = %0d",
                (WIDTH - 2) * (HEIGHT - 2)
            );

            $display(
                "Actual = %0d",
                window_count
            );

            error_count = error_count + 1;

        end

        //========================================================
        // Final report
        //========================================================

        $display("");
        $display("==============================================");

        if (error_count == 0) begin

            $display("WINDOW GENERATOR TEST PASSED");

        end
        else begin

            $display("WINDOW GENERATOR TEST FAILED");

        end

        $display("==============================================");

        $display(
            "Pixels tested  = %0d",
            pixel_count
        );

        $display(
            "Windows tested = %0d",
            window_count
        );

        $display(
            "Errors         = %0d",
            error_count
        );

        $display(
            "Cycles         = %0d",
            cycle_count
        );

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule

