`timescale 1ns / 1ps
// ============================================================
// AXI-Stream Stereo IIR Biquad Wrapper
// ------------------------------------------------------------
// - Stereo processing (L/R identical coefficients)
// - AXI4-Stream data interface
// - AXI4-Lite control & coefficient registers
// - Fixed-point Q1.15 internal core
//
// Latency:
//   - Core latency        : 1 cycle
//   - AXI wrapper latency : 0 additional cycles
// ============================================================

module iir_biquad_axis #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    parameter integer DATA_WIDTH         = 32   // Stereo: [31:16]=L, [15:0]=R
)(
    // --------------------------------------------------------
    // Global Clock & Reset
    // --------------------------------------------------------
    input  wire aclk,
    input  wire aresetn,   // Active-low reset

    // --------------------------------------------------------
    // AXI4-Stream Slave (Input)
    // --------------------------------------------------------
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire                  s_axis_tlast,

    // --------------------------------------------------------
    // AXI4-Stream Master (Output)
    // --------------------------------------------------------
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast,

    // --------------------------------------------------------
    // AXI4-Lite Slave (Control)
    // --------------------------------------------------------
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                          s_axi_awvalid,
    output wire                          s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output wire                          s_axi_wready,
    output wire [1:0]                    s_axi_bresp,
    output wire                          s_axi_bvalid,
    input  wire                          s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                          s_axi_arvalid,
    output wire                          s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0]                    s_axi_rresp,
    output wire                          s_axi_rvalid,
    input  wire                          s_axi_rready
);

    // ========================================================
    // 1. Register Map (AXI-Lite)
    // ========================================================
    // 0x00 : CTRL   [0]=Enable, [1]=Soft Reset
    // 0x04 : b0
    // 0x08 : b1
    // 0x0C : b2
    // 0x10 : a1
    // 0x14 : a2
    // ========================================================

    reg [31:0] reg_ctrl;
    reg [31:0] reg_b0;
    reg [31:0] reg_b1;
    reg [31:0] reg_b2;
    reg [31:0] reg_a1;
    reg [31:0] reg_a2;

    // --------------------------------------------------------
    // AXI-Lite internal signals
    // --------------------------------------------------------
    reg        axi_awready;
    reg        axi_wready;
    reg [1:0]  axi_bresp;
    reg        axi_bvalid;
    reg        axi_arready;
    reg [31:0] axi_rdata;
    reg        axi_rvalid;
    reg        aw_en;

    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = axi_rvalid;

    // ========================================================
    // 2. AXI-Lite Write Channel
    // ========================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= 2'b00;
            aw_en       <= 1'b1;

            reg_ctrl <= 32'h0000_0001; // Enable = 1
            reg_b0   <= 32'd0;
            reg_b1   <= 32'd0;
            reg_b2   <= 32'd0;
            reg_a1   <= 32'd0;
            reg_a2   <= 32'd0;
        end else begin
            // Address handshake
            axi_awready <= (~axi_awready && s_axi_awvalid && aw_en);
            axi_wready  <= (~axi_wready  && s_axi_wvalid  && aw_en);

            // Write transaction
            if (axi_awready && s_axi_awvalid &&
                axi_wready  && s_axi_wvalid &&
                ~axi_bvalid) begin

                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00;
                aw_en      <= 1'b0;

                case (s_axi_awaddr[4:2])
                    3'h0: reg_ctrl <= s_axi_wdata;
                    3'h1: reg_b0   <= s_axi_wdata;
                    3'h2: reg_b1   <= s_axi_wdata;
                    3'h3: reg_b2   <= s_axi_wdata;
                    3'h4: reg_a1   <= s_axi_wdata;
                    3'h5: reg_a2   <= s_axi_wdata;
                    default: ;
                endcase
            end
            else if (axi_bvalid && s_axi_bready) begin
                axi_bvalid <= 1'b0;
                aw_en      <= 1'b1;
            end
        end
    end

    // ========================================================
    // 3. AXI-Lite Read Channel
    // ========================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rdata   <= 32'd0;
        end else begin
            axi_arready <= (~axi_arready && s_axi_arvalid);

            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                case (s_axi_araddr[4:2])
                    3'h0: axi_rdata <= reg_ctrl;
                    3'h1: axi_rdata <= reg_b0;
                    3'h2: axi_rdata <= reg_b1;
                    3'h3: axi_rdata <= reg_b2;
                    3'h4: axi_rdata <= reg_a1;
                    3'h5: axi_rdata <= reg_a2;
                    default: axi_rdata <= 32'd0;
                endcase
            end
            else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // ========================================================
    // 4. Control & Handshake Logic
    // ========================================================
    wire core_enable;
    wire core_reset;

    assign core_enable = reg_ctrl[0];
    assign core_reset  = ~aresetn | reg_ctrl[1];

    wire axis_fire;
    assign axis_fire = s_axis_tvalid && s_axis_tready;

    assign s_axis_tready = (m_axis_tready || !m_axis_tvalid) && core_enable;

    // ========================================================
    // 5. Biquad Core Instances (Stereo)
    // ========================================================
    wire signed [15:0] x_l = s_axis_tdata[31:16];
    wire signed [15:0] x_r = s_axis_tdata[15:0];

    wire signed [15:0] y_l;
    wire signed [15:0] y_r;

    iir_biquad_core_16 inst_left (
        .clk   (aclk),
        .rst   (core_reset),
        .en    (axis_fire && core_enable),
        .x_in  (x_l),
        .y_out (y_l),
        .b0    (reg_b0[15:0]),
        .b1    (reg_b1[15:0]),
        .b2    (reg_b2[15:0]),
        .a1    (reg_a1[15:0]),
        .a2    (reg_a2[15:0])
    );

    iir_biquad_core_16 inst_right (
        .clk   (aclk),
        .rst   (core_reset),
        .en    (axis_fire && core_enable),
        .x_in  (x_r),
        .y_out (y_r),
        .b0    (reg_b0[15:0]),
        .b1    (reg_b1[15:0]),
        .b2    (reg_b2[15:0]),
        .a1    (reg_a1[15:0]),
        .a2    (reg_a2[15:0])
    );

    // ========================================================
    // 6. AXI-Stream Output Register
    // ========================================================
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (m_axis_tready || !m_axis_tvalid) begin
            m_axis_tvalid <= axis_fire && core_enable;
            m_axis_tlast  <= s_axis_tlast;
        end
    end

    assign m_axis_tdata = {y_l, y_r};

endmodule
