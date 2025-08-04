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
    assign signed_sum = 1 + imm_signed + pc_mux_signed; //We also add 1 here since (as of now) the signed sum is only
    //used for BEQ and BNE, which work from the next instruction in most arch's.
    
    
    assign overwrite_data = (is_jump) ? unsigned_sum : signed_sum;
    
endmodule
