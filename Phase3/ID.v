module DECODE(clk, rst_n, branch_instr, IF_ID_INSTRUCTION, IF_ID_PC_plus2, WB_RegWrite, WB_WriteReg, WB_WriteData, LLB_in, LHB_in, flags, read_data_1, read_data_2, JUMP_PC, sign_ext_imm, branch, LLB_out, LHB_out, MemRead, MemWrite, RegWrite, MemToReg, ALUSrc, ALUOp); 
    
    input clk, rst_n, branch_instr; //clock and reset signals
   
    input wire [15:0] IF_ID_INSTRUCTION, IF_ID_PC_plus2;

    //all from MEM/WB stage
    input wire WB_RegWrite;
    input [2:0] flags;
    input wire [3:0] WB_WriteReg;
    input wire [15:0] WB_WriteData;
    input wire LLB_in, LHB_in;
    

    output wire [15:0] JUMP_PC;
    output wire [15:0] read_data_1, read_data_2;
    output wire [15:0] sign_ext_imm;
    output wire [3:0] ALUOp;
    output wire LLB_out, LHB_out;
    output wire branch;
    output wire MemRead, MemWrite, RegWrite, MemToReg, ALUSrc;

    assign ALUOp = IF_ID_INSTRUCTION[15:12];

    wire [15:0] sign_ext_imm_shift_left_2;
    wire [15:0] pc_plus_imm;
    wire ctrl_MemRead, ctrl_MemWrite, ctrl_RegWrite, ctrl_MemToReg, ctrl_ALUSrc;

    //Evaluate branch conditions
    wire bne_taken, beq_taken, bgt_taken, blt_taken;
    wire bge_taken, ble_taken, bov_taken, uncond_taken;
    
    assign bne_taken = ~flags[0];                 //BNE: Take if Z = 0
    assign beq_taken = flags[0];                  //BEQ: Take if Z = 1
    assign bgt_taken = ~flags[0] & ~flags[2];       //BGT: Take if Z = 0 & N = 0
    assign blt_taken = flags[2];                  //BLT: Take if N = 1
    assign bge_taken = flags[0] | ~flags[2];        //BGE: Take if Z = 1 | N = 0
    assign ble_taken = flags[0] | flags[2];         //BLE: Take if Z = 1 | N = 1
    assign bov_taken = flags[1];                  //BOV: Take if V = 1
    assign uncond_taken = 1'b1;                 //Unconditional: Always take
    
    //Use case statement to determine if branch is taken
    reg branch_cond_met;
    
    always @* 
        case (IF_ID_INSTRUCTION[11:9])
        3'b000: branch_cond_met = bne_taken;
        3'b001: branch_cond_met = beq_taken;
        3'b010: branch_cond_met = bgt_taken;
        3'b011: branch_cond_met = blt_taken;
        3'b100: branch_cond_met = bge_taken;
        3'b101: branch_cond_met = ble_taken;
        3'b110: branch_cond_met = bov_taken;
        3'b111: branch_cond_met = uncond_taken;
        default: branch_cond_met = 1'b0;
        endcase


    wire branch_in;
    assign branch_in = branch_cond_met & branch_instr;

    dff branch_dff (.q(branch), .d(branch_in), .wen(1'b1), .clk(clk), .rst(~rst_n)); //register for branch signal

    wire [15:0] JUMP_PC_in;
    assign JUMP_PC_in = (IF_ID_INSTRUCTION[15:12] == 4'b1101) ? read_data_1 : pc_plus_imm; //jump address

    dff JUMP_PC_dff[15:0] (.q(JUMP_PC), .d(JUMP_PC_in), .wen(1'b1), .clk(clk), .rst(~rst_n)); //register for jump address
    
    assign LLB_out = IF_ID_INSTRUCTION[15:12] == 4'b1010;
    assign LHB_out = IF_ID_INSTRUCTION[15:12] == 4'b1011;
            //control logic\\
    control control1(
    .opcode(IF_ID_INSTRUCTION[15:12]),
    .MemRead(ctrl_MemRead), 
    .MemWrite(ctrl_MemWrite), 
    .RegWrite(ctrl_RegWrite), 
    .MemToReg(ctrl_MemToReg), 
    .ALUSrc(ctrl_ALUSrc)
    );

    assign MemRead = ctrl_MemRead;
    assign MemWrite = ctrl_MemWrite;
    assign RegWrite = ctrl_RegWrite;
    assign MemToReg = ctrl_MemToReg;
    assign ALUSrc = ctrl_ALUSrc;

            //branch logic\\
    assign sign_ext_imm = (ALUOp[3:1] == 3'b010 | ALUOp[3:0] == 4'b0110 | ALUOp[3:1] == 3'b100) ? {{12{IF_ID_INSTRUCTION[3]}}, IF_ID_INSTRUCTION[3:0]} : {{8{IF_ID_INSTRUCTION[7]}}, IF_ID_INSTRUCTION[7:0]}; //sign extend immediate value
    
    //left shift by 2 for branch address
    assign sign_ext_imm_shift_left_2 = {{6{IF_ID_INSTRUCTION[8]}}, IF_ID_INSTRUCTION[8:0], 1'b0}; //left shift by 1 for branch address

    //add shifted val with PC+2 for jump address
    cla_16bit_nonSAT cla1(
        .A(IF_ID_PC_plus2),
        .B(sign_ext_imm_shift_left_2),
        .Sum(pc_plus_imm)
    );
            //register file logic\\
    RegisterFile register_file1( 
        .clk(clk),
        .rst_n(rst_n),
        .SrcReg1(IF_ID_INSTRUCTION[7:4]), //Read Rs
        .SrcReg2(IF_ID_INSTRUCTION[15:13] == 3'b100 ? IF_ID_INSTRUCTION[11:8] : IF_ID_INSTRUCTION[3:0]), //Read Rt
        .DstReg(WB_WriteReg),
        .WriteReg(WB_RegWrite),
        .writedata(WB_WriteData),
        .LLB(LLB_in),
        .LHB(LHB_in),
        .SrcData1(read_data_1),
        .SrcData2(read_data_2)
    );
endmodule

module control (opcode, MemRead, MemWrite, RegWrite, MemToReg, ALUSrc);
    input [3:0] opcode;
    output reg MemRead, MemWrite, RegWrite, MemToReg, ALUSrc;

    always @* begin
        // Default values to prevent latches
        RegWrite = 0;
        MemRead  = 0;
        MemWrite = 0;
        MemToReg = 0;
        ALUSrc   = 0;

        case (opcode)
            4'b0000:  RegWrite = 1; // ADD
            4'b0001:  RegWrite = 1; // SUB
            4'b0010:  RegWrite = 1; // XOR
            4'b0011:  RegWrite = 1; // RED
            4'b0100:  begin 
                RegWrite = 1; // SLL
                ALUSrc = 1;
            end
            4'b0101:  begin 
                RegWrite = 1; // SRA
                ALUSrc = 1;
            end
            4'b0110:  begin 
                RegWrite = 1; // ROR
                ALUSrc = 1;
            end
            4'b0111:  RegWrite = 1; // PADDSB
            4'b1010:  begin
                RegWrite = 1; // LLB
                ALUSrc = 1;
            end
            4'b1011:  begin
                RegWrite = 1; // LHB
                ALUSrc = 1;
            end

            4'b1000:  // LW
            begin
                RegWrite = 1;
                MemRead = 1;
                MemToReg = 1;
                ALUSrc = 1;
            end

            4'b1001:  // SW
            begin
                MemWrite = 1;
                ALUSrc = 1;
            end

            4'b1100: RegWrite = 0; // B
            4'b1101: RegWrite = 0; // BR
            4'b1110: RegWrite = 1; // PCS
            4'b1111: RegWrite = 0; // HLT

            default: RegWrite = 0;
        endcase
    end

endmodule