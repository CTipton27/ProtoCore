`timescale 1ns / 1ps
//FILE: program_counter.v
module program_counter(
    input clk,
    input rst,
    input en,
    input overwrite,
    input [7:0] overwrite_data,
    output [7:0] addr
    );
    
    reg [7:0] proc_addr = 0;
    always @ (posedge clk) begin 
        if (rst) proc_addr <= 8'b0;//Always start at instruction 0
        else if (overwrite) proc_addr <= overwrite_data; //if overwriting, move to overwritten data.
        else if (en) proc_addr <= proc_addr + 1; 
    end
    assign addr = proc_addr;
endmodule
