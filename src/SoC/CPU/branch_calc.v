`timescale 1ns / 1ps
//FILE: branch_calc.v

module branch_calc(
    input [7:0] pc_addr,
    input [7:0] imm,
    
    output [7:0] branch_target
    );
    
    assign branch_target = pc_addr + 1 + imm;
    
endmodule
