module cpu (
    input clk, rst_n,
    output hlt,
    output [15:0] pc
);
    // Internal wires for connecting modules
    wire [15:0] pc_branch, pc_plus_two, instr;
    wire N, V, Z, WriteV, WriteZ, WriteN;
    wire [2:0] flagEnable;
    wire [15:0] ALU_out, mux2_out;
    wire [1:0] forwardA, forwardB;
    wire stall, branch_taken;
    wire test;
    
    // Pipeline register signals
    wire [15:0] IF_ID_PC, IF_ID_Instr;
    wire [2:0] flags;
    wire LHB_in, LLB_in;
    wire IF_ID_hlt, ID_EX_hlt, EX_MEM_hlt, MEM_WB_hlt;
    
    wire [3:0] ID_EX_RegisterRs, ID_EX_RegisterRt, ID_EX_RegisterRd;
    wire [15:0] ID_EX_Immediate;
    wire useImmediate, ID_EX_MemRead, ID_EX_MemWrite;
    wire ID_EX_MemToReg, ID_EX_RegWrite;
    wire [15:0] ID_EX_ReadData1, ID_EX_ReadData2;
    wire [3:0] ID_EX_ALUOp;
    
    wire EX_MEM_MemRead, EX_MEM_MemWrite;
    wire EX_MEM_MemToReg, EX_MEM_RegWrite;
    wire [15:0] EX_MEM_ALU_Result, EX_MEM_WriteData;
    wire EX_MEM_Z;
    wire [3:0] EX_MEM_WriteRegAddr;
    reg [2:0] newest_flags;
    
    wire MEM_WB_MemToReg, MEM_WB_RegWrite;
    wire [15:0] MEM_WB_ReadData, MEM_WB_ALU_Result;
    wire [3:0] MEM_WB_WriteRegAddr;
    wire [15:0] MEM_WB_Forward, EX_MEM_Forward;
    
    wire [15:0] read_data_1, read_data_2, mem_read_data, write_back_data;
    wire [15:0] sign_extended_imm;
    wire ALUSrc, MemRead, MemWrite, RegWrite, MemToReg;
    wire [3:0] ALUOp;
    wire [3:0] rs, rt, rd;
    wire [15:0] ID_EX_PC_plus2;

    // Memory interface signals
    wire [15:0] D_miss_address; // Address for memory access  
    wire [15:0] I_miss_address; // Address for memory access
    wire [15:0] main_mem_data;    // Data from memory
    wire [15:0] mem_miss_address; // Address to memory
    wire main_mem_valid;          // Valid signal from memory

    always @*
        case (flagEnable)
            3'b000: newest_flags = flags;
            3'b001: newest_flags = {flags[2:1], Z};
            3'b010: newest_flags = {flags[2], V, flags[1]};
            3'b011: newest_flags = {flags[2], V, Z};
            3'b100: newest_flags = {N, flags[1:0]};
            3'b101: newest_flags = {N, flags[1], Z};
            3'b110: newest_flags = {N, V, flags[0]};
            3'b111: newest_flags = {N, V, Z};
        endcase

    // Flag Register
    FlagRegister flagRegister1(
        .clk(clk), 
        .rst_n(rst_n), 
        .D({N,V,Z}),
        .WriteV(flagEnable[1]),
        .WriteZ(flagEnable[0]),
        .WriteN(flagEnable[2]),
        .Out(flags)
    );

    // FETCH Stage
    FETCH fetch1(
        // Inputs
        .clk(clk), 
        .rst_n(rst_n), 
        .PCSrc(branch_taken),
        .pc_branch(pc_branch),
        .stall(stall | mem_stall),
        .mem_data(main_mem_data),
        .mem_data_valid(main_mem_valid),
        .I_mem_enable(I_cache_enable),
        .mem_stall(mem_stall), // NOT USED
        
        // Outputs
        .branch_instr(branch_instr),
        .pc(pc),
        .pc_plus_two(pc_plus_two), 
        .instr(instr),
        .fsm_busy(I_cache_request),
        .mem_address(I_miss_address),
        .cache_stall(I_cache_stall)
    );

    // IF/ID Pipeline Register
    IF_ID_REG if_id_regs(
        //Inputs
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall | mem_stall | I_cache_stall),
        .flush(branch_taken),
        .incremented_pc_in(pc_plus_two),
        .instr_in(instr),
        .branch_instr_in(branch_instr),

        //Outputs
        .incremented_pc_out(IF_ID_PC),
        .instr_out(IF_ID_Instr),
        .hlt_out(IF_ID_hlt),
        .IF_ID_Branch(IF_ID_Branch)
    );
    
    // DECODE Stage
    DECODE decode1(
        //Inputs
        .clk(clk),
        .rst_n(rst_n),
        .IF_ID_INSTRUCTION(IF_ID_Instr),
        .IF_ID_PC_plus2(IF_ID_PC),
        .WB_RegWrite(MEM_WB_RegWrite),
        .WB_WriteReg(MEM_WB_WriteRegAddr),
        .WB_WriteData(write_back_data),
        .LLB_in(MEM_WB_LLB_out),
        .LHB_in(MEM_WB_LHB_out),
        .flags(newest_flags),
        .branch_instr(IF_ID_Branch),

        //Outputs
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .JUMP_PC(pc_branch),
        .sign_ext_imm(sign_extended_imm),
        .branch(branch_taken),
        .LLB_out(ID_LLB_out),
        .LHB_out(ID_LHB_out),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp)
    );
    
    // ID/EX Pipeline Register
    ID_EX_Regs id_ex_regs(
        .clk(clk),
        .rst_n(rst_n),
        .stall(mem_stall),
        .LLB_in(ID_LLB_out),
        .LHB_in(ID_LHB_out),

        // Control signals
        .ALUSrc_in(ALUSrc),
        .MemRead_in(MemRead),
        .MemWrite_in(MemWrite),
        .MemToReg_in(MemToReg),
        .RegWrite_in(RegWrite),
        .ALUOp_in(ALUOp),
        .IF_ID_hlt(IF_ID_hlt),
        .ID_PC_plus2(IF_ID_PC),

        // Data
        .read_data_1_in(read_data_1),
        .read_data_2_in(read_data_2),
        .sign_ext_in(sign_extended_imm),
        .rs_in(IF_ID_Instr[7:4]),
        .rt_in(IF_ID_Instr[15:13] == 3'b100 ? IF_ID_Instr[11:8] : IF_ID_Instr[3:0]),
        .rd_in(IF_ID_Instr[11:8]),

        // Outputs
        .ALUSrc(useImmediate),
        .MemRead(ID_EX_MemRead),
        .MemWrite(ID_EX_MemWrite),
        .MemToReg(ID_EX_MemToReg),
        .RegWrite(ID_EX_RegWrite),
        .ALUOp(ID_EX_ALUOp),
        .ID_EX_ReadData1(ID_EX_ReadData1),
        .ID_EX_ReadData2(ID_EX_ReadData2),
        .ID_EX_SignExtImm(ID_EX_Immediate),
        .ID_EX_Rs(ID_EX_RegisterRs),
        .ID_EX_Rt(ID_EX_RegisterRt),
        .ID_EX_Rd(ID_EX_RegisterRd),
        .ID_EX_hlt(ID_EX_hlt),
        .ID_EX_PC_plus2(ID_EX_PC_plus2),

        .LLB_out(ID_EX_LLB_out),
        .LHB_out(ID_EX_LHB_out)
    );
    
    // EXECUTE Stage
    EXECUTE execute1(
        .ID_EX_RegisterRs(ID_EX_ReadData1), 
        .ID_EX_RegisterRt(ID_EX_ReadData2),  
        .ID_EX_Immediate(ID_EX_Immediate),
        .useImmediate(useImmediate),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .ALU_OP(ID_EX_ALUOp),
        .MEM_WB_Forward(MEM_WB_Forward),
        .EX_MEM_Forward(EX_MEM_Forward),
        .flagEnable(flagEnable),
        .ALU_out(ALU_out),
        .mux2_out(mux2_out),
        .N(N),
        .V(V),
        .Z(Z),
        .LHB(MEM_WB_LHB_out),
        .LLB(MEM_WB_LLB_out),
        .ID_EX_PC_plus2(ID_EX_PC_plus2)
    );
    
    // EX/MEM Pipeline Register
    EX_MEM_Regs ex_mem_regs(
        .clk(clk),
        .rst_n(rst_n),
        .LLB_in(ID_EX_LLB_out),
        .LHB_in(ID_EX_LHB_out),
        .stall(mem_stall),

        // Control signals
        .MemRead_in(ID_EX_MemRead),
        .MemWrite_in(ID_EX_MemWrite),
        .MemToReg_in(ID_EX_MemToReg),
        .RegWrite_in(ID_EX_RegWrite),
        .ID_EX_hlt(ID_EX_hlt),

        // Data
        .ALU_result_in(ALU_out),
        .write_reg_addr_in(ID_EX_RegisterRd),
        .mux2_out(forwardB[0] ? MEM_WB_Forward : ID_EX_ReadData2),

        // Outputs
        .EX_MEM_MemRead(EX_MEM_MemRead),
        .EX_MEM_MemWrite(EX_MEM_MemWrite),
        .EX_MEM_MemToReg(EX_MEM_MemToReg),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_ALU_Result(EX_MEM_ALU_Result),
        .EX_MEM_WriteData(EX_MEM_WriteData),
        .EX_MEM_WriteRegAddr(EX_MEM_WriteRegAddr),
        .EX_MEM_hlt(EX_MEM_hlt),
	    .test(test),

        .LLB_out(EX_MEM_LLB_out),
        .LHB_out(EX_MEM_LHB_out)
    );
    
    // Forwarding output for EX stage
    assign EX_MEM_Forward = EX_MEM_ALU_Result;
    
    // MEMORY Stage
    MEMORY memory1 (
        .clk(clk),
        .rst_n(rst_n),
        .Address(EX_MEM_ALU_Result),         // 16-bit address from ALU
        .WriteData(EX_MEM_WriteData),        // 16-bit write data
        .MemRead(EX_MEM_MemRead),            // Read control
        .MemWrite(EX_MEM_MemWrite),          // Write control
        .mem_data(main_mem_data),            // 16-bit data from main memory
        .memory_data_valid(main_mem_valid),  // Valid signal from main memory
        .D_mem_enable(D_cache_enable),          // Enable signal for D-Cache from memory arbiter
        .mem_address(D_miss_address),      // 16-bit address to main memory
        .ReadData(mem_read_data),            // 16-bit data to MEM/WB
        .cache_stall(mem_stall),                   // Stall signal to pipeline
        .fsm_busy(D_cache_request)      // D-Cache request signal to memory
    );

    
    // MEM/WB Pipeline Register
    MEM_WB_Regs mem_wb_regs(
        .clk(clk),
        .rst_n(rst_n),
        .LLB_in(EX_MEM_LLB_out),
        .LHB_in(EX_MEM_LHB_out),
        .stall(mem_stall),

        // Control signals
        .MemToReg_in(EX_MEM_MemToReg),
        .RegWrite_in(EX_MEM_RegWrite),
        .EX_MEM_hlt(EX_MEM_hlt),

        // Data
        .mem_read_data_in(mem_read_data),
        .ALU_result_in(EX_MEM_ALU_Result),
        .write_reg_addr_in(EX_MEM_WriteRegAddr),

        // Outputs
        .MEM_WB_MemToReg(MEM_WB_MemToReg),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_ReadData(MEM_WB_ReadData),
        .MEM_WB_ALU_Result(MEM_WB_ALU_Result),
        .MEM_WB_WriteRegAddr(MEM_WB_WriteRegAddr),
        .MEM_WB_hlt(hlt),

        .LLB_out(MEM_WB_LLB_out),
        .LHB_out(MEM_WB_LHB_out)
    );
    
    // Forwarding output for WB stage
    assign MEM_WB_Forward = MEM_WB_MemToReg ? MEM_WB_ReadData : MEM_WB_ALU_Result;
    
    // WRITEBACK Stage
    WRITEBACK writeback1(
        .MEM_WB_ALU_Result(MEM_WB_ALU_Result),
        .MEM_WB_ReadData(MEM_WB_ReadData),
        .MEM_WB_MemToReg(MEM_WB_MemToReg),
        .WriteData(write_back_data)
    );
    
    // Hazard Detection Unit
    HazardDetection hazard_detection (
        .ID_EX_RegisterRs(ID_EX_RegisterRs),
        .ID_EX_RegisterRt(ID_EX_RegisterRt),
        .EX_MEM_RegisterRd(EX_MEM_WriteRegAddr),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .EX_MEM_MemRead(EX_MEM_MemRead),          
        .MEM_WB_RegisterRd(MEM_WB_WriteRegAddr),   
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .IF_ID_Branch(IF_ID_Branch), 
        .IF_ID_RegisterRs(IF_ID_Instr[7:4]),       
        .IF_ID_RegisterRt(IF_ID_Instr[11:8]),       
        .stall(stall),
	    .test(test)
    );

    
    // Forwarding Unit
    ForwardingUnit forwarding_unit(
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ID_EX_Rs(ID_EX_RegisterRs),
        .ID_EX_Rt(ID_EX_RegisterRt),
        .EX_MEM_WriteRegAddr(EX_MEM_WriteRegAddr),
        .MEM_WB_WriteRegAddr(MEM_WB_WriteRegAddr),
        .LLB(MEM_WB_LLB_out),
        .ForwardA(forwardA),
        .ForwardB(forwardB)
    );

    // Arbitration Logic for memory access
    assign mem_miss_address = (D_cache_enable) ? D_miss_address : I_miss_address;

    //keep track of last enabled
    //pipelines arb signal over 4 cycles
    // 0: No cache request, 1: I-cache, 2: D-cache
    wire [1:0] request, next_request;
    dff arb_dff[1:0] (.q(request), .d(next_request), .wen(1'b1), .clk(clk), .rst(~rst_n));

    assign next_request = (request == 2'b00) ? ((D_cache_request) ? 2'b10 : (I_cache_request) ? 2'b01 : 2'b00) : 
                          (request == 2'b01) ? (I_cache_request ? 2'b01 : D_cache_request ? 2'b10 : 2'b00) : 
                          (request == 2'b10) ? (D_cache_request ? 2'b10 : I_cache_request ? 2'b01 : 2'b00) : 
                          2'b00;

    assign I_cache_enable = request == 2'b01 & next_request == 2'b01;
    assign D_cache_enable = request == 2'b10 & next_request == 2'b10;

    wire [15:0] mem_access_address;
    assign mem_access_address = (I_cache_enable | D_cache_enable) ? mem_miss_address : EX_MEM_ALU_Result;

    wire mem_enable, mem_write;
    assign mem_enable = I_cache_enable | D_cache_enable | EX_MEM_MemWrite;
    assign mem_write = EX_MEM_MemWrite & ~D_cache_enable & ~I_cache_enable;

    // Multicycle Memory
    memory4c multiMEM (.data_out(main_mem_data), .data_in(EX_MEM_WriteData), .addr(mem_access_address), 
        .enable(mem_enable), .wr(mem_write), .clk(clk), .rst(~rst_n), .data_valid(main_mem_valid));

endmodule