`timescale 1ns / 1ps
//FILE: pc_datapath.v

module pc_datapath(
    input pc_overwrite,
    input [7:0] imm_value,
    input [7:0] pc_mux,
    input is_jump,
    output [7:0] overwrite_data
    );
    
    wire signed [7:0] imm_signed, pc_mux_signed, signed_sum;
    wire [7:0] unsigned_sum;

    assign imm_signed = imm_value;
    assign pc_mux_signed = pc_mux;
    assign unsigned_sum = imm_value + pc_mux;
    assign signed_sum = imm_signed + pc_mux_signed;
    
    assign overwrite_data = (is_jump) ? unsigned_sum : signed_sum;
    
endmodule
