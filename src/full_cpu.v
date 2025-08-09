`timescale 1ns / 1ps
//FILE: full_cpu.v

module full_cpu(
    input clk, //From xdc
    input rst, //From xdc, corresponds to center button
    input [2:0] clk_speed,
    input clk_visual,
    input UART_rx, //Used for instruction flashing
    output [6:0] seg, //7-seg will show PC counter
    output [3:0] an,
    output [15:0] led  //LEDs will show BIN data of read_b and read_a respectively
    
    );
    wire [2:0] alu_opcode;
    wire [3:0] ra_addr, rb_addr, rd_addr;
    wire write_alu, write_en, imm_flag, alu_zero, alu_carry, pc_en, pc_overwrite, HALT_flag, reset_PC, data_ack, cpu_paused, pc_overwrite_IM;
    wire ram_write_en, is_load, is_jump, s_clk, clk_mux, iRAM_write_enable, instruction_load_flag, packet_ready, packet_ack;
    wire [7:0] imm_value, read_a, read_b, pc_overwrite_data, pc_addr, alu_out, ram_addr, ram_read_data, ram_write_data, pc_datapath_mux, iRAM_addr;
    wire [7:0] extern_iRAM_addr, uart_packet;
    wire [23:0] iRAM_data_in, iRAM_data_out;
    
    datapath datapath (
        .clk(clk_mux),
        .write_alu(write_alu),
        .alu_opcode(alu_opcode),
        .ram_data(ram_read_data),
        .imm_data(imm_value),
        .write_addr(rd_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .is_load(is_load),
        .imm_flag(imm_flag),
        .cpu_paused(cpu_paused),
        .read_a(read_a), 
        .read_b(read_b),
        .alu_zero(alu_zero), 
        .alu_carry(alu_carry),
        .alu_out(alu_out)
    );
    
    program_counter PC (
        .clk(clk_mux),
        .rst(rst),
        .en(pc_en),
        .overwrite(pc_overwrite),
        .overwrite_data(pc_overwrite_data),
        .addr(pc_addr)
    );
    
    instruction_ram iRAM (
        .clk(clk),
        .we(iRAM_write_enable),
        .addr(iRAM_addr),
        .data_in(iRAM_data_in),
        .data_out(iRAM_data_out),
        .data_ack(data_ack)
    );
    
    instruction_decode IM (
        .instruction(iRAM_data_out),
        .rst(rst),
        .alu_zero(alu_zero),
        .write_alu(write_alu),
        .alu_opcode(alu_opcode),
        .imm_value(imm_value),
        .write_addr(rd_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .imm_flag(imm_flag),
        .HALT(HALT_flag),
        .pc_overwrite(pc_overwrite_IM),
        .is_load(is_load),
        .ram_write_en(ram_write_en),
        .is_jump(is_jump)
    );
    
    sev_seg sev_seg (
        .clk(clk),
        .PC_addr(pc_addr),
        .seg(seg),
        .an(an)
    );
    
    ram ram(
        .clk(s_clk),
        .addr(ram_addr),
        .write_data(ram_write_data),
        .write_en(ram_write_en),
        .cpu_paused(cpu_paused),
        .read_data(ram_read_data)
    );
    
    pc_datapath pc_datapath(
        .pc_overwrite(pc_overwrite),
        .imm_value(imm_value),
        .pc_mux(pc_datapath_mux),
        .is_jump(is_jump),
        .overwrite_data(pc_overwrite_data)
    );
    
    clk_visualizer clk_visualizer(
        .clk(clk),
        .clk_speed(clk_speed),
        .s_clk(s_clk)
    );
    
    uart_rx uart_rx(
        .clk(clk),
        .HALT_flag(HALT_flag),
        .rst(rst),
        .rx(UART_rx),
        .packet_ack(packet_ack),
        .packet_ready(packet_ready),
        .uart_packet(uart_packet)
    );
    
    cpu_instruction_loader cpu_instruction_loader(
        .clk(clk),
        .rst(rst),
        .HALT_flag(HALT_flag),
        .packet_ready(packet_ready),
        .data_ack(data_ack),
        .PC_addr(pc_addr),
        .uart_packet(uart_packet),
        .packet_ack(packet_ack),
        .cpu_paused(cpu_paused),
        .reset_PC(reset_PC),
        .iRAM_write_enable(iRAM_write_enable),
        .extern_iRAM_addr(extern_iRAM_addr),
        .iRAM_data_in(iRAM_data_in)
    );
    
    assign pc_overwrite = reset_PC ? 1 : pc_overwrite_IM;
    assign pc_datapath_mux = (reset_PC) ? 8'b0 : ((is_jump) ? read_a : pc_addr);
    assign ram_write_data = read_b;
    assign pc_en = !(HALT_flag || reset_PC);
    assign ram_addr = alu_out;
    assign clk_mux = clk_visual ? s_clk : clk;
    
    assign iRAM_addr = cpu_paused ? extern_iRAM_addr : pc_addr;
    
    assign led = HALT_flag ? {8'b0, imm_value} : {read_b, read_a};
endmodule