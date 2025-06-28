`timescale 1ns / 1ps
`define ADD 3'b000
`define SUB 3'b001
`define AND 3'b010
`define OR  3'b011
`define XOR 3'b100
`define NOT 3'b101
`define SHL 3'b110
`define SHR 3'b111

module DATAPATH_TB(
    );
    reg [2:0] alu_opcode;
    reg clk;
    reg alu_en;
    reg [3:0] ra_addr;
    reg [3:0] rb_addr;
    reg [3:0] write_addr;
    reg [7:0] user_write_data;
    reg write_en;
    wire [7:0] read_a;
    wire [7:0] read_b;
    wire alu_carry;
    wire alu_zero;
    
    integer logs;
    integer i;
    reg [7:0] expected_out;
    reg [24:0] op_name;
    integer j;
    integer k;
    
    datapath DUT(
        .clk(clk),
        .alu_en(alu_en),
        .alu_opcode(alu_opcode),
        .user_write_data(user_write_data),
        .write_addr(write_addr), 
        .ra_addr(ra_addr), 
        .rb_addr(rb_addr),
        .write_en(write_en),
        .read_a(read_a), 
        .read_b(read_b),
        .alu_zero(alu_zero), 
        .alu_carry(alu_carry)
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
    $fmonitor(logs, "ra: %d | rb: %d | wa: %d | uwd: %h | we: %b | read_a: %h | read_b: %h | opcode: %d | zero: %b | carry: %b |",
              ra_addr, rb_addr, write_addr, user_write_data, write_en, read_a, read_b, alu_opcode, alu_zero, alu_carry);
              
        write_addr=0;
        user_write_data=0;
        ra_addr=0;
        rb_addr=0;
        write_en = 0;
        alu_en = 0;
        @(posedge clk);
        
//----------------------DEFAULT REG FUNCTIONS----------------------------//
        // Write unique values to every register
        write_en = 1;
        for (i = 0; i < 16; i = i + 1) begin
            write_addr = i[3:0];
            user_write_data = i * 8'h11; // 0x00, 0x11, ..., 0xFF
            @(posedge clk);
        end
        
        write_en = 0;
        @(posedge clk);
        // Read back and verify
        for (i = 0; i < 16; i = i + 1) begin
            ra_addr = i[3:0];
            rb_addr = (15 - i) & 4'hF; // test independent reads
            @(posedge clk);
        end
        
        // Overwrite test
        write_en = 1;
        write_addr = 4'd3;
        user_write_data = 8'hAA;
        @(posedge clk);
        write_en = 0;

        ra_addr = 4'd3;
        rb_addr = 4'd3;
        @(posedge clk);
        
          // Read without write enable (should not change data)
        write_addr = 4'd5;
        user_write_data = 8'h11;
        write_en = 0;
        @(posedge clk); // No write should occur

        ra_addr = 4'd5;
        @(posedge clk);

//----------------------ALU REG FUNCTIONS----------------------------//
        //Writes 0 to reg0, 1 to reg1, then increments reg0 to 64
        user_write_data = 8'h01;
        write_addr = 4'd0;
        write_en = 1;
        @(posedge clk);
        
        write_addr = 4'd1;
        user_write_data = 8'h00;
        ra_addr = 4'd0;
        rb_addr = 4'd1;
        alu_opcode = `ADD;
        @(posedge clk);
        
        alu_en = 1;
        for (i = 0; i < 64; i = i+1) begin
            @(posedge clk);
        end
        
        $fclose(logs);
        $finish;
    end
endmodule
