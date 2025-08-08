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
    output reg packet_ack,
    output reg cpu_paused,
    output reg reset_PC,
    output reg iRAM_write_enable,
    output reg [7:0] extern_iRAM_addr,
    output reg [23:0] iRAM_data_in
    );

    parameter [1:0] IDLE    = 2'b00,
                    RECEIVE = 2'b01,
                    SEND    = 2'b10,
                    END     = 2'b11;

    reg [1:0] state = IDLE;
    reg [1:0] packets_held = 0;
    reg [15:0] temp_word = 0;
    wire [23:0] full_word;
    wire wait_for_PC_reset;

    always @ (posedge clk) begin

        if (rst || !HALT_flag) begin
            state <= IDLE;
            packet_ack <= 0;
            cpu_paused <= 1;
            reset_PC <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_data_in <= 0;
            temp_word <= 0;
            packets_held <= 0;
        end else begin
            case (state)
                IDLE: begin
                    iRAM_write_enable <= 0;
                    if (packet_ready & !packet_ack)
                        state <= RECEIVE;
                    if (!packet_ready & packet_ack)
                        packet_ack <= 0;
                end

                RECEIVE: begin
                    if (packet_ready & !packet_ack) begin
                        temp_word <= {uart_packet, temp_word[15:8]};
                        packets_held <= packets_held + 1;
                        packet_ack <= 1;

                        if (packets_held >= 2) begin //this will not trigger until 3rd recieve line (since packets_held is updated at the end of the clock)
                            packets_held <= 0;
                            if ({uart_packet, temp_word} == 24'hFFFF00) begin
                                // End flag 1: FFFF00
                                cpu_paused <= 1;
                                reset_PC <= 1;
                                state <= END;
                            end else if ({uart_packet, temp_word} == 24'hFFF00) begin
                                // End flag 2: FFF000
                                cpu_paused <= 1;
                                state <= END;
                            end else begin
                                iRAM_data_in <= full_word;
                                state <= SEND;
                            end
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                SEND: begin
                    iRAM_write_enable <= 1;
                    if (data_ack) begin
                        iRAM_write_enable <= 0;
                        extern_iRAM_addr <= extern_iRAM_addr + 1;
                        state <= IDLE;
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
                end

                default: state <= IDLE;
            endcase
        end
    end
    
    assign wait_for_PC_reset = (PC_addr == 8'b0) ? 0 : 1; //wire only high if PC_addr is 8'b0
    assign full_word = {uart_packet , temp_word};
endmodule
