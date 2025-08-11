`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////
//This module is the interface between the RX channel of UART and
//The rest of the cpu core. when the system is HALTed, it will allow
//recieving. this module just filters the uart packets and outputs
//when a packet is ready, and what the packet is. As of now, it hears a packet_ack
//signal, but does not act on it besides turning off packet_ready. Future updates will
//add some error signaling when a packet was not acknowledged perhaps through a TX transmission.
///////////////////////////////////////////////////////////////////
module uart_rx(
    input clk,
    input HALT_flag,
    input rst,
    input rx,
    input packet_ack,
    output reg packet_ready,
    output reg [7:0] uart_packet
    );

    parameter BAUD_RATE = 115200;
    parameter SYS_CLK_SPEED = 100_000_000;
    
    parameter TICKS_PER_BIT = SYS_CLK_SPEED / BAUD_RATE;
    parameter START_DELAY = TICKS_PER_BIT / 2;

    // FSM States
    parameter [1:0] IDLE = 2'b00,
                    START = 2'b01,
                    RECEIVE = 2'b10;

    reg [1:0] state = IDLE;
    reg [13:0] tick_counter = 0;
    reg [3:0] bit_count = 0;
    reg [7:0] shift_reg = 0;

    always @(posedge clk) begin
        if (rst || !HALT_flag) begin
            state         <= IDLE;
            tick_counter  <= 0;
            bit_count     <= 0;
            shift_reg     <= 0;
            uart_packet   <= 0;
            packet_ready  <= 0;
        end else begin
            // Clear packet_ready only on ack
            if (packet_ready && packet_ack)
                packet_ready <= 0;

            case (state)
                IDLE: begin
                    if (rx == 0 && HALT_flag) begin
                        if (!packet_ready) begin
                            tick_counter <= 0;
                            state <= START;
                        end else begin
                            //Will eventually add some error logic here for if a packet was not recieved by the downstream loader.
                        end
                    end
                end

                START: begin
                    tick_counter <= tick_counter + 1;
                    if (tick_counter == START_DELAY - 1) begin
                        tick_counter <= 0;
                        bit_count <= 0;
                        state <= RECEIVE;
                    end
                end

                RECEIVE: begin
                    tick_counter <= tick_counter + 1;

                    if (tick_counter == TICKS_PER_BIT - 1) begin
                        tick_counter <= 0;

                        if (bit_count < 8) begin
                            shift_reg <= {rx, shift_reg[7:1]};
                            bit_count <= bit_count + 1;
                        end else begin
                            // Stop bit received
                            if (rx == 1) begin
                                uart_packet <= shift_reg;
                                packet_ready <= 1;
                            end
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
