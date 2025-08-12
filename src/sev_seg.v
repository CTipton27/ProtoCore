`timescale 1ns / 1ps
//FILE: sev_seg.v

module sev_seg(
    input clk, //Currently accepts 100MHZ
    input [7:0] PC_addr,
    output reg [6:0] seg = 0,
    output reg [3:0] an = 0
    );
    
    reg [16:0] seg_counter;
    reg [1:0] digit_sel;
    reg [3:0] digit;
    
    //Inits for double dabble algorithm
    reg [19:0] shift_reg;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    integer i;
    
   
    always @ (*) begin //Double dabble algorithm for BIN to BCD
        shift_reg = 0;
        shift_reg [7:0] = PC_addr;
        
        for (i=0 ; i<8 ; i=i+1) begin //if any BCD sections >= 5, add 3 to carry properly.
            if (shift_reg[11:8] >= 5) shift_reg[11:8] = shift_reg[11:8] + 3;
            if (shift_reg[15:12] >= 5) shift_reg[15:12] = shift_reg[15:12] + 3;
            if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
            //shift left 1.
            shift_reg = shift_reg << 1;
        end
        //extract BCD
        hundreds = shift_reg[19:16];
        tens     = shift_reg[15:12];
        ones     = shift_reg[11:8];
    end
   
    always @ (posedge clk) begin
        seg_counter <= seg_counter +1;
        if (seg_counter == 99_999) begin //Divides by 100,000 (makes 1kHz)
            seg_counter <= 0;
            digit_sel <= digit_sel + 1; //Rotates 0 thru 3
        end
    end 
       
    always @ (*) begin
        case (digit_sel)
            2'b00:begin   digit = ones;     an = 4'b1110;end //Ones
            2'b01:begin   digit = tens;     an = 4'b1101;end //Tens
            2'b10:begin   digit = hundreds; an = 4'b1011;end //Hundreds
            2'b11:begin   digit = 0;        an = 4'b0111;end // thousands, always 0
            default:begin digit = 0;        an = 4'b1111;end
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
