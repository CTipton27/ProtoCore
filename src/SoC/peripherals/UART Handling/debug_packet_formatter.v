`timescale 1ns / 1ps
//FILE: debug_packet_formatter.v

/* 
If send_debug is high and tx_busy is clear, this module sends a snapshot of the current cpu state. It will send 14 ASCII characters, corresponding to:
1-6  : Current instruction
7-8  : PC Address
9-10 : RA data
11-12: RB data
13-14: \r\n

It will not take any snapshots if the send_debug line is asserted while it is actively transmitting an old snapshot.
During implementation, ensure there is enough time between traces to allow for all 14 bytes to transmit.
*/

module debug_packet_formatter(
    input clk,
    input rst,
    input [23:0] instruction,
    input [7:0] pc_addr,
    input [7:0] ra_data,
    input [7:0] rb_data,
    input send_debug,
    input tx_busy,
    
    output reg [7:0] uart_byte,
    output reg send_byte
    );
    
    parameter IDLE = 1'b0,
              SEND = 1'b1;
    reg state = IDLE;          
    
    reg [23:0] instruction_reg = 0;
    reg [7:0] pc_addr_reg = 0, ra_data_reg = 0, rb_data_reg = 0;
    reg [3:0] byte_index = 0;
    reg send_debug_prev = 0;
    
    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            if(nibble < 10)
                hex_ascii = "0" + nibble;
            else
                hex_ascii = "A" + (nibble - 10);
        end
    endfunction
    
    
    always @(posedge clk) begin
        if (rst) begin 
            uart_byte <= 0;
            send_byte <= 0;
            instruction_reg <= 0;
            pc_addr_reg <= 0;
            ra_data_reg <= 0;
            rb_data_reg <= 0;
            byte_index <= 0;
            send_debug_prev <= 0;
            state <= IDLE;
        end else begin
            send_debug_prev <= send_debug;
            case (state)
                IDLE: begin 
                    if (send_debug && (send_debug != send_debug_prev)) begin
                        instruction_reg <= instruction;
                        pc_addr_reg <= pc_addr;
                        ra_data_reg <= ra_data;
                        rb_data_reg <= rb_data;
                        byte_index <= 0;
                        send_byte <= 0;
                        state <= SEND;
                    end
                end
                
                SEND: begin 
                    if (!tx_busy && !send_byte) begin 
                        case (byte_index)
                            4'd0:  uart_byte <= hex_ascii(instruction_reg[23:20]);
                            4'd1:  uart_byte <= hex_ascii(instruction_reg[19:16]);
                            4'd2:  uart_byte <= hex_ascii(instruction_reg[15:12]);
                            4'd3:  uart_byte <= hex_ascii(instruction_reg[11:8]);
                            4'd4:  uart_byte <= hex_ascii(instruction_reg[7:4]);
                            4'd5:  uart_byte <= hex_ascii(instruction_reg[3:0]);
                            4'd6:  uart_byte <= hex_ascii(pc_addr_reg[7:4]);
                            4'd7:  uart_byte <= hex_ascii(pc_addr_reg[3:0]);
                            4'd8:  uart_byte <= hex_ascii(ra_data_reg[7:4]);
                            4'd9:  uart_byte <= hex_ascii(ra_data_reg[3:0]);
                            4'd10: uart_byte <= hex_ascii(rb_data_reg[7:4]);
                            4'd11: uart_byte <= hex_ascii(rb_data_reg[3:0]);
                            4'd12: uart_byte <= 8'h0D;
                            4'd13: uart_byte <= 8'h0A;                           
                            default: uart_byte <= 8'b0;
                        endcase
                        send_byte <= 1;
                    end else if (tx_busy && send_byte) begin 
                        send_byte <= 0;
                        if (byte_index == 13) begin
                            byte_index <= 0;
                            state <= IDLE;
                        end else byte_index <= byte_index + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
    
    
endmodule