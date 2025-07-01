`timescale 1ns / 1ps
//FILE: instruction_rom.v

module instruction_rom(
    input [7:0] addr,
    output [23:0] data
    );
    reg [23:0] rom [255:0]; //256x24 rom
    
    initial $readmemh("program.mem", rom);
    
    
    assign data = rom[addr];
endmodule
