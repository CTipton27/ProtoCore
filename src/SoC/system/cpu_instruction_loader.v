`timescale 1ns / 1ps
//FILE: instruction_loader.v

module instruction_loader(
    input clk,
    input rst,
    input cpu_halted,
    input programming_active,

    input inst_packet_ready,
    input [23:0] inst_packet,

    input inst_write_ack,

    output reg inst_packet_ack = 0,
    output reg iRAM_write_enable = 0,
    output reg [7:0] extern_iRAM_addr = 0,
    output reg [23:0] iRAM_packet = 0,
    output reg clear_halt = 0
);

    parameter [1:0] IDLE = 1'b0,
                    PROG = 1'b1;

    reg state = IDLE;

    always @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
            inst_packet_ack <= 0;
            iRAM_write_enable <= 0;
            extern_iRAM_addr <= 0;
            iRAM_packet <= 0;
            clear_halt <= 0;
        end
        else begin
            if (inst_packet_ack && !inst_packet_ready)
                inst_packet_ack <= 0;

            case (state)
                IDLE: begin
                    iRAM_write_enable <= 0;
                    extern_iRAM_addr <= 0;
                    iRAM_packet <= 0;
                    inst_packet_ack <= 0;
                    clear_halt <= 0;
                    
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
                        extern_iRAM_addr <= extern_iRAM_addr + 1'b1;
                    end
                    else if (inst_packet_ready && !inst_packet_ack) begin
                        inst_packet_ack <= 1;
                        iRAM_packet <= inst_packet;
                        iRAM_write_enable <= 1;
                    end
                end
            endcase
        end
    end

endmodule