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
    reg [7:0] imm_value;
    reg write_en;
    wire [7:0] read_a;
    wire [7:0] read_b;
    wire alu_carry;
    wire alu_zero;
    
    integer logs;
    integer i;
    reg [7:0] expected_out_alu;
    reg [24:0] op_name;
    
    datapath DUT(
        .clk(clk),
        .rst(rst),
        .alu_en(alu_en),
        .alu_opcode(alu_opcode),
        .imm_value(imm_value),
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
    $fmonitor(logs, "Time: %0t | ra: %d | rb: %d | wa: %d | uwd: %h | we: %b | read_a: %h | read_b: %h | opcode: %d | zero: %b | carry: %b |",
              $time, ra_addr, rb_addr, write_addr, imm_value, write_en, read_a, read_b, alu_opcode, alu_zero, alu_carry);
              
        //Initialize all inputs to 0.
        @(negedge clk);
        alu_opcode = 0;
        alu_en = 0;
        ra_addr = 0;
        rb_addr = 0;
        write_addr = 0;
        imm_value = 0;
        write_en = 0;
        @(posedge clk);
        
//----------------------DEFAULT REG FUNCTIONS----------------------------//
        // Write unique values to every register
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            write_en = 1;
            write_addr = i;
            imm_value = i * 8'h11; // 0x00, 0x11, ..., 0xFF
            @(posedge clk);
        end
        
        @(negedge clk)
        write_en = 0;
        
        // Read back and verify
        for (i = 0; i < 16; i = i + 1) begin
            ra_addr = i;
            rb_addr = 15 - i;
            #3; //testing asynchronous reads
        end
        
        // Overwrite test
        @(negedge clk);
        write_en = 1;
        write_addr = 3;
        imm_value = 8'hAA;
        @(posedge clk);
        
        @(negedge clk);
        write_en = 0;
        #2;
        ra_addr = 3;
        rb_addr = 3;
        @(posedge clk);
        
        //Test write to reg0, should not change
        @(negedge clk);
        write_en = 1;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        @(posedge clk);
        @(posedge clk);
        
        // Read without write enable (should not change data)
        @(negedge clk);
        write_addr = 5;
        imm_value = 8'h11;
        write_en = 0;
        ra_addr = 5;
        @(posedge clk); // No write should occur
        @(posedge clk);

//----------------------ALU REG FUNCTIONS----------------------------//
        //Writes 0 to reg1, 1 to reg2, then increments reg1 to 64
        @(negedge clk);
        alu_opcode = `ADD;
        alu_en = 0;
        ra_addr = 1;
        rb_addr = 2;
        
        //This should write 0 to reg1
        write_en = 1;
        write_addr = 1;
        imm_value = 8'h00;
        @(posedge clk);
        
        //This should write 1 to reg2
        @(negedge clk);
        write_addr = 2;
        imm_value = 8'h01;
        @(posedge clk);
        
        //enable ALU, writing results to reg1.
        @(negedge clk);
        write_addr = 1;
        alu_en = 1;
        alu_opcode = `ADD;
        //reg1 should end at 64
        //The very first loop should be 0+1, the second loop 1+1, then 2+1, etc etc
        for (i = 0; i < 64; i = i+1) begin
            @(posedge clk);
        end
        
        //Test subtraction, should start at 127-10 --> -123
        @(negedge clk);
        alu_en = 0;
        write_addr = 12;
        imm_value = 8'h7F;
        @(posedge clk);
        @(negedge clk);
        write_addr = 6;
        imm_value = 8'h0A;
        @(posedge clk);
        @(negedge clk);
        ra_addr = 12;
        rb_addr = 6;
        alu_opcode = `SUB;
        alu_en = 1;
        write_addr = 12;
        for (i = 0; i < 25; i=i+1) begin
            @(posedge clk);
        end

        $fclose(logs);
        $finish;
    end
endmodule