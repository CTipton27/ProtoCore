`timescale 1ns / 1ps
`define ADD 3'b000
`define SUB 3'b001
`define AND 3'b010
`define OR  3'b011
`define XOR 3'b100
`define NOT 3'b101
`define SHL 3'b110
`define SHR 3'b111

module DATAPATH_TB();
    reg clk;
    reg write_alu;
    reg [2:0] alu_opcode;
    reg [7:0] ram_data, imm_data;
    reg [3:0] write_addr, ra_addr, rb_addr;
    reg write_en;
    reg is_load;
    reg imm_flag;
    wire [7:0] read_a, read_b;
    wire alu_zero, alu_carry;
    wire [7:0] alu_out;

    reg fail;
    integer logs;
    integer excel_logs;
    integer i;
    reg [7:0] expected_out_alu;
    reg [7:0] expected_reg[15:0];
    reg [24:0] op_name;
    
    datapath DUT(
        .clk(clk),
        .write_alu(write_alu),
        .alu_opcode(alu_opcode),
        .ram_data(top_data),
        .imm_data(top_data),
        .write_addr(write_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .is_load(is_load),
        .imm_flag(imm_flag),
        .read_a(read_a), 
        .read_b(read_b),
        .alu_zero(alu_zero), 
        .alu_carry(alu_carry),
        .alu_out(alu_out)
    );
    
    always @(*) begin
        case (alu_opcode)
            `ADD: op_name = "ADD";
            `SUB: op_name = "SUB";
            `AND: op_name = "AND";
            `OR:  op_name = "OR ";
            `XOR: op_name = "XOR";
            `NOT: op_name = "NOT";
            `SHL: op_name = "SHL";
            `SHR: op_name = "SHR";
            default: op_name = "UNK";
        endcase
    end
    
//----------------------SETUP ENVIRONMENT----------------------------//    

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
    
    `ifndef LOG_PATH
		`define LOG_PATH "DATAPATHlog.txt"  // fallback path if not passed in
	`endif
	`ifndef EXCEL_LOG_PATH
	   `define EXCEL_LOG_PATH "EDATAPATHlog.txt"
	`endif
	
	initial begin
		logs = $fopen(`LOG_PATH, "w");
		if (!logs) begin
			$display("Failed to open log file at %s", `LOG_PATH);
			$finish;
		end
		excel_logs = $fopen(`EXCEL_LOG_PATH, "w");
		if (!excel_logs) begin
		    $display("Failed to open log file at %s", `EXCEL_LOG_PATH);
			$finish;
	    end
	    
	$fdisplay(logs, "DATAPATH Testbench Log");
    $fmonitor(excel_logs, "%0t | %d | %d | %d | %h | %h | %b | %h | %h | %h | %b | %b | %b | %b",
              $time, ra_addr, rb_addr, write_addr, imm_data, ram_data, write_en, read_a, read_b, alu_opcode, alu_zero, alu_carry, imm_flag, fail);
    end
endmodule