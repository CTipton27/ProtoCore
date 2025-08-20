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
    output reg cpu_paused = 0,
    output reg reset_PC = 0,
    output reg iRAM_write_enable = 0,
    output reg [7:0] extern_iRAM_addr = 0,
    output reg [23:0] iRAM_data_in = 0
    );

    parameter [1:0] IDLE    = 2'b00,
                    RECEIVE = 2'b01,
                    SEND    = 2'b10,
                    END     = 2'b11;

    reg [1:0] state = IDLE;
    reg [1:0] packets_held = 0;
    reg [23:0] full_word = 24'b0;
    wire wait_for_PC_reset;
    reg allow_write = 0;

    always @ (posedge clk) begin

        if (rst) begin
            state <= IDLE;
            packet_ack <= 0;
            cpu_paused <= 0;
            reset_PC <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_data_in <= 0;
            packets_held <= 0;
        end else begin
            case (state)
                IDLE: begin
                    iRAM_write_enable <= 0;
                    if (packet_ready & !packet_ack)
                        state <= RECEIVE;
                    if (!packet_ready & packet_ack)
                        packet_ack <= 0;
                        
                    if (packets_held == 3) begin
                            packets_held <= 0;
                            if (full_word == 24'hFF0000 && HALT_flag) begin
                                // Start flag: FF0000
                                allow_write <= 1;
                                cpu_paused <= 1;
                            end else if (cpu_paused && full_word == 24'hFFFF00) begin
                                // End flag 1: FFFF00, reset
                                reset_PC <= 1;
                                allow_write <= 0;
                                state <= END;
                            end else if (cpu_paused && full_word == 24'hFFF000) begin
                                // End flag 2: FFF000, do not reset
                                allow_write <= 0;
                                state <= END;
                            end else if (allow_write == 1) begin
                                iRAM_data_in <= full_word;
                                state <= SEND;
                            end
                        end
                end

                RECEIVE: begin
                    if (packet_ready & !packet_ack) begin
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
                    if (reset_PC) begin
                        if (!wait_for_PC_reset) begin
                            cpu_paused <= 0;
                            reset_PC <= 0;
                        end
                    end else begin
                        cpu_paused <= 0;
                    end

                    if (!cpu_paused)
                        state <= IDLE;
                        
                    extern_iRAM_addr <= 0;
                    full_word <= 24'b0;
                end

                default: state <= IDLE;
            endcase
        end
    end
    
    assign wait_for_PC_reset = (PC_addr == 8'b0) ? 0 : 1; //wire only high if PC_addr is 8'b0
endmodule
