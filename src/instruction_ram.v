`timescale 1ns / 1ps
//FILE: instruction_ram.v

module instruction_ram(
    input clk,
    input we,
    input [7:0] addr,
    input [23:0] data_in,
    output reg [23:0] data_out
    );
    reg [23:0] mem [255:0]; //256x24 rom
    
    initial $readmemb("program.mem", mem);
    
    always @ (posedge clk) begin
        if (we) 
            mem[addr] <= data_in;
        data_out <= mem[addr];
    end
endmodule
