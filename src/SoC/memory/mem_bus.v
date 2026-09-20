`timescale 1ns / 1ps
//FILE: mem_bus.v

module mem_bus(
    input clk_cpu,
    input clk_sys,
    input rst,

    input [7:0] cpu_addr,
    input cpu_write_en,
    input [7:0] cpu_write_data,
    output [7:0] cpu_read_data,
    input cpu_mode_select,
    
    input [7:0] ext_addr,
    input ext_write_en,
    input [7:0] ext_write_data,
    output [7:0] ext_read_data,
    
    output [15:0] mmio_led
    );
    wire [7:0] ram_read_data;
    wire [7:0] sys_read_data_a;
    wire [7:0] sys_read_data_b;
    
    
    ram ram(
        .clk(clk_cpu),
        .addr(cpu_addr),
        .write_data(cpu_write_data),
        .write_en(cpu_write_en && !cpu_mode_select),
        .read_data(ram_read_data)
    );
    
    sys_mem sys_mem(
        .clk(clk_sys),
        .rst(rst),
    
        .addr_a(cpu_addr),
        .write_data_a(cpu_write_data),
        .write_en_a(cpu_write_en && cpu_mode_select),
        .read_data_a(sys_read_data_a),
    
        .addr_b(ext_addr),
        .write_data_b(ext_write_data),
        .write_en_b(ext_write_en),
        .read_data_b(sys_read_data_b),
        
        .mmio_led(mmio_led)
    );
    
    
    assign cpu_read_data = cpu_mode_select ?
        sys_read_data_a : ram_read_data;
    assign ext_read_data = sys_read_data_b;
    
endmodule
