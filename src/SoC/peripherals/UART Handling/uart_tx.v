`timescale 1ns / 1ps
//FILE: uart_tx.v

module uart_tx(
    input clk,
    input rst,
    
    input send_byte,
    input [7:0] uart_byte,
    
    output reg tx = 1,
    output reg busy = 0
    );

    parameter BAUD_RATE = 115200;
    parameter SYS_CLK_SPEED = 100_000_000;
    
    parameter TICKS_PER_BIT = SYS_CLK_SPEED / BAUD_RATE;

    // FSM States
    parameter  IDLE    = 1'b0,
               SEND    = 1'b1;

    reg state = IDLE;
    reg [13:0] tick_counter = 14'b0;
    reg [7:0] uart_buffer = 8'b0;
    reg [3:0] bit_index = 4'h0;
   
    always @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            tick_counter <= 0;
            uart_buffer  <= 0;
            busy         <= 0;
            tx           <= 1;
            bit_index    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (send_byte) begin //prepare for transmission
                        uart_buffer <= uart_byte;
                        busy <= 1;
                        tick_counter <= 0;
                        state <= SEND;
                    end
                end

                SEND: begin
                     case(bit_index)
                        4'h0: tx <= 0; // send start bit
                        4'h9: tx <= 1; // send stop bit
                        default: tx <= uart_buffer[bit_index-1]; //send uart_buffer bit
                     endcase
                     
                     tick_counter <= tick_counter + 1;
                     if (tick_counter == TICKS_PER_BIT-1) begin 
                        tick_counter <= 0;
                        if (bit_index == 4'h9) begin // stop bit finished, go back to idle
                            bit_index <= 4'h0;
                            busy <= 0;
                            uart_buffer <= 0;
                            state <= IDLE;
                        end else bit_index <= bit_index + 1;
                     end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule