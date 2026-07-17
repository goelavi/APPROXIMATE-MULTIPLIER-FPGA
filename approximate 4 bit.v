`timescale 1ns / 1ps

module Approx_4x4_encode_multiplier_M1(
    input [3:0] A,
    input [3:0] B,
    output [7:0] P
);

wire [3:0] PP0, PP1, PP2, PP3;
wire c1, c2, c3, c4, c5, c6;
wire P2_0, P2_1, P3_0, P3_1;
wire G2_0, G2_1, G3_0, G3_1;

assign PP0 = A & {4{B[0]}};
assign PP1 = A & {4{B[1]}};
assign PP2 = A & {4{B[2]}};
assign PP3 = A & {4{B[3]}};

assign P[0] = PP0[0];

HA HAx1 (.X1(PP0[1]),.X2(PP1[0]),.sum(P[1]),.cout(c1));

assign P2_0 = PP0[2] | PP2[0];
assign G2_0 = PP0[2] & PP2[0];

assign P[2] = P2_0 | PP1[1];
assign c2 = G2_0 | c1;

assign P2_1 = PP1[2] | PP2[1];
assign P3_0 = PP0[3] | PP3[0];
assign G2_1 = PP1[2] & PP2[1];
assign G3_0 = PP0[3] & PP3[0];

assign P[3] = ~c2 | P2_1 | P3_0;
assign c3   = (c2 & (G3_0 | G2_1)) | (P2_1 & P3_0);

assign P3_1 = PP1[3] | PP3[1];
assign G3_1 = PP1[3] & PP3[1];

assign P[4] = P3_1 | G3_1 | PP2[2];
assign c4   = G3_1 | PP2[2] & c3;

FA FAx1 (.X1(PP2[3]), .X2(PP3[2]), .cin(c4),
                 .sum(P[5]), .cout(c5));

HA HAx2 (.X1(PP3[3]), .X2(c5),
                 .sum(P[6]), .cout(c6));

assign P[7] = c6;

endmodule

