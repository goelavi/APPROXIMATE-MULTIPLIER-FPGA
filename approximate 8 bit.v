`timescale 1ns / 1ps

module Approx_8x8_multi_M1(
    input  [7:0] A,
    input  [7:0] B,
    output [15:0] P
    );

    wire [7:0] PP0, PP1, PP2, PP3;

    Approx_4x4_encode_multiplier_M1 AMx1 (.A(A[3:0]), .B(B[3:0]), .P(PP0));
    Approx_4x4_encode_multiplier_M1 AMx2 (.A(A[7:4]), .B(B[3:0]), .P(PP1));
    Approx_4x4_encode_multiplier_M1 AMx3 (.A(A[3:0]), .B(B[7:4]), .P(PP2));
    Approx_4x4_encode_multiplier_M1 AMx4 (.A(A[7:4]), .B(B[7:4]), .P(PP3));

    assign P = {8'b0, {PP0}} +
               {4'b0, {PP1}, 4'b0} +
               {4'b0, {PP2}, 4'b0} +
               {{PP3}, 8'b0};

endmodule
