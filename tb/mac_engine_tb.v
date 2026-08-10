`timescale 1ns/1ps

module mac_engine_tb;

    parameter PIXEL_WIDTH = 8;
    parameter COEFF_WIDTH = 8;
    parameter ACC_WIDTH   = 20;

    reg clk;
    reg rst;
    reg window_valid;
    wire mac_valid;

    reg [7:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;
    reg signed [7:0] k0, k1, k2, k3, k4, k5, k6, k7, k8;

    wire signed [ACC_WIDTH-1:0] mac_out;

    // Unit Under Test
    mac_engine #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .window_valid(window_valid),
        .mac_valid(mac_valid),
        .p0(p0), .p1(p1), .p2(p2),
        .p3(p3), .p4(p4), .p5(p5),
        .p6(p6), .p7(p7), .p8(p8),
        .k0(k0), .k1(k1), .k2(k2),
        .k3(k3), .k4(k4), .k5(k5),
        .k6(k6), .k7(k7), .k8(k8),
        .mac_out(mac_out)
    );

    always #5 clk = ~clk;

    integer errors;
    integer total_tests;
    integer q_wr, q_rd;
    integer i;

    // Golden Model Queue
    reg signed [ACC_WIDTH-1:0] exp_queue [0:2047];

    initial begin
        clk = 0;
        rst = 1;
        errors = 0;
        total_tests = 0;
        q_wr = 0;
        q_rd = 0;
        window_valid = 0;
        {p0,p1,p2,p3,p4,p5,p6,p7,p8} = 0;
        {k0,k1,k2,k3,k4,k5,k6,k7,k8} = 0;

        #20;
        rst = 0;
        #10;

        $display("==============================================");
        $display("STARTING MAC RANDOMIZED STRESS TEST (500 WINS)");
        $display("==============================================");

        // Phase 1: 250 Back-to-Back Streaming Windows
        for (i = 0; i < 250; i = i + 1) begin
            drive_random_window();
        end

        // Phase 2: 250 Windows with Random Pipeline Bubbles/Stalls
        for (i = 0; i < 250; i = i + 1) begin
            if (($random & 32'h1) == 32'd1) begin
                @(negedge clk);
                window_valid = 0; // Insert bubble
            end
            drive_random_window();
        end

        @(negedge clk);
        window_valid = 0;

        // Drain pipeline
        #100;

        $display("==============================================");
        if (errors == 0) begin
            $display("MAC ENGINE STRESS TEST PASSED!");
            $display("Total Windows Processed : %0d", total_tests);
            $display("Total Errors Recorded   : 0");
        end else begin
            $display("MAC STRESS TEST FAILED WITH %0d ERRORS!", errors);
        end
        $display("==============================================");

        $finish;
    end

    // Random Window Task with local lint suppression for random bit truncation
    task drive_random_window;
        reg [7:0] tp0, tp1, tp2, tp3, tp4, tp5, tp6, tp7, tp8;
        reg signed [7:0] tk0, tk1, tk2, tk3, tk4, tk5, tk6, tk7, tk8;
        reg signed [ACC_WIDTH-1:0] exp_sum;
        begin
            @(negedge clk);
            window_valid = 1;
            
            /* verilator lint_off WIDTHTRUNC */
            tp0 = $random; tp1 = $random; tp2 = $random;
            tp3 = $random; tp4 = $random; tp5 = $random;
            tp6 = $random; tp7 = $random; tp8 = $random;

            tk0 = $random; tk1 = $random; tk2 = $random;
            tk3 = $random; tk4 = $random; tk5 = $random;
            tk6 = $random; tk7 = $random; tk8 = $random;
            /* verilator lint_on WIDTHTRUNC */

            p0 = tp0; p1 = tp1; p2 = tp2; p3 = tp3; p4 = tp4; p5 = tp5; p6 = tp6; p7 = tp7; p8 = tp8;
            k0 = tk0; k1 = tk1; k2 = tk2; k3 = tk3; k4 = tk4; k5 = tk5; k6 = tk6; k7 = tk7; k8 = tk8;

            // Calculate Golden Output
            exp_sum = ($signed({1'b0, tp0}) * tk0) + ($signed({1'b0, tp1}) * tk1) +
                      ($signed({1'b0, tp2}) * tk2) + ($signed({1'b0, tp3}) * tk3) +
                      ($signed({1'b0, tp4}) * tk4) + ($signed({1'b0, tp5}) * tk5) +
                      ($signed({1'b0, tp6}) * tk6) + ($signed({1'b0, tp7}) * tk7) +
                      ($signed({1'b0, tp8}) * tk8);

            exp_queue[q_wr] = exp_sum;
            q_wr = q_wr + 1;
        end
    endtask

    // Output Checker Process
    always @(negedge clk) begin
        if (mac_valid) begin
            total_tests <= total_tests + 1;
            if (mac_out !== exp_queue[q_rd]) begin
                $display("FAIL [Win #%0d]: DUT = %d | EXP = %d", total_tests + 1, mac_out, exp_queue[q_rd]);
                errors <= errors + 1;
            end
            q_rd <= q_rd + 1;
        end
    end

endmodule

