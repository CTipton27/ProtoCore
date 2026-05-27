`timescale 1ns / 1ps
//FILE: datapath.v
module datapath(
    input clk,
    
    input alu_src_immediate,
    input [2:0] alu_opcode,
    
    input [7:0] mem_data,
    input [7:0] imm_data,
    
    input reg_write_enable,
    input mem_to_reg,
    input [3:0] rd_addr,
    input [3:0] ra_addr,
    input [3:0] rb_addr,
    output [7:0] reg_a_data,
    output [7:0] reg_b_data,
    
    output [7:0] alu_out,
    output alu_zero,
    output alu_carry
    );
    
    wire [7:0] read_a, read_b, reg_write_data;
    
    wire [7:0] alu_data_b;
    
    alu alu(
        .a(read_a),
        .b(alu_data_b),
        .opcode(alu_opcode),
        .out(alu_out),
        .zero(alu_zero),
        .carry(alu_carry)
    );
    
    reg_file reg_file (
        .clk(clk),
        .write_enable(reg_write_enable),
        .write_addr(rd_addr),
        .write_data(reg_write_data),
        .read_addr_a(ra_addr),
        .read_addr_b(rb_addr),
        .read_data_a(read_a),
        .read_data_b(read_b)
    );
    
    assign alu_data_b = alu_src_immediate ? imm_data : read_b;
    assign reg_write_data = mem_to_reg ? mem_data : alu_out;
    assign reg_a_data = read_a;
    assign reg_b_data = read_b;
    
endmodule
