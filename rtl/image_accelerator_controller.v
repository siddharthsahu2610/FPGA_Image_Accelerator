module image_accelerator_controller #(
    parameter DATA_WIDTH = 8,
    parameter IMG_WIDTH  = 288,
    parameter IMG_HEIGHT = 288
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Input AXI4-Stream
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,

    // Output AXI4-Stream
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire [DATA_WIDTH-1:0] m_axis_tdata,

    // Status Signals
    output reg [15:0]            col_cnt,
    output reg [15:0]            row_cnt,
    output wire                  frame_done
);

    wire                  skid_out_valid;
    wire                  skid_out_ready;
    wire [DATA_WIDTH-1:0] skid_out_data;

    // Instantiate Skid Buffer on input path
    skid_buffer #(
        .DATA_WIDTH(DATA_WIDTH)
    ) in_skid (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),
        .m_axis_tvalid(skid_out_valid),
        .m_axis_tready(skid_out_ready),
        .m_axis_tdata(skid_out_data)
    );

    // Pass Skid Buffer output directly to controller downstream
    assign skid_out_ready = m_axis_tready;
    assign m_axis_tvalid  = skid_out_valid;
    assign m_axis_tdata   = skid_out_data;

    // Handshake occurred
    wire transfer = skid_out_valid && skid_out_ready;

    // Boundary Control Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= 16'd0;
            row_cnt <= 16'd0;
        end else if (transfer) begin
            if (col_cnt == IMG_WIDTH - 1) begin
                col_cnt <= 16'd0;
                if (row_cnt == IMG_HEIGHT - 1) begin
                    row_cnt <= 16'd0;
                end else begin
                    row_cnt <= row_cnt + 1'b1;
                end
            end else begin
                col_cnt <= col_cnt + 1'b1;
            end
        end
    end

    assign frame_done = transfer && (col_cnt == IMG_WIDTH - 1) && (row_cnt == IMG_HEIGHT - 1);

endmodule

