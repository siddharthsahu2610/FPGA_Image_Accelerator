module skid_buffer #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Upstream (Slave Interface)
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,

    // Downstream (Master Interface)
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire [DATA_WIDTH-1:0] m_axis_tdata
);

    reg [DATA_WIDTH-1:0] r_data;
    reg                  r_valid;

    reg [DATA_WIDTH-1:0] skid_data;
    reg                  skid_valid;

    // Upstream ready as long as the skid buffer is empty
    assign s_axis_tready = !skid_valid;

    // Downstream outputs ALWAYS read from the main output register
    assign m_axis_tvalid = r_valid;
    assign m_axis_tdata  = r_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_valid    <= 1'b0;
            skid_valid <= 1'b0;
            r_data     <= {DATA_WIDTH{1'b0}};
            skid_data  <= {DATA_WIDTH{1'b0}};
        end else begin

            // Case 1: Downstream accepts current byte (or output pipe is idle)
            if (m_axis_tready || !r_valid) begin
                if (skid_valid) begin
                    // Move skid data into the main output register
                    r_data     <= skid_data;
                    r_valid    <= 1'b1;
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        // Simultaneous upstream arrival: buffer into skid register
                        skid_data  <= s_axis_tdata;
                        skid_valid <= 1'b1;
                    end else begin
                        skid_valid <= 1'b0;
                    end
                end else if (s_axis_tvalid && s_axis_tready) begin
                    // Normal pass-through directly to main output register
                    r_data  <= s_axis_tdata;
                    r_valid <= 1'b1;
                end else begin
                    // No data available anywhere
                    r_valid <= 1'b0;
                end
            end 
            // Case 2: Downstream is STALLED (m_axis_tready == 0)
            else if (s_axis_tvalid && s_axis_tready) begin
                // Capture incoming overflow data into skid buffer
                skid_data  <= s_axis_tdata;
                skid_valid <= 1'b1;
            end

        end
    end

endmodule
