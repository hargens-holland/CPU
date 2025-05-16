module ReadDecoder_4_16(input [3:0] RegId, output [15:0] Wordline);

    assign Wordline[0] = (RegId == 4'b0000);
    assign Wordline[1] = (RegId == 4'b0001);
    assign Wordline[2] = (RegId == 4'b0010);
    assign Wordline[3] = (RegId == 4'b0011);
    assign Wordline[4] = (RegId == 4'b0100);
    assign Wordline[5] = (RegId == 4'b0101);
    assign Wordline[6] = (RegId == 4'b0110);
    assign Wordline[7] = (RegId == 4'b0111);
    assign Wordline[8] = (RegId == 4'b1000);
    assign Wordline[9] = (RegId == 4'b1001);
    assign Wordline[10] = (RegId == 4'b1010);
    assign Wordline[11] = (RegId == 4'b1011);
    assign Wordline[12] = (RegId == 4'b1100);
    assign Wordline[13] = (RegId == 4'b1101);
    assign Wordline[14] = (RegId == 4'b1110);
    assign Wordline[15] = (RegId == 4'b1111);

endmodule


module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);

    assign Wordline[0] = WriteReg ? (RegId == 4'b0000) : 1'b0;
    assign Wordline[1] = WriteReg ? (RegId == 4'b0001) : 1'b0;
    assign Wordline[2] = WriteReg ? (RegId == 4'b0010) : 1'b0;
    assign Wordline[3] = WriteReg ? (RegId == 4'b0011) : 1'b0;
    assign Wordline[4] = WriteReg ? (RegId == 4'b0100) : 1'b0;
    assign Wordline[5] = WriteReg ? (RegId == 4'b0101) : 1'b0;
    assign Wordline[6] = WriteReg ? (RegId == 4'b0110) : 1'b0;
    assign Wordline[7] = WriteReg ? (RegId == 4'b0111) : 1'b0;
    assign Wordline[8] = WriteReg ? (RegId == 4'b1000) : 1'b0;
    assign Wordline[9] = WriteReg ? (RegId == 4'b1001) : 1'b0;
    assign Wordline[10] = WriteReg ? (RegId == 4'b1010) : 1'b0;
    assign Wordline[11] = WriteReg ? (RegId == 4'b1011) : 1'b0;
    assign Wordline[12] = WriteReg ? (RegId == 4'b1100) : 1'b0;
    assign Wordline[13] = WriteReg ? (RegId == 4'b1101) : 1'b0;
    assign Wordline[14] = WriteReg ? (RegId == 4'b1110) : 1'b0;
    assign Wordline[15] = WriteReg ? (RegId == 4'b1111) : 1'b0;

endmodule


module BitCell( input clk,  input rst_n, input D, input WriteEnable, input ReadEnable1, input ReadEnable2, input halfByte, inout Bitline1, inout Bitline2);

    wire Q, in;

    assign in = halfByte ? Q : D;

    dff flipflop(.q(Q), .d(in), .wen(WriteEnable), .clk(clk), .rst(~rst_n));
    
    assign Bitline1 = (~rst_n) ? 1'b0 : 
                     (ReadEnable1 ? (WriteEnable ? in : Q) : 1'bz);
    assign Bitline2 = (~rst_n) ? 1'b0 : 
                     (ReadEnable2 ? (WriteEnable ? in : Q) : 1'bz);

endmodule


module Register(input clk,  input rst_n, input [15:0] D, input WriteReg, input ReadEnable1, input ReadEnable2, input LLB, input LHB, inout [15:0] Bitline1, inout [15:0] Bitline2);

    BitCell B0(.clk(clk), .rst_n(rst_n), .D(D[0]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[0]),  .Bitline2(Bitline2[0]));
    BitCell B1(.clk(clk), .rst_n(rst_n), .D(D[1]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[1]),  .Bitline2(Bitline2[1]));
    BitCell B2(.clk(clk), .rst_n(rst_n), .D(D[2]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[2]),  .Bitline2(Bitline2[2]));
    BitCell B3(.clk(clk), .rst_n(rst_n), .D(D[3]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[3]),  .Bitline2(Bitline2[3]));
    BitCell B4(.clk(clk), .rst_n(rst_n), .D(D[4]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[4]),  .Bitline2(Bitline2[4]));
    BitCell B5(.clk(clk), .rst_n(rst_n), .D(D[5]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[5]),  .Bitline2(Bitline2[5]));
    BitCell B6(.clk(clk), .rst_n(rst_n), .D(D[6]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[6]),  .Bitline2(Bitline2[6]));
    BitCell B7(.clk(clk), .rst_n(rst_n), .D(D[7]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LHB), .Bitline1(Bitline1[7]),  .Bitline2(Bitline2[7]));
    BitCell B8(.clk(clk), .rst_n(rst_n), .D(D[8]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[8]),  .Bitline2(Bitline2[8]));
    BitCell B9(.clk(clk), .rst_n(rst_n), .D(D[9]),  .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[9]),  .Bitline2(Bitline2[9]));
    BitCell B10(.clk(clk), .rst_n(rst_n), .D(D[10]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[10]), .Bitline2(Bitline2[10]));
    BitCell B11(.clk(clk), .rst_n(rst_n), .D(D[11]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[11]), .Bitline2(Bitline2[11]));
    BitCell B12(.clk(clk), .rst_n(rst_n), .D(D[12]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[12]), .Bitline2(Bitline2[12]));
    BitCell B13(.clk(clk), .rst_n(rst_n), .D(D[13]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[13]), .Bitline2(Bitline2[13]));
    BitCell B14(.clk(clk), .rst_n(rst_n), .D(D[14]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[14]), .Bitline2(Bitline2[14]));
    BitCell B15(.clk(clk), .rst_n(rst_n), .D(D[15]), .WriteEnable(WriteReg), .ReadEnable1(ReadEnable1), .ReadEnable2(ReadEnable2), .halfByte(LLB), .Bitline1(Bitline1[15]), .Bitline2(Bitline2[15]));

endmodule


module RegisterFile(input clk, input rst_n, input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0] DstReg, input WriteReg, input [15:0] writedata, input LLB, input LHB, inout [15:0] SrcData1, inout [15:0] SrcData2);

    wire [15:0] read1, read2, write;
    wire [15:0] DstData; //, CurrentRegValue;

    ReadDecoder_4_16 rd1(.RegId(SrcReg1), .Wordline(read1));
    ReadDecoder_4_16 rd2(.RegId(SrcReg2), .Wordline(read2));
    
    WriteDecoder_4_16 wd1(.RegId(DstReg), .WriteReg(WriteReg), .Wordline(write));

    assign DstData = (LLB) ? (writedata & 16'h00FF) :
                    (LHB) ? ((writedata & 16'h00FF) << 8) :
                    writedata;

    // assign DstData = ({16{LLB & ~LHB}} & {8'b00000000, writedata[7:0]}) |
    //              ({16{~LLB & LHB}} & {writedata[7:0], 8'b00000000}) |
    //              ({16{~LLB & ~LHB}} & writedata);
    
    Register R0(.clk(clk), .rst_n(rst_n), .D(16'h0000), .WriteReg(1'b1),  .ReadEnable1(read1[0]),  .ReadEnable2(read2[0]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R1(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[1]),  .ReadEnable1(read1[1]),  .ReadEnable2(read2[1]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R2(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[2]),  .ReadEnable1(read1[2]),  .ReadEnable2(read2[2]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R3(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[3]),  .ReadEnable1(read1[3]),  .ReadEnable2(read2[3]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R4(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[4]),  .ReadEnable1(read1[4]),  .ReadEnable2(read2[4]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R5(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[5]),  .ReadEnable1(read1[5]),  .ReadEnable2(read2[5]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R6(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[6]),  .ReadEnable1(read1[6]),  .ReadEnable2(read2[6]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R7(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[7]),  .ReadEnable1(read1[7]),  .ReadEnable2(read2[7]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R8(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[8]),  .ReadEnable1(read1[8]),  .ReadEnable2(read2[8]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R9(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[9]),  .ReadEnable1(read1[9]),  .ReadEnable2(read2[9]),  .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R10(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[10]), .ReadEnable1(read1[10]), .ReadEnable2(read2[10]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R11(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[11]), .ReadEnable1(read1[11]), .ReadEnable2(read2[11]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R12(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[12]), .ReadEnable1(read1[12]), .ReadEnable2(read2[12]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R13(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[13]), .ReadEnable1(read1[13]), .ReadEnable2(read2[13]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R14(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[14]), .ReadEnable1(read1[14]), .ReadEnable2(read2[14]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));
    Register R15(.clk(clk), .rst_n(rst_n), .D(DstData), .WriteReg(write[15]), .ReadEnable1(read1[15]), .ReadEnable2(read2[15]), .LLB(LLB), .LHB(LHB), .Bitline1(SrcData1), .Bitline2(SrcData2));

endmodule

module FlagRegister( 
    input clk,          // Clock signal
    input rst_n,          // Reset signal
    input [2:0] D,      // 3-bit data input
    input WriteZ,     // Write enable signal
    input WriteV, 
    input WriteN, 
    output [2:0] Out  // Read port 1 output
);

    // Instantiate 3 BitCells for the 3-bit flag register
    dff Flags[2:0] (.q(Out), .d(D), .wen(WriteZ | WriteV | WriteN), .clk(clk), .rst(~rst_n));

    //BitCell Z(.clk(clk), .rst_n(rst_n), .D(D[0]), .WriteEnable(WriteZ), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(Out[0]), .Bitline2());
    //BitCell V(.clk(clk), .rst_n(rst_n), .D(D[1]), .WriteEnable(WriteV), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(Out[1]), .Bitline2());
    //BitCell N(.clk(clk), .rst_n(rst_n), .D(D[2]), .WriteEnable(WriteN), .ReadEnable1(1'b1), .ReadEnable2(1'b0), .Bitline1(Out[2]), .Bitline2());

endmodule