`timescale 1ns / 1ps
module mul_2x2 (
    input clk,
    input signed [63:0] a,  
    input signed [63:0] b,  
    output reg signed [127:0] c 
);

    wire signed [15:0] a00 = a[15:0];
    wire signed [15:0] a01 = a[31:16];
    wire signed [15:0] a10 = a[47:32];
    wire signed [15:0] a11 = a[63:48];
    wire signed [15:0] b00 = b[15:0];
    wire signed [15:0] b01 = b[31:16];
    wire signed [15:0] b10 = b[47:32];
    wire signed [15:0] b11 = b[63:48];

    always @(negedge clk) begin
        c[31:0]   <= (a00 * b00) + (a01 * b10);
        c[63:32]  <= (a00 * b01) + (a01 * b11);
        c[95:64]  <= (a10 * b00) + (a11 * b10);
        c[127:96] <= (a10 * b01) + (a11 * b11);
    end
endmodule



