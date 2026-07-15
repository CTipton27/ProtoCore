`timescale 1ns / 1ps

module MCU_TB;
    reg clk;
    reg rst;
    reg [2:0] clk_speed;
    reg clk_visual;
    reg UART_rx;
    reg program_mode;
    wire [6:0] seg;
    wire [3:0] an;
    wire [15:0] led;

    // Instantiate DUT
    basys_3_wrapper DUT (
        .clk_system(clk),
        .rst(rst),
        .clk_speed(clk_speed),
        .clk_visual(clk_visual),
        .UART_rx(UART_rx),
        .program_mode(program_mode),
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
        program_mode = 0;
        UART_rx = 1; // idle high for UART
        rst = 1;
        #1000;
        rst = 0;

        // Wait for rst to cool off
        #100000; 
        
        program_mode = 1;
        #10000;

        //Start word
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hFF);
        
send_uart_byte(8'h01);
send_uart_byte(8'h01);
send_uart_byte(8'h80);

send_uart_byte(8'h01);
send_uart_byte(8'h10);
send_uart_byte(8'hB0);

send_uart_byte(8'hFF);
send_uart_byte(8'h10);
send_uart_byte(8'hB0);

send_uart_byte(8'h00);
send_uart_byte(8'h00);
send_uart_byte(8'hB0);

send_uart_byte(8'hFE);
send_uart_byte(8'h00);
send_uart_byte(8'hB0);

send_uart_byte(8'h00);
send_uart_byte(8'h0F);
send_uart_byte(8'hA0);

send_uart_byte(8'h80);
send_uart_byte(8'h0F);
send_uart_byte(8'h9F);

send_uart_byte(8'h07);
send_uart_byte(8'h0D);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h0F);
send_uart_byte(8'h7F);

send_uart_byte(8'hFF);
send_uart_byte(8'h0D);
send_uart_byte(8'h8D);

send_uart_byte(8'hFD);
send_uart_byte(8'h00);
send_uart_byte(8'hDD);

send_uart_byte(8'h01);
send_uart_byte(8'h0E);
send_uart_byte(8'hA0);

send_uart_byte(8'h01);
send_uart_byte(8'h0E);
send_uart_byte(8'h9E);

send_uart_byte(8'h07);
send_uart_byte(8'h0D);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h0E);
send_uart_byte(8'h6E);

send_uart_byte(8'hFF);
send_uart_byte(8'h0D);
send_uart_byte(8'h8D);

send_uart_byte(8'hFD);
send_uart_byte(8'h00);
send_uart_byte(8'hDD);

send_uart_byte(8'h01);
send_uart_byte(8'h0D);
send_uart_byte(8'h80);

send_uart_byte(8'h00);
send_uart_byte(8'h01);
send_uart_byte(8'hAD);

send_uart_byte(8'h00);
send_uart_byte(8'h02);
send_uart_byte(8'hAD);

send_uart_byte(8'h00);
send_uart_byte(8'h03);
send_uart_byte(8'hAD);

send_uart_byte(8'h00);
send_uart_byte(8'h01);
send_uart_byte(8'h71);

send_uart_byte(8'h00);
send_uart_byte(8'h03);
send_uart_byte(8'h63);

send_uart_byte(8'h02);
send_uart_byte(8'h00);
send_uart_byte(8'hCD);

send_uart_byte(8'h00);
send_uart_byte(8'hF3);
send_uart_byte(8'h03);

send_uart_byte(8'h1C);
send_uart_byte(8'h00);
send_uart_byte(8'hE0);

send_uart_byte(8'h00);
send_uart_byte(8'hE1);
send_uart_byte(8'h01);

send_uart_byte(8'h1C);
send_uart_byte(8'h00);
send_uart_byte(8'hE0);

send_uart_byte(8'h00);
send_uart_byte(8'h32);
send_uart_byte(8'h32);

send_uart_byte(8'h00);
send_uart_byte(8'h22);
send_uart_byte(8'h41);

send_uart_byte(8'h03);
send_uart_byte(8'h00);
send_uart_byte(8'hCD);

send_uart_byte(8'h00);
send_uart_byte(8'h26);
send_uart_byte(8'h00);

send_uart_byte(8'h00);
send_uart_byte(8'h0D);
send_uart_byte(8'h80);

send_uart_byte(8'h12);
send_uart_byte(8'h00);
send_uart_byte(8'hE0);

send_uart_byte(8'hFE);
send_uart_byte(8'h20);
send_uart_byte(8'hB0);

send_uart_byte(8'hFF);
send_uart_byte(8'h60);
send_uart_byte(8'hB0);

send_uart_byte(8'h01);
send_uart_byte(8'h0D);
send_uart_byte(8'h80);

send_uart_byte(8'h26);
send_uart_byte(8'h00);
send_uart_byte(8'hE0);

send_uart_byte(8'h01);
send_uart_byte(8'h60);
send_uart_byte(8'hB0);

send_uart_byte(8'h00);
send_uart_byte(8'h20);
send_uart_byte(8'hB0);

send_uart_byte(8'h05);
send_uart_byte(8'h00);
send_uart_byte(8'hE0);
        
        //Stop word w/ Reset
        send_uart_byte(8'h00);
        send_uart_byte(8'hF0);
        send_uart_byte(8'hFF);

#10000;
program_mode = 0;
        #1000000;
        rst = 1;
        #10000;
        rst = 0;
        #1000000;
        $stop;
    end
endmodule