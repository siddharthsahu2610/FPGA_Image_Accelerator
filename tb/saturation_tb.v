`timescale 1ns/1ps

module saturation_tb;

    parameter IN_WIDTH  = 20;
    parameter OUT_WIDTH = 8;

    reg signed [IN_WIDTH-1:0] sum_in;
    wire [OUT_WIDTH-1:0] pixel_out;

    saturation #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .SHIFT(0)
    ) uut (
        .sum_in(sum_in),
        .pixel_out(pixel_out)
    );

    integer errors;
    integer tests;

    task check_sat;
        input signed [IN_WIDTH-1:0] in_val;
        input [OUT_WIDTH-1:0] exp_val;

        begin

            sum_in = in_val;

            #1;

            tests = tests + 1;

            if (pixel_out !== exp_val) begin

                $display(
                    "[FAIL] Test %0d | In = %0d | Expected = %0d | Got = %0d",
                    tests,
                    in_val,
                    exp_val,
                    pixel_out
                );

                errors = errors + 1;

            end

            else begin

                $display(
                    "[PASS] Test %0d | In = %0d | Output = %0d",
                    tests,
                    in_val,
                    pixel_out
                );

            end

        end

    endtask

    initial begin

        errors = 0;
        tests  = 0;
        sum_in = 0;

        $display("==============================================");
        $display("STARTING SATURATION MODULE VERIFICATION");
        $display("==============================================");

        //----------------------------------------------------
        // Negative / underflow
        //----------------------------------------------------

        check_sat(-500, 8'd0);
        check_sat(-1,   8'd0);

        //----------------------------------------------------
        // Lower boundary
        //----------------------------------------------------

        check_sat(0, 8'd0);

        //----------------------------------------------------
        // Valid range
        //----------------------------------------------------

        check_sat(1,   8'd1);
        check_sat(128, 8'd128);
        check_sat(254, 8'd254);
        check_sat(255, 8'd255);

        //----------------------------------------------------
        // Overflow
        //----------------------------------------------------

        check_sat(256,  8'd255);
        check_sat(1024, 8'd255);
        check_sat(291465, 8'd255);

        //----------------------------------------------------
        // Final result
        //----------------------------------------------------

        $display("==============================================");
        $display("SATURATION VERIFICATION SUMMARY");
        $display("==============================================");
        $display("Total Tests  : %0d", tests);
        $display("Total Errors : %0d", errors);

        if (errors == 0) begin

            $display("----------------------------------------------");
            $display("SATURATION MODULE TEST PASSED");
            $display("----------------------------------------------");

        end

        else begin

            $display("----------------------------------------------");
            $display("SATURATION MODULE TEST FAILED");
            $display("----------------------------------------------");

        end

        $display("==============================================");

        $finish;

    end

endmodule

