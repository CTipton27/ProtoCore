`timescale 1ns / 1ps
//FILE: datapath.v
module datapath(
    input clk,
    input alu_en,
    input [3:0] alu_opcode,
    input [7:0] user_write_data,
    input [3:0] write_addr, ra_addr, rb_addr,
    input write_en,
    output [7:0] read_a, read_b,
    output alu_zero, alu_carry
    );
    wire [7:0] ra_data, rb_data;
    wire [7:0] alu_out;
    wire [7:0] write_data;
    
    ALU alu (
        .a(ra_data),
        .b(rb_data),
        .opcode(alu_opcode),
        .out(alu_out),
        .zero(alu_zero),
        .carry(alu_carry)
    );
    
    reg_file regfile (
        .clk(clk),
        .ra(ra_addr),
        .rb(rb_addr),
        .wa(write_addr),
        .wd(write_data),
        .we(write_en),
        .read_a(ra_data),
        .read_b(rb_data)
    );
    assign write_data = alu_en ? alu_out : user_write_data;
    assign read_a = (write_en && ra_addr == write_addr) ? write_data : ra_data;
    assign read_b = (write_en && rb_addr == write_addr) ? write_data : rb_data;
endmodule
