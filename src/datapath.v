`timescale 1ns / 1ps

module datapath(
    input clk,
    input [3:0] alu_opcode,
    input [7:0] write_data,
    input [3:0] write_addr, ra_addr, rb_addr,
    input write_en,
    output [7:0] read_a, read_b,
    output alu_zero, alu_carry
    );
    wire [7:0] ra_data, rb_data;
    wire [7:0] alu_out;
    
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
    assign read_a = ra_data;
    assign read_b = rb_data;
endmodule
