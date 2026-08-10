`timescale 1ns/1ps

module mac_engine #(
    parameter PIXEL_WIDTH = 8,
    parameter COEFF_WIDTH = 8,
    parameter ACC_WIDTH   = 20
)(
    input  wire clk,
    input  wire rst,

    // Control Interface
    input  wire window_valid,
    output reg  mac_valid,

    // 3x3 Window Pixels (Unsigned 8-bit)
    input  wire [PIXEL_WIDTH-1:0] p0, p1, p2,
    input  wire [PIXEL_WIDTH-1:0] p3, p4, p5,
    input  wire [PIXEL_WIDTH-1:0] p6, p7, p8,

    // Kernel Coefficients (Signed 8-bit Integer)
    input  wire signed [COEFF_WIDTH-1:0] k0, k1, k2,
    input  wire signed [COEFF_WIDTH-1:0] k3, k4, k5,
    input  wire signed [COEFF_WIDTH-1:0] k6, k7, k8,

    // Raw Accumulator Output (20-bit Signed)
    output reg signed [ACC_WIDTH-1:0] mac_out
);

    localparam PROD_W = PIXEL_WIDTH + COEFF_WIDTH; // 16-bit
    localparam PAIR_W = PROD_W + 1;                // 17-bit

    //------------------------------------------------------------
    // Pipeline Valid Propagator (2-Cycle Latency)
    //------------------------------------------------------------
    reg vld_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            vld_stage1 <= 1'b0;
            mac_valid  <= 1'b0;
        end else begin
            vld_stage1 <= window_valid;
            mac_valid  <= vld_stage1;
        end
    end

    //------------------------------------------------------------
    // STAGE 0: Explicit Unsigned->Signed Extension & Multiplication
    //------------------------------------------------------------
    wire signed [PIXEL_WIDTH:0] p0_s = {1'b0, p0};
    wire signed [PIXEL_WIDTH:0] p1_s = {1'b0, p1};
    wire signed [PIXEL_WIDTH:0] p2_s = {1'b0, p2};
    wire signed [PIXEL_WIDTH:0] p3_s = {1'b0, p3};
    wire signed [PIXEL_WIDTH:0] p4_s = {1'b0, p4};
    wire signed [PIXEL_WIDTH:0] p5_s = {1'b0, p5};
    wire signed [PIXEL_WIDTH:0] p6_s = {1'b0, p6};
    wire signed [PIXEL_WIDTH:0] p7_s = {1'b0, p7};
    wire signed [PIXEL_WIDTH:0] p8_s = {1'b0, p8};

    wire signed [PROD_W-1:0] prod0 = p0_s * k0;
    wire signed [PROD_W-1:0] prod1 = p1_s * k1;
    wire signed [PROD_W-1:0] prod2 = p2_s * k2;
    wire signed [PROD_W-1:0] prod3 = p3_s * k3;
    wire signed [PROD_W-1:0] prod4 = p4_s * k4;
    wire signed [PROD_W-1:0] prod5 = p5_s * k5;
    wire signed [PROD_W-1:0] prod6 = p6_s * k6;
    wire signed [PROD_W-1:0] prod7 = p7_s * k7;
    wire signed [PROD_W-1:0] prod8 = p8_s * k8;

    //------------------------------------------------------------
    // STAGE 1: Explicit 17-bit Pair Sum Registers
    //------------------------------------------------------------
    reg signed [PAIR_W-1:0] s0; // prod0 + prod1
    reg signed [PAIR_W-1:0] s1; // prod2 + prod3
    reg signed [PAIR_W-1:0] s2; // prod4 + prod5
    reg signed [PAIR_W-1:0] s3; // prod6 + prod7
    reg signed [PAIR_W-1:0] s4; // prod8 (sign-extended to 17-bit)

    always @(posedge clk) begin
        if (rst) begin
            s0 <= 0; s1 <= 0; s2 <= 0; s3 <= 0; s4 <= 0;
        end else if (window_valid) begin
            s0 <= prod0 + prod1;
            s1 <= prod2 + prod3;
            s2 <= prod4 + prod5;
            s3 <= prod6 + prod7;
            s4 <= $signed({{1{prod8[PROD_W-1]}}, prod8});
        end
    end

    //------------------------------------------------------------
    // STAGE 2: Final 20-bit Signed Accumulation
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            mac_out <= 0;
        end else if (vld_stage1) begin
            mac_out <= $signed({{ACC_WIDTH-PAIR_W{s0[PAIR_W-1]}}, s0}) +
                       $signed({{ACC_WIDTH-PAIR_W{s1[PAIR_W-1]}}, s1}) +
                       $signed({{ACC_WIDTH-PAIR_W{s2[PAIR_W-1]}}, s2}) +
                       $signed({{ACC_WIDTH-PAIR_W{s3[PAIR_W-1]}}, s3}) +
                       $signed({{ACC_WIDTH-PAIR_W{s4[PAIR_W-1]}}, s4});
        end
    end

endmodule

