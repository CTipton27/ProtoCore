`timescale 1ns / 1ps
//FILE: rx_decoder

/*
After data is received from uart_rx module, it is transmitted here to be contextualized. It determines
whether the incoming byte is data, system commands, program information, etc, and raises relevant signals.
*/

module rx_decoder(
    input clk_system,
    input rst,
    input byte_ready,
    input [7:0] uart_byte,
    
    input inst_byte_ack,
    input reset_ack,
    input step_ack,
    
    output reg debug_display = 0,
    output programming_active,
    output reg reset_pc_req,
    output reg debug_mode,
    output reg step_cpu_req,
    output reg [7:0] inst_byte,
    output reg inst_byte_ready,
    
    
    output reg uart_byte_ack
    );
    
    parameter [1:0] IDLE = 2'b00,
                    PROG = 2'b01,
                    DEBG = 2'b10;
    
    reg [1:0] state = IDLE;
    reg debug_listen = 0;
    reg [1:0] byte_counter = 0;
    reg programming_active_reg;
    
    always @(posedge clk_system) begin 
        if (rst) begin
            state <= IDLE; 
            programming_active_reg <= 0;
            debug_listen <= 0;
            reset_pc_req <= 0;
            debug_mode <= 0;
            step_cpu_req <= 0;
            byte_counter <= 0;
            inst_byte <= 0;
            inst_byte_ready <= 0;
            uart_byte_ack <= 0;
            //leave display unchanged even when resetting
        end
        else begin
            if (reset_pc_req && reset_ack) begin
                reset_pc_req <= 0;
                programming_active_reg <= 0;
                if (debug_mode)
                    state <= DEBG;
                else
                    state <= IDLE;
            end else
            
            if (step_cpu_req && step_ack)
                step_cpu_req <= 0;
            else 
            
            if (inst_byte_ready && inst_byte_ack)
                inst_byte_ready <= 0;
            
            else if (!inst_byte_ready) begin 
                if (byte_ready & !uart_byte_ack) begin
                    uart_byte_ack <= 1;
                    
                    case (state)
                        IDLE: begin
                            case (uart_byte)
                                8'hF1: begin //begin program
                                    state <= PROG;
                                    programming_active_reg <= 1;
                                    byte_counter <= 0;
                                end
                                
                                8'hF4: begin //MMIO display
                                    debug_display <= 0;
                                end
                                
                                8'hF5: begin //REG display
                                    debug_display <= 1;
                                end
                                
                                8'hF6: begin //Debug Mode
                                    debug_listen <= 1;
                                    state <= DEBG;
                                end
                                
                                8'hF7: begin //Reset
                                    if (!reset_pc_req)
                                        reset_pc_req <= 1; 
                                end   
                                default: begin end 
                            endcase // uart_byte 
                        end // IDLE state
                        
                        PROG: begin 
                            if (byte_counter == 0) begin
                                case (uart_byte)
                                    8'hF2: begin //end, keep PC
                                        programming_active_reg <= 0;
                                        byte_counter <= 0;
                                        if (debug_mode) 
                                            state <= DEBG; 
                                        else 
                                            state <= IDLE;
                                    end
                                    
                                    8'hF3: begin  //end, reset PC
                                        reset_pc_req <= 1;
                                        byte_counter <= 0;
                                        state <= PROG; // do not leave until reset is confirmed!
                                    end
                                    
                                    8'hF4: begin //MMIO display
                                        debug_display <= 0;
                                        byte_counter <= 0;
                                    end
                                    
                                    8'hF5: begin //REG display
                                        debug_display <= 1;
                                        byte_counter <= 0;
                                    end
                                    
                                    8'hF6: begin //check DEBUG mode
                                        debug_listen <= 1;
                                        byte_counter <= 1;
                                    end
                                    
                                    default: begin //instruction data
                                        inst_byte <= uart_byte;
                                        inst_byte_ready <= 1;
                                        byte_counter <= 1;
                                    end
                                endcase //uart_byte
                            end //byte_counter == 0 
                            else if (byte_counter == 1) begin
                                if (debug_listen) begin
                                    case (uart_byte)
                                        8'h00: begin //normal mode
                                            debug_listen <= 0;
                                            debug_mode <= 0;
                                            byte_counter <= 0;
                                        end
                                        
                                        8'h01: begin
                                            debug_listen <= 0;
                                            debug_mode <= 1;
                                            byte_counter <= 0;
                                        end
                                    endcase
                                end //debug_listen 
                                else begin
                                    inst_byte <= uart_byte;
                                    inst_byte_ready <= 1;
                                    byte_counter <= 2;
                                end //!debug_listen
                            end //byte_counter == 1
                            else begin
                                inst_byte <= uart_byte;
                                inst_byte_ready <= 1;
                                byte_counter <= 0;
                            end //byte_counter == 2
                        end // PROG state
                        
                        DEBG: begin
                            case (uart_byte)
                                8'h00: begin //run in normal mode
                                    if (debug_listen) begin 
                                        debug_listen <= 0;
                                        debug_mode <= 0;
                                        state <= IDLE;
                                    end // debug_listen
                                end
                                
                                8'h01: begin //run in debug mode
                                    if (debug_listen) begin
                                        debug_mode <= 1;
                                        debug_listen <= 0;
                                    end
                                end
                                
                                8'hF4: begin //MMIO display
                                    debug_display <= 0;
                                    byte_counter <= 0;
                                end
                                
                                8'hF5: begin //REG display
                                    debug_display <= 1;
                                    byte_counter <= 0;
                                end
                                
                                8'hF6: begin 
                                    debug_listen <= 1;
                                end
                                
                                8'hF7: begin 
                                    if (!reset_pc_req)
                                        reset_pc_req <= 1;
                                end
                                
                                8'hF8: begin //Step PC
                                    if (!step_cpu_req)
                                        step_cpu_req <= 1;
                                end
                            endcase // uart_byte
                        end // DEBG state
                        
                    endcase //state
                end else begin//byte_ready & !uart_byte_ack
                    if (!byte_ready & uart_byte_ack) uart_byte_ack <= 0;
                end 
            end //!inst_packet_ready
        end //!rst
    end //posedge clk
    
    assign programming_active = programming_active_reg;
    
endmodule