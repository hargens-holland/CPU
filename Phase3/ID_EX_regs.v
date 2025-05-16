module ID_EX_Regs (
    input clk,
    input rst_n,
    input stall,
    input LLB_in,
    input LHB_in,
    
    // Control signals
    input ALUSrc_in,
    input MemRead_in,
    input MemWrite_in,
    input MemToReg_in,
    input RegWrite_in,
    input [3:0] ALUOp_in,
    input IF_ID_hlt,

    // Data
    input [15:0] read_data_1_in,
    input [15:0] read_data_2_in,
    input [15:0] sign_ext_in,
    input [15:0] ID_PC_plus2,
    input [3:0] rs_in,
    input [3:0] rt_in,
    input [3:0] rd_in,

    // Outputs
    output wire ALUSrc,
    output wire MemRead,
    output wire MemWrite,
    output wire MemToReg,
    output wire RegWrite,
    output wire [3:0] ALUOp,
    output wire [15:0] ID_EX_ReadData1,
    output wire [15:0] ID_EX_ReadData2,
    output wire [15:0] ID_EX_SignExtImm,
    output wire [3:0] ID_EX_Rs,
    output wire [3:0] ID_EX_Rt,
    output wire [3:0] ID_EX_Rd,
    output wire ID_EX_hlt,
    output [15:0] ID_EX_PC_plus2,

    output LLB_out,
    output LHB_out
);

// Control signals
// wire [3:0] ALUOp, ID_EX_Rs, ID_EX_Rt, ID_EX_Rd;
// wire [15:0] ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_SignExtImm;

// assign ALUOp_real = stall ? 4'h4 : ALUOp;
// assign ID_EX_ReadData1_real = stall ? 16'h0000 : ID_EX_ReadData1;
// assign ID_EX_ReadData2_real = stall ? 16'h0000 : ID_EX_ReadData2;  
// assign ID_EX_SignExtImm_real = stall ? 16'h0000 : ID_EX_SignExtImm;
// assign ID_EX_Rs_real = stall ? 4'h0 : ID_EX_Rs;
// assign ID_EX_Rt_real = stall ? 4'h0 : ID_EX_Rt;
// assign ID_EX_Rd_real = stall ? 4'h0 : ID_EX_Rd;

wire[3:0] ALUOp1_out, ALUOp2_out;

wire reset = ~rst_n | (ALUOp_in == ALUOp2_out & ALUOp_in[3] != 1'b1 & ALUOp_in != 4'h7);

// 1-bit sigs
dff ALUSrc_dff (.q(ALUSrc), .d(ALUSrc_in), .wen(~stall), .clk(clk), .rst(reset));
dff MemRead_dff (.q(MemRead), .d(MemRead_in), .wen(~stall), .clk(clk), .rst(reset));
dff MemWrite_dff (.q(MemWrite), .d(MemWrite_in), .wen(~stall), .clk(clk), .rst(reset));
dff MemToReg_dff (.q(MemToReg), .d(MemToReg_in), .wen(~stall), .clk(clk), .rst(reset));
dff RegWrite_dff (.q(RegWrite), .d(RegWrite_in), .wen(~stall), .clk(clk), .rst(reset));
dff halt_dff (.q(ID_EX_hlt), .d(IF_ID_hlt), .wen(~stall), .clk(clk), .rst(reset));

//Timing Stuff
dff ALU1_dff[3:0] (
    .q(ALUOp1_out),
    .d(ALUOp_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff ALU2_dff[3:0] (
    .q(ALUOp2_out),
    .d(ALUOp1_out),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

//multi-bit sigs
dff ALUOp1_dff (
    .q(ALUOp[3]),
    .d(ALUOp_in[3]),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

NOT_dff ALUOp2_dff[2:0] (
    .q(ALUOp[2:0]),
    .d(ALUOp_in[2:0]),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff pc_dff[15:0] (
    .q(ID_EX_PC_plus2),
    .d(ID_PC_plus2),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff read_data_1_dff[15:0] (
    .q(ID_EX_ReadData1),
    .d(read_data_1_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff read_data_2_dff[15:0] (
    .q(ID_EX_ReadData2),
    .d(read_data_2_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff sign_ext_dff[15:0] (
    .q(ID_EX_SignExtImm),
    .d(sign_ext_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff rs_dff[3:0] (
    .q(ID_EX_Rs),
    .d(rs_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff rt_dff[3:0] (
    .q(ID_EX_Rt),
    .d(rt_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff rd_dff[3:0] (
    .q(ID_EX_Rd),
    .d(rd_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff LLB (
    .q(LLB_out),
    .d(LLB_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

dff LHB (
    .q(LHB_out),
    .d(LHB_in),
    .wen(~stall),
    .clk(clk),
    .rst(reset)
);

endmodule
