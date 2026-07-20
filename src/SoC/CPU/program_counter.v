`timescale 1ns / 1ps
//FILE: program_counter.v
module program_counter(
    input clk,
    input rst,
    input enable,
    input load_enable,
    input [7:0] load_data,
    
    output [7:0] addr,
    output reg load_ack = 0
    );
    
    reg [7:0] pc_reg = 0;
    always @ (posedge clk) begin 
        load_ack <= 0;
        if (rst) pc_reg <= 8'b0;//Always start at instruction 0
        else if (load_enable) begin // if overwriting, move to overwritten data.
            pc_reg <= load_data;
            load_ack <= 1; 
        end  
        else if (enable) pc_reg <= pc_reg + 1; 
    end
    assign addr = pc_reg;
    
endmodule
