`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: memory_interface.v

module memory_interface(
    input clk_sys,
    input rst,
    
    // System Memory / Port Interface
    input [7:0] port_read_data,
    output reg [7:0] port_write_data,
    output reg [7:0] port_addr,
    output reg port_we,
    
    // Graphics Streamer Handshake
    input frame_done,
    output [2:0] format_ID,
    output [7:0] base_addr,
    output frame_ready
);

    // State Machine States (accounting for synchronous RAM read latency)
    localparam S_IDLE          = 3'd0; // Poll GPHC_ST for trigger bit
    localparam S_FETCH_AD      = 3'd1; // Wait 1 cycle for VRAM_AD data to arrive
    localparam S_WAIT_DONE     = 3'd2; // Wait for graphics streamer to finish frame
    localparam S_PREP_RELEASE  = 3'd3; // Switch address back to GPHC_ST and wait 1 cycle
    localparam S_RELEASE       = 3'd4; // Write back GPHC_ST[7] = 1 (clear handshake)
    localparam S_DONE_WRITE    = 3'd5; // Hold write for 1 cycle, return to IDLE

    reg [2:0] r_state;
    reg [7:0] r_base_addr;
    reg [2:0] r_format_ID;
    reg r_frame_ready;

    always @ (posedge clk_sys or posedge rst) begin
        if (rst) begin
            r_state           <= S_IDLE;
            port_addr         <= `MMIO_GPHC_ST;
            r_base_addr       <= 8'h00;
            port_write_data   <= 8'h00;
            r_frame_ready     <= 1'b0;
            port_we           <= 1'b0;
            r_format_ID       <= 3'b000;
        end else begin
            // Default pulse de-assertions
            port_we       <= 1'b0;
            r_frame_ready <= 1'b0;

            case (r_state)
                S_IDLE: begin
                    port_addr <= `MMIO_GPHC_ST;
                    // Check if CPU triggered the handshake (Bit 7 high)
                    if (port_read_data[7] == 1'b1) begin
                        r_format_ID <= port_read_data[6:4];
                        port_addr   <= `MMIO_VRAM_AD; // Request base address next cycle
                        r_state     <= S_FETCH_AD;
                    end
                end
                
                S_FETCH_AD: begin
                    // Synchronous RAM has now output MMIO_VRAM_AD data
                    r_base_addr   <= port_read_data;
                    r_frame_ready <= 1'b1; // Pulse start to streamer
                    r_state       <= S_WAIT_DONE;
                end
                
                S_WAIT_DONE: begin
                    // Wait for the graphics streamer to finish copying the frame
                    if (frame_done) begin
                        port_addr <= `MMIO_GPHC_ST; // Point back to status register
                        r_state   <= S_PREP_RELEASE;
                    end
                end

                S_PREP_RELEASE: begin
                    // Wait 1 cycle for port_read_data to reflect GPHC_ST content
                    r_state <= S_RELEASE;
                end
                
                S_RELEASE: begin
                    // Flip Bit 7 back to 0 while preserving lower status bits
                    port_write_data <= {1'b0, port_read_data[6:0]};
                    port_we         <= 1'b1;
                    r_state         <= S_DONE_WRITE;
                end

                S_DONE_WRITE: begin
                    port_we <= 1'b0;
                    r_state <= S_IDLE;
                end
                
                default: begin
                    r_state <= S_IDLE;
                end
            endcase
        end
    end
    
    assign base_addr   = r_base_addr;
    assign format_ID   = r_format_ID; // Or assign via wire/reg logic
    assign frame_ready = r_frame_ready;
    
endmodule