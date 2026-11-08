`timescale 1ns / 1ps
//FILE: mem_bus.v

module mem_bus(
    input clk_cpu,
    input clk_sys,
    input rst,

    input [7:0] cpu_addr,
    input [7:0] ram_addr_ext,
    input cpu_write_en,
    input [7:0] cpu_write_data,
    output [7:0] cpu_read_data,
    input cpu_mode_select,
    input ext_mode_select,
    
    input [7:0] ext_addr,
    input ext_write_en,
    input [7:0] ext_write_data,
    output [7:0] ext_read_data,
    
    output [15:0] mmio_led,
    
    // Error outputs exposed so you don't have to wire them yet (can leave floating at top level)
    output sys_write_error_cpu,
    output sys_write_error_ext
);
    wire [7:0] ram_read_cpu, ram_read_ext;
    wire [7:0] sys_read_data_cpu;
    wire [7:0] sys_read_data_ext;
    wire [8:0] unused_uart_status;
    
    // Private RAM (Exclusive CPU write, Port B read)
    ram ram_inst(
        .clk(clk_cpu),
        .addr_cpu(cpu_addr),
        .addr_b(ram_addr_ext),
        .write_data(cpu_write_data),
        .write_en(cpu_write_en && !cpu_mode_select),
        .read_data_cpu(ram_read_cpu),
        .read_data_b(ram_read_ext)
    );
    
    // System RAM / MMIO space (Shared dual-port with error detection)
    sys_mem sys_mem_inst(
        .clk(clk_sys),
        .rst(rst),
    
        .addr_a(cpu_addr),
        .write_data_a(cpu_write_data),
        .write_en_a(cpu_write_en && cpu_mode_select),
        .read_data_a(sys_read_data_cpu),
    
        .addr_b(ext_addr),
        .write_data_b(ext_write_data),
        .write_en_b(ext_write_en),
        .read_data_b(sys_read_data_ext),
        
        .write_error_a(sys_write_error_cpu),
        .write_error_b(sys_write_error_ext),
        .mmio_led(mmio_led),
        .uart_status(unused_uart_status)
    );
    
    // CPU read multiplexer (0-cycle combinational select)
    assign cpu_read_data = cpu_mode_select ? sys_read_data_cpu : ram_read_cpu;
    
    // External port read mapping
    assign ext_read_data = ext_mode_select ? sys_read_data_ext : ram_read_ext;
    
endmodule