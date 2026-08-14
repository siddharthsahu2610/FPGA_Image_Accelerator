`timescale 1ns/1ps

module sobel_accelerator_top #(
    parameter integer DATA_WIDTH = 8,
    parameter integer IMG_WIDTH  = 128,
    parameter integer IMG_HEIGHT = 128
)(
    input  wire                   clk,
    input  wire                   rst,

    // Input pixel stream
    input  wire                   s_axis_valid,
    input  wire [DATA_WIDTH-1:0]  s_axis_data,

    // Output processed pixel stream
    output wire                   m_axis_valid,
    output wire [DATA_WIDTH-1:0]  m_axis_data
);

    // =========================================================
    // 1. 3x3 WINDOW GENERATOR
    // =========================================================

    wire                   window_valid;

    wire [DATA_WIDTH-1:0] w00;
    wire [DATA_WIDTH-1:0] w01;
    wire [DATA_WIDTH-1:0] w02;

    wire [DATA_WIDTH-1:0] w10;
    wire [DATA_WIDTH-1:0] w11;
    wire [DATA_WIDTH-1:0] w12;

    wire [DATA_WIDTH-1:0] w20;
    wire [DATA_WIDTH-1:0] w21;
    wire [DATA_WIDTH-1:0] w22;

    window_generator #(
        .WIDTH  (IMG_WIDTH),
        .HEIGHT (IMG_HEIGHT),
        .PDATA  (DATA_WIDTH)
    ) u_window_gen (
        .clk         (clk),
        .rst         (rst),

        .pixel_valid (s_axis_valid),
        .pixel_in    (s_axis_data),

        .window_valid(window_valid),

        .w00(w00), .w01(w01), .w02(w02),
        .w10(w10), .w11(w11), .w12(w12),
        .w20(w20), .w21(w21), .w22(w22)
    );


    // =========================================================
    // 2. SOBEL-X MAC ENGINE
    //
    // Kernel:
    //
    //     -1   0  +1
    //     -2   0  +2
    //     -1   0  +1
    //
    // =========================================================

    wire                   mac_valid;
    wire signed [19:0]    mac_out;

    mac_engine #(
        .PIXEL_WIDTH (DATA_WIDTH),
        .COEFF_WIDTH (8),
        .ACC_WIDTH   (20)
    ) u_mac (
        .clk         (clk),
        .rst         (rst),

        .window_valid(window_valid),

        .mac_valid   (mac_valid),

        // 3x3 window
        .p0(w00), .p1(w01), .p2(w02),
        .p3(w10), .p4(w11), .p5(w12),
        .p6(w20), .p7(w21), .p8(w22),

        // Sobel-X coefficients
        .k0(-8'sd1), .k1( 8'sd0), .k2( 8'sd1),
        .k3(-8'sd2), .k4( 8'sd0), .k5( 8'sd2),
        .k6(-8'sd1), .k7( 8'sd0), .k8( 8'sd1),

        .mac_out(mac_out)
    );


    // =========================================================
    // 3. SATURATION / OUTPUT QUANTIZATION
    //
    // Signed 20-bit MAC result
    //          ↓
    // Negative  → 0
    // >255      → 255
    // 0..255    → unchanged
    //
    // SHIFT = 0 for Sobel-X
    // =========================================================

    wire [DATA_WIDTH-1:0] saturated_pixel;

    saturation #(
        .IN_WIDTH  (20),
        .OUT_WIDTH (DATA_WIDTH),
        .SHIFT     (0)
    ) u_saturation (
        .sum_in    (mac_out),
        .pixel_out (saturated_pixel)
    );


    // =========================================================
    // 4. OUTPUT STREAM
    //
    // MAC valid already contains the 2-cycle pipeline latency.
    // Therefore the saturation result is associated with mac_valid.
    // =========================================================

    assign m_axis_valid = mac_valid;
    assign m_axis_data  = saturated_pixel;

endmodule

