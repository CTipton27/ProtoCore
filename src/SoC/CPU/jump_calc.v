`timescale 1ns / 1ps
//FILE: jump_calc.v

module jump_calc(
    input [7:0] reg_data,
    input [7:0] imm,
    
    output [7:0] jump_target
    );
    
    assign jump_target = reg_data + imm;
    
endmodule
