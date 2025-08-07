`timescale 1ns / 1ps
module uart_rom_loader(
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
    reg [23:0] full_word = 0;

    always @ (posedge clk) begin
        // Default clears
        packet_ack <= 0;
        iRAM_write_enable <= 0;
        reset_PC <= 0;

        if (rst || !HALT_flag) begin
            state <= IDLE;
            packet_ack <= 0;
            cpu_paused <= 1;
            reset_PC <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_data_in <= 0;
            full_word <= 0;
            packets_held <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (packet_ready)
                        state <= RECEIVE;
                end

                RECEIVE: begin
                    if (packet_ready) begin
                        full_word <= {uart_packet, full_word[23:8]};
                        packets_held <= packets_held + 1;
                        packet_ack <= 1;

                        if (packets_held == 2) begin
                            packets_held <= 0;
                            if (full_word[15:0] == 16'hFF00 && uart_packet == 8'hFF) begin
                                // End flag 1: FFFF00
                                cpu_paused <= 1;
                                reset_PC <= 1;
                                state <= END;
                            end else if (full_word[15:0] == 16'hF000 && uart_packet == 8'hFF) begin
                                // End flag 2: FFF000
                                cpu_paused <= 1;
                                state <= END;
                            end else begin
                                iRAM_data_in <= {uart_packet, full_word[23:8]};
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
                        extern_iRAM_addr <= extern_iRAM_addr + 1;
                        state <= RECEIVE;
                    end
                end

                END: begin
                    if (reset_PC) begin
                        if (PC_addr == 8'h00)
                            cpu_paused <= 0;
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
endmodule
