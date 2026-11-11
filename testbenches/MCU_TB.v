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

    // VGA simulation wires
    wire vga_hsync;
    wire vga_vsync;
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;

    // Instantiate DUT (Basys 3 Wrapper) with VGA outputs hooked up
    basys_3_wrapper DUT (
        .clk_system(clk),
        .hard_rst(rst),
        .clk_speed(clk_speed),
        .clk_visual(clk_visual),
        .UART_rx(UART_rx),
        .seg(seg),
        .an(an),
        .led(led),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
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
        
        // Begin programming session
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hF1);
        
        // --- Inserted program.txt instructions ---
send_uart_byte(8'hFF);
send_uart_byte(8'h00);
send_uart_byte(8'h81);

send_uart_byte(8'hFF);
send_uart_byte(8'h00);
send_uart_byte(8'h82);

send_uart_byte(8'h00);
send_uart_byte(8'h12);
send_uart_byte(8'hB0);

send_uart_byte(8'h02);
send_uart_byte(8'h10);
send_uart_byte(8'hC0);

send_uart_byte(8'hFF);
send_uart_byte(8'h10);
send_uart_byte(8'h81);

send_uart_byte(8'hFC);
send_uart_byte(8'h00);
send_uart_byte(8'hC0);

send_uart_byte(8'h05);
send_uart_byte(8'h01);
send_uart_byte(8'hA4);

send_uart_byte(8'h80);
send_uart_byte(8'h40);
send_uart_byte(8'h94);

send_uart_byte(8'hFD);
send_uart_byte(8'h40);
send_uart_byte(8'hD0);

send_uart_byte(8'hC0);
send_uart_byte(8'h00);
send_uart_byte(8'h83);

send_uart_byte(8'h06);
send_uart_byte(8'h00);
send_uart_byte(8'hB1);

send_uart_byte(8'h05);
send_uart_byte(8'h03);
send_uart_byte(8'hB1);

send_uart_byte(8'hF5);
send_uart_byte(8'h00);
send_uart_byte(8'hC0);



        // -----------------------------------------
        
        // Stop word w/ Reset (0xF3 = Reset PC)
        send_uart_byte(8'h00);
        send_uart_byte(8'h00);
        send_uart_byte(8'hF3);

        #10000;
        program_mode = 0;
        
        // Let the simulation run long enough to watch memory fill and VGA frame trigger
        #2000000;
        
        $stop;
    end
endmodule