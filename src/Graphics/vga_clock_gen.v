`timescale 1ns / 1ps
// FILE: vga_clock_gen.v

module vga_clock_gen (
    input  wire clk_100mhz,    // Master 100 MHz board clock
    input  wire rst,           // Reset
    output reg  clk_25m        // 25 MHz pixel clock output
);

    reg [1:0] cnt;

    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            cnt     <= 2'b00;
            clk_25m <= 1'b0;
        end else begin
            if (cnt == 2'd1) begin
                cnt     <= 2'b00;
                clk_25m <= ~clk_25m; // Toggle every 2 cycles to get a clean 50% duty cycle 25MHz
            end else begin
                cnt     <= cnt + 1'b1;
            end
        end
    end

endmodule