`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////
// Receives UART packets and assembles them into 24-bit instructions.
//
// Programming sequence:
//   1. Receive FF0000 start packet while program_mode is enabled.
//   2. Disable CPU execution.
//   3. Accept instructions and write them sequentially into iRAM.
//   4. Receive FFFF00 (reset PC) or FFF000 (keep PC).
//   5. Resume CPU execution.
///////////////////////////////////////////////////////////////////
module cpu_instruction_loader(
    input clk,
    input rst,
    input cpu_halted,
    input packet_ready,
    input data_ack,
    input [7:0] PC_addr,
    input [7:0] uart_packet,
    input program_mode,
    output reg packet_ack = 0,
    output reg cpu_enable = 0,
    output reg reset_PC = 0,
    output reg clear_halt = 0,
    output reg iRAM_write_enable = 0,
    output reg [7:0] extern_iRAM_addr = 0,
    output reg [23:0] iRAM_data_in = 0,
    output reg debug_display_reg = 0
    );

    parameter [1:0] IDLE    = 2'b00,
                    RECEIVE = 2'b01,
                    SEND    = 2'b10;

    reg [1:0] state = IDLE;
    
    // Counts received UART bytes (0-3)
    reg [1:0] packets_held = 0;
    
    // Holds one complete 24-bit UART packet
    reg [23:0] full_word = 24'b0;
    
    // True while a programming session is active
    reg programming_active = 0;

    always @ (posedge clk) begin

        if (rst) begin
            state <= IDLE;
            packet_ack <= 0;
            cpu_enable <= 0;
            reset_PC <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_data_in <= 0;
            packets_held <= 0;
            programming_active <= 0;
            clear_halt <= 0;
            full_word <= 24'b0;
        end else begin
            case (state)
                IDLE: begin
                    // Hold halt request until the CPU has cleared its halt
                    if (clear_halt) begin
                        if (!cpu_halted)
                            clear_halt <= 0;
                    end else
                    // Hold reset request until the CPU has actually reset.
                    if (reset_PC) begin
                        cpu_enable <= 0;
                    
                        if (PC_addr == 8'h00) begin
                            reset_PC <= 0;
                        end
                    end
                    else begin
                        // Normal CPU instruction unless programming.
                        cpu_enable <= !(program_mode || programming_active);
                    end
                    // Accept a newly received UART byte.
                    if (packet_ready && !packet_ack)
                        state <= RECEIVE;
                    // Release acknowledgement once RX lowers packet_ready.
                    if (!packet_ready && packet_ack)
                        packet_ack <= 0;
                    
                    // Three UART bytes form one 24-bit command.
                    if (packets_held == 3) begin
                        packets_held <= 0;
                        // Begin programming session.
                        if (full_word == 24'hFF0000 && program_mode) begin
                            // Start flag: FF0000
                            programming_active <= 1;
                            extern_iRAM_addr <= 0;
                        end else if (programming_active) begin
                            // Handle programming commands.
                            case (full_word)
                                24'hFFD000: begin //Select MMIO LED display
                                    debug_display_reg <= 0;
                                end
                                24'hFFE000: begin //Select REG LED display
                                    debug_display_reg <= 1;
                                end
                                24'hFFFF00: begin //End flag 1: Reset PC
                                    reset_PC <= 1;
                                    programming_active <= 0;
                                    packets_held <= 0;
                                    full_word <= 24'b0;
                                    extern_iRAM_addr <= 0;
                                    clear_halt <= 1;
                                    state <= IDLE;
                                end
                                24'hFFF000: begin //End flag 2: Keep PC
                                    programming_active <= 0;
                                    packets_held <= 0;
                                    full_word <= 24'b0;
                                    extern_iRAM_addr <= 0;
                                    clear_halt <= 1;
                                    state <= IDLE;
                                end
                                default: begin // Normal instruction into iRAM
                                    iRAM_data_in <= full_word;
                                    state <= SEND;
                                end
                            endcase
                        end
                    end
                end 

                RECEIVE: begin
                    if (packet_ready && !packet_ack) begin
                        // Shift incoming UART byte into the current instruction.
                        full_word <= {uart_packet, full_word[23:8]};
                        packets_held <= packets_held + 1;
                        packet_ack <= 1;
                        state <= IDLE;
                    end
                end

                SEND: begin
                    iRAM_write_enable <= 1;
                    // Wait until instruction RAM acknowledges the write.
                    if (data_ack) begin
                        iRAM_write_enable <= 0;
                        // Advance to the next instruction address.
                        extern_iRAM_addr <= extern_iRAM_addr + 1;
                        state <= IDLE;
                        full_word <= 24'b0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
