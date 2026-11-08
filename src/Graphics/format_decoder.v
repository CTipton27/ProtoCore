`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: format_decoder.v

module format_decoder(
    input[2:0] format_ID,
    
    output format_active,
    output offset_x,
    output offset_y,
    output [1:0] scale, //x10, x15, x20, x30
    output [1:0] color_depth //1, 2, 4, 8
);

    reg r_format_active;
    reg r_offset_x;
    reg r_offset_y;
    reg [1:0] r_scale;
    reg [1:0] r_color_depth;
    
    always @(*) begin
        r_format_active = 0;
        r_offset_x = 0;
        r_offset_y = 0;
        r_scale = 0;
        r_color_depth = 0;
        
        case (format_ID)
            3'h0: begin
                r_format_active = 0;
                r_offset_x = 0;
                r_offset_y = 0;
                r_scale = 0;
                r_color_depth = 0;
            end
            `FMT_32x32_1BPP: begin
                r_format_active = 1;
                r_offset_x = 1;
                r_offset_y = 0;
                r_scale = 2'b01;
                r_color_depth = 2'b00;
            end
            `FMT_32x16_2BPP: begin
                r_format_active = 1;
                r_offset_x = 0;
                r_offset_y = 1;
                r_scale = 2'b10;
                r_color_depth = 2'b01;
            end
            `FMT_16x16_4BPP: begin
                r_format_active = 1;
                r_offset_x = 1;
                r_offset_y = 0;
                r_scale = 2'b11;
                r_color_depth = 2'b10;
            end
            `FMT_64x32_1BPP: begin
                r_format_active = 1;
                r_offset_x = 0;
                r_offset_y = 1;
                r_scale = 2'b00;
                r_color_depth = 2'b00;
            end
            `FMT_32x32_2BPP: begin
                r_format_active = 1;
                r_offset_x = 1;
                r_offset_y = 0;
                r_scale = 2'b01;
                r_color_depth = 2'b01;
            end
            `FMT_32x16_4BPP: begin
                r_format_active = 1;
                r_offset_x = 0;
                r_offset_y = 1;
                r_scale = 2'b10;
                r_color_depth = 2'b10;
            end
            `FMT_16x16_8BPP: begin
                r_format_active = 1;
                r_offset_x = 1;
                r_offset_y = 0;
                r_scale = 2'b11;
                r_color_depth = 2'b11;
            end
            
        endcase
    end
    
    assign format_active = r_format_active;
    assign offset_x      = r_offset_x;
    assign offset_y      = r_offset_y;
    assign scale         = r_scale;
    assign color_depth   = r_color_depth;
    
endmodule

/*
General:
640x480 @ 60Hz
requires 25.175MHz clock

Horizontal: 800
640 visible
16 FP
96 SP
48 BP

Vertical: 525
480 visible
10 FP
2 SP
33 BP


0x0: Nothing.
64x32: 10px per bit
	- scale vertical and horizontal by 10x
	- start vertical at px80
32x32: 15px per bit
	- scale vertical and horizontal by 15x
	- start horizontal at px80
32x16: 20px per bit
	- scale vertical and horizontal by 20x
	- start vertical at px80
16x16: 30px per bit
	- scale vertical and horizontal by 30x
	- start horizontal at px80
*/