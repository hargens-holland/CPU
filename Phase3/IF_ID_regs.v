module IF_ID_REG (
    input clk, 
    input rst_n, 
    input stall, 
    input flush,
    input branch_instr_in,
    
    input [15:0] incremented_pc_in, 
    input [15:0] instr_in, 

    output [15:0] incremented_pc_out, 
    output [15:0] instr_out, 
    output hlt_out,
    output IF_ID_Branch
    );

    wire hlt;
    assign hlt = instr_in[15:12] == 4'b1111;

    wire reset;

    assign reset = ~rst_n;// | stall;

    dff pc_dff[15:0] (
        .q(incremented_pc_out), 
        .d(incremented_pc_in & {16{~flush}}), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );

    dff instr1_dff (
        .q(instr_out[15]), 
        .d(instr_in[15] & ~flush), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );

    NOT_dff instr2_dff[2:0] (
        .q(instr_out[14:12]), 
        .d(instr_in[14:12] | & {3{flush}}), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );

    dff instr_dff[11:0] (
        .q(instr_out[11:0]), 
        .d(instr_in[11:0] & {12{~flush}}), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );

    dff halt_dff (
        .q(hlt_out), 
        .d(hlt & ~flush), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );

    dff branch_instr_dff (
        .q(IF_ID_Branch), 
        .d(branch_instr_in & ~flush), 
        .wen(~stall), 
        .clk(clk), 
        .rst(reset)
    );
    
endmodule
