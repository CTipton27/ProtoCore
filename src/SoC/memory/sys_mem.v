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
    
    output [15:0] mmio_led,
    
    output [8:0] uart_status
);
    reg [7:0] mem [0:255];

    reg [7:0] data_a_last;
    reg [7:0] data_b_last;

    reg [7:0] addr_a_last;
    reg [7:0] addr_b_last;

    reg write_a_last;
    reg write_b_last;


    always @(posedge clk) begin
        if (rst) begin
            write_error_a <= 1'b0;
            write_error_b <= 1'b0;

            data_a_last  <= 8'b0;
            data_b_last  <= 8'b0;

            addr_a_last  <= 8'b0;
            addr_b_last  <= 8'b0;

            write_a_last <= 1'b0;
            write_b_last <= 1'b0;
        end //rst
        else begin
            // Detect illegal collision
            if (write_en_a &&
                write_en_b &&
                (addr_a == addr_b)) begin
                write_error_a <= 1'b1;
                write_error_b <= 1'b1;
            end
            
            // Port A write
            else begin
            if (write_en_a) begin
                //Check for illegal CPU write locations
                case (addr_a)
                    `MMIO_UART_RX: 
                        write_error_a <= 1;
                    default: begin 
                        if (!write_a_last ||
                           (addr_a != addr_a_last) ||
                           (write_data_a != data_a_last)) begin
    
                            mem[addr_a] <= write_data_a;
                            data_a_last  <= write_data_a;
                            addr_a_last  <= addr_a;
                            write_a_last <= write_en_a;
                        end 
                    end
                endcase            
            end

            // Port B write
            if (write_en_b) begin
                //Check for illegal CPU write locations
                case (addr_b)
                    `MMIO_UART_TX: 
                        write_error_b <= 1;
                    default: begin 
                        if (!write_b_last ||
                           (addr_b != addr_b_last) ||
                           (write_data_b != data_b_last)) begin
    
                            mem[addr_b] <= write_data_b;
                            data_b_last  <= write_data_b;
                            addr_b_last  <= addr_b;
                            write_b_last <= write_en_b;
                        end 
                    end
                endcase            
            end
            
            end //writes
            

        end //~rst
    end


    // Read logic
    always @(*) begin
        read_data_a = mem[addr_a];
        read_data_b = mem[addr_b];
    end
    
    assign mmio_led = {mem[`MMIO_LED_LO], mem[`MMIO_LED_HI]};

endmodule