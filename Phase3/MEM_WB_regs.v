module MEM_WB_Regs (
    input clk, 
    input rst_n,
    input LLB_in,
    input LHB_in,
    input stall,
    
    //Control signal inputs
    input MemToReg_in,
    input RegWrite_in,
    input EX_MEM_hlt,
    
    //Data inputs
    input [15:0] mem_read_data_in,
    input [15:0] ALU_result_in,
    input [3:0] write_reg_addr_in,
    
    //Control signal outputs
    output MEM_WB_MemToReg,
    output MEM_WB_RegWrite,
    
    //Data outputs
    output [15:0] MEM_WB_ReadData,
    output [15:0] MEM_WB_ALU_Result,
    output [3:0] MEM_WB_WriteRegAddr,
    output MEM_WB_hlt,

    output LLB_out,
    output LHB_out
    );

    wire write_enable = ~stall; // Write enable signal for the flip-flops, active when not stalled
    wire reset = ~rst_n;

    dff memtoreg_dff (
        .q(MEM_WB_MemToReg),
        .d(MemToReg_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff regwrite_dff (
        .q(MEM_WB_RegWrite),
        .d(RegWrite_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff mem_read_data_dff[15:0] (
        .q(MEM_WB_ReadData),
        .d(mem_read_data_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff alu_result_dff[15:0] (
        .q(MEM_WB_ALU_Result),
        .d(ALU_result_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff write_reg_addr_dff[3:0] (
        .q(MEM_WB_WriteRegAddr),
        .d(write_reg_addr_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff halt_dff (
        .q(MEM_WB_hlt),
        .d(EX_MEM_hlt),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff LLB (
        .q(LLB_out),
        .d(LLB_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );

    dff LHB (
        .q(LHB_out),
        .d(LHB_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
endmodule
