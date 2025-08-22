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

    // UART bit timing (in clock cycles)
    parameter BIT_CYCLES = 868;

    task send_uart_byte(input [7:0] byte);
        integer i;
        begin
            // Start bit
            UART_rx = 0;
            #(BIT_CYCLES*10); // Wait full bit period (nanoseconds)
            // Data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                UART_rx = byte[i];
                #(BIT_CYCLES*10);
            end
            // Stop bit
            UART_rx = 1;
            #(BIT_CYCLES*10);
        end
    endtask

    // Stimulus
    initial begin
        clk_speed = 3'b000;
        clk_visual = 0;
        UART_rx = 1; // idle high for UART
//        rst = 1;
//        #1000;
        rst = 0;

        // Wait for rst to cool off
        #100000; 

        //Start word
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        
send_uart_byte(8'h10);
send_uart_byte(8'h01);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h10);
send_uart_byte(8'hB0);

send_uart_byte(8'h02);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

        //Stop word w/ Reset
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);

        #100000;
        
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        
send_uart_byte(8'h00);
send_uart_byte(8'h02);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h02);
send_uart_byte(8'hA0);

send_uart_byte(8'h01);
send_uart_byte(8'h00);
send_uart_byte(8'hC2);

send_uart_byte(8'h01);
send_uart_byte(8'h20);
send_uart_byte(8'hC1);

send_uart_byte(8'h04);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h03);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);        
        
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        send_uart_byte(8'hFF);
      
        #1000000;
        
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        
send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h05);
send_uart_byte(8'h01);
send_uart_byte(8'h80);

send_uart_byte(8'h06);
send_uart_byte(8'h02);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h23);
send_uart_byte(8'h01);

send_uart_byte(8'h0B);
send_uart_byte(8'h04);
send_uart_byte(8'h80);

send_uart_byte(8'h01);
send_uart_byte(8'h40);
send_uart_byte(8'hC3);

send_uart_byte(8'h01);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);

send_uart_byte(8'h02);
send_uart_byte(8'h00);
send_uart_byte(8'hF0);
        
        send_uart_byte(8'h00);
        send_uart_byte(8'hF0);
        send_uart_byte(8'hFF);
        
        #1000000;
        
        $stop;
    end
endmodule
