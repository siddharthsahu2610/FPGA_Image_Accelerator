`timescale 1ns/1ps

module skid_buffer #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Slave Interface
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,

    // Master Interface
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire [DATA_WIDTH-1:0] m_axis_tdata
);

    reg                  reg_valid;
    reg [DATA_WIDTH-1:0] reg_data;
    reg                  skid_valid;
    reg [DATA_WIDTH-1:0] skid_data;

    assign s_axis_tready = !skid_valid;
    assign m_axis_tvalid = reg_valid;
    assign m_axis_tdata  = reg_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_valid  <= 1'b0;
            reg_data   <= {DATA_WIDTH{1'b0}};
            skid_valid <= 1'b0;
            skid_data  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                if (m_axis_tvalid && !m_axis_tready) begin
                    skid_valid <= 1'b1;
                    skid_data  <= s_axis_tdata;
                end else begin
                    reg_valid  <= 1'b1;
                    reg_data   <= s_axis_tdata;
                end
            end else if (m_axis_tready) begin
                if (skid_valid) begin
                    reg_valid  <= 1'b1;
                    reg_data   <= skid_data;
                    skid_valid <= 1'b0;
                end else begin
                    reg_valid  <= 1'b0;
                end
            end
        end
    end

endmodule
