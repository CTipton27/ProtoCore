`timescale 1ns / 1ps
//FILE: reg_vile.v
module reg_file(
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
    
    always @ (posedge clk) if (we) regfile[wa] <= wd; //note to self: REQUIRES we *BEFORE* posedge to write properly.
endmodule