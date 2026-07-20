`timescale 1ns / 1ps
//FILE: basys_3_wrapper.v

module basys_3_wrapper(
    input clk_system,
    input hard_rst,
    input clk_visual,
    input [2:0] clk_speed,
    input UART_rx,
    
    output UART_tx,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an
    );
    
    //------------------------------
    // CLKS, RSTS
    //------------------------------
    wire clk_cpu;
    wire s_clk;
    
    
    //------------------------------
    // CPU / SOC signals
    //------------------------------   
    wire clear_halt;
    wire cpu_halted;
    wire [7:0] pc_addr;
    wire [7:0] cpu_data_out;
    wire reset_pc_req;
    wire reset_pc_ack;
    
    
    //------------------------------
    // IRAM interface
    //------------------------------
    wire iram_write_enable;
    wire [23:0] iram_write_data;
    wire [7:0] iram_write_addr;
    wire iram_packet_ack;
    
    
    
    //------------------------------
    // Debug Signals
    //------------------------------
    wire debug_mode;
    wire step_cpu_req;
    wire step_pc_ack;
    wire [7:0] ra_data; 
    wire [7:0] rb_data;
    wire [23:0] cpu_instruction;
    
    
    
    //------------------------------
    // UART Signals
    //------------------------------
    wire [7:0] rx_byte;
    wire [7:0] tx_byte;
    wire programming_active;
    wire uart_byte_ack;
    wire uart_byte_ready;
    wire tx_busy;
    wire tx_send;
    wire send_debug_packet;
    wire inst_byte_ready;
    wire inst_byte_ack;
    wire [7:0] inst_byte;
    
    
    //------------------------------
    // User IO
    //------------------------------
    wire [15:0] mmio_display;
    reg [15:0] output_reg;
    wire display_regs;
    
    
    //------------------------------
    // SOC
    //------------------------------
    soc soc(
        .clk_cpu(clk_cpu),
        .clk_sys(clk_system),
        .rst(hard_rst),
        .cpu_enable(!programming_active),
        .reset_pc_req(reset_pc_req),
        .clear_halt(clear_halt),
        .iram_write_enable(iram_write_enable),
        .iram_write_data(iram_write_data),
        .iram_write_addr(iram_write_addr),
        
        .cpu_ra_data(ra_data),
        .cpu_rb_data(rb_data),
        .cpu_data_out(cpu_data_out),
        .cpu_instruction(cpu_instruction),
        .pc_addr_out(pc_addr),
        .cpu_halted(cpu_halted),
        .iram_packet_ack(iram_packet_ack),
        .mmio_data(mmio_display),
        .reset_pc_ack(reset_pc_ack)
    );
    
    
    //------------------------------
    // INSTRUCTION PROGRAMMING
    //------------------------------
    instruction_loader instruction_loader(
        .clk(clk_system),
        .rst(hard_rst),
        .cpu_halted(cpu_halted),
        .programming_active(programming_active),
    
        .inst_byte_ready(inst_byte_ready),
        .inst_byte(inst_byte),
    
        .inst_write_ack(iram_packet_ack),
    
        .inst_byte_ack(inst_byte_ack),
        .iRAM_write_enable(iram_write_enable),
        .extern_iRAM_addr(iram_write_addr),
        .iRAM_packet(iram_write_data),
        .clear_halt(clear_halt)
    );
    

    
    
    //------------------------------
    // UART RX
    //------------------------------    
    uart_rx uart_rx(
        .clk(clk_system),
        .rst(hard_rst),
        .rx(UART_rx),
        .byte_ack(uart_byte_ack),
        .byte_ready(uart_byte_ready),
        .uart_byte(rx_byte)
    );
    
    rx_decoder rx_decoder(
        .clk_system(clk_system),
        .rst(hard_rst),
        .byte_ready(uart_byte_ready),
        .uart_byte(rx_byte),
        
        .inst_byte_ack(inst_byte_ack),
        .reset_ack(reset_pc_ack),
        .step_ack(step_pc_ack),
        
        .debug_display(display_regs),
        .programming_active(programming_active),
        .reset_pc_req(reset_pc_req),
        .debug_mode(debug_mode),
        .step_cpu_req(step_cpu_req),
        .inst_byte(inst_byte),
        .inst_byte_ready(inst_byte_ready),
    
        .uart_byte_ack(uart_byte_ack)
    );    
    
    
    //------------------------------
    // UART TX
    //------------------------------
    
    uart_tx uart_tx(
        .clk(clk_system),
        .rst(hard_rst),
        .send_byte(tx_send),
        .uart_byte(tx_byte),
        .tx(UART_tx),
        .busy(tx_busy)
    );
    
    debug_packet_formatter debug_packet_formatter(
        .clk(clk_system),
        .rst(hard_rst),
        .instruction(cpu_instruction),
        .pc_addr(pc_addr),
        .ra_data(ra_data),
        .rb_data(rb_data),
        .send_debug(send_debug_packet),
        .tx_busy(tx_busy),
        .uart_byte(tx_byte),
        .send_byte(tx_send)
    );
    
    debug_controller debug_controller(
        .debug_mode(debug_mode),
        .clk_visual(clk_visual),
        .clk_cpu(clk_cpu),
        .send_debug_packet(send_debug_packet)
    );
    
    
    //------------------------------
    // IO
    //------------------------------
    sev_seg sev_seg(    
        .clk(clk_system),
        .PC_addr(pc_addr),
        .seg(seg),
        .an(an)
    );
    
    clk_visualizer clk_visualizer(
        .clk(clk_system),
        .debug_mode(debug_mode),
        .step_cpu_req(step_cpu_req),
        .clk_speed(clk_speed),
        .s_clk(s_clk),
        .step_pc_ack(step_pc_ack)
    );
 
    //display combinatorial block
    always @ (*) begin
        if (programming_active)
            output_reg = 16'h1;
        else if (cpu_halted)
            output_reg = {8'b0, cpu_data_out};
        else if (display_regs)
            output_reg = {ra_data, rb_data};
        else
            output_reg = mmio_display;
    end
    
    assign led = output_reg;
    assign clk_cpu = clk_visual ? s_clk : clk_system;
    
endmodule