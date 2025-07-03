`timescale 1ns / 1ps
//FILE: sev_seg.v

module sev_seg(
    input clk, //Currently accepts 100MHZ
    input [7:0] PC_addr,
    output reg [6:0] seg,
    output reg [3:0] an
    );
    
    reg [16:0] seg_counter;
    wire [3:0] low_nibble, high_nibble;
    reg [1:0] digit_sel;
    reg [3:0] digit;
    
    assign low_nibble = PC_addr[3:0];
    assign high_nibble = PC_addr[7:4];
    
   
    always @ (posedge clk) begin
        seg_counter <= seg_counter +1;
        if (seg_counter == 99_999) begin //Divides by 100,000 (makes 1kHz)
            seg_counter <= 0;
            digit_sel <= digit_sel + 1; //Rotates 0 thru 3
        end
    end    
    always @ (*) begin
        case (digit_sel)
            2'b00: begin digit = low_nibble; an = 4'b1110; end
            2'b01: begin digit = high_nibble; an = 4'b1101;end
            2'b10: begin digit = 4'b0; an = 4'b1011; end
            2'b11: begin digit = 4'b0; an = 4'b0111;end
        endcase
    end
    always @ (*) seg = hex_to_7seg(digit);
    
    
    function [6:0] hex_to_7seg;
        input [3:0] val;
        case (val)
            4'h0: hex_to_7seg = 7'b1000000;
            4'h1: hex_to_7seg = 7'b1111001;
            4'h2: hex_to_7seg = 7'b0100100;
            4'h3: hex_to_7seg = 7'b0110000;
            4'h4: hex_to_7seg = 7'b0011001;
            4'h5: hex_to_7seg = 7'b0010010;
            4'h6: hex_to_7seg = 7'b0000010;
            4'h7: hex_to_7seg = 7'b1111000;
            4'h8: hex_to_7seg = 7'b0000000;
            4'h9: hex_to_7seg = 7'b0010000;
            4'hA: hex_to_7seg = 7'b0001000;
            4'hB: hex_to_7seg = 7'b0000011;
            4'hC: hex_to_7seg = 7'b1000110;
            4'hD: hex_to_7seg = 7'b0100001;
            4'hE: hex_to_7seg = 7'b0000110;
            4'hF: hex_to_7seg = 7'b0001110;
            default: hex_to_7seg = 7'b1111111;
        endcase
    endfunction
endmodule
