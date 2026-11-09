`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: mem_bus.v

module mem_bus(
    input clk_cpu,
    input clk_sys,
    input rst,

    // CPU Bus Interface
    input [7:0] cpu_addr,
    input cpu_write_en,
    input [7:0] cpu_write_data,
    output [7:0] cpu_read_data,
    input cpu_mode_select,
    
    // Dedicated Streamer Port (Directly drives private RAM Port B)
    input [7:0] streamer_addr,
    output [7:0] streamer_read_data,

    // MMIO / External Control Bus (Directly drives sys_mem Port B)
    input ext_mode_select,
    input [7:0] ext_addr,
    input ext_write_en,
    input [7:0] ext_write_data,
    output [7:0] ext_read_data,
    
    // Board Outputs & Error Flags
    output [15:0] mmio_led,
    output sys_write_error_cpu,
    output sys_write_error_ext
);

    wire [7:0] ram_read_cpu;
    wire [7:0] sys_read_data_cpu;
    wire [7:0] sys_read_data_ext;
    
    // 1. Private RAM (Port A: CPU write/read, Port B: Streamer read-only)
    ram ram(
        .clk(clk_cpu),
        .addr_cpu(cpu_addr),
        .addr_b(streamer_addr),
        .write_data(cpu_write_data),
        .write_en(cpu_write_en && !cpu_mode_select),
        .read_data_cpu(ram_read_cpu),
        .read_data_b(streamer_read_data)
    );
    
    // 2. System RAM / MMIO space (Port A: CPU, Port B: MMIO Control Interface)
    sys_mem sys_mem(
        .clk(clk_sys),
        .rst(rst),
    
        .addr_a(cpu_addr),
        .write_data_a(cpu_write_data),
        .write_en_a(cpu_write_en && cpu_mode_select),
        .read_data_a(sys_read_data_cpu),
    
        .addr_b(ext_addr),
        .write_data_b(ext_write_data),
        .write_en_b(ext_write_en && ext_mode_select),
        .read_data_b(sys_read_data_ext),
        
        .write_error_a(sys_write_error_cpu),
        .write_error_b(sys_write_error_ext),
        .mmio_led(mmio_led)
    );
    
    // CPU read multiplexer (0-cycle combinational select)
    assign cpu_read_data = cpu_mode_select ? sys_read_data_cpu : ram_read_cpu;
    
    // External MMIO read mapping
    assign ext_read_data = sys_read_data_ext;
    
endmodule