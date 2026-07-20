`timescale 1ns / 1ps
//FILE: debug_controller.v

module debug_controller(
    input debug_mode,
    input clk_visual,
    input clk_cpu,
    
    output send_debug_packet
    );
    
    assign send_debug_packet = ~clk_cpu & (clk_visual || debug_mode);
    
endmodule