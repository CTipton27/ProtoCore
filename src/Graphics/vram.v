`timescale 1ns / 1ps
// FILE: vram.v

module vram (
    input clk,          // System / Write clock
    
    // Write Port (from Graphics Streamer / System Bus)
    input we,           // Write Enable
    input [7:0] w_addr,       // Write Address (0 to 255)
    input [7:0] w_data,       // Write Data byte
    
    // Read Port (from VGA Pixel Mapper)
    input [7:0] r_addr,       // Read Address (0 to 255)
    output [7:0] r_data        // Read Data byte (combinational read)
);

    // 256 bytes of local VRAM storage
    reg [7:0] mem [0:255];


    integer i;
    initial begin
        for (i = 0; i < 256; i = i+1)
            mem[i] = 8'h00; //initialize values to 0
    end
    // Synchronous Write
    always @(posedge clk) begin
        if (we) begin
            mem[w_addr] <= w_data;
        end
    end

    // Asynchronous Read for instant pixel lookups
    assign r_data = mem[r_addr];

endmodule