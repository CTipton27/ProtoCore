`timescale 1ns / 1ps
//FILE: ram.v

module ram(
    input clk,
    input [7:0] addr,
    input [7:0] write_data,
    input write_en,
    output [7:0] read_data
    );
    reg [7:0] mem [255:0];
    
    always @ (posedge clk) begin
        if (write_en) mem[addr] <= write_data;
    end
    
    assign read_data = mem[addr];
endmodule
