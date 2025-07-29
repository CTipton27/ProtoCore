`timescale 1ns / 1ps
`define ADD 3'b000
`define SUB 3'b001
`define AND 3'b010
`define OR  3'b011
`define XOR 3'b100
`define NOT 3'b101
`define SHL 3'b110
`define SHR 3'b111

module ALU_TB();
    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] opcode;
    wire carry;
    wire zero;
    wire [7:0] out;
    integer status = 2;

    integer logs;
    integer excel_logs;
    reg [7:0] expected_out;
    reg [24:0] op_name;
    integer i = 0;
    integer j = 0;

    ALU DUT(
        .a(a),
        .b(b),
        .out(out),
        .opcode(opcode),
        .carry(carry),
        .zero(zero)
    );

    // Operation name assignment
    always @(*) begin
        case (opcode)
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

    // Expected output
    always @(*) begin
        case (opcode)
            `ADD: expected_out = a + b;
            `SUB: expected_out = a - b;
            `AND: expected_out = a & b;
            `OR:  expected_out = a | b;
            `XOR: expected_out = a ^ b;
            `NOT: expected_out = ~a;
            `SHL: expected_out = a << 1;
            `SHR: expected_out = a >> 1;
            default: expected_out = 8'b0;
        endcase
    end

    `ifndef LOG_PATH
        `define LOG_PATH "ALUlog.txt"
    `endif
    `ifndef EXCEL_LOG_PATH
        `define EXCEL_LOG_PATH "EALUlog.txt"
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

        $fdisplay(logs, "ALU Testbench Log");
        $fdisplay(excel_logs, "Time | A | B | OPCODE | CARRY | ZERO | OUT | STATUS");

        // ADD
        opcode = `ADD;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                a = 2**i;
                b = 2**j;
                #10;
                check_result();
            end
        end

        // SUB
        opcode = `SUB;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                a = 2**i;
                b = 2**j;
                #10;
                check_result();
            end
        end

        // AND
        opcode = `AND;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;
                check_result();
            end
        end

        // OR
        opcode = `OR;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;
                check_result();
            end
        end

        // XOR
        opcode = `XOR;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;
                check_result();
            end
        end

        // NOT
        opcode = `NOT;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;
            check_result();
        end

        // SHL
        opcode = `SHL;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;
            check_result();
        end

        // SHR
        opcode = `SHR;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;
            check_result();
        end

        $fclose(logs);
        $fclose(excel_logs);
        $display("All tests completed.");
        $finish;
    end

    task check_result;
        begin
            if (out !== expected_out) begin
                status = 1;
                $fdisplay(logs, "FAIL @ %0t: %s  a=%h b=%h  expected=%h  got=%h", 
                    $time, op_name, a, b, expected_out, out);
            end else begin
                status = 0;
                $fdisplay(logs, "PASS @ %0t: %s  a=%h b=%h  out=%h", 
                    $time, op_name, a, b, out);
            end

            // Log to excel-compatible file
            $fdisplay(excel_logs, "%0t | %d | %d | %b | %b | %b | %d | %1d", 
                $time, a, b, opcode, carry, zero, out, status);
        end
    endtask

endmodule
