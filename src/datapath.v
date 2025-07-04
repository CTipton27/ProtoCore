`timescale 1ns / 1ps
//FILE: datapath.v
module datapath(
    input clk,
    input write_alu,
    input [3:0] alu_opcode,
    input [7:0] top_data,
    input [3:0] write_addr, ra_addr, rb_addr,
    input write_en,
    input imm_flag,
    output [7:0] read_a, read_b,
    output alu_zero, alu_carry,
    output [7:0] alu_out
    );
    wire [7:0] ra_data, rb_data; //output data of regs.
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
    assign write_data = write_alu ? alu_out : top_data; //Chooses whether to write to regs from the ALU or from top module
    assign read_a = (ra_addr == 0) ? 8'b0 : (write_en && ra_addr == write_addr) ? write_data : ra_data;
    assign read_b = (rb_addr == 0) ? 8'b0 : (write_en && rb_addr == write_addr) ? write_data : rb_data;
    assign rb_data_mux = (imm_flag == 1) ? top_data : rb_data;
endmodule
