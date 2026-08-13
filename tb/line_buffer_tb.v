`timescale 1ns/1ps

module line_buffer_tb;

    parameter PIXEL_WIDTH = 8;
    parameter IMG_WIDTH   = 640;

    reg clk;
    reg rst;
    reg pixel_valid;
    reg [PIXEL_WIDTH-1:0] pixel_in;

    wire [PIXEL_WIDTH-1:0] row0_out;
    wire [PIXEL_WIDTH-1:0] row1_out;
    wire [PIXEL_WIDTH-1:0] row2_out;

    // DUT Instance
    line_buffer #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .IMG_WIDTH(IMG_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .row0_out(row0_out),
        .row1_out(row1_out),
        .row2_out(row2_out)
    );

    always #5 clk = ~clk;

    integer i;
    integer errors;
    integer checks_performed;

    /* verilator lint_off UNUSEDSIGNAL */
    /* verilator lint_off WIDTHTRUNC */
    integer calc_r1, calc_r0;
    reg [7:0] exp_r0, exp_r1, exp_r2;
    /* verilator lint_on WIDTHTRUNC */
    /* verilator lint_on UNUSEDSIGNAL */

    initial begin
        clk = 0;
        rst = 1;
        pixel_valid = 0;
        pixel_in = 0;
        errors = 0;
        checks_performed = 0;

        #20;
        rst = 0;
        #10;

        $display("==============================================");
        $display("STARTING LINE BUFFER VERIFICATION");
        $display("==============================================");

        // Stream 3 full lines (1920 pixels)
        for (i = 0; i < (3 * IMG_WIDTH); i = i + 1) begin
            @(posedge clk);
            pixel_valid = 1'b1;
            pixel_in    = i[7:0];

            @(negedge clk); // Check outputs on falling edge after BRAM read update
            if (i >= 2 * IMG_WIDTH) begin
                calc_r1 = i - IMG_WIDTH;
                calc_r0 = i - 2 * IMG_WIDTH;

                exp_r2 = i[7:0];
                exp_r1 = calc_r1[7:0];
                exp_r0 = calc_r0[7:0];

                checks_performed = checks_performed + 1;

                if ((row2_out !== exp_r2) || (row1_out !== exp_r1) || (row0_out !== exp_r0)) begin
                    $display("[FAIL] Pixel %0d: Expected (R2:%0d, R1:%0d, R0:%0d) | Got (R2:%0d, R1:%0d, R0:%0d)",
                             i, exp_r2, exp_r1, exp_r0, row2_out, row1_out, row0_out);
                    errors = errors + 1;
                end
            end
        end

        @(posedge clk);
        pixel_valid = 1'b0;
        #20;

        $display("==============================================");
        $display("VERIFICATION SUMMARY");
        $display("  Total Pixels Streamed : %0d", 3 * IMG_WIDTH);
        $display("  Spatial Checks Run   : %0d", checks_performed);
        $display("  Total Errors Found   : %0d", errors);
        
        if (errors == 0 && checks_performed == IMG_WIDTH) begin
            $display("RESULT: [PASS] - All 3 rows strictly aligned!");
        end else begin
            $display("RESULT: [FAIL] - Alignment mismatch detected!");
        end
        $display("==============================================");

        $finish;
    end

endmodule

