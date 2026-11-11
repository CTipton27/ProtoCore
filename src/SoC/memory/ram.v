`timescale 1ns / 1ps
//FILE: ram.v

module ram(
    input clk,
    input [7:0] addr_cpu,
    input [7:0] addr_b,
    input [7:0] write_data,
    input write_en,
    output [7:0] read_data_cpu,
    output [7:0] read_data_b
    );
    reg [7:0] mem [255:0];
    
    
    integer i;
    initial begin
        for (i = 0; i < 256; i = i+1)
            mem[i] = 8'h00; //initialize values to 0
    end
    
    always @ (posedge clk) begin
        if (write_en) mem[addr_cpu] <= write_data;
    end
    
    
    assign read_data_cpu = mem[addr_cpu];
    assign read_data_b   = mem[addr_b];
endmodule
