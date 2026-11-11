`timescale 1ns / 1ps
//FILE: rx_decoder.v

module rx_decoder(
    input clk_system,
    input rst,
    input byte_ready,
    input [7:0] uart_byte,
    
    input inst_packet_ack,
    input reset_ack,
    input step_ack,
    
    output reg debug_display = 0,
    output programming_active,
    output reg reset_pc_req,
    output reg debug_mode,
    output reg step_cpu_req,
    output reg [23:0] inst_packet,
    output reg inst_packet_ready,
    output reg uart_byte_ack
);
    
    parameter [1:0] IDLE = 2'b00,
                    PROG = 2'b01,
                    DEBG = 2'b10;
    
    reg [1:0] state = IDLE;
    reg debug_listen = 0;
    reg [1:0] byte_counter = 0;
    reg programming_active_reg;
    reg [23:0] temp_packet = 24'b0;
    
    always @(posedge clk_system) begin  
        if (rst) begin
            state <= IDLE; 
            programming_active_reg <= 0;
            debug_listen <= 0;
            reset_pc_req <= 0;
            debug_mode <= 0;
            step_cpu_req <= 0;
            byte_counter <= 0;
            inst_packet <= 0;
            inst_packet_ready <= 0;
            uart_byte_ack <= 0;
            temp_packet <= 0;
        end
        else begin
            if (reset_pc_req && reset_ack) begin
                reset_pc_req <= 0;
                programming_active_reg <= 0;
                state <= debug_mode ? DEBG : IDLE;
            end 
            else if (step_cpu_req && step_ack)
                step_cpu_req <= 0;
            else if (inst_packet_ready && inst_packet_ack)
                inst_packet_ready <= 0;
            else if (!inst_packet_ready) begin 
                if (byte_ready & !uart_byte_ack) begin
                    uart_byte_ack <= 1;
                    
                    case (state)
                        IDLE: begin
                            case (uart_byte)
                                8'hF1: begin // Begin program stream
                                    state <= PROG;
                                    programming_active_reg <= 1;
                                    byte_counter <= 0;
                                end
                                8'hF4: debug_display <= 0;
                                8'hF5: debug_display <= 1;
                                8'hF6: begin
                                    debug_listen <= 1;
                                    state <= DEBG;
                                end
                                8'hF7: begin
                                    if (!reset_pc_req)
                                        reset_pc_req <= 1; 
                                end 
                                default: begin end 
                            endcase
                        end
                        
                        PROG: begin 
                            // Accumulate 3 bytes blindly into the window first
                            case (byte_counter)
                                2'd0: begin
                                    temp_packet[7:0] <= uart_byte;
                                    byte_counter <= 2'd1;
                                end
                                2'd1: begin
                                    temp_packet[15:8] <= uart_byte;
                                    byte_counter <= 2'd2;
                                end
                                2'd2: begin
                                    temp_packet[23:16] <= uart_byte;
                                    byte_counter <= 2'd0; // Reset counter for next window
                                    
                                    // NOW check the 3rd byte to see if it's a system command
                                    case (uart_byte)
                                            8'hF2: begin // End programming, keep PC
                                                programming_active_reg <= 0;
                                                state <= debug_mode ? DEBG : IDLE;
                                            end
                                            8'hF3: begin // End programming, reset PC
                                                reset_pc_req <= 1;
                                                state <= PROG;
                                            end
                                            8'hF4: begin
                                                debug_display <= 0;
                                            end
                                            8'hF5: begin
                                                debug_display <= 1;
                                            end
                                            default: begin
                                                // Not a system command; pass the 3-byte window as an instruction!
                                                inst_packet <= {uart_byte, temp_packet[15:8], temp_packet[7:0]};
                                                inst_packet_ready <= 1;
                                            end
                                    endcase
                                end
                            endcase
                        end
                        
                        DEBG: begin
                            case (uart_byte)
                                8'h00: begin
                                    if (debug_listen) begin 
                                        debug_listen <= 0;
                                        debug_mode <= 0;
                                        state <= IDLE;
                                    end
                                end
                                8'h01: begin
                                    if (debug_listen) begin
                                        debug_mode <= 1;
                                        debug_listen <= 0;
                                    end
                                end
                                8'hF4: debug_display <= 0;
                                8'hF5: debug_display <= 1;
                                8'hF6: debug_listen <= 1;
                                8'hF7: begin if (!reset_pc_req) reset_pc_req <= 1; end
                                8'hF8: begin if (!step_cpu_req) step_cpu_req <= 1; end
                                default: begin end
                            endcase
                        end
                    endcase
                end 
                else begin
                    if (!byte_ready & uart_byte_ack) 
                        uart_byte_ack <= 0;
                end 
            end
        end
    end
    
    assign programming_active = programming_active_reg;
    
endmodule