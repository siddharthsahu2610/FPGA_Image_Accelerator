`timescale 1ns/1ps

module image_accelerator_top #(
    parameter PDATA      = 8,
    parameter IMG_WIDTH  = 640,
    parameter IMG_HEIGHT = 480,
    parameter SHIFT      = 0
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 pixel_valid,
    input  wire [PDATA-1:0]     pixel_in,

    // 9 Signed Kernel Coefficients
    input  wire signed [7:0]    k0, k1, k2,
    input  wire signed [7:0]    k3, k4, k5,
    input  wire signed [7:0]    k6, k7, k8,

    output wire                 valid_out,
    output wire [PDATA-1:0]     pixel_out
);

    // Internal Window Signals
    wire [PDATA-1:0] w00, w01, w02;
    wire [PDATA-1:0] w10, w11, w12;
    wire [PDATA-1:0] w20, w21, w22;
    wire             window_valid;
    wire             mac_valid;
    wire signed [19:0] mac_sum;

    // 1. Instantiation mapped to your exact window_generator parameters
    window_generator #(
        .WIDTH(IMG_WIDTH),
        .HEIGHT(IMG_HEIGHT),
        .PDATA(PDATA)
    ) u_window_gen (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_in(pixel_in),
        .window_valid(window_valid),
        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22)
    );

    // 2. 9-DSP Parallel MAC Engine
    mac_engine u_mac (
        .clk(clk),
        .rst(rst),
        .window_valid(window_valid),
        .p0(w00), .p1(w01), .p2(w02),
        .p3(w10), .p4(w11), .p5(w12),
        .p6(w20), .p7(w21), .p8(w22),
        .k0(k0), .k1(k1), .k2(k2),
        .k3(k3), .k4(k4), .k5(k5),
        .k6(k6), .k7(k7), .k8(k8),
        .mac_valid(mac_valid),
        .mac_out(mac_sum)
    );

    // 3. Output Saturation & Dynamic Range Scaling
    saturation #(
        .IN_WIDTH(20),
        .OUT_WIDTH(PDATA),
        .SHIFT(SHIFT)
    ) u_sat (
        .sum_in(mac_sum),
        .pixel_out(pixel_out)
    );

    assign valid_out = mac_valid;

endmodule

