`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: graphics_streamer.v

module graphics_streamer(
    input clk,
    input rst,
    
    // Control & Status Interface
    input format_active,
    input [2:0] format_ID,
    input frame_ready,          // Triggered to start transfer
    output frame_ack,           // Acknowledges start to CPU
    output frame_done,          // Pulses high for 1 cycle when full frame is written
    input [7:0] base_addr,      // VRAM target base address offset
    
    // System RAM Read Interface
    output [7:0] sys_ram_r_addr,
    input [7:0] sys_ram_r_data,
    
    // Local VRAM Write Interface
    output vram_we,
    output [7:0] vram_w_addr,
    output [7:0] vram_w_data
);

    // State Machine States
    localparam S_IDLE  = 2'd0;
    localparam S_READ  = 2'd1;
    localparam S_WAIT  = 2'd2; // 1-cycle pipeline wait for RAM read data
    localparam S_WRITE = 2'd3;

    reg [1:0] r_state;
    reg [7:0] r_index;
    reg       r_frame_ack;
    reg       r_frame_done;
    reg       r_vram_we;
    reg [7:0] r_sys_ram_r_addr;

    // Tier 1 formats are 128 bytes (0 to 127), Tier 2 formats are 256 bytes (0 to 255)
    wire is_tier1 = (format_ID == `FMT_32x32_1BPP) || 
                    (format_ID == `FMT_32x16_2BPP) || 
                    (format_ID == `FMT_16x16_4BPP);
    
    wire [7:0] max_index = is_tier1 ? 8'h7F : 8'hFF;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_state          <= S_IDLE;
            r_index          <= 8'd0;
            r_frame_ack      <= 1'b0;
            r_frame_done     <= 1'b0;
            r_vram_we        <= 1'b0;
            r_sys_ram_r_addr <= 8'd0;
        end else begin
            // Default pulse clear for frame_done
            r_frame_done <= 1'b0;

            case (r_state)
                S_IDLE: begin
                    r_vram_we   <= 1'b0;
                    r_index     <= 8'd0;
                    if (frame_ready && !r_frame_ack) begin
                        r_frame_ack      <= 1'b1;
                        r_sys_ram_r_addr <= base_addr;
                        r_state          <= S_READ;
                    end else if (!frame_ready) begin
                        r_frame_ack      <= 1'b0;
                    end
                end

                S_READ: begin
                    r_vram_we        <= 1'b0;
                    r_sys_ram_r_addr <= base_addr + r_index;
                    r_state          <= S_WAIT;
                end

                S_WAIT: begin
                    r_state          <= S_WRITE;
                end

                S_WRITE: begin
                    r_vram_we <= 1'b1;
                    if (r_index == max_index) begin
                        r_state      <= S_IDLE;
                        r_frame_done <= 1'b1; // Signal transfer complete
                    end else begin
                        r_index      <= r_index + 1'b1;
                        r_state      <= S_READ;
                    end
                end

                default: begin
                    r_state <= S_IDLE;
                end
            endcase
        end
    end

    assign frame_ack      = r_frame_ack;
    assign frame_done     = r_frame_done;
    assign sys_ram_r_addr = r_sys_ram_r_addr;
    assign vram_we        = r_vram_we;
    assign vram_w_addr    = base_addr + r_index;
    assign vram_w_data    = sys_ram_r_data;

endmodule