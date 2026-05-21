`timescale 1ns / 1ps
//FILE: reg_file.v
module reg_file(
    input clk,
    
    input write_enable,
    input [3:0] write_addr,
    input [7:0] write_data,
    
    input [3:0] read_addr_a,
    input [3:0] read_addr_b,

    output [7:0] read_data_a,
    output [7:0] read_data_b
    );

    reg [7:0] regfile [15:0];
    assign read_data_a = (read_addr_a == 0) ? 8'b0 : regfile[read_addr_a];
    assign read_data_b = (read_addr_b == 0) ? 8'b0 : regfile[read_addr_b];
    
    always @(posedge clk) begin
    if (write_addr == 0)
        regfile[0] <= 8'b0;
    else if (write_enable)
        regfile[write_addr] <= write_data;
    end
endmodule