`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: sram_decoder.v

module sram_decoder(
    input  wire       clk,
    input  wire       rst,
    
    // CPU MMIO Bus Interface
    input  wire [7:0] cpu_addr,
    input  wire [7:0] cpu_w_data,
    input  wire       cpu_we,
    
    // Streamer Handshake Inputs
    input  wire       frame_ack,
    input  wire       frame_done,
    
    // Decoded Outputs to Graphics Subsystem
    output wire [7:0] gphc_ctrl,
    output wire [7:0] base_addr,
    output wire       frame_ready
);

    reg [7:0] r_gphc_ctrl;
    reg [7:0] r_base_addr;

    // Decode and latch CPU MMIO writes (`MMIO_GPHC_ST` and `MMIO_VRAM_AD`)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_gphc_ctrl <= 8'h00;
            r_base_addr <= 8'h00;
        end else begin
            // Auto-clear frame_ready bit (bit 7) when frame transfer acknowledges or completes
            if (frame_done || frame_ack) begin
                r_gphc_ctrl[7] <= 1'b0;
            end

            // Listen to CPU writes on MMIO address bus
            if (cpu_we) begin
                case (cpu_addr)
                    `MMIO_GPHC_ST: r_gphc_ctrl <= cpu_w_data;
                    `MMIO_VRAM_AD: r_base_addr <= cpu_w_data;
                    default: ;
                endcase
            end
        end
    end

    assign gphc_ctrl   = r_gphc_ctrl;
    assign base_addr   = r_base_addr;
    assign frame_ready = r_gphc_ctrl[7];

endmodule