`timescale 1ns / 1ps
// FILE: vga_timing.v

module vga_timing (
    input  wire        clk_25m,       // 25 MHz pixel clock
    input  wire        rst,           // System reset
    
    output reg         vga_hsync,     // Horizontal sync pulse
    output reg         vga_vsync,     // Vertical sync pulse
    output reg  [9:0]  pixel_x,       // Current horizontal pixel (0-639 active)
    output reg  [9:0]  pixel_y,       // Current vertical line (0-479 active)
    output wire        video_on       // High only when drawing inside 640x480 active area
);

    // Standard 640x480 @ 60Hz timing constants
    // Horizontal parameters (Total = 800)
    localparam H_VISIBLE = 10'd640;
    localparam H_FP      = 10'd16;
    localparam H_SYNC    = 10'd96;
    localparam H_BP      = 10'd48;
    localparam H_TOTAL   = H_VISIBLE + H_FP + H_SYNC + H_BP; // 800

    // Vertical parameters (Total = 525)
    localparam V_VISIBLE = 10'd480;
    localparam V_FP      = 10'd10;
    localparam V_SYNC    = 10'd2;
    localparam V_BP      = 10'd33;
    localparam V_TOTAL   = V_VISIBLE + V_FP + V_SYNC + V_BP; // 525

    // Internal counters
    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal counter
    always @(posedge clk_25m or posedge rst) begin
        if (rst) begin
            h_count <= 10'd0;
        end else if (h_count == H_TOTAL - 1) begin
            h_count <= 10'd0;
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    // Vertical counter (increments every time horizontal row finishes)
    always @(posedge clk_25m or posedge rst) begin
        if (rst) begin
            v_count <= 10'd0;
        end else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1) begin
                v_count <= 10'd0;
            end else begin
                v_count <= v_count + 1'b1;
            end
        end
    end

    // Generate Sync Pulses (Standard VGA uses active-low sync)
    always @(posedge clk_25m or posedge rst) begin
        if (rst) begin
            vga_hsync <= 1'b1;
            vga_vsync <= 1'b1;
        end else begin
            // HSYNC low during sync pulse period
            vga_hsync <= ~((h_count >= (H_VISIBLE + H_FP)) && (h_count < (H_VISIBLE + H_FP + H_SYNC)));
            // VSYNC low during sync pulse period
            vga_vsync <= ~((v_count >= (V_VISIBLE + V_FP)) && (v_count < (V_VISIBLE + V_FP + V_SYNC)));
        end
    end

    // Active video region flag
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Export current pixel coordinates (clamped or direct during active region)
    always @(*) begin
        pixel_x = video_on ? h_count : 10'd0;
        pixel_y = video_on ? v_count : 10'd0;
    end

endmodule