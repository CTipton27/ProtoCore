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
    reg [7:0] top_data;
    reg [3:0] write_addr, ra_addr, rb_addr;
    reg write_en;
    reg is_load;
    reg alu_imm_flag;
    wire [7:0] read_a, read_b;
    wire alu_zero, alu_carry;
    wire [7:0] alu_out;

    integer status = 2; //Used to convey pass, fail, or initialization.
    integer logs;
    integer excel_logs;
    integer i;
    reg [7:0] expected_out_alu;
    reg [7:0] expected_reg[15:0];
    reg [7:0] RAM = 0;
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
        .alu_imm_flag(alu_imm_flag),
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
        $fmonitor(excel_logs, "%0t | %d | %d | %d | %d | %b | %d | %d | %d | %b | %b | %b | %1d",
                  $time, ra_addr, rb_addr, write_addr, top_data, write_en, read_a, read_b, alu_opcode, alu_zero, alu_carry, alu_imm_flag, status);
                  
        @(negedge clk); //Initialize all inputs to zero
        write_alu = 0;
        alu_opcode = 0; 
        top_data = 0;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        write_en = 0;
        is_load = 0;
        alu_imm_flag = 0;
        status = 2;
        expected_reg[0] = 0;
        @(posedge clk);
        
/////////////////////////////////////////////////////////////////////
//BEGIN TESTING
/////////////////////////////////////////////////////////////////////
        
        //Write unique values to every register
        for (i = 1; i < 16; i = i+1) begin //Values will be 1x11, 2x22, 3x33, ... , FxFF
            @(negedge clk);
            write_en = 1;
            write_addr = i;
            top_data = i * 8'h11;
            @(posedge clk);
            expected_reg[i] = top_data;
        end
        
/////////////////////////////////////////////////////////////////////
//BEGIN READBACK TEST
//Tests asynchronous reads from ra and rb
/////////////////////////////////////////////////////////////////////
        @(negedge clk);
        status = 2;
        write_en = 0;
        top_data = 0;
        write_addr = 0;
        @(posedge clk);
        
        for (i = 0; i < 16; i = i+1) begin
            #2 
            status = 2;
            ra_addr = i;
            rb_addr = 15-i;
            #2
            if (read_a != expected_reg[ra_addr]) begin 
                $fdisplay(logs, "FAIL: Readback test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
                status = 1;
            end else if (read_b != expected_reg[rb_addr]) begin 
                $fdisplay(logs, "FAIL: Readback test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
                status = 1;
            end else begin
                $fdisplay(logs, "PASS: Readback test passed, read_a = %h, read_b = %h", read_a, read_b);
                status = 0;
            end
        end

/////////////////////////////////////////////////////////////////////
//BEGIN FORWARDING / OVERWRITE TEST
//Overwrites R9 with A4
/////////////////////////////////////////////////////////////////////
        @(negedge clk);
        status = 2;
        write_en = 1;
        top_data = 8'hA4;
        write_addr = 9;
        ra_addr = 9;
    
        #0;    
        if (read_a != top_data) begin 
            $fdisplay(logs, "FAIL: FORWARDING test failed, read_a = %h, expected %h", read_a, top_data);
            status = 1;
        end else begin
            $fdisplay(logs, "PASS: FORWARDING test passed, read_a = %h, expected %h", read_a, top_data);
            status = 0;
        end
        @(posedge clk);
        expected_reg[write_addr] = top_data;
        status = 2;
        @(negedge clk);
        status = 2;
        write_en = 0;
        top_data = 0;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 9;
        
        #0;
        if (read_b != expected_reg[rb_addr]) begin 
            $fdisplay(logs, "FAIL: OVERWRITE test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
            status = 1;
        end else begin
            $fdisplay(logs, "PASS: OVERWRITE test passed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
            status = 0;
        end

/////////////////////////////////////////////////////////////////////
//BEGIN R0 TEST
//Attempts to write data to R0
/////////////////////////////////////////////////////////////////////        
            
        @(negedge clk);
        status = 2;
        write_en = 1;
        top_data = 8'hA4;
        write_addr = 0;
        ra_addr = 0;
        if (read_a != 0) begin 
            $fdisplay(logs, "FAIL: R0 FORWARDING test failed, read_a = %h, expected 00", read_a);
            status = 1;
        end else begin
            $fdisplay(logs, "PASS: R0 FORWARDING test passed, read_a = %h, expected 00", read_a);
            status = 0;
        end
        @(posedge clk);
        status = 2;
        @(negedge clk);
        status = 2;
        write_en = 0;
        top_data = 0;
        write_addr = 0;
        rb_addr = 0;
        #0;
        
        if (read_b != expected_reg[rb_addr]) begin 
            $fdisplay(logs, "FAIL: R0 OVERWRITE test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
            status = 1;
        end else begin
            $fdisplay(logs, "PASS: R0 OVERWRITE test passed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
            status = 0;
        end  
        
/////////////////////////////////////////////////////////////////////
//BEGIN MEMORY TEST
//Attempts to load 6C from RAM into R13
/////////////////////////////////////////////////////////////////////
        @(posedge clk);
        status = 2;
        RAM = 8'h6C;
        @(negedge clk);
        status = 2;
        write_en = 1;
        is_load = 1;
        write_addr = 13;
        top_data = RAM;
        @(posedge clk);
        expected_reg[write_addr] = top_data;
        ra_addr = 13;
        rb_addr = 13;
        #0;
        if (read_a != expected_reg[ra_addr]) begin 
            $fdisplay(logs, "FAIL: MEMORY test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
            status = 1;
        end else if (read_b != expected_reg[rb_addr]) begin 
            $fdisplay(logs, "FAIL: MEMORY test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
            status = 1;
        end else begin
            $fdisplay(logs, "PASS: MEMORY test passed, read_a = %h, read_b = %h", read_a, read_b);
            status = 0;
        end
       
/////////////////////////////////////////////////////////////////////
//BEGIN ADDITION TEST
//Begins a loop to add up to 64 on reg1
/////////////////////////////////////////////////////////////////////        
        @(negedge clk);
        is_load = 0;
        status = 2;
        write_en = 1;
        top_data = 0;
        write_addr = 1;
        ra_addr = 1;
        @(posedge clk);
        expected_reg[write_addr] = top_data;
        @(negedge clk);
        write_en = 1;
        top_data = 1;
        write_addr = 2;
        rb_addr = 2;
        @(posedge clk);
        expected_reg[write_addr] = top_data;
        @(negedge clk);
        alu_opcode = `ADD;
        write_alu = 1;
        write_addr = 1;
        for (i = 0; i < 64; i=i+1) begin
            @(posedge clk);
            expected_reg[write_addr] = alu_out;
            if (read_a != expected_reg[ra_addr]) begin 
                $fdisplay(logs, "FAIL: ADD test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
                status = 1;
            end else if (read_b != expected_reg[rb_addr]) begin 
                $fdisplay(logs, "FAIL: ADD test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
                status = 1;
            end else begin
                $fdisplay(logs, "PASS: ADD test passed, read_a = %h, read_b = %h", read_a, read_b);
                status = 0;
            end
        end
        @(negedge clk);
        write_alu = 0;
        alu_opcode = 0; 
        top_data = 0;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        write_en = 0;
        status = 2;
        @(posedge clk);
        
/////////////////////////////////////////////////////////////////////
//BEGIN SUBTRACTION TEST
//Begins a loop to subtract down to to -67 on reg1
///////////////////////////////////////////////////////////////////// 
        @(negedge clk);
        is_load = 0;
        status = 2;
        write_en = 1;
        top_data = 10;
        write_addr = 2;
        ra_addr = 1;
        rb_addr = 2;
        @(posedge clk);
        expected_reg[write_addr] = top_data;
        @(negedge clk);
        alu_opcode = `SUB;
        write_alu = 1;
        write_addr = 1;
        for (i = 0; i < 13; i=i+1) begin
            @(posedge clk);
            expected_reg[write_addr] = alu_out;
            if (read_a != expected_reg[ra_addr]) begin 
                $fdisplay(logs, "FAIL: SUB test failed, read_a = %h, expected %h", read_a, expected_reg[ra_addr]);
                status = 1;
            end else if (read_b != expected_reg[rb_addr]) begin 
                $fdisplay(logs, "FAIL: SUB test failed, read_b = %h, expected %h", read_b, expected_reg[rb_addr]);
                status = 1;
            end else begin
                $fdisplay(logs, "PASS: SUB test passed, read_a = %h, read_b = %h", read_a, read_b);
                status = 0;
            end
        end
        @(negedge clk);
        write_alu = 0;
        alu_opcode = 0; 
        top_data = 0;
        write_addr = 0;
        ra_addr = 0;
        rb_addr = 0;
        write_en = 0;
        status = 2;
        @(posedge clk);
        $fdisplay(logs, "all tests complete");
        $fclose(logs);
        $fclose(excel_logs);
        $finish;
    end //End testing block
endmodule