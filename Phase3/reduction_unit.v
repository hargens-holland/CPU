// Purpose:
// Handles the RED instruction’s operation.

// Key Responsibilities:

// Reduction Operation:
// At the first level, add corresponding 4-bit half-byte pairs (e.g., aaaa with eeee) using 4-bit CLAs to produce 5-bit results.
// At the second level, add pairs of these 5-bit results (again, using 4-bit CLA units where applicable).
// At the third level, combine the results and produce the final sign-extended output.
// Design: Implement the tree structure as specified.

module reduction_unit (output [15:0] Sum, input [15:0] A, input [15:0] B);

     wire[4:0] aeSum, bfSum, cgSum, dhSum;
    wire[5:0] aebfSum, cgdhSum;
    wire[6:0] finalSum;
    wire carry1, carry2, carry3, Cout1, Cout2, Cout3, Cout4, Cout5, Cout6, Cout7;
    
    // Declare intermediate wires for sum connections
    wire [3:0] aebf2_sum, cgdh2_sum, final2_sum;
    
    cla_4bit ae(.A(A[15:12]), .B(B[15:12]), .Cin(1'b0), .sum(aeSum[3:0]), .Cout(Cout1));
    assign aeSum[4] = Cout1 ^ A[15] ^ B[15];
    cla_4bit bf(.A(A[11:8]), .B(B[11:8]), .Cin(1'b0), .sum(bfSum[3:0]), .Cout(Cout2));
    assign bfSum[4] = Cout2 ^ A[11] ^ B[11];
    cla_4bit cg(.A(A[7:4]), .B(B[7:4]), .Cin(1'b0), .sum(cgSum[3:0]), .Cout(Cout3));
    assign cgSum[4] = Cout3 ^ A[7] ^ B[7];
    cla_4bit dh(.A(A[3:0]), .B(B[3:0]), .Cin(1'b0), .sum(dhSum[3:0]), .Cout(Cout4));
    assign dhSum[4] = Cout4 ^ A[3] ^ B[3];
    
    cla_4bit aebf1(.A(aeSum[3:0]), .B(bfSum[3:0]), .Cin(1'b0), .sum(aebfSum[3:0]), .Cout(carry1));
    cla_4bit aebf2(.A({{3{aeSum[4]}}, aeSum[4]}), .B({{3{bfSum[4]}}, bfSum[4]}), .Cin(carry1), .sum(aebf2_sum), .Cout(Cout5));
    assign aebfSum[4] = aebf2_sum[0]; // Extract the bit we need
    assign aebfSum[5] = Cout5 ^ aeSum[4] ^ bfSum[4];
    
    cla_4bit cgdh1(.A(cgSum[3:0]), .B(dhSum[3:0]), .Cin(1'b0), .sum(cgdhSum[3:0]), .Cout(carry2));
    cla_4bit cgdh2(.A({{3{cgSum[4]}}, cgSum[4]}), .B({{3{dhSum[4]}}, dhSum[4]}), .Cin(carry2), .sum(cgdh2_sum), .Cout(Cout6));
    assign cgdhSum[4] = cgdh2_sum[0]; // Extract the bit we need
    assign cgdhSum[5] = Cout6 ^ cgSum[4] ^ dhSum[4];
    
    cla_4bit final1(.A(aebfSum[3:0]), .B(cgdhSum[3:0]), .Cin(1'b0), .sum(finalSum[3:0]), .Cout(carry3));
    cla_4bit final2(.A({{2{aebfSum[5]}}, aebfSum[5:4]}), .B({{2{cgdhSum[5]}}, cgdhSum[5:4]}), .Cin(carry3), .sum(final2_sum), .Cout(Cout7));
    assign finalSum[5:4] = final2_sum[1:0]; // Extract the bits we need
    assign finalSum[6] = Cout7 ^ aebfSum[5] ^ cgdhSum[5];
    
    assign Sum = {{9{finalSum[6]}}, finalSum};

endmodule