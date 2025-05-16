module EXECUTE(ID_EX_RegisterRs, ID_EX_RegisterRt, ID_EX_Immediate, useImmediate, forwardA, forwardB, MEM_WB_Forward, EX_MEM_Forward, ALU_OP, LHB, LLB, ALU_out, mux2_out, N, V, Z, flagEnable, ID_EX_PC_plus2); //module for execute stage
    input wire [15:0] ID_EX_RegisterRs, ID_EX_RegisterRt;
    input wire [15:0] ID_EX_Immediate; //regs from ID/EX stage
    input wire [15:0] MEM_WB_Forward, EX_MEM_Forward, ID_EX_PC_plus2; //forwarded values
    input wire useImmediate; //control signal from control unit
    input wire [1:0] forwardA, forwardB; //forwarding signals from forwarding unit
    input wire [3:0] ALU_OP;
    input LHB;
    input LLB;
    
    output wire [2:0] flagEnable; //enable signal for flags
    output wire [15:0] ALU_out; //output of ALU
    output wire [15:0] mux2_out;
    output wire N, V, Z; //flags from ALU

    wire [15:0] mux1_out;

    assign mux1_out = forwardA[1] ? (forwardA[0] ? {EX_MEM_Forward[7:0], MEM_WB_Forward[7:0]} : EX_MEM_Forward) :
        (forwardA[0] ? LHB ? {MEM_WB_Forward[7:0], ID_EX_RegisterRs[7:0]} : 
            LLB ? {8'h0, MEM_WB_Forward[7:0]} : MEM_WB_Forward :
            ID_EX_RegisterRs); //mux for first input to ALU

    assign mux2_out = (ALU_OP == 4'b1110) ? ID_EX_PC_plus2 : useImmediate ? (ID_EX_Immediate) : 
        forwardB[1] ? (forwardB[0] ? {EX_MEM_Forward[7:0], MEM_WB_Forward[7:0]} : EX_MEM_Forward) :
            forwardB[0] ? LHB ? {MEM_WB_Forward[7:0], ID_EX_RegisterRt[7:0]} : 
            LLB ? {8'h0, MEM_WB_Forward[7:0]} : MEM_WB_Forward :
                ID_EX_RegisterRt; //mux for second input to ALU

    ALU alu1(.ALU_Out(ALU_out), .ALU_In1(mux1_out), .ALU_In2(mux2_out), .N(N), .V(V), .Z(Z), .Opcode(ALU_OP), .flagEnable(flagEnable));
    
endmodule