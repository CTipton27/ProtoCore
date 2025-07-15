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

    reg [2:0] alu_opcode;
    reg clk;
    reg write_alu;
    reg [3:0] ra_addr;
    reg [3:0] rb_addr;
    reg [3:0] write_addr;
    reg [7:0] top_data;
    reg imm_flag;
    reg is_load = 0;
    reg write_en;
    wire [7:0] read_a;
    wire [7:0] read_b;
    wire alu_carry;
    wire alu_zero;
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
              
//----------------------START TEST----------------------------//       
       
        //Initialize all inputs to 0.
        @(negedge clk);
        alu_opcode = 0;
        write_alu = 0;
        ra_addr = 0;
        rb_addr = 0;
        imm_flag = 0;
        write_addr = 0;
        top_data = 0;
        write_en = 0;
        fail = 0;
        @(posedge clk);
        
//----------------------DEFAULT REG FUNCTIONS----------------------------//
//----------------------STANDARD READ----------------------------//
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);
            write_en = 1;
            imm_flag = 1;
            write_addr = i;
            top_data = i * 8'h11; // 0x00, 0x11, ..., 0xFF
            expected_reg[write_addr] = top_data;
            @(posedge clk);
        end
        
        @(negedge clk)
        write_en = 0;
        imm_flag = 0;
        
        // Read back and verify
        for (i = 0; i < 16; i = i + 1) begin 
            fail = 0;
            ra_addr = i; //0, 1, 2, ...
            rb_addr = 15 - i; //15, 14, 13, ...
            #3; //testing asynchronous reads
            if (read_a !== expected_reg[ra_addr]) begin
                $fdisplay(logs, "FAIL at %0t: read_a[%0d] = %h, expected %h", $time, ra_addr, read_a, expected_reg[ra_addr]);
                fail = 1;
            end
            if (read_b !== expected_reg[rb_addr]) begin
                $fdisplay(logs, "FAIL at %0t: read_b[%0d] = %h, expected %h", $time, rb_addr, read_b, expected_reg[rb_addr]);
                fail = 1;
            end
            if (fail == 0) begin
                $fdisplay(logs, "PASS at %0t: read_a[%0d] = %h, read_b[%0d] = %h", $time, ra_addr, read_a, rb_addr, read_b);
            end
        end
        
//----------------------OVERWRITE----------------------------//
        @(negedge clk);
        fail = 0;
        write_en = 1;
        imm_flag = 1;
        
        write_addr = 3;
        top_data = 8'hAA;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        @(negedge clk);
        write_en = 0;
        imm_flag = 0;
        #2;
        ra_addr = 3;
        rb_addr = 3;
        @(posedge clk);
        if (read_a !== expected_reg[ra_addr]) begin
            $fdisplay(logs, "FAIL: Overwrite test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end else begin
            $fdisplay(logs, "PASS: Overwrite test succeeded, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end
        
//----------------------REG0 WRITE----------------------------//
        @(negedge clk);
        fail=0;
        write_en = 1;
        imm_flag = 1;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        expected_reg[0] = 0;
        top_data = 8'hAA;
        @(posedge clk);
        if (read_a != expected_reg[0]) begin
            $fdisplay(logs, "FAIL: Reg0 test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end else begin
            $fdisplay(logs, "PASS: Reg0 test succeeded, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end
        
//----------------------WRITE ENABLE OFF----------------------------//
        @(negedge clk);
        write_addr = 5;
        top_data = 8'h11;
        write_en = 0;
        ra_addr = 5;
        @(posedge clk); // No write should occur
        if (read_a != expected_reg[ra_addr]) begin
            $fdisplay(logs, "FAIL: Write enable off test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end else begin
            $fdisplay(logs, "PASS: Write enable off test succeeded, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
        end

//----------------------ALU REG FUNCTIONS----------------------------//
        //Writes 0 to reg1, 1 to reg2, then increments reg1 to 64
        @(negedge clk);
        alu_opcode = `ADD;
        write_alu = 0;
        ra_addr = 1;
        rb_addr = 2;
        
        //This should write 0 to reg1
        write_en = 1;
        write_addr = 1;
        imm_flag = 1;
        top_data = 8'h00;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        //This should write 1 to reg2
        @(negedge clk);
        write_addr = 2;
        top_data = 8'h01;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        //enable ALU, writing results to reg1.
        @(negedge clk);
        write_addr = 1;
        write_alu = 1;
        imm_flag = 0;
        alu_opcode = `ADD;
        //reg1 should end at 64
        //The very first loop should be 0+1, the second loop 1+1, then 2+1, etc etc
        for (i = 0; i < 64; i = i+1) begin
            @(posedge clk);
            fail = 0;
            expected_reg[write_addr] = expected_reg[write_addr] + read_b;
            if (read_a != expected_reg[write_addr]) begin
                $fdisplay(logs, "FAIL: ADD test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
            end else begin
                $fdisplay(logs, "PASS: ADD test succeeded, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
            end
        end
        
        //Test subtraction, should start at 127-10 --> -123
        @(negedge clk);
        write_alu = 0;
        write_addr = 12;
        top_data = 8'h7F;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        @(negedge clk);
        write_addr = 6;
        top_data = 8'h0A;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        @(negedge clk);
        ra_addr = 12;
        rb_addr = 6;
        alu_opcode = `SUB;
        write_alu = 1;
        write_addr = 12;
        imm_flag = 0;
        
        for (i = 0; i < 25; i=i+1) begin
            @(posedge clk);
            fail = 0;
            expected_reg[write_addr] = expected_reg[write_addr] - read_b;
            if (read_a != expected_reg[write_addr]) begin
                $fdisplay(logs, "FAIL: SUB test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
            end else begin
                $fdisplay(logs, "PASS: SUB test succeeded, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
            end
        end

        //Test ADDI, should start at 15+12 --> 27
        @(negedge clk);
        write_alu = 0;
        write_addr = 5;
        top_data = 8'h0F;
        expected_reg[write_addr] = top_data;
        @(posedge clk);
        
        @(negedge clk);
        write_addr = 9;
        top_data = 8'h0C;
        expected_reg[write_addr] = top_data;
        @(posedge clk);

        @(negedge clk);
        write_addr = 1;
        write_alu = 1;
        ra_addr = 5;
        rb_addr = 9;
        @(posedge clk);
        ra_addr = 1;
        if (read_a != 27) begin
            $fdisplay(logs, "FAIL: ADDI test failed, read_a = %h, expected 1B", read_a);
        end else begin
            $fdisplay(logs, "PASS: ADDI test succeeded, read_a = %h, expected 1B", read_a, expected_reg[ra_addr]);
        end
        

        $fclose(logs);
        $finish;
    end
endmodule