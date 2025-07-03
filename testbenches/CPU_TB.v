`timescale 1ns / 1ps
//FILE: CPU_TB
module CPU_TB();
    reg clk;
    reg rst;
    
    full_cpu DUT(
        .clk(clk),
        .rst(rst)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
    initial begin
        rst = 1;
        #50
        rst = 0;
    end
endmodule
