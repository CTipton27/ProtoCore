`timescale 1ns / 1ps
//FILE: instruction_decode.v

module instruction_decode(
    input [23:0] instruction,
    output rst,
    output alu_en,
    output [3:0] alu_opcode,
    output [7:0] user_write_data,
    output [3:0] write_addr, ra_addr, rb_addr,
    output write_en
    );
    wire [3:0] opcode, ra, rb, rd, data;
    
    
endmodule
