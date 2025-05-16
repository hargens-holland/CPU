module ForwardingUnit (
    input [3:0] ID_EX_Rs, ID_EX_Rt,      //Register source operands from ID/EX
    input [3:0] EX_MEM_WriteRegAddr,     //Register destination in EX/MEM
    input [3:0] MEM_WB_WriteRegAddr,     //Register destination in MEM/WB
    input EX_MEM_RegWrite,               //Register write control in EX/MEM
    input MEM_WB_RegWrite,               //Register write control in MEM/WB_RegWrite
    input LLB,
    output [1:0] ForwardA, ForwardB      //Forward control signals
);

    //EX/MEM forwarding condition for Rs
    wire ex_mem_forward_a = EX_MEM_RegWrite & 
                           (EX_MEM_WriteRegAddr != 4'b0000) &
                           (EX_MEM_WriteRegAddr == ID_EX_Rs);
    
    //EX/MEM forwarding condition for Rt
    wire ex_mem_forward_b = EX_MEM_RegWrite &
                           (EX_MEM_WriteRegAddr != 4'b0000) &
                           (EX_MEM_WriteRegAddr == ID_EX_Rt);
    
    //MEM/WB forwarding condition for Rs
    wire mem_wb_forward_a = MEM_WB_RegWrite & 
                           (MEM_WB_WriteRegAddr != 4'b0000) & 
                           (MEM_WB_WriteRegAddr == ID_EX_Rs) & 
                           (!ex_mem_forward_a | LLB);
    
    //MEM/WB forwarding condition for Rt
    wire mem_wb_forward_b = MEM_WB_RegWrite & 
                           (MEM_WB_WriteRegAddr != 4'b0000) & 
                           (MEM_WB_WriteRegAddr == ID_EX_Rt) &
                           (!ex_mem_forward_b | LLB);
    
    //Forward control logic using priority encoder pattern
    //2'b00: No forwarding (use register file values)
    //2'b10: Forward from EX/MEM stage
    //2'b01: Forward from MEM/WB stage
    
    assign ForwardA[0] = mem_wb_forward_a;

    assign ForwardA[1] = 0; //ex_mem_forward_a; Not needed with the way we implemented caching
    
    assign ForwardB[0] = mem_wb_forward_b;

    assign ForwardB[1] = 0; //ex_mem_forward_b;

endmodule