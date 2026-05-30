`timescale 1ns / 1ps
// FILE: control_unit.v

module control_unit(
    input [23:0] instruction,

    input alu_zero,

    output reg reg_write_enable,
    output reg [3:0] rd_addr,
    output reg [3:0] ra_addr,
    output reg [3:0] rb_addr,

    output reg [2:0] alu_opcode,
    output reg alu_src_immediate,

    output reg data_write_enable,
    output reg is_load,

    output reg [1:0] pc_select, // 00:PC+1, 01:branch, 10:jump

    output reg halt_detect,

    output [7:0] imm_value
);

    wire [3:0] inst_opcode = instruction[23:20];
    wire [3:0] inst_ra     = instruction[19:16];
    wire [3:0] inst_rb     = instruction[15:12];
    wire [3:0] inst_rd     = instruction[11:8];

    assign imm_value = instruction[7:0];

    always @(*) begin
        reg_write_enable   = 1'b0;
        data_write_enable  = 1'b0;
        is_load            = 1'b0;
        alu_src_immediate  = 1'b0;
        alu_opcode         = 3'b000;
        pc_select          = 2'b00;
        halt_detect        = 1'b0;
        rd_addr            = 4'b0;
        ra_addr            = 4'b0;
        rb_addr            = 4'b0;

        case (inst_opcode)
            // Binary ALU
            4'h0, 4'h1, 4'h2, 4'h3, 4'h4: begin
                reg_write_enable = 1'b1;
                alu_opcode = inst_opcode[2:0];
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                rb_addr = inst_rb;
            end

            // Unary ALU
            4'h5, 4'h6, 4'h7: begin
                reg_write_enable = 1'b1;
                alu_opcode = inst_opcode[2:0];
                rd_addr = inst_rd;
                ra_addr = inst_ra;
            end

            // Immediate ALU
            4'h8, 4'h9: begin
                reg_write_enable = 1'b1;
                alu_opcode = {1'b0, inst_opcode[0], 1'b0};
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                alu_src_immediate = 1'b1;
            end

            // LOAD
            4'hA: begin
                reg_write_enable = 1'b1;
                is_load = 1'b1;
                alu_opcode = 3'b000;
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                alu_src_immediate = 1'b1;
            end

            // STORE
            4'hB: begin
                data_write_enable = 1'b1;
                alu_opcode = 3'b000;
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_src_immediate = 1'b1;
            end

            // BEQ
            4'hC: begin
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_opcode = 3'b001; // SUB
                pc_select = alu_zero ? 2'b01 : 2'b00;
            end

            // BNE
            4'hD: begin
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_opcode = 3'b001; // SUB
                pc_select = alu_zero ? 2'b00 : 2'b01;
            end

            // JMP
            4'hE: begin
                pc_select = 2'b10;
                ra_addr = inst_ra;
            end

            // HALT
            4'hF: begin
                halt_detect = 1'b1;
            end

            default: begin
            end

        endcase
    end

endmodule