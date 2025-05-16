module WRITEBACK (
    input [15:0] MEM_WB_ALU_Result,   // Result from ALU operation
    input [15:0] MEM_WB_ReadData,     // Data read from memory
    input MEM_WB_MemToReg,            // Control signal to select between ALU result and memory data
    output [15:0] WriteData           // Data to be written back to register file
);
    
    // Select between memory data and ALU result based on MemToReg control signal
    // If MemToReg = 1, select memory data (load instruction)
    // If MemToReg = 0, select ALU result (arithmetic/logic instruction)
    assign WriteData = MEM_WB_MemToReg ? MEM_WB_ReadData : MEM_WB_ALU_Result;

endmodule