`timescale 1ns/1ps

module sobel_accelerator_top_tb (
    input wire clk,
    input wire rst_n
);

    parameter DATA_WIDTH       = 8;
    parameter IMG_WIDTH        = 288;
    parameter IMG_HEIGHT       = 2;
    parameter TOTAL_PIXELS     = IMG_WIDTH * IMG_HEIGHT;

    reg                  s_axis_tvalid;
    wire                 s_axis_tready;
    reg [DATA_WIDTH-1:0] s_axis_tdata;

    wire                 m_axis_tvalid;
    reg                  m_axis_tready;
    wire [DATA_WIDTH-1:0] m_axis_tdata;

    wire [15:0] col_cnt;
    wire [15:0] row_cnt;
    wire        frame_done;

    // Memory arrays for file I/O
    reg [DATA_WIDTH-1:0] input_mem  [0:TOTAL_PIXELS-1];
    reg [DATA_WIDTH-1:0] golden_mem [0:TOTAL_PIXELS-1];

    integer errors = 0;
    integer accepted_inputs = 0;
    integer accepted_outputs = 0;
    integer idx = 0;

    sobel_accelerator_top #(
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

    // Test Driver Sequence
    initial begin
        // Load Hex Files
        $readmemh("input_pixels.hex", input_mem);
        $readmemh("golden_output.hex", golden_mem);

        s_axis_tvalid = 0;
        s_axis_tdata  = 0;
        m_axis_tready = 1;

        @(posedge rst_n);
        @(posedge clk);

        $display("==================================================");
        $display("STARTING FILE-DRIVEN GOLDEN MODEL VERIFICATION");
        $display("==================================================");

        // Feed input stream from file memory
        for (idx = 0; idx < TOTAL_PIXELS; idx = idx + 1) begin
            s_axis_tvalid = 1'b1;
            s_axis_tdata  = input_mem[idx];

            @(posedge clk);
            while (!s_axis_tready) begin
                @(posedge clk);
            end

            accepted_inputs = accepted_inputs + 1;
            s_axis_tvalid = 1'b0;
        end

        s_axis_tvalid = 1'b0;

        // Dynamic Drain Loop
        while (!frame_done && (accepted_outputs < TOTAL_PIXELS)) begin
            @(posedge clk);
        end

        @(posedge clk);

        $display("==================================================");
        $display("GOLDEN MODEL VERIFICATION SUMMARY");
        $display("  Input Accepted   : %0d / %0d", accepted_inputs, TOTAL_PIXELS);
        $display("  Expected Outputs : %0d", TOTAL_PIXELS);
        $display("  Output Accepted  : %0d", accepted_outputs);
        $display("  Mismatches       : %0d", errors);
        $display("--------------------------------------------------");

        if (errors == 0 && 
            accepted_inputs == TOTAL_PIXELS && 
            accepted_outputs == TOTAL_PIXELS) begin
            $display("  STATUS: BIT-EXACT GOLDEN MATCH PASS 🟢");
        end else begin
            $display("  STATUS: GOLDEN MODEL MATCH FAIL 🔴");
        end
        $display("==================================================");

        $finish;
    end

    // Monitor Outputs and Compare with Python Golden Reference
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accepted_outputs <= 0;
            m_axis_tready    <= 1'b1;
        end else begin
            // 70% backpressure stall rate
            m_axis_tready <= ($urandom_range(0, 9) < 7);

            if (m_axis_tvalid && m_axis_tready) begin
                if (m_axis_tdata !== golden_mem[accepted_outputs]) begin
                    $display("[MISMATCH] Pixel %0d | Expected: 0x%02h | Got: 0x%02h",
                             accepted_outputs, golden_mem[accepted_outputs], m_axis_tdata);
                    errors = errors + 1;
                end
                accepted_outputs <= accepted_outputs + 1;
            end
        end
    end

endmodule
