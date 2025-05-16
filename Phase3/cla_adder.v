// Purpose:
// Provides A fast adder implementation used by the ALU (and possibly by the reduction unit) for performing 16-bit additions.

// Key Responsibilities:

// Implement the CLA logic to perform additions and detect overflow

module cla_16bit_nonSAT (input [15:0] A, input [15:0] B, output [15:0] Sum);

    wire [2:0] C;

    // 4-bit CLA instances
    cla_4bit cla0 (.A(A[3:0]),   .B(B[3:0]),   .Cin(1'b0),   .sum(Sum[3:0]), .Cout(C[0]));
    cla_4bit cla1 (.A(A[7:4]),   .B(B[7:4]),   .Cin(C[0]),   .sum(Sum[7:4]), .Cout(C[1]));
    cla_4bit cla2 (.A(A[11:8]),  .B(B[11:8]),  .Cin(C[1]),   .sum(Sum[11:8]), .Cout(C[2]));
    cla_4bit cla3 (.A(A[15:12]), .B(B[15:12]), .Cin(C[2]),   .sum(Sum[15:12]), .Cout());

endmodule

module cla_16bit (input [15:0] A, input [15:0] B, input sub, output [15:0] Sum_sat, output Ovfl);

    wire [2:0] C;
    wire [15:0] B_sub, Sum;

    assign B_sub = sub ? ~B : B;

    // 4-bit CLA instances
    cla_4bit cla0 (.A(A[3:0]),   .B(B_sub[3:0]),   .Cin(sub),   .sum(Sum[3:0]), .Cout(C[0]));
    cla_4bit cla1 (.A(A[7:4]),   .B(B_sub[7:4]),   .Cin(C[0]),   .sum(Sum[7:4]), .Cout(C[1]));
    cla_4bit cla2 (.A(A[11:8]),  .B(B_sub[11:8]),  .Cin(C[1]),   .sum(Sum[11:8]), .Cout(C[2]));
    cla_4bit cla3 (.A(A[15:12]), .B(B_sub[15:12]), .Cin(C[2]),   .sum(Sum[15:12]), .Cout());

    assign Ovfl = (sub) ? (A[15] != B[15]) && (Sum[15] != A[15]) : (A[15] == B[15]) && (Sum[15] != A[15]);

    assign Sum_sat = Ovfl ? (~sub ? (A[15] == 0 & B[15] == 0 & Sum[15] == 1 ? 16'h7FFF : 16'h8000) : (A[15] == 0 & B[15] == 1 & Sum[15] == 1 ? 16'h7FFF : 16'h8000)) : Sum;

endmodule

module cla_4bit (input [3:0] A, input [3:0] B, input Cin, output [3:0] sum, output Cout);
    wire [3:0] G = A & B;
    wire [3:0] P = A ^ B;
    wire [4:0] C;

    assign C[0] = Cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C[0]);

    assign sum = P ^ C[3:0];
    assign g_out = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);
    assign p_out = P[3] & P[2] & P[1] & P[0];
    assign Cout = C[4];

endmodule

module cla_4bit_sat (input [3:0] A, input [3:0] B, input Cin, output [3:0] Sum_sat, output g_out, output p_out, output Cout);
    wire [3:0] G = A & B;
    wire [3:0] P = A ^ B;
    wire [3:0] C, Sum;

    assign C[0] = Cin;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);

    assign Sum = P ^ C;

    assign Sum_sat = ((A[3] == B[3]) & (Sum[3] != A[3])) ? ((A[3] == 0 & B[3] == 0 & Sum[3] == 1) ? 4'b0111 : 4'b1000) : Sum;

endmodule