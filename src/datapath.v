`timescale 1ns / 1ps
//FILE: datapath.v
module datapath(
    input clk,
    input alu_en,
    input [3:0] alu_opcode,
    input [7:0] imm_value,
    input [3:0] write_addr, ra_addr, rb_addr,
    input write_en,
    input imm_flag,
    output [7:0] read_a, read_b,
    output alu_zero, alu_carry,
    output [7:0] jump_target
    );
    wire [7:0] ra_data, rb_data; //output data of regs.
    wire [7:0] alu_out;
    wire [7:0] write_data;
    wire [7:0] rb_data_mux;
    
    ALU alu (
        .a(ra_data),
        .b(rb_data_mux),
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
    assign write_data = alu_en ? alu_out : imm_value; //Chooses whether to write from the ALU or from the user
    assign read_a = (ra_addr == 0) ? 8'b0 : (write_en && ra_addr == write_addr) ? write_data : ra_data;
    assign read_b = (rb_addr == 0) ? 8'b0 : (write_en && rb_addr == write_addr) ? write_data : rb_data;
    assign rb_data_mux = (imm_flag == 1) ? imm_value : rb_data;
    assign jump_target = alu_out;
endmodule
