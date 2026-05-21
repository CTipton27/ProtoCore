`timescale 1ns / 1ps
//FILE: clk_visualizer.v

//This module is used to artificially slow the clock on the calculations to .5Hz, 1Hz, 2Hz, or 4Hz. this allows you to easily
//see the outputs on the LEDs and seven segment displays.

module clk_visualizer(
    input clk,
    input [2:0] clk_speed,
    output reg s_clk = 0
    );
    parameter SYS_CLK_SPEED = 100_000_000; //100MHz
    
    reg [31:0] counter = 0;
    reg [31:0] target = SYS_CLK_SPEED;
    reg [2:0] clk_spd_prev = 3'b000;
    
    always @(posedge clk) begin
        if (clk_spd_prev != clk_speed) begin
            case (clk_speed)
                3'b000: target <= SYS_CLK_SPEED /1;   //1Hz
                3'b001: target <= SYS_CLK_SPEED /2;   //2Hz
                3'b010: target <= SYS_CLK_SPEED /4;   //4Hz
                3'b011: target <= SYS_CLK_SPEED /8;   //8Hz
                3'b100: target <= SYS_CLK_SPEED /16;  //16Hz
                3'b101: target <= SYS_CLK_SPEED /32;  //32Hz
                3'b110: target <= SYS_CLK_SPEED /64;  //64Hz
                3'b111: target <= SYS_CLK_SPEED /128; //128Hz
                default: s_clk <= clk;
            endcase
            counter <= 0;
        end else begin
            counter <= counter + 1;
            if (counter >= target) begin
                s_clk <= ~s_clk;
                counter <= 0;
            end
        end
        clk_spd_prev <= clk_speed;
    end
endmodule