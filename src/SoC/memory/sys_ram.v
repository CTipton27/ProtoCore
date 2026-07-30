`timescale 1ns / 1ps
//FILE: sys_ram.v

module sys_ram(
    input clk,
    input [7:0] addr,
    input [7:0] write_data,
    input write_en,
    output [7:0] read_data
    );
    
    parameter [7:0] LED_HI  = 8'h01,
                    LED_LO  = 8'h00,
                    UART_RX = 8'h02,
                    UART_TX = 8'h03,
                    UART_ST = 8'h04;
    
    reg [7:0] mem [255:0];
    
    always @ (posedge clk) begin
        if (write_en) mem[addr] <= write_data;
    end
    
    
    assign read_data = mem[addr];
endmodule
