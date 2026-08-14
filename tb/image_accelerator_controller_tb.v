`timescale 1ns/1ps

module image_accelerator_controller_tb;

    parameter DATA_WIDTH = 8;
    parameter IMG_WIDTH  = 288;
    parameter IMG_HEIGHT = 2;

    reg clk;
    reg rst_n;

    // ---------------------------------------------------------
    // AXI4-Stream Input
    // ---------------------------------------------------------

    reg                  s_axis_tvalid;
    wire                 s_axis_tready;
    reg [DATA_WIDTH-1:0] s_axis_tdata;

    // ---------------------------------------------------------
    // AXI4-Stream Output
    // ---------------------------------------------------------

    wire                 m_axis_tvalid;
    reg                  m_axis_tready;
    wire [DATA_WIDTH-1:0] m_axis_tdata;

    // ---------------------------------------------------------
    // Status
    // ---------------------------------------------------------

    wire [15:0] col_cnt;
    wire [15:0] row_cnt;
    wire        frame_done;

    integer errors;
    integer accepted_inputs;
    integer accepted_outputs;

    reg [15:0] exp_col;
    reg [15:0] exp_row;

    // ---------------------------------------------------------
    // DUT Instance
    // ---------------------------------------------------------

    image_accelerator_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),

        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),

        .col_cnt(col_cnt),
        .row_cnt(row_cnt),
        .frame_done(frame_done)
    );

    // ---------------------------------------------------------
    // Clock Generation (100 MHz)
    // ---------------------------------------------------------

    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // VCD Waveform Tracing
    // ---------------------------------------------------------

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, image_accelerator_controller_tb);
    end

    // ---------------------------------------------------------
    // Synchronous Pure Reference Function
    // ---------------------------------------------------------

    function [7:0] expected_data(input [15:0] row, input [15:0] col);
        begin
            expected_data = 8'((row + col) & 16'h00FF);
        end
    endfunction

    // ---------------------------------------------------------
    // Input Driver (Using Blocking '=' inside initial block)
    // ---------------------------------------------------------

    reg [15:0] r;
    reg [15:0] c;

    initial begin
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata  = 0;
        m_axis_tready = 1;

        errors = 0;
        accepted_inputs = 0;
        accepted_outputs = 0;

        // Reset Sequence
        repeat (4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("==================================================");
        $display("STARTING SYNCHRONOUS AXI4-STREAM TEST");
        $display("==================================================");

        for (r = 0; r < IMG_HEIGHT; r = r + 1) begin
            for (c = 0; c < IMG_WIDTH; c = c + 1) begin
                
                // Assert valid and present data using blocking '='
                s_axis_tvalid = 1'b1;
                s_axis_tdata  = expected_data(r, c);

                // Wait until handshake completes on posedge clk
                do begin
                    @(posedge clk);
                end while (!s_axis_tready);

                accepted_inputs = accepted_inputs + 1;
                s_axis_tvalid  = 1'b0;
            end
        end

        // Deassert upstream valid after transfer completes
        s_axis_tvalid = 1'b0;

        // Allow output pipeline & skid buffer to drain
        repeat (100) @(posedge clk);

        // Print Summary Report
        $display("==================================================");
        $display("AXI4-STREAM TEST SUMMARY");
        $display("  Input Pixels Accepted  : %0d", accepted_inputs);
        $display("  Output Pixels Accepted : %0d", accepted_outputs);
        $display("  Total Errors           : %0d", errors);

        if (errors == 0 && accepted_inputs == (IMG_WIDTH * IMG_HEIGHT)) begin
            $display("  STATUS: PASS");
        end else begin
            $display("  STATUS: FAIL");
        end
        $display("==================================================");

        $finish;
    end

    // ---------------------------------------------------------
    // Downstream Backpressure Generator & Output Checker
    // ---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_col       <= 0;
            exp_row       <= 0;
            m_axis_tready <= 1'b0;
        end else begin
            // Generate randomized backpressure on posedge
            m_axis_tready <= ($urandom_range(0, 9) < 8);

            // Synchronous check ONLY when handshake occurs
            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tdata !== expected_data(exp_row, exp_col)) begin
                    $display("[MISMATCH] Row %0d Col %0d | Expected: 0x%02h | Got: 0x%02h",
                             exp_row, exp_col, expected_data(exp_row, exp_col), m_axis_tdata);
                    errors = errors + 1;
                end

                accepted_outputs = accepted_outputs + 1;

                // Advance coordinate trackers
                if (exp_col == IMG_WIDTH - 1) begin
                    exp_col <= 0;
                    exp_row <= exp_row + 1;
                end else begin
                    exp_col <= exp_col + 1;
                end
            end
        end
    end

endmodule

