`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: graphics_top.v

module graphics_top(
    input  wire        clk,               // Master system clock (100 MHz)
    input  wire        rst,               // System reset
    
    // Two 8-lane Data Ports
    input  wire [7:0] ram_read_data,      // RAM READ DATA (from system RAM for streamer)
    input  wire [7:0] sram_read_data,   // INPUT SRAM_DATA (VRAM bus)
    output wire [7:0] sram_write_data, // OUTPUT SRAM_DATA (VRAM bus)
    
    // Two 8-lane Address Ports
    output wire [7:0] ram_addr,        // RAM ADDR (system RAM read address from streamer)
    output wire [7:0] sram_addr,       // SRAM ADDR (VRAM / SRAM address)
    
    // SRAM Control
    output wire        sram_we,          // SRAM WE (Write Enable)
    
    // VGA Outputs
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    // Internal Clock Wire
    wire clk_vga;

    // VGA Timing & Display Wires
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_on;

    // Format Decoder Wires (Driven exclusively by format_decoder)
    wire [2:0] format_ID;
    wire       format_active;
    wire       offset_x;
    wire       offset_y;
    wire [1:0] scale;
    wire [1:0] color_depth;
    
    // Internal VRAM Interconnect Wires
    wire       vram_we;
    wire [7:0] vram_w_addr;
    wire [7:0] vram_w_data;
    wire [7:0] vram_r_addr;
    wire [7:0] vram_r_data;

    // Streamer internal wires (base_addr and format_ID are driven by memory_interface)
    wire       frame_ready;
    wire       frame_done;
    wire [7:0] base_addr;
    wire       buffer_sel = 1'b0;

    // Gating Control Latch
    reg        frame_valid;

    // Latch frame_valid high after the first successful frame transfer completes
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_valid <= 1'b0;
        end else if (frame_done) begin
            frame_valid <= 1'b1;
        end
    end

    // 1. Pixel Clock Generator (100MHz -> ~25MHz)
    vga_clock_gen vga_clock_gen(
        .clk_100mhz (clk),
        .rst        (rst),
        .clk_25m    (clk_vga)
    );
        
    // 2. VGA Timing Generator
    vga_timing vga_timing (
        .clk_25m    (clk_vga),        
        .rst        (rst),                    
        .vga_hsync  (vga_hsync),    
        .vga_vsync  (vga_vsync),    
        .pixel_x    (pixel_x),        
        .pixel_y    (pixel_y),        
        .video_on   (video_on)      
    );
        
    // 3. Format Decoder
    format_decoder format_decoder(
        .format_ID     (format_ID),
        .format_active (format_active),
        .offset_x      (offset_x),
        .offset_y      (offset_y),
        .scale         (scale),            
        .color_depth   (color_depth)
    );
        
    // 4. Local VRAM Buffer
    vram vram(
        .clk     (clk),
        .we      (vram_we),
        .w_addr  (vram_w_addr),
        .w_data  (vram_w_data),
        .r_addr  (vram_r_addr),
        .r_data  (vram_r_data)
    );

    // 5. VGA Pixel Mapper & Scaler Engine
    vga_pixel_mapper vga_pixel_mapper(
        .pixel_x       (pixel_x),
        .pixel_y       (pixel_y),
        .video_on      (video_on),
        .format_active (format_active),
        .format_ID     (format_ID),
        .offset_x      (offset_x),
        .offset_y      (offset_y),
        .scale         (scale),
        .color_depth   (color_depth),
        .frame_valid   (frame_valid),
        .buffer_sel    (buffer_sel),
        .vram_r_data   (vram_r_data),
        .vram_r_addr   (vram_r_addr),
        .vga_r         (vga_r),
        .vga_g         (vga_g),
        .vga_b         (vga_b)
    );

    // 6. Graphics Streamer (DMA Transfer Engine)
    graphics_streamer graphics_streamer(
        .clk            (clk),
        .rst            (rst),
        .format_active  (format_active),
        .format_ID      (format_ID),
        .frame_ready    (frame_ready),
        .frame_done     (frame_done),
        .base_addr      (base_addr),
        .ram_read_addr  (ram_addr),      // Connects to top-level RAM ADDR port
        .ram_read_data  (ram_read_data),   // Connects to top-level RAM READ DATA port
        .vram_we        (vram_we),
        .vram_w_addr    (vram_w_addr),
        .vram_w_data    (vram_w_data)
    );
    
    // 7. Memory Interface (Handling SRAM calls)
    memory_interface memory_interface(
        .clk_sys             (clk),
        .rst                 (rst),
        .port_read_data      (sram_read_data),
        .port_write_data     (sram_write_data),
        .port_addr           (sram_addr),
        .port_we             (sram_we),
        .frame_done          (frame_done),
        .format_ID           (format_ID),
        .base_addr           (base_addr),
        .frame_ready         (frame_ready)
    );
        
endmodule