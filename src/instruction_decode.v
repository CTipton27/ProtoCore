`timescale 1ns / 1ps
//FILE: instruction_decode.v

module instruction_decode(
    input [23:0] instruction,
    input rst,
    output reg alu_en,
    output reg [3:0] alu_opcode,
    output reg [7:0] imm_value,
    output reg [3:0] write_addr, ra_addr, rb_addr,
    output reg write_en,
    output reg imm_flag,
    output reg HALT
    );
    wire [3:0] opcode, ra, rb, rd, data;
    
    assign opcode = instruction [23:20];
    assign ra = instruction [19:16];
    assign rb = instruction [15:12];
    assign rd = instruction [11:8];
    assign data = instruction [7:0];
    
    always @ (*) begin
        alu_en = 0;
        ra_addr = 4'b0000;
        rb_addr = 4'b0000;
        write_addr = 4'b0000;
        write_en = 0;
        alu_opcode = 4'b0000;
        imm_value = 8'b00000000;
        imm_flag = 0;
        case (opcode)
            4'h0, 4'h1, 4'h2, 4'h3, 4'h4: begin//Binary ALU operations
                alu_en = 1;
                ra_addr = ra;
                rb_addr = rb;
                alu_opcode = opcode;
                write_en = 1;
                write_addr = rd;
                end
            4'h5, 4'h6, 4'h7: begin//Unary ALU operations
                alu_en = 1;
                ra_addr = ra;
                alu_opcode = opcode;
                write_en = 1;
                write_addr = rd;
                end
            4'h8, 4'h9: begin //Immediate ALU operations
                imm_flag = 1;
                alu_en = 1;
                ra_addr = ra;
                imm_value = data;
                alu_opcode = opcode[0]; //Maps 1000 -> 0000, 1001 -> 0001
                write_en = 1;
                write_addr = rd;
                end
            4'hA, 4'hB: begin end //memory access statements, undefined as of now
            4'hC, 4'hD, 4'hE: begin end //branching logic, undefined as of now
            4'hF: HALT = 1;
            default: begin end
        endcase
    end
endmodule
