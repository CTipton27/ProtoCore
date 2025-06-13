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

    integer logs;
    reg [7:0] expected_out;
    reg [24:0] op_name;
    integer i = 0;
    integer j = 0;
    integer k = 0;

    ALU DUT(
        .a(a),
        .b(b),
        .out(out),
        .opcode(opcode),
        .carry(carry),
        .zero(zero)
    );

    // Assign operation name for readable logs
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

    // Compute expected output combinationally based on opcode
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

    initial begin
        logs = $fopen("log.txt", "w");
        if (!logs) begin
            $display("Failed to open log file!");
            $finish;
        end

        $fdisplay(logs, "ALU Testbench Log");

        // Test ADD
        opcode = `ADD;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                a = 2**i;
                b = 2**j;
                #10;
                check_result();
            end
        end

        // Test SUB (including edge cases)
        opcode = `SUB;
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                a = 2**i;
                b = 2**j;
                #10;
                check_result();
            end
        end

        // Test AND
        opcode = `AND;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;  // Let the outputs settle
                check_result();
            end
        end


        // Test OR
        opcode = `OR;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;  // Let the outputs settle
                check_result();
            end
        end

        // Test XOR
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            for (j = 0; j < 256; j = j + 51) begin
                b = j[7:0];
                #10;  // Let the outputs settle
                check_result();
            end
        end

        // Test NOT (only 'a' matters)
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;  // Let the outputs settle
            check_result();
        end

        // Test SHL (check shifting bits left)
        opcode = `SHL;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;  // Let the outputs settle
            check_result();
        end

        // Test SHR (check shifting bits right)
        opcode = `SHR;
        for (i = 0; i < 256; i = i + 17) begin
            a = i[7:0];
            #10;  // Let the outputs settle
            check_result();
        end

        $fclose(logs);
        $display("All tests completed.");
        $finish;
    end

    task check_result;
        begin
            if (out !== expected_out) begin
                $display("ERROR at time %0t: %s failed. a=%h, b=%h, expected=%h, got=%h",
                         $time, op_name, a, b, expected_out, out);
                $fdisplay(logs, "ERROR at time %0t: %s failed. a=%h, b=%h, expected=%h, got=%h",
                          $time, op_name, a, b, expected_out, out);
                $stop;
            end else begin
                $fdisplay(logs, "PASS at time %0t: %s correct. a=%h, b=%h, out=%h",
                         $time, op_name, a, b, out);
            end
        end
    endtask

endmodule