`timescale 1ns/1ps

module image_accelerator_top_tb;

    // 1. Parameters
    parameter PDATA      = 8;
    parameter IMG_WIDTH  = 640;
    parameter IMG_HEIGHT = 5;

    // 2. Registers & Wires
    reg clk;
    reg rst;
    reg pixel_valid;
    reg [PDATA-1:0] pixel_in;

    // Sobel X Coefficients
    reg signed [7:0] k0, k1, k2;
    reg signed [7:0] k3, k4, k5;
    reg signed [7:0] k6, k7, k8;

    wire valid_out;
    wire [PDATA-1:0] pixel_out;

    integer r, c;
    integer total_pixels_out;
    integer error_count;

    // Combinational evaluation variables for dynamic checker
    integer out_col, out_row;
    reg [PDATA-1:0] expected_pixel;

    // 3. DUT Instantiation
    image_accelerator_top #(
        .PDATA(PDATA),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .SHIFT(0)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .k0(k0), .k1(k1), .k2(k2),
        .k3(k3), .k4(k4), .k5(k5),
        .k6(k6), .k7(k7), .k8(k8),
        .valid_out(valid_out),
        .pixel_out(pixel_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        pixel_valid = 0;
        pixel_in = 0;
        total_pixels_out = 0;
        error_count = 0;

        // Sobel X Kernel [-1 0 1; -2 0 2; -1 0 1]
        k0 = -1; k1 =  0; k2 =  1;
        k3 = -2; k4 =  0; k5 =  2;
        k6 = -1; k7 =  0; k8 =  1;

        #20;
        rst = 0;
        #10;

        $display("==============================================");
        $display("STARTING PIXEL-ACCURATE VERIFICATION (SOBEL-X)");
        $display("==============================================");

        // Stream image frame
        for (r = 0; r < IMG_HEIGHT; r = r + 1) begin
            for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                @(posedge clk);
                pixel_valid = 1'b1;

                if (c < (IMG_WIDTH / 2))
                    pixel_in = 8'd50;  // Dark region
                else
                    pixel_in = 8'd200; // Bright region
            end
        end

        @(posedge clk);
        pixel_valid = 1'b0;
        #100;

        $display("==============================================");
        $display("VERIFICATION SUMMARY");
        $display("  Total Input Pixels Streamed : %0d", IMG_HEIGHT * IMG_WIDTH);
        $display("  Processed Pixels Produced   : %0d", total_pixels_out);
        $display("  Total Mismatches / Errors   : %0d", error_count);
        
        if (error_count == 0 && total_pixels_out == 1914) begin
            $display("  STATUS: PASS (Pixel-Accurate Match!)");
        end else begin
            $display("  STATUS: FAIL");
        end
        $display("==============================================");

        $finish;
    end

    // Combinational evaluation of expected golden value based on pixel count
    always @(*) begin
        out_col = total_pixels_out % (IMG_WIDTH - 2);
        out_row = total_pixels_out / (IMG_WIDTH - 2);

        // Sobel-X transition at boundary (Cols 317 & 318 of 0..637 output frame)
        if (out_col == (IMG_WIDTH/2 - 2) || out_col == (IMG_WIDTH/2 - 1)) begin
            expected_pixel = 8'd255;
        end else begin
            expected_pixel = 8'd0;
        end
    end

    // Synchronous checking block (using pure non-blocking assignments)
    always @(posedge clk) begin
        if (rst) begin
            total_pixels_out <= 0;
            error_count      <= 0;
        end else if (valid_out) begin
            if (pixel_out !== expected_pixel) begin
                $error("[MISMATCH] Row %0d Col %0d | Expected: 0x%0h, Got: 0x%0h", 
                       out_row, out_col, expected_pixel, pixel_out);
                error_count <= error_count + 1;
            end
            total_pixels_out <= total_pixels_out + 1;
        end
    end

endmodule

