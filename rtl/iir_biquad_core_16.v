`timescale 1ns / 1ps
// ============================================================
// IIR Biquad Core (Mono, Fixed-Point)
// ------------------------------------------------------------
// Data format:
//   Input  x[n]   : Q1.15 (signed 16-bit)
//   Coeff  b*, a* : Q1.15 (signed 16-bit)
//   Accumulator  : Q2.30 (internal)
//   Output y[n]  : Q1.15 (saturated)
//
// Difference equation:
//   y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2]
//          - a1*y[n-1] - a2*y[n-2]
//
// Fixed latency: 1 clock cycle (when en = 1)
// ============================================================

module iir_biquad_core_16 #(
    parameter integer ACC_W = 64
)(
    input  wire clk,
    input  wire rst,
    input  wire en,

    input  wire signed [15:0] x_in,
    output reg  signed [15:0] y_out,

    input  wire signed [15:0] b0,
    input  wire signed [15:0] b1,
    input  wire signed [15:0] b2,
    input  wire signed [15:0] a1,
    input  wire signed [15:0] a2
);

    // --------------------------------------------------------
    // State registers (Q1.15)
    // --------------------------------------------------------
    reg signed [15:0] x1, x2;
    reg signed [15:0] y1, y2;

    // --------------------------------------------------------
    // Internal signals
    // --------------------------------------------------------
    reg signed [ACC_W-1:0] acc;
    reg signed [15:0]      y_next;

    // --------------------------------------------------------
    // Sequential process
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            x1    <= 16'sd0;
            x2    <= 16'sd0;
            y1    <= 16'sd0;
            y2    <= 16'sd0;
            y_out <= 16'sd0;
        end
        else if (en) begin
            // --------------------------------------------
            // Accumulation (Q2.30 result)
            // --------------------------------------------
            acc =  $signed(x_in) * b0
                 + $signed(x1)   * b1
                 + $signed(x2)   * b2
                 - $signed(y1)   * a1
                 - $signed(y2)   * a2;

            // --------------------------------------------
            // Q2.30 -> Q1.15 conversion with saturation
            // --------------------------------------------
            if ((acc >>> 15) >  32767)
                y_next =  16'sd32767;
            else if ((acc >>> 15) < -32768)
                y_next = -16'sd32768;
            else
                y_next = acc[30:15];

            // --------------------------------------------
            // Output register
            // --------------------------------------------
            y_out <= y_next;

            // --------------------------------------------
            // State update
            // --------------------------------------------
            x2 <= x1;
            x1 <= x_in;

            y2 <= y1;

            // Light damping to suppress limit cycles
            y1 <= y_next - (y_next >>> 10);
        end
    end

endmodule
