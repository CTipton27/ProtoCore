`timescale 1ns / 1ps


module ALU_TB();
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] opcode;
    wire carry;
    wire zero;
    wire [7:0] out;

     ALU DUT(
        .a(a), 
        .b(b), 
        .out(out), 
        .opcode(opcode), 
        .carry(carry), 
        .zero(zero)
        );

endmodule
