module HazardDetection (
    input [3:0] ID_EX_RegisterRs,      // Source register 1 from ID/EX
    input [3:0] ID_EX_RegisterRt,      // Source register 2 from ID/EX
    input [3:0] EX_MEM_RegisterRd,     // Destination register from EX/MEM
    input EX_MEM_RegWrite,             
    input EX_MEM_MemRead,              
    input [3:0] MEM_WB_RegisterRd,     // Destination register from MEM/WB
    input MEM_WB_RegWrite,             
    input IF_ID_Branch,                // Branch indicator from IF/ID
    input [3:0] IF_ID_RegisterRs,      
    input [3:0] IF_ID_RegisterRt,     
    output test, 
    output stall                       
    );

    // Internal wires for hazard detection
    wire hazard_EX_MEM;
    wire branch_hazard_EX_MEM;
    wire branch_hazard_MEM_WB;

    // Detecting load-use hazard (EX/MEM to ID/EX)
    assign hazard_EX_MEM = EX_MEM_MemRead &                          // Load in EX/MEM
                          (EX_MEM_RegisterRd != 4'b0000) &          // Not register 0
                          ((EX_MEM_RegisterRd == ID_EX_RegisterRs) | // Matches Rs or Rt
                           (EX_MEM_RegisterRd == ID_EX_RegisterRt));

    // Hazard detection for branches (EX/MEM to IF/ID)
    assign branch_hazard_EX_MEM = IF_ID_Branch & EX_MEM_RegWrite &   // EX/MEM writes a register
                                 (EX_MEM_RegisterRd != 4'b0000) &    // Not register 0
                                 ((EX_MEM_RegisterRd == IF_ID_RegisterRs) | // Matches branch Rs
                                  (EX_MEM_RegisterRd == IF_ID_RegisterRt)); // Matches branch Rt

    // Hazard detection for branches (MEM/WB to IF/ID)
    assign branch_hazard_MEM_WB = IF_ID_Branch & MEM_WB_RegWrite &   // MEM/WB writes a register
                                 (MEM_WB_RegisterRd != 4'b0000) &    // Not register 0
                                 ((MEM_WB_RegisterRd == IF_ID_RegisterRs) | // Matches branch Rs
                                  (MEM_WB_RegisterRd == IF_ID_RegisterRt)); // Matches branch Rt

    assign test = hazard_EX_MEM;
    assign stall = hazard_EX_MEM | branch_hazard_EX_MEM | branch_hazard_MEM_WB;

endmodule