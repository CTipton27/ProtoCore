`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Conner Tipton
// 
// Create Date: 06/11/2025 04:19:32 PM
// Design Name: 8-Bit ALU
// Project Name: RISC Core
//////////////////////////////////////////////////////////////////////////////////

/*
000 : add
001 : sub
010 : and
011 : or
100 : xor
101 : not(a)
110 : shl(a)
111 : shr(a)

*/
module ALU(
    input [7:0] a,
    input [7:0] b,
    input [2:0] opcode,
    output reg [7:0] out,
    output reg zero,
    output reg carry
    );
    always @ (*) begin
        case (opcode)
            3'd0: {carry, out} = a + b;     //add
            3'd1: {carry, out} = a - b;     //sub
            3'd2: out = a & b;              //and
            3'd3: out = a | b;              //or
            3'd4: out = a ^ b;              //xor
            3'd5: out = ~a;                   //not(a)
            3'd6: out = {a[6:0], 1'b0};       //shl(a)
            3'd7: out = {1'b0, a[7:1]};       //shr(a)
            default: out = "00000000";
        endcase
        zero = (out == 8'b0);
    end
endmodule
