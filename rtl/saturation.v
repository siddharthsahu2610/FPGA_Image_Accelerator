`timescale 1ns/1ps

module saturation #(
    parameter IN_WIDTH  = 20,
    parameter OUT_WIDTH = 8,
    parameter SHIFT     = 0
)(
    input  wire signed [IN_WIDTH-1:0] sum_in,
    output reg        [OUT_WIDTH-1:0] pixel_out
);

    //------------------------------------------------------------
    // Maximum representable output value
    //------------------------------------------------------------

    localparam [OUT_WIDTH-1:0] MAX_VALUE_OUT =
        {OUT_WIDTH{1'b1}};

    //------------------------------------------------------------
    // Same maximum value extended to accumulator width
    //------------------------------------------------------------

    localparam signed [IN_WIDTH-1:0] MAX_VALUE_IN =
        (1 << OUT_WIDTH) - 1;

    //------------------------------------------------------------
    // Normalization
    //
    // Arithmetic right shift preserves the sign.
    //
    // SHIFT = 0 → no scaling
    // SHIFT = 1 → divide by 2
    // SHIFT = 3 → divide by 8
    // SHIFT = 4 → divide by 16
    //------------------------------------------------------------

    wire signed [IN_WIDTH-1:0] scaled_sum =
        sum_in >>> SHIFT;

    //------------------------------------------------------------
    // Saturation logic
    //------------------------------------------------------------

    always @(*) begin

        //--------------------------------------------------------
        // Underflow
        //--------------------------------------------------------

        if (scaled_sum < 0) begin

            pixel_out = {OUT_WIDTH{1'b0}};

        end

        //--------------------------------------------------------
        // Overflow
        //--------------------------------------------------------

        else if (scaled_sum > MAX_VALUE_IN) begin

            pixel_out = MAX_VALUE_OUT;

        end

        //--------------------------------------------------------
        // Valid 8-bit range
        //--------------------------------------------------------

        else begin

            pixel_out = scaled_sum[OUT_WIDTH-1:0];

        end

    end

endmodule

