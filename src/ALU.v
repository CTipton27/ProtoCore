`timescale 1ns / 1ps
//FILE: ALU.v
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
        carry = 0;
        out = 8'b0;
        case (opcode)
            3'd0: {carry, out} = a + b;     //add
            3'd1: out = a - b;              //sub
            3'd2: out = a & b;              //and
            3'd3: out = a | b;              //or
            3'd4: out = a ^ b;              //xor
            3'd5: out = ~a;                 //not(a)
            3'd6: out = a<<1;               //shl(a)
            3'd7: out = a>>1;               //shr(a)
            default: out = 8'b0;
        endcase
        zero = (out == 8'b0);
    end
endmodule
