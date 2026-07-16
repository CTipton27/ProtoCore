`timescale 1ns / 1ps
//FILE: debug_packet_formatter.v

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
    reg [2:0] byte_index = 0;
    
    always @(posedge clk) begin
        if (rst) begin 
            uart_byte <= 0;
            send_byte <= 0;
            instruction_reg <= 0;
            pc_addr_reg <= 0;
            ra_data_reg <= 0;
            rb_data_reg <= 0;
            byte_index <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin 
                    if (send_debug) begin
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
                            3'h0: uart_byte <= instruction_reg[23:16];
                            3'h1: uart_byte <= instruction_reg[15:8];
                            3'h2: uart_byte <= instruction_reg[7:0];
                            3'h3: uart_byte <= pc_addr_reg;
                            3'h4: uart_byte <= ra_data_reg;
                            3'h5: uart_byte <= rb_data_reg;
                            default: uart_byte <= 8'b0;
                        endcase
                        send_byte <= 1;
                    end else if (tx_busy && send_byte) begin 
                        send_byte <= 0;
                        if (byte_index == 5) begin
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