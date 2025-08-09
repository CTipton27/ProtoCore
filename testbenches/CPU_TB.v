`timescale 1ns / 1ps

module CPU_TB;
    reg clk;
    reg rst;
    reg [2:0] clk_speed;
    reg clk_visual;
    reg UART_rx;
    wire [6:0] seg;
    wire [3:0] an;
    wire [15:0] led;

    // Instantiate DUT
    full_cpu DUT (
        .clk(clk),
        .rst(rst),
        .clk_speed(clk_speed),
        .clk_visual(clk_visual),
        .UART_rx(UART_rx),
        .seg(seg),
        .an(an),
        .led(led)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        clk_speed = 3'b000;
        clk_visual = 0;
        UART_rx = 1; // idle high for UART
        rst = 1;
        #100;
        rst = 0;

        // Run simulation long enough to inspect waveforms
        #1000;

        $stop;
    end
endmodule
