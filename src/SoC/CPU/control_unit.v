`timescale 1ns / 1ps
//FILE: control_unit.v

module control_unit(
    input [23:0] instruction,
    
    input alu_zero,
    
    output reg reg_write_enable,
    output reg [3:0] rd_addr,
    output reg [3:0] ra_addr,
    output reg [3:0] rb_addr,
    
    output reg [2:0] alu_opcode,
    output reg alu_src_immediate,
    
    output reg ram_write_enable,
    output reg is_load,
    
    output reg [1:0] pc_select, //00:PC+1, 01:branch target, 10:jump target
    
    output reg halt_flag,
    
    output [7:0] imm_value
    );
    wire [3:0] inst_opcode = instruction [23:20];
    wire [3:0] inst_ra = instruction [19:16];
    wire [3:0] inst_rb = instruction [15:12];
    wire [3:0] inst_rd = instruction [11:8];
    assign imm_value = instruction [7:0];

    always @ (*) begin
        reg_write_enable = 0;
        ram_write_enable = 0;
        is_load = 0;
        alu_src_immediate = 0;
        halt_flag = 0;
        pc_select = 2'b00;
        alu_opcode = 3'b000;
        rd_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        
        case(inst_opcode)
            4'h0, 4'h1, 4'h2, 4'h3, 4'h4: begin //binary ALU operations
                reg_write_enable = 1;
                alu_opcode = inst_opcode[2:0];
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                end
            4'h5, 4'h6, 4'h7: begin //unary ALU operations
                reg_write_enable = 1;
                alu_opcode = inst_opcode[2:0];
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                end
            4'h8, 4'h9: begin //immediate ALU operations
                alu_opcode = {1'b0, inst_opcode[0], 1'b0}; // maps to 000 (add) or 010 (and)
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                alu_src_immediate = 1;
                end
            4'hA: begin //LOAD RD=x(RA+DATA)
                reg_write_enable = 1;
                alu_opcode = 3'b0;
                rd_addr = inst_rd;
                ra_addr = inst_ra;
                alu_src_immediate = 1;
                is_load = 1;
                end
            4'hB: begin //STORE x(RA+DATA) = RB
                ram_write_enable = 1;
                alu_opcode = 3'b0;
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_src_immediate = 1;
                end
            4'hC: begin // Branch if equal
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_opcode = 3'b001; //subtraction, zero flag determines equality
                pc_select = alu_zero ? 2'b01 : 2'b00;
                end
            4'hD: begin //Branch not equal
                ra_addr = inst_ra;
                rb_addr = inst_rb;
                alu_opcode = 3'b001; //subtraction, zero flag determines equality
                pc_select = alu_zero ? 2'b00 : 2'b01;
                end
            4'hE: begin //Jump
                pc_select = 2'b10;
                ra_addr = inst_ra;
                end
            4'hF: begin //begin
                halt_flag = 1;
                end
            default: begin end
        endcase
    end

endmodule
