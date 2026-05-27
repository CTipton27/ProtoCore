`timescale 1ns / 1ps
//FILE: cpu_core.v

module cpu_core(
    input clk,
    input rst,
    
    input [23:0] instruction,
    
    input [7:0] data_in,
    
    output [7:0] register_a_data,
    output [7:0] register_b_data,
    
    output [7:0] data_request_addr,
    
    output [7:0] pc_addr
    );
    
    wire reg_write_enable;
    wire [3:0] ra_addr, rb_addr, rd_addr;
    
    wire alu_src_immediate, alu_zero, alu_carry;
    wire [2:0] alu_opcode;
    
    wire ram_write_enable, is_load;
    
    reg [7:0] pc_load_addr;
	wire [7:0] pc_branch_addr, pc_jump_addr;
    wire [1:0] pc_select;
    reg pc_load, pc_enable;
    
    wire halt_flag;
    
    wire [7:0] imm_value;
    
    
    control_unit control_unit(
        .instruction(instruction),
        .alu_zero(alu_zero),
        .reg_write_enable(reg_write_enable),
        .rd_addr(rd_addr),
        .ra_addr(ra_addr),
        .rb_addr(rb_addr),
        .alu_opcode(alu_opcode),
        .alu_src_immediate(alu_src_immediate),
        .ram_write_enable(ram_write_enable),
        .is_load(is_load),
        .pc_select(pc_select),
        .halt_flag(halt_flag),
        .imm_value(imm_value)
    );
    
    datapath datapath(
        .clk(clk),
        .alu_src_immediate(alu_src_immediate),
        .alu_opcode(alu_opcode),
        .extern_write_data(data_in),
        .imm_data(imm_value),
        .reg_write_enable(reg_write_enable),
        .reg_write_external(is_load),
        .rd_addr(rd_addr),
        .ra_addr(ra_addr),
        .rb_addr(rb_addr),
        .reg_a_data(register_a_data),
        .reg_b_data(register_b_data),
        .alu_out(data_request_addr),
        .alu_zero(alu_zero),
        .alu_carry(alu_carry)
    );
    
    program_counter program_counter(
        .clk(clk),
        .rst(rst),
        .enable(pc_enable),
        .load_enable(pc_load),
        .load_data(pc_load_addr),
        .addr(pc_addr)
    );    
    branch_calc branch_calc(
		.pc_addr(pc_addr),
		.imm(imm_value),
		.branch_target(pc_branch_addr)
	);
    jump_calc jump_calc(
	.reg_data(register_a_data),
    .imm(imm_value),
    .jump_target(pc_jump_addr)
	);
    
    //Assign PC target if not +1
    always @ (*) begin
        pc_enable = 0;
        pc_load = 0;
		pc_load_addr = 8'b0;
        case (pc_select)
            2'b00: pc_enable = 1; // PC + 1
            2'b01: begin // Branch target
				pc_load = 1;
				pc_load_addr = pc_branch_addr;
				end 
            2'b10: begin // Jump target
				pc_load = 1;
				pc_load_addr = pc_jump_addr;
				end
			default: pc_enable = 0;
        endcase
    end
    
    endmodule