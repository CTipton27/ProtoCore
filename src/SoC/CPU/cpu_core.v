`timescale 1ns / 1ps
// FILE: cpu_core.v

module cpu_core(
    input clk,
    input rst,
    input cpu_enable,
    input reset_pc_req,
    input clear_halt,

    input  [23:0] instruction,

    input  [7:0] mem_read_data,
    output [7:0] mem_write_data,
    output [8:0] mem_addr,
    output mem_write_enable,
    output mem_read_enable,

    output [7:0] register_a_data,
    output [7:0] register_b_data,

    output [7:0] pc_addr,
    output halt_state,
    output reset_pc_ack,
    output reg [7:0] halt_code
);

    reg halt_state_reg;
    wire halt_detect;
    reg pc_enable;
    wire pc_load_ack;

    wire reg_write_enable, mem_write_request, mem_read_request;
    wire [3:0] ra_addr, rb_addr, rd_addr;
    wire mem_space;
    wire [7:0] data_addr;

    wire alu_src_immediate, alu_zero, alu_carry;
    wire [2:0] alu_opcode;
    
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
        .data_write_enable(mem_write_request),
        .data_read_enable(mem_read_request),
        .pc_select(pc_select),
        .halt_detect(halt_detect),
        .mem_space(mem_space),
        .imm_value(imm_value)
    );

    datapath datapath(
        .clk(clk),
        .cpu_enable(cpu_enable),
        .alu_src_immediate(alu_src_immediate),
        .alu_opcode(alu_opcode),
        .extern_data(mem_read_data),
        .imm_data(imm_value),
        .reg_write_enable(reg_write_enable && cpu_enable && !halt_state_reg),
        .wb_select(mem_read_request),
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
        .addr(pc_addr),
        .load_ack(pc_load_ack)
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

        if (reset_pc_req) begin
            pc_load = 1'b1;
            pc_load_addr = 8'b0;
        end else if (cpu_enable && !halt_state_reg && !halt_detect) begin
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
        if (rst) begin
            halt_state_reg <= 1'b0;
            halt_code <= 8'b0;
        end else begin
            if (clear_halt)
                halt_state_reg <= 1'b0;
            else if (!halt_state_reg && halt_detect) begin
                halt_state_reg <= 1'b1;
                halt_code <= imm_value;
            end
        end
    end
        
    assign mem_write_data = register_b_data;
    assign halt_state = halt_state_reg;
    assign mem_write_enable = mem_write_request && cpu_enable && !halt_state_reg;
    assign mem_read_enable = mem_read_request && cpu_enable && !halt_state_reg;
    assign reset_pc_ack = reset_pc_req && pc_load_ack;
    assign mem_addr = {mem_space, data_addr};
endmodule