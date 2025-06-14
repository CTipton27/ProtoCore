`timescale 1ns / 1ps

module Reg_File_2R1W(
    input clk,
    input [3:0] ra,
    input [3:0] rb,
    input [3:0] wa,
    input [7:0] wd,
    input we,
    output [7:0] read_a,
    output [7:0] read_b
    );

    reg [7:0] regfile [15:0];
    
    assign read_a = regfile[ra];
    assign read_b = regfile[rb];
    
    always @ (posedge clk) begin
        if (we) begin
            regfile[wa] <= wd;
        end
    end
endmodule