module EX_MEM_Regs (
    input clk, rst_n,
    input LLB_in,
    input LHB_in,
    input stall,
    
    // Control signals inputs
    input MemRead_in,
    input MemWrite_in,
    input MemToReg_in,
    input RegWrite_in,
    input ID_EX_hlt,
    
    // Data inputs
    input [15:0] ALU_result_in,
    input [3:0] write_reg_addr_in,
    input [15:0] mux2_out,
    input test,
    
    // Control signals outputs
    output EX_MEM_MemRead,
    output EX_MEM_MemWrite,
    output EX_MEM_MemToReg,
    output EX_MEM_RegWrite,
    
    // Data outputs
    output [15:0] EX_MEM_ALU_Result,
    output [15:0] EX_MEM_WriteData,
    output [3:0] EX_MEM_WriteRegAddr,
    output EX_MEM_hlt,
    output LLB_out,
    output LHB_out
    
);
    wire [15:0] store_address;
    wire delay_flag, next_delay_flag;
    wire write_enable;
    wire reset;
    wire delay_flag_out;
    wire MemRead_out1, MemRead_out2, MemWrite_out1, MemWrite_out2;
    // Fixed values
    assign write_enable = ~stall;
    assign reset = ~rst_n | (((MemRead_in == MemRead_out2 & MemRead_in == 1) | (MemWrite_in == MemWrite_out2 & MemWrite_in == 1)));

    dff memR1_dff (
        .q(MemRead_out1),
        .d(MemRead_in),
        .wen(write_enable),
        .clk(clk),
        .rst(~rst_n)
    );

    dff memR2_dff (
        .q(MemRead_out2),
        .d(MemRead_out1),
        .wen(write_enable),
        .clk(clk),
        .rst(~rst_n)
    );

    dff memW1_dff (
        .q(MemWrite_out1),
        .d(MemWrite_in),
        .wen(write_enable),
        .clk(clk),
        .rst(~rst_n)
    );

    dff memW2_dff (
        .q(MemWrite_out2),
        .d(MemWrite_out1),
        .wen(write_enable),
        .clk(clk),
        .rst(~rst_n)
    );
    
    // Calculate next state for delay flag
    assign next_delay_flag = (test & ~delay_flag) ? 1'b1 : 
                             delay_flag ? 1'b0 : 
                             delay_flag;
    
    // Delay flag register
    dff delay_flag_dff (
        .q(delay_flag),
        .d(next_delay_flag),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    // Calculate address to store (with offset)
    wire [15:0] addr_with_offset = ALU_result_in + 16'h0004;
    
    // Address storage logic
    wire [15:0] next_store_address = (MemWrite_in & ~test & ~delay_flag) ? addr_with_offset : store_address;
    
    // Store address register
    dff store_addr_dff[15:0] (
        .q(store_address),
        .d(next_store_address),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    // Calculate the ALU result
    wire [15:0] final_alu_result = ((MemWrite_in & test) | (MemWrite_in & delay_flag)) ? store_address : ALU_result_in;
    
    // Output for debugging
    assign delay_flag_out = delay_flag;
    
    // Control signals
    dff memread_dff (
        .q(EX_MEM_MemRead),
        .d(MemRead_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff memwrite_dff (
        .q(EX_MEM_MemWrite),
        .d(MemWrite_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff memtoreg_dff (
        .q(EX_MEM_MemToReg),
        .d(MemToReg_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff regwrite_dff (
        .q(EX_MEM_RegWrite),
        .d(RegWrite_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff alu_result_dff[15:0] (
        .q(EX_MEM_ALU_Result),
        .d(final_alu_result),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff write_data_dff[15:0] (
        .q(EX_MEM_WriteData),
        .d(mux2_out),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff write_reg_addr_dff[3:0] (
        .q(EX_MEM_WriteRegAddr),
        .d(write_reg_addr_in),
        .wen(write_enable),
        .clk(clk),
        .rst(reset)
    );
    
    dff hlt (
        .q(EX_MEM_hlt),
        .d(ID_EX_hlt),
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