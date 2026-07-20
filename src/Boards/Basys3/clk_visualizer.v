`timescale 1ns / 1ps
//FILE: clk_visualizer.v

module clk_visualizer(
    input clk,
    input debug_mode,
    input step_cpu_req,
    input [2:0] clk_speed,

    output reg s_clk = 0,
    output reg step_pc_ack = 0
);

    parameter SYS_CLK_SPEED = 100_000_000;

    reg [31:0] counter = 0;
    reg [31:0] target = SYS_CLK_SPEED;
    reg [2:0] clk_spd_prev = 3'b000;

    reg step_pending = 0;
    reg step_req_prev = 0;


    always @(posedge clk) begin

        // Default values every cycle
        step_pc_ack <= 0;

        // Track step request edge
        step_req_prev <= step_cpu_req;


        //----------------------------------------
        // DEBUG MODE
        //----------------------------------------
        if (debug_mode) begin

            s_clk <= 0;
            counter <= 0;

            // Rising edge of step request
            if (step_cpu_req && !step_req_prev && !step_pending) begin
                step_pending <= 1;
                s_clk <= 1;
            end

            // Finish the clock pulse
            else if (step_pending) begin
                s_clk <= 0;
                step_pc_ack <= 1;
                step_pending <= 0;
            end

        end


        //----------------------------------------
        // NORMAL CLOCK MODE
        //----------------------------------------
        else begin

            step_pending <= 0;

            if (clk_spd_prev != clk_speed) begin

                case (clk_speed)
                    3'b000: target <= SYS_CLK_SPEED / 4;    //2 Hz
                    3'b001: target <= SYS_CLK_SPEED / 8;    //4 Hz
                    3'b010: target <= SYS_CLK_SPEED / 16;   //8 Hz
                    3'b011: target <= SYS_CLK_SPEED / 32;   //16 Hz
                    3'b100: target <= SYS_CLK_SPEED / 64;   //32 Hz
                    3'b101: target <= SYS_CLK_SPEED / 128;  //64 Hz
                    3'b110: target <= SYS_CLK_SPEED / 256;  //128 Hz
                    3'b111: target <= SYS_CLK_SPEED / 512;  //256 Hz
                endcase

                counter <= 0;

            end

            else begin

                counter <= counter + 1;

                if (counter >= target) begin
                    s_clk <= ~s_clk;
                    counter <= 0;
                end

            end

        end


        clk_spd_prev <= clk_speed;

    end

endmodule