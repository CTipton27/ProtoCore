`timescale 1ns / 1ps
//FILE: basys_3_wrapper.v

module basys_3_wrapper(
    input clk_system,
    input rst,
    input clk_visual,
    input [2:0] clk_speed,
    input UART_rx,
    input program_mode,
    
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an
    );
    
    wire clk_cpu, s_clk;
    wire cpu_enable;
    wire iram_write_enable;
    wire [23:0] iram_write_data;
    wire [15:0] mmio_display;
    wire [7:0] iram_write_addr;
    
    wire [7:0] ra_data, rb_data;
    wire [7:0] cpu_data_out;
    wire cpu_halted;
    wire iram_packet_receive;
    wire reset_pc, clear_halt;
    
    wire packet_ready;
    wire [7:0] pc_addr;
    wire [7:0] uart_packet;
    wire packet_ack;
    
    wire debug_display_reg;
    
    reg [15:0] output_reg;
    
    soc soc(
        .clk_cpu(clk_cpu),
        .clk_sys(clk_system),
        .rst(rst),
        .cpu_enable(cpu_enable),
        .reset_pc(reset_pc),
        .clear_halt(clear_halt),
        .iram_write_enable(iram_write_enable),
        .iram_write_data(iram_write_data),
        .iram_write_addr(iram_write_addr),
        
        .cpu_ra_data(ra_data),
        .cpu_rb_data(rb_data),
        .cpu_data_out(cpu_data_out),
        .pc_addr_out(pc_addr),
        .cpu_halted(cpu_halted),
        .iram_packet_receive(iram_packet_receive),
        .mmio_data(mmio_display)
    );
    
    clk_visualizer clk_visualizer(
        .clk(clk_system),
        .clk_speed(clk_speed),
        .s_clk(s_clk) 
    );
    
    cpu_instruction_loader cpu_instruction_loader(
        .clk(clk_system),
        .rst(rst),
        .packet_ready(packet_ready),
        .data_ack(iram_packet_receive),
        .program_mode(program_mode),
        .PC_addr(pc_addr),
        .uart_packet(uart_packet),
        .packet_ack(packet_ack),
        .cpu_enable(cpu_enable),
        .reset_PC(reset_pc),
        .clear_halt(clear_halt),
        .iRAM_write_enable(iram_write_enable),
        .extern_iRAM_addr(iram_write_addr),
        .iRAM_data_in(iram_write_data),
        .debug_display_reg(debug_display_reg)
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
     
    //display combinatorial block
    always @ (*) begin
        if (program_mode)
            output_reg = 16'h1;
        else if (cpu_halted)
            output_reg = {8'b0, cpu_data_out};
        else if (debug_display_reg)
            output_reg = {ra_data, rb_data};
        else
            output_reg = mmio_display;
    end
    
    assign led = output_reg;
    assign clk_cpu = clk_visual ? s_clk : clk_system;
    
endmodule