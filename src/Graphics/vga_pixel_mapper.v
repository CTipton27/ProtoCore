`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: vga_pixel_mapper.v

/*
BYTE PACKING & COLOR DEPTH FORMATS (VRAM byte contents):

1BPP (8 pixels/byte):
  Bits:   [  7  ][  6  ][  5  ][  4  ][  3  ][  2  ][  1  ][  0  ]
  Pixels: [Pix 7 ][Pix 6 ][Pix 5 ][Pix 4 ][Pix 3 ][Pix 2 ][Pix 1 ][Pix 0 ]
  Color:  Black & White (1-bit intensity)
  
2BPP (4 pixels/byte):
  Bits:   [  7:6  ][  5:4  ][  3:2  ][  1:0  ]
  Pixels: [Pix 3  ][Pix 2  ][Pix 1  ][Pix 0  ]
  Color:  4-level Grayscale
  
4BPP (2 pixels/byte - RGB 1-2-1):
  Bits:   [  7:4 (Pix 1)   ][  3:0 (Pix 0)   ]
  Sub-bits: [R][GG][B] per pixel (1 bit Red, 2 bits Green, 1 bit Blue)
  
8BPP (1 pixel/byte - RGB 3-3-2):
  Bits:   [  7:5  ][  4:2  ][  1:0  ]
  Sub-bits: [ Red ][ Green ][ Blue ] (3 bits Red, 3 bits Green, 2 bits Blue)
*/

module vga_pixel_mapper(
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input video_on,
    
    // Format & Control
    input format_active,
    input [2:0] format_ID,
    input offset_x,
    input offset_y,
    input [1:0] scale,
    input [1:0] color_depth,
    
    // Display Gating & Double-Buffering
    input frame_valid,          // High only after at least one valid frame is streamed
    input buffer_sel,           // 0 = Buffer A (0..127), 1 = Buffer B (128..255) for Tier 1 formats
    
    // VRAM Interface
    input [7:0] vram_r_data,
    output [7:0] vram_r_addr,
    
    // VGA Outputs
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b
);

    reg [7:0] r_vram_r_addr;
    reg [3:0] r_vga_r;
    reg [3:0] r_vga_g;
    reg [3:0] r_vga_b;

    // Apply 80-pixel borders (Pillarbox / Letterbox)
    wire [9:0] img_x = pixel_x - (offset_x ? 10'd80 : 10'd0);
    wire [9:0] img_y = pixel_y - (offset_y ? 10'd80 : 10'd0);

    reg       inside_image;
    reg [5:0] grid_x;
    reg [4:0] grid_y;

    // Scale coordinate mapping & bounding check (Gated by frame_valid)
    always @(*) begin
        inside_image = 0;
        grid_x       = 0;
        grid_y       = 0;

        if (video_on && format_active && frame_valid) begin
            case (scale)
                2'b00: begin // x10 scale
                    if (img_x < 10'd640 && img_y < 10'd320) begin
                        inside_image = 1;
                        grid_x       = img_x / 10;
                        grid_y       = img_y / 10;
                    end
                end
                2'b01: begin // x15 scale
                    if (img_x < 10'd480 && img_y < 10'd480) begin
                        inside_image = 1;
                        grid_x       = img_x / 15;
                        grid_y       = img_y / 15;
                    end
                end
                2'b10: begin // x20 scale
                    if (img_x < 10'd640 && img_y < 10'd320) begin
                        inside_image = 1;
                        grid_x       = img_x / 20;
                        grid_y       = img_y / 20;
                    end
                end
                2'b11: begin // x30 scale
                    if (img_x < 10'd480 && img_y < 10'd480) begin
                        inside_image = 1;
                        grid_x       = img_x / 30;
                        grid_y       = img_y / 30;
                    end
                end
            endcase
        end
    end

    // Identify Tier 1 formats (128 bytes, supports double-buffering)
    wire is_tier1 = (format_ID == `FMT_32x32_1BPP) || 
                    (format_ID == `FMT_32x16_2BPP) || 
                    (format_ID == `FMT_16x16_4BPP);

    // Buffer base offset: Tier 1 can select Buffer A (0x00) or Buffer B (0x80)
    wire [7:0] tier_base_offset = (is_tier1 && buffer_sel) ? 8'h80 : 8'h00;

    // Compute VRAM Read Address based on format (Scale + Color Depth + Buffer Offset)
    reg [7:0] calc_addr;
    always @(*) begin
        calc_addr = 0;
        case ({scale, color_depth})
            4'b00_00: calc_addr = (grid_y * 8)  + (grid_x[5:3]);
            4'b01_00: calc_addr = (grid_y * 4)  + (grid_x[4:3]);
            4'b01_01: calc_addr = (grid_y * 8)  + (grid_x[4:2]);
            4'b10_01: calc_addr = (grid_y * 8)  + (grid_x[4:2]);
            4'b10_10: calc_addr = (grid_y * 16) + (grid_x[4:1]);
            4'b11_10: calc_addr = (grid_y * 8)  + (grid_x[3:1]);
            4'b11_11: calc_addr = (grid_y * 16) + (grid_x[3:0]);
            default:  calc_addr = 0;
        endcase
        r_vram_r_addr = tier_base_offset + calc_addr;
    end

    // Extract specific bit/pixel value from the fetched VRAM byte
    reg [7:0] pixel_val;
    always @(*) begin
        pixel_val = 0;
        if (inside_image) begin
            case (color_depth)
                2'b00: pixel_val = {7'b0, (vram_r_data >> grid_x[2:0]) & 1'b1};
                2'b01: pixel_val = {6'b0, (vram_r_data >> (grid_x[1:0] * 2)) & 2'b11};
                2'b10: pixel_val = {4'b0, (vram_r_data >> (grid_x[0] * 4)) & 4'hF};
                2'b11: pixel_val = vram_r_data;
            endcase
        end
    end

    // Drive RGB Outputs based on color depth bit-fields
    always @(*) begin
        if (!inside_image) begin
            r_vga_r = 0;
            r_vga_g = 0;
            r_vga_b = 0;
        end else begin
            case (color_depth)
                2'b00: begin // 1BPP: Black & White
                    r_vga_r = pixel_val[0] ? 4'hF : 4'h0;
                    r_vga_g = pixel_val[0] ? 4'hF : 4'h0;
                    r_vga_b = pixel_val[0] ? 4'hF : 4'h0;
                end
                2'b01: begin // 2BPP: Grayscale (4 levels)
                    r_vga_r = {pixel_val[1:0], pixel_val[1:0]};
                    r_vga_g = {pixel_val[1:0], pixel_val[1:0]};
                    r_vga_b = {pixel_val[1:0], pixel_val[1:0]};
                end
                2'b10: begin // 4BPP: RGB 1-2-1 (R G G B)
                    r_vga_r = {4{pixel_val[3]}};
                    r_vga_g = {pixel_val[2:1], pixel_val[2:1]};
                    r_vga_b = {4{pixel_val[0]}};
                end
                2'b11: begin // 8BPP: RGB 3-3-2 (RRR GGG BB)
                    r_vga_r = {pixel_val[7:5], pixel_val[7]};
                    r_vga_g = {pixel_val[4:2], pixel_val[4]};
                    r_vga_b = {pixel_val[1:0], pixel_val[1:0]};
                end
                default: begin
                    r_vga_r = 0;
                    r_vga_g = 0;
                    r_vga_b = 0;
                end
            endcase
        end
    end

    assign vram_r_addr = r_vram_r_addr;
    assign vga_r       = r_vga_r;
    assign vga_g       = r_vga_g;
    assign vga_b       = r_vga_b;

endmodule