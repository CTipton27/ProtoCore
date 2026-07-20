`timescale 1ns / 1ps
//FILE: instruction_loader.v

module instruction_loader(
    input clk,
    input rst,
    input cpu_halted,
    input programming_active,

    input inst_byte_ready,
    input [7:0] inst_byte,

    input inst_write_ack,

    output reg inst_byte_ack = 0,
    output reg iRAM_write_enable = 0,
    output reg [7:0] extern_iRAM_addr = 0,
    output reg [23:0] iRAM_packet = 0,
    output reg clear_halt = 0
    );

    parameter [1:0] IDLE = 1'b0,
                    PROG = 1'b1;

    reg [1:0] state = IDLE;

    // Counts received UART bytes (0-2)
    reg [1:0] bytes_held = 0;

    // Holds one complete 24-bit UART packet
    reg [23:0] full_word = 24'b0;

    always @ (posedge clk) begin

        if (rst) begin
            state <= IDLE;
            inst_byte_ack <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_packet <= 0;
            bytes_held <= 0;
            full_word <= 0;
            clear_halt <= 0;
        end
        else begin

            // release byte acknowledge
            if (inst_byte_ack && !inst_byte_ready)
                inst_byte_ack <= 0;

            case (state)
                IDLE: begin
                    bytes_held <= 0;
                    iRAM_write_enable <= 0;
                    extern_iRAM_addr <= 0;
                    iRAM_packet <= 0;
                    full_word <= 0;
                    inst_byte_ack <= 0;
                    
                    if (programming_active)
                        state <= PROG;
                    if (!cpu_halted && clear_halt)
                        clear_halt <= 0;
                end

                PROG: begin
                    if (!programming_active) begin
                        iRAM_write_enable <= 0;
                        extern_iRAM_addr <= 0;
                        clear_halt <= 1;
                        state <= IDLE;
                    end
                    else if (iRAM_write_enable && inst_write_ack) begin
                        iRAM_write_enable <= 0;
                        extern_iRAM_addr <= extern_iRAM_addr + 1;
                    end
                    else if (inst_byte_ready && !inst_byte_ack) begin //new byte

                        inst_byte_ack <= 1;

                        case (bytes_held)
                            2'd0: full_word[7:0] <= inst_byte;

                            2'd1: full_word[15:8] <= inst_byte;

                            2'd2: begin
                                full_word[23:16] <= inst_byte;

                                iRAM_packet <= {
                                    inst_byte,
                                    full_word[15:8],
                                    full_word[7:0]
                                };

                                iRAM_write_enable <= 1;
                            end
                        endcase

                        if (bytes_held == 2)
                            bytes_held <= 0;
                        else
                            bytes_held <= bytes_held + 1;

                    end //inst_byte_ready & !inst_byte_ack
                end
            endcase //state
        end // !rst
    end // clk
endmodule