`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////
//This module recieves packets from the uart_rx module, and converts them into 24 bit words.
//It will first check to make sure the first packet was a "begin overwrite" packet from RX, then
//will keep overwriting until it recieves one of two stop packets, one to reset PC and one to keep PC.
//This will then handle the logic accordingly and unpause the CPU when its finished.
///////////////////////////////////////////////////////////////////
module cpu_instruction_loader(
    input clk,
    input rst,
    input HALT_flag,
    input packet_ready,
    input data_ack,
    input [7:0] PC_addr,
    input [7:0] uart_packet,
    output reg packet_ack = 0,
    output reg cpu_resume = 0,
    output reg reset_PC = 0,
    output reg iRAM_write_enable = 0,
    output reg [7:0] extern_iRAM_addr = 0,
    output reg [23:0] iRAM_data_in = 0,
    output reg debug_display_reg = 0
    );

    parameter [1:0] IDLE    = 2'b00,
                    RECEIVE = 2'b01,
                    SEND    = 2'b10,
                    END     = 2'b11;

    reg [1:0] state = IDLE;
    reg [1:0] packets_held = 0;
    reg [23:0] full_word = 24'b0;
    reg allow_write = 0;

    always @ (posedge clk) begin

        if (rst) begin
            state <= IDLE;
            packet_ack <= 0;
            cpu_resume <= 0;
            reset_PC <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_data_in <= 0;
            packets_held <= 0;
            allow_write <= 0;
            full_word <= 24'b0;
            debug_display_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cpu_resume <= 0;
                    iRAM_write_enable <= 0;
                    if (packet_ready && !packet_ack)
                        state <= RECEIVE;
                    if (!packet_ready && packet_ack)
                        packet_ack <= 0;
                        
                    if (packets_held == 3) begin
                            packets_held <= 0;
                            if (full_word == 24'hFF0000 && HALT_flag) begin
                                // Start flag: FF0000
                                allow_write <= 1;
                                cpu_resume <= 0;
                            end else if (allow_write) begin
                                case (full_word)
                                    24'hFFD000: begin //Display Param: MMIO
                                        debug_display_reg <= 0;
                                    end
                                    24'hFFE000: begin //Display Param: REG
                                        debug_display_reg <= 1;
                                    end
                                    24'hFFFF00: begin //End flag 1: Reset PC
                                        reset_PC <= 1;
                                        allow_write <= 0;
                                        packets_held <= 0;
                                        full_word <= 24'b0;
                                        extern_iRAM_addr <= 0;
                                        state <= END;
                                    end
                                    24'hFFF000: begin //End flag 2: Keep PC
                                        allow_write <= 0;
                                        packets_held <= 0;
                                        full_word <= 24'b0;
                                        extern_iRAM_addr <= 0;
                                        state <= END;
                                    end
                                    default: begin // Normal instruction
                                        iRAM_data_in <= full_word;
                                        state <= SEND;
                                    end
                                endcase
                            end
                        end else begin
                            cpu_resume <= 0;
                        end
                end 

                RECEIVE: begin
                    if (packet_ready && !packet_ack) begin
                        full_word <= {uart_packet, full_word[23:8]};
                        packets_held <= packets_held + 1;
                        packet_ack <= 1;
                        state <= IDLE;
                    end
                end

                SEND: begin
                    iRAM_write_enable <= 1;
                    if (data_ack) begin
                        iRAM_write_enable <= 0;
                        extern_iRAM_addr <= extern_iRAM_addr + 1;
                        state <= IDLE;
                        full_word <= 24'b0;
                    end
                end

                END: begin
                    cpu_resume <= 1;
                
                    if (!HALT_flag) begin
                        cpu_resume <= 0;
                        reset_PC <= 0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
