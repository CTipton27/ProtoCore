`timescale 1ns / 1ps
//FILE: reg_vile.v
module reg_file(
    input clk,
    input rst,
    input [3:0] ra,
    input [3:0] rb,
    input [3:0] wa,
    input [7:0] wd,
    input we,
    output [7:0] read_a,
    output [7:0] read_b
    );

    reg [7:0] regfile [15:0];
    assign read_a = (ra == 0) ? 8'b0 : regfile[ra];
    assign read_b = (rb == 0) ? 8'b0 : regfile[rb];
    
    always @ (posedge clk) begin 
        if (rst) regfile[0] <= 8'b0;
        else if (we && wa != 0) regfile[wa] <= wd;
    end
endmodule