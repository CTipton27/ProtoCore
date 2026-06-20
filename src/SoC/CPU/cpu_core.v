`timescale 1ns / 1ps
// FILE: cpu_core.v

module cpu_core(
    input clk,
    input rst,
    input cpu_resume,
    input reset_pc,

    input  [23:0] instruction,

    input  [7:0] data_in,
    output [7:0] data_out,

    output [7:0] register_a_data,
    output [7:0] register_b_data,

    output [7:0] data_addr,
    output data_write_enable,

    output [7:0] pc_addr,
    output halt_state
);

    reg halt_state_reg;
    wire halt_detect;
    reg [7:0] halt_imm;
    reg pc_enable;

    wire reg_write_enable;
    wire [3:0] ra_addr, rb_addr, rd_addr;

    wire alu_src_immediate, alu_zero, alu_carry;
    wire [2:0] alu_opcode;

    wire is_load;
    wire [1:0] pc_select;
    
    wire [7:0] imm_value;
    
    reg pc_load;
    reg [7:0] pc_load_addr;

    wire [7:0] pc_branch_addr;
    wire [7:0] pc_jump_addr;

    control_unit control_unit(
        .instruction(instruction),
        .alu_zero(alu_zero),
        .reg_write_enable(reg_write_enable),
        .rd_addr(rd_addr),
        .ra_addr(ra_addr),
        .rb_addr(rb_addr),
        .alu_opcode(alu_opcode),
        .alu_src_immediate(alu_src_immediate),
        .data_write_enable(data_write_enable),
        .is_load(is_load),
        .pc_select(pc_select),
        .halt_detect(halt_detect),
        .imm_value(imm_value)
    );

    datapath datapath(
        .clk(clk),
        .alu_src_immediate(alu_src_immediate),
        .alu_opcode(alu_opcode),
        .extern_data(data_in),
        .imm_data(imm_value),
        .reg_write_enable(reg_write_enable),
        .wb_select(is_load),
        .rd_addr(rd_addr),
        .ra_addr(ra_addr),
        .rb_addr(rb_addr),
        .reg_a_data(register_a_data),
        .reg_b_data(register_b_data),
        .alu_out(data_addr),
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
    
    // PC Control
    always @(*) begin
        pc_enable = 1'b0;
        pc_load = 1'b0;
        pc_load_addr = 8'b0;

        if (reset_pc) begin
            pc_load = 1'b1;
            pc_load_addr = 8'b0;
        end else if (!halt_state_reg) begin
            case (pc_select)
                2'b00: begin
                    pc_enable = 1'b1;
                end

                2'b01: begin
                    pc_load = 1'b1;
                    pc_load_addr = pc_branch_addr;
                end

                2'b10: begin
                    pc_load = 1'b1;
                    pc_load_addr = pc_jump_addr;
                end
            endcase
        end
    end

    // HALT control
    always @(posedge clk) begin
        if (rst)
            halt_state_reg <= 1'b0;
        else begin
            if (cpu_resume)
                halt_state_reg <= 1'b0;
            else if (halt_detect)
                halt_state_reg <= 1'b1;
            
            if (halt_detect && !halt_state_reg)
                halt_imm <= imm_value;
        end
    end
    
    assign data_out = halt_state_reg ? halt_imm : register_b_data;
    assign halt_state = halt_state_reg;
endmodule