`timescale 1ns / 1ps
// FILE: soc.v

module soc(
    input clk_cpu,
    input clk_sys,
    input rst,
    input cpu_enable,
    input reset_pc_req,
    input clear_halt,
    input iram_write_enable,
    input [23:0] iram_write_data,
    input [7:0] iram_write_addr,
    
    // PORT 1: Dedicated Streamer Read Port (Connected to private RAM Port B)
    input [7:0] streamer_addr,
    output [7:0] streamer_read_data,

    // PORT 2: MMIO / External Control Bus (Connected to Sys_Mem Port B)
    output [7:0] ext_addr,
    output ext_write_en,
    output [7:0] ext_write_data,
    input  [7:0] ext_read_data,
    
    // CPU Debug / Status Outputs
    output [7:0] cpu_ra_data,
    output [7:0] cpu_rb_data,
    output [7:0] cpu_data_out,
    output [23:0] cpu_instruction,
    output [7:0] pc_addr_out,
    output cpu_halted,
    
    output iram_packet_ack,
    output [15:0] mmio_led,
    output reset_pc_ack
);
    
    // Internal Wires
    wire [23:0] instruction;
    wire [7:0] cpu_data_in;
    wire [7:0] pc_addr, iram_addr;
    wire iram_we;
    
    wire [7:0] cpu_addr;
    wire cpu_write_enable;
    wire cpu_read_enable;
    wire cpu_mem_mode_select;
    
    wire ext_mode_select = 1'b1;

    // 1. CPU Core
    cpu_core cpu_core(
        .clk(clk_cpu),
        .rst(rst),
        .cpu_enable(cpu_enable),
        .reset_pc_req(reset_pc_req),
        .clear_halt(clear_halt),
        .instruction(instruction),
        .mem_read_data(cpu_data_in),
        .mem_write_data(cpu_data_out),
        .mem_addr(cpu_addr),
        .mem_mode_select(cpu_mem_mode_select),
        .mem_write_enable(cpu_write_enable),
        .mem_read_enable(cpu_read_enable),
        .register_a_data(cpu_ra_data),
        .register_b_data(cpu_rb_data),
        .pc_addr(pc_addr),
        .halt_state(cpu_halted),
        .reset_pc_ack(reset_pc_ack)
    );
    
    // 2. Instruction RAM
    instruction_ram instruction_ram(
        .clk(clk_sys),
        .we(iram_we),
        .addr(iram_addr),
        .data_in(iram_write_data),
        .data_out(instruction),
        .data_ack(iram_packet_ack)
    );
    
    // 3. Memory Bus Arbiter (Routes CPU vs. Streamer & MMIO space)
    mem_bus mem_bus(
        .clk_cpu(clk_cpu),
        .clk_sys(clk_sys),
        .rst(rst),

        .cpu_addr(cpu_addr),
        .cpu_write_en(cpu_write_enable),
        .cpu_write_data(cpu_data_out),
        .cpu_read_data(cpu_data_in),
        .cpu_mode_select(cpu_mem_mode_select),
        
        // Streamer port mapping
        .streamer_addr(streamer_addr),
        .streamer_read_data(streamer_read_data),

        // MMIO / External control bus mapping
        .ext_mode_select(ext_mode_select),
        .ext_addr(ext_addr),
        .ext_write_en(ext_write_en),
        .ext_write_data(ext_write_data),
        .ext_read_data(ext_read_data),
        
        .mmio_led(mmio_led)
    );
    
    assign iram_addr = iram_we ? iram_write_addr : pc_addr;
    assign iram_we = iram_write_enable;
    assign pc_addr_out = pc_addr;
    assign cpu_instruction = instruction;

endmodule