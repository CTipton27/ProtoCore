`timescale 1ns/1ps

module REG_TB();
    reg clk;
    reg [3:0] ra;
    reg [3:0] rb;
    reg [3:0] wa;
    reg [7:0] wd;
    reg we;
    wire [7:0] read_a;
    wire [7:0] read_b;
    reg [7:0] expected[15:0];
    reg fail;

    integer logs;
    integer excel_logs;
    integer i;


    reg_file DUT(
        .clk(clk),
        .ra(ra),
        .rb(rb),
        .wa(wa),
        .wd(wd),
        .we(we),
        .read_a(read_a),
        .read_b(read_b)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end
	`ifndef LOG_PATH
		`define LOG_PATH "REGlog.txt"  // fallback path if not passed in
	`endif
	`ifndef EXCEL_LOG_PATH
	   `define EXCEL_LOG_PATH "EREGlog.txt"
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
	    
    $fdisplay(logs, "REG Testbench Log");
    $fmonitor(excel_logs, "%0t | %d | %d | %d | %h | %b | %h | %h | %b", 
              $time, ra, rb, wa, wd, we, read_a, read_b, fail);
        
        wa=0;
        wd=0;
        ra=0;
        rb=0;
        we = 0;
        fail = 0;
        @(posedge clk);
        
        // Write unique values to every register
        for (i = 0; i < 16; i = i + 1) begin
            we = 1;
            wa = i[3:0];
            wd = i * 8'h11; // 0x00, 0x11, ..., 0xFF
            expected[wa] = wd;
            @(posedge clk);
        end
        
        we = 0;
        @(posedge clk);
        for (i = 0; i < 16; i = i + 1) begin
            fail = 0;
            ra = i[3:0];
            rb = (15 - i) & 4'hF;
            @(posedge clk);
            if (read_a !== expected[ra]) begin
                $fdisplay(logs, "FAIL at %0t: read_a[%0d] = %h, expected %h", $time, ra, read_a, expected[ra]);
                fail = 1;
            end
            if (read_b !== expected[rb]) begin
                $fdisplay(logs, "FAIL at %0t: read_b[%0d] = %h, expected %h", $time, rb, read_b, expected[rb]);
                fail = 1;
            end
            if (fail == 0) begin
                $fdisplay(logs, "PASS at %0t: read_a[%0d] = %h, read_b[%0d] = %h", $time, ra, read_a, rb, read_b);
            end
            fail = 0;
        end
        
        // Overwrite test
        we = 1;
        wa = 4'd3;
        wd = 8'hAA;
        expected[wa] = wd;
        @(posedge clk);
        we = 0;

        ra = 4'd3;
        rb = 4'd3;
        @(posedge clk);
        
        if (read_a !== expected[ra]) begin
            $fdisplay(logs, "FAIL: Overwrite test failed, read_a = %h, expected %h", read_a, expected[ra]);
            fail = 1;
        end else begin
            $fdisplay(logs, "PASS: Overwrite test Succeeded, read_a = %h, expected %h", read_a, expected[ra]);
        end
          // Read without write enable (should not change data)
        fail = 0;
        wa = 4'd5;
        wd = 8'h11;
        we = 0;
        @(posedge clk); // No write should occur

        ra = 4'd5;
        @(posedge clk);
        
        if (read_a !== expected[ra]) begin
            $fdisplay(logs, "FAIL: Write enable off test failed, read_a = %h, expected %h", read_a, expected[ra]);
        end else begin
            $fdisplay(logs, "PASS: Write enable off test Succeeded, read_a = %h, expected %h", read_a, expected[ra]);
            fail = 1;
        end

        $fclose(logs);
        $finish;
    end
endmodule
