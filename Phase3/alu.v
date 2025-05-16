// Purpose:
// Implements the arithmetic and logical operations required by the ISA.

// Key Responsibilities:

// Compute Operations: Support instructions such as ADD, SUB, XOR, PADDSB, SLL, SRA, ROR, and RED.
// Saturating Arithmetic: For ADD and SUB, perform operations with saturation when results exceed the allowed 16-bit signed range.
// Flag Generation: Update the FLAG register bits (Z, N, and V) as specified (only for arithmetic and some logical instructions).
// Submodule Instantiation: Use the carry lookahead adder (CLA) for efficient addition operations.

module ALU (ALU_Out, ALU_In1, ALU_In2, N, V, Z, Opcode, flagEnable);
input [15:0] ALU_In1, ALU_In2;
input [3:0] Opcode;
output reg N, V, Z;
output reg [2:0] flagEnable;
output reg [15:0] ALU_Out;

    wire [15:0] Sum, Shift_Out, Sum_red, Sum_par;
    wire sub, Ovfl;

    cla_16bit cla_16b(.A(ALU_In1), .B(Opcode == 4'b1001 ? ALU_In2 << 1 : ALU_In2), .sub(sub), .Sum_sat(Sum), .Ovfl(Ovfl));

    PSA_16bit pa1(.Sum_sat(Sum_par), .A(ALU_In1), .B(ALU_In2));

    shifter shft(.rd(Shift_Out), .rs(ALU_In1), .imm(ALU_In2), .mode(Opcode[1:0]));

    reduction_unit red(.Sum(Sum_red), .A(ALU_In1), .B(ALU_In2));

    assign sub = (Opcode == 4'h1);

    always @ (*) begin

        flagEnable = 3'b000;

        case (Opcode)
            4'h0: begin
                ALU_Out = Sum;
                N = ALU_Out[15];
                V = Ovfl;
                Z = (ALU_Out == 0);
                flagEnable = 3'b111;
            end
            4'h1: begin
                ALU_Out = Sum;
                N = ALU_Out[15];
                V = Ovfl;
                Z = (ALU_Out == 0);
                flagEnable = 3'b111;
            end
            4'h2: begin
                ALU_Out = ALU_In1 ^ ALU_In2;
                Z = (ALU_Out == 0);
                flagEnable = 3'b001;
            end
            4'h3: begin
                //RED
                ALU_Out = Sum_red;
                flagEnable = 3'b000;
            end
            4'h4: begin
                //Shifter SLL
                ALU_Out = Shift_Out;
                Z = (ALU_Out == 0);
                flagEnable = 3'b001;
            end
            4'h5: begin
                //Shifter SRA
                ALU_Out = Shift_Out;
                Z = (ALU_Out == 0);
                flagEnable = 3'b001;
            end
            4'h6: begin
                ALU_Out = Shift_Out;
                Z = (ALU_Out == 0);
                flagEnable = 3'b001;
            end
            4'h7: begin
                ALU_Out = Sum_par;
                flagEnable = 3'b000;
            end
            4'h8: begin
                ALU_Out = Sum;
            end
            4'h9: begin
                ALU_Out = Sum;
            end
            default: begin
                ALU_Out = ALU_In2;
                flagEnable = 3'b000;
                N = 0;
                V = 0;
                Z = 0;
            end
        endcase
    end

endmodule

module PSA_16bit (Sum_sat, A, B);
input [15:0] A, B; // Input data values
output [15:0] Sum_sat; // Sum output

    wire Ovfl1, Ovfl2, Ovfl3, Ovfl4;
    wire [15:0] Sum;

    full_adder_1bit FA0 (.A(A[0]), .B(B[0]), .Cin(1'b0), .Sum(Sum[0]), .Cout(Carry1));
    full_adder_1bit FA1 (.A(A[1]), .B(B[1]), .Cin(Carry1),  .Sum(Sum[1]), .Cout(Carry2));
    full_adder_1bit FA2 (.A(A[2]), .B(B[2]), .Cin(Carry2),  .Sum(Sum[2]), .Cout(Carry3));
    full_adder_1bit FA3 (.A(A[3]), .B(B[3]), .Cin(Carry3),  .Sum(Sum[3]), .Cout(Cout));

    assign Ovfl1 = (A[3] == B[3]) && (Sum[3] != A[3]);

    assign Sum_sat[3:0] = (Ovfl1) ? ((A[3] == 0 && B[3] == 0 && Sum[3] == 1) ? 4'h7 : 4'h8) : Sum[3:0];

    full_adder_1bit FA4 (.A(A[4]), .B(B[4]), .Cin(1'b0), .Sum(Sum[4]), .Cout(Carry4));
    full_adder_1bit FA5 (.A(A[5]), .B(B[5]), .Cin(Carry4),  .Sum(Sum[5]), .Cout(Carry5));
    full_adder_1bit FA6 (.A(A[6]), .B(B[6]), .Cin(Carry5),  .Sum(Sum[6]), .Cout(Carry6));
    full_adder_1bit FA7 (.A(A[7]), .B(B[7]), .Cin(Carry6),  .Sum(Sum[7]), .Cout(Cout));

    assign Ovfl2 = (A[7] == B[7]) && (Sum[7] != A[7]);

    assign Sum_sat[7:4] = (Ovfl2) ? ((A[7] == 0 && B[7] == 0 && Sum[7] == 1) ? 4'h7 : 4'h8) : Sum[7:4];

    full_adder_1bit FA8 (.A(A[8]), .B(B[8]), .Cin(1'b0), .Sum(Sum[8]), .Cout(Carry7));
    full_adder_1bit FA9 (.A(A[9]), .B(B[9]), .Cin(Carry7),  .Sum(Sum[9]), .Cout(Carry8));
    full_adder_1bit FA10 (.A(A[10]), .B(B[10]), .Cin(Carry8),  .Sum(Sum[10]), .Cout(Carry9));
    full_adder_1bit FA11 (.A(A[11]), .B(B[11]), .Cin(Carry9),  .Sum(Sum[11]), .Cout(Cout));

    assign Ovfl3 = (A[11] == B[11]) && (Sum[11] != A[11]);

    assign Sum_sat[11:8] = (Ovfl3) ? ((A[11] == 0 && B[11] == 0 && Sum[11] == 1) ? 4'h7 : 4'h8) : Sum[11:8];

    full_adder_1bit FA12 (.A(A[12]), .B(B[12]), .Cin(1'b0), .Sum(Sum[12]), .Cout(Carry10));
    full_adder_1bit FA13 (.A(A[13]), .B(B[13]), .Cin(Carry10),  .Sum(Sum[13]), .Cout(Carry11));
    full_adder_1bit FA14 (.A(A[14]), .B(B[14]), .Cin(Carry11),  .Sum(Sum[14]), .Cout(Carry12));
    full_adder_1bit FA15 (.A(A[15]), .B(B[15]), .Cin(Carry12),  .Sum(Sum[15]), .Cout(Cout));

    assign Ovfl4 = (A[15] == B[15]) && (Sum[15] != A[15]);

    assign Sum_sat[15:12] = (Ovfl4) ? ((A[15] == 0 && B[15] == 0 && Sum[15] == 1) ? 4'h7 : 4'h8) : Sum[15:12];

endmodule

module full_adder_1bit (input A, input B, input Cin, output Sum, output Cout);

    assign Sum = (A ^ B) ^ Cin;
    assign Cout = (A & B) | (A & Cin) | (B & Cin);

endmodule