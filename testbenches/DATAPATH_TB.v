`timescale 1ns / 1ps



module DATAPATH_TB(
    );
    reg [2:0] alu_opcode;
    reg clk;
    reg [3:0] ra_addr;
    reg [3:0] rb_addr;
    reg [3:0] write_addr;
    reg [7:0] write_data;
    reg write_en;
    wire [7:0] read_a;
    wire [7:0] read_b;
    wire alu_carry;
    wire alu_zero;
    
    integer logs;
    
    datapath DUT(
        .clk(clk),
        .alu_opcode(alu_opcode),
        .write_data(write_data),
        .write_addr(write_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .read_a(read_a), 
        .read_b(read_b),
        .alu_zero(alu_zero), 
        .alu_carry(alu_carry)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
    `ifndef LOG_PATH
		`define LOG_PATH "DATAPATHlog.txt"  // fallback path if not passed in
	`endif
	initial begin
		logs = $fopen(`LOG_PATH, "w");
		if (!logs) begin
			$display("Failed to open log file at %s", `LOG_PATH);
			$finish;
		end
	$fdisplay(logs, "DATAPATH Testbench Log");
    $fmonitor(logs, "ra: %d | rb: %d | wa: %d | wd: %h | we: %b | read_a: %h | read_b: %h",
              ra, rb, wa, wd, we, read_a, read_b);
    end
endmodule
