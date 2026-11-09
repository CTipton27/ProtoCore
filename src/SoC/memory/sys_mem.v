`timescale 1ns / 1ps
`include "ProtoCore.vh"
// FILE: sys_mem.v

module sys_mem(
    input clk,
    input rst,

    input [7:0] addr_a,
    input [7:0] write_data_a,
    input write_en_a,
    output reg [7:0] read_data_a,

    input [7:0] addr_b,
    input [7:0] write_data_b,
    input write_en_b,
    output reg [7:0] read_data_b,

    output reg write_error_a,
    output reg write_error_b,
    
    output [15:0] mmio_led
);

    reg [7:0] mem [0:255];

    reg [7:0] data_a_last;
    reg [7:0] data_b_last;

    reg [7:0] addr_a_last;
    reg [7:0] addr_b_last;

    reg write_a_last;
    reg write_b_last;

    // 16-bit LED Staging & Pending Registers (Atomic 8-bit to 16-bit bridge)
    reg [7:0]  led_low_staging;
    reg        half_word_pending;
    reg [15:0] mmio_led_reg;

    always @(posedge clk) begin
        if (rst) begin
            write_error_a     <= 1'b0;
            write_error_b     <= 1'b0;

            data_a_last       <= 8'h0;
            data_b_last       <= 8'h0;

            addr_a_last       <= 8'h0;
            addr_b_last       <= 8'h0;

            write_a_last      <= 1'b0;
            write_b_last      <= 1'b0;

            led_low_staging   <= 8'h00;
            half_word_pending <= 1'b0;
            mmio_led_reg      <= 16'h0000;
        end 
        else begin
            // Default error flags to 0 each cycle
            write_error_a <= 1'b0;
            write_error_b <= 1'b0;

            // Default updates for last-state trackers
            write_a_last  <= write_en_a;
            write_b_last  <= write_en_b;
            
            if (write_en_a) begin
                addr_a_last <= addr_a;
                data_a_last <= write_data_a;
            end
            if (write_en_b) begin
                addr_b_last <= addr_b;
                data_b_last <= write_data_b;
            end

            // Detect illegal collision (both ports writing to the same address simultaneously)
            if (write_en_a && write_en_b && (addr_a == addr_b)) begin
                write_error_a <= 1'b1;
                write_error_b <= 1'b1;
            end
            else begin
                // Port A write (CPU)
                if (write_en_a) begin
                    case (addr_a)
                        `MMIO_UART_RX:  
                            write_error_a <= 1'b1;
                            
                        `MMIO_LED_LO: begin
                            mem[addr_a]       <= write_data_a; // Write to memory for read-back
                            led_low_staging   <= write_data_a;
                            half_word_pending <= 1'b1;
                        end
                        
                        `MMIO_LED_HI: begin
                            mem[addr_a]       <= write_data_a; // Write to memory for read-back
                            if (half_word_pending) begin
                                mmio_led_reg      <= {write_data_a, led_low_staging}; // Atomic commit to LEDs
                                half_word_pending <= 1'b0;
                            end
                        end
                        
                        default: begin  
                            if (!write_a_last || (addr_a != addr_a_last) || (write_data_a != data_a_last)) begin
                                mem[addr_a] <= write_data_a;
                            end 
                        end
                    endcase         
                end

                // Port B write (Streamer / External Master)
                if (write_en_b) begin
                    case (addr_b)
                        `MMIO_UART_TX:  
                            write_error_b <= 1'b1;
                        default: begin  
                            if (!write_b_last || (addr_b != addr_b_last) || (write_data_b != data_b_last)) begin
                                mem[addr_b] <= write_data_b;
                            end 
                        end
                    endcase         
                end
            end
        end
    end

    // 0-cycle asynchronous read logic
    always @(*) begin
        read_data_a = mem[addr_a];
        read_data_b = mem[addr_b];
    end
    
    assign mmio_led = mmio_led_reg;

endmodule