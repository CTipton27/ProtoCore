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

    integer logs;
    integer i;


    Reg_File_2R1W DUT(
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
		`define LOG_PATH "REGLog.txt"  // fallback path if not passed in
	`endif

	initial begin
		logs = $fopen(`LOG_PATH, "w");
		if (!logs) begin
			$display("Failed to open log file at %s", `LOG_PATH);
			$finish;
		end

    $fdisplay(logs, "REG Testbench Log");
    $fmonitor(logs, "ra: %d | rb: %d | wa: %d | wd: %h | we: %b | read_a: %h | read_b: %h",
              ra, rb, wa, wd, we, read_a, read_b);
        
        wa=0;
        wd=0;
        ra=0;
        rb=0;
        we = 0;
        @(posedge clk);
        
        // Write unique values to every register
        for (i = 0; i < 16; i = i + 1) begin
            we = 1;
            wa = i[3:0];
            wd = i * 8'h11; // 0x00, 0x11, ..., 0xFF
            @(posedge clk);
        end
        
        we = 0;
        @(posedge clk);
        // Read back and verify
        for (i = 0; i < 16; i = i + 1) begin
            ra = i[3:0];
            rb = (15 - i) & 4'hF; // test independent reads
            @(posedge clk);
        end
        
        // Overwrite test
        we = 1;
        wa = 4'd3;
        wd = 8'hAA;
        @(posedge clk);
        we = 0;

        ra = 4'd3;
        rb = 4'd3;
        @(posedge clk);
        
          // Read without write enable (should not change data)
        wa = 4'd5;
        wd = 8'h11;
        we = 0;
        @(posedge clk); // No write should occur

        ra = 4'd5;
        @(posedge clk);

        $fclose(logs);
        $finish;
    end
endmodule
