`timescale 1ns / 1ps
//FILE: soc.v

module soc(
    input clk_cpu,
    input clk_sys,
    input rst,
    input cpu_resume,
    input reset_pc,
    input iram_write_enable,
    input [23:0] iram_write_data,
    input [7:0] iram_write_addr,
    
    
    output [7:0] cpu_ra_data,
    output [7:0] cpu_rb_data,
    output [7:0] cpu_data_out,
    output [7:0] pc_addr_out,
    output cpu_halt,
    
    output iram_packet_receive,
    output [15:0] mmio_data
    );
    
    wire [23:0] instruction;
    wire [7:0] cpu_data_in;
    wire [7:0] ram_data_addr;
    wire ram_write_enable, iram_we;
    wire [7:0] pc_addr, iram_addr;
    wire [15:0] ram_mmio_data;
    reg [15:0] mmio_data_reg;
    reg mmio_pending;
    
    cpu_core cpu_core(
        .clk(clk_cpu),
        .rst(rst),
        .cpu_resume(cpu_resume),
        .reset_pc(reset_pc),
        .instruction(instruction),
        .data_in(cpu_data_in),
        .data_out(cpu_data_out),
        .register_a_data(cpu_ra_data),
        .register_b_data(cpu_rb_data),
        .data_addr(ram_data_addr),
        .data_write_enable(ram_write_enable),
        .pc_addr(pc_addr),
        .halt_state(cpu_halt)
    );
    
    instruction_ram instruction_ram(
        .clk(clk_sys),
        .we(iram_we),
        .addr(iram_addr),
        .data_in(iram_write_data),
        .data_out(instruction),
        .data_ack(iram_packet_receive)
    );
    
    ram ram(
        .clk(clk_cpu),
        .addr(ram_data_addr),
        .write_data(cpu_data_out),
        .write_en(ram_write_enable && !cpu_halt),
        .read_data(cpu_data_in),
        .mmio_data(ram_mmio_data)
    );
    
    always @(posedge clk_cpu or posedge rst) begin
        if (rst) begin
            mmio_pending <= 0;
            mmio_data_reg <= 16'b0;
        end else begin
            if (ram_mmio_data != mmio_data_reg) begin 
                if (mmio_pending) begin
                    mmio_pending <= 0;
                    mmio_data_reg <= ram_mmio_data;
                end else
                    mmio_pending <= 1;
            end
        end
    end
    
    assign iram_addr = cpu_halt ? iram_write_addr : pc_addr;
    assign iram_we = cpu_halt && iram_write_enable;
    assign pc_addr_out = pc_addr;
    assign mmio_data = mmio_data_reg;
endmodule