`timescale 1ns / 1ps
//FILE: soc.v

module basys_3_wrapper(
    input clk_system,
    input rst,
    input clk_visual,
    input [2:0] clk_speed,
    input UART_rx,
    
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an
    );
    
    wire clk_cpu, s_clk;
    wire cpu_resume;
    wire iram_write_enable;
    wire [23:0] iram_write_data;
    wire [7:0] iram_write_addr;
    
    wire [7:0] ra_data, rb_data;
    wire [7:0] cpu_data_out;
    wire cpu_halt;
    wire iram_packet_receive;
    wire reset_pc;
    
    wire packet_ready;
    wire [7:0] pc_addr;
    wire [7:0] uart_packet;
    wire packet_ack;
    
    soc soc(
        .clk_cpu(clk_cpu),
        .clk_sys(clk_system),
        .rst(rst),
        .cpu_resume(cpu_resume),
        .reset_pc(reset_pc),
        .iram_write_enable(iram_write_enable),
        .iram_write_data(iram_write_data),
        .iram_write_addr(iram_write_addr),
        
        .cpu_ra_data(ra_data),
        .cpu_rb_data(rb_data),
        .cpu_data_out(cpu_data_out),
        .pc_addr_out(pc_addr),
        .cpu_halt(cpu_halt),
        .iram_packet_receive(iram_packet_receive)
    );
    
    clk_visualizer clk_visualizer(
        .clk(clk_system),
        .clk_speed(clk_speed),
        .s_clk(s_clk) 
    );
    
    cpu_instruction_loader cpu_instruction_loader(
        .clk(clk_system),
        .rst(rst),
        .HALT_flag(cpu_halt),
        .packet_ready(packet_ready),
        .data_ack(iram_packet_receive),
        .PC_addr(pc_addr),
        .uart_packet(uart_packet),
        .packet_ack(packet_ack),
        .cpu_resume(cpu_resume),
        .reset_PC(reset_pc),
        .iRAM_write_enable(iram_write_enable),
        .extern_iRAM_addr(iram_write_addr),
        .iRAM_data_in(iram_write_data)
    );
    
    sev_seg sev_seg(    
        .clk(clk_system),
        .PC_addr(pc_addr),
        .seg(seg),
        .an(an)
    );
    
    uart_rx uart_rx(
        .clk(clk_system),
        .rst(rst),
        .rx(UART_rx),
        .packet_ack(packet_ack),
        .packet_ready(packet_ready),
        .uart_packet(uart_packet)
    );
    
    assign led = cpu_halt ? {8'b0, cpu_data_out} : {ra_data, rb_data};
    assign clk_cpu = clk_visual ? s_clk : clk_system;
    
endmodule