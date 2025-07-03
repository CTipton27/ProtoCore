`timescale 1ns / 1ps
//FILE: full_cpu.v

module full_cpu(
    input clk, //From xdc
    input rst, //From xdc, corresponds to center button
    output [6:0] seg, //7-seg will show PC counter
    output [3:0] an,
    output [15:0] led  //LEDs will show BIN data of read_b and read_a respectively
    
    );
    wire [2:0] alu_opcode;
    wire [3:0] ra_addr, rb_addr, rd_addr;
    wire alu_en, write_en, imm_flag, alu_zero, alu_carry, pc_en, pc_overwrite, HALT_flag, is_jump;
    wire [7:0] imm_value, read_a, read_b, pc_overwrite_data, pc_addr, jump_target;
    wire [23:0] ROM_data;
    
    datapath datapath (
        .clk(clk),
        .alu_en(alu_en),
        .alu_opcode(alu_opcode),
        .imm_value(imm_value),
        .write_addr(rd_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .imm_flag(imm_flag),
        .read_a(read_a), 
        .read_b(read_b),
        .alu_zero(alu_zero), 
        .alu_carry(alu_carry),
        .jump_target(jump_target)
    );
    
    program_counter PC (
        .clk(clk),
        .rst(rst),
        .en(pc_en),
        .overwrite(pc_overwrite),
        .overwrite_data(pc_overwrite_data),
        .addr(pc_addr)
    );
    
    instruction_rom ROM (
        .addr(pc_addr),
        .data(ROM_data)
    );
    
    instruction_decode IM (
        .instruction(ROM_data),
        .rst(rst),
        .alu_zero(alu_zero),
        .alu_en(alu_en),
        .alu_opcode(alu_opcode),
        .imm_value(imm_value),
        .write_addr(rd_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .imm_flag(imm_flag),
        .HALT(HALT_flag),
        .pc_overwrite(pc_overwrite)
    );
    
    sev_seg sev_seg (
        .clk(clk),
        .PC_addr(pc_addr),
        .seg(seg),
        .an(an)
    );
    
    assign pc_en = !HALT_flag;
    assign pc_overwrite_data = jump_target;
    
    assign led[15:8] = read_b;
    assign led[7:0]  = read_a;
endmodule