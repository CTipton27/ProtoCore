`timescale 1ns / 1ps
//FILE: instruction_decode.v

module instruction_decode(
    input [23:0] instruction,
    input rst,
    input alu_zero,
    output reg write_alu = 0,
    output reg [2:0] alu_opcode = 0,
    output reg [7:0] imm_value = 0,
    output reg [3:0] write_addr = 0, ra_addr = 0, rb_addr = 0,
    output reg write_en = 0,
    output reg ram_write_en = 0,
    output reg imm_flag = 0,
    output reg HALT = 0,
    output reg pc_overwrite = 0,
    output reg is_load = 0,
    output is_jump
    );
    wire [3:0] opcode = instruction [23:20];
    wire [3:0] ra = instruction [19:16];
    wire [3:0] rb = instruction [15:12];
    wire [3:0] rd = instruction [11:8];
    wire [7:0] data = instruction [7:0];
   
    assign is_jump = (opcode == 4'hE);
    always @ (*) begin
        write_alu = 0;
        ra_addr = 4'b0;
        rb_addr = 4'b0;
        write_addr = 4'b0;
        write_en = 0;
        alu_opcode = 3'b0;
        imm_value = 8'b0;
        imm_flag = 0;
        HALT = 0;
        ram_write_en = 0;
        is_load = 0;
        case (opcode)
            4'h0, 4'h1, 4'h2, 4'h3, 4'h4: begin//Binary ALU operations
                write_alu = 1;
                ra_addr = ra;
                rb_addr = rb;
                alu_opcode = opcode[2:0];
                write_en = 1;
                write_addr = rd;
                end
            4'h5, 4'h6, 4'h7: begin//Unary ALU operations
                write_alu = 1;
                ra_addr = ra;
                alu_opcode = opcode[2:0];
                write_en = 1;
                write_addr = rd;
                end
            4'h8, 4'h9: begin //Immediate ALU operations
                imm_flag = 1;
                write_alu = 1;
                ra_addr = ra;
                imm_value = data;
                alu_opcode = {2'b00, opcode[0]}; //Maps 1000 -> 000, 1001 -> 001
                write_en = 1;
                write_addr = rd;
                end
            4'hA: begin //LOAD RD=x(RA+DATA)
                write_en = 1;
                write_addr = rd;
                imm_flag = 1;
                imm_value = data;
                ra_addr = ra;
                alu_opcode = 3'b0;
                is_load = 1;
                end
            4'hB: begin //STORE x(RA+DATA) = RB
                ram_write_en = 1;
                alu_opcode = 3'b0;
                imm_flag = 1;
                ra_addr = ra;
                rb_addr = rb;
                imm_value = data;
                end //STORE
            4'hC, 4'hD: begin 
                ra_addr = ra;
                rb_addr = rb;
                alu_opcode = 3'b1; //subtraction, zero flag determines equality
                imm_value = data;
                end
            4'hE: begin 
                ra_addr = ra;
                imm_value = data;
                end 
            4'hF:begin
                HALT = 1;
                write_en = 0;
                ram_write_en = 0;
                imm_value = data;
                end
            default: begin end
        endcase
        pc_overwrite = (is_jump) || (opcode == 4'hC && alu_zero) || (opcode == 4'hD && !alu_zero);
    end
endmodule
