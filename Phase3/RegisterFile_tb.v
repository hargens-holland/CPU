
module RegisterFile_tb();

reg clk, rst, WriteReg, LLB;
reg [3:0] SrcReg1, SrcReg2, DstReg;
reg [15:0] DstData;
wire [15:0] SrcData1, SrcData2;


    RegisterFile iDUT(.clk(clk), .rst_n(~rst), .SrcReg1(SrcReg1), .SrcReg2(SrcReg2), .DstReg(DstReg), .WriteReg(WriteReg), .writedata(DstData), .LLB(LLB), .LHB(1'b0), .SrcData1(SrcData1), .SrcData2(SrcData2));  
    
    initial begin

        clk = 0;
        rst = 1;

        @(posedge clk);
        @(negedge clk);

        rst = 0;
        DstReg = 2;
        WriteReg = 1;
        LLB = 1;
        DstData = 16'hFFA5;

        @(posedge clk);
        @(negedge clk);

        DstReg = 3;
        WriteReg = 1;
        LLB = 0;
        DstData = 16'hC130;

        @(posedge clk);
        @(negedge clk);

        SrcReg1 = 2;
        SrcReg2 = 3;
        WriteReg = 0;

        @(posedge clk);
        @(negedge clk);

        if (SrcData1 !== 16'h00A5) begin
            $display("SrcData1 was expected to be 0x00A5 but was %h", SrcData1);
            $stop();
        end

        if (SrcData2 !== 16'hC130) begin
            $display("SrcData2 was expected to be 0xC130 but was %h", SrcData2);
            $stop();
        end

        DstReg = 2;
        WriteReg = 1;
        DstData = 16'h2570;

        SrcReg1 = 2;
        SrcReg2 = 3;

        @(posedge clk);
        @(negedge clk);

        if (SrcData1 !== 16'h2570) begin
            $display("SrcData1 was expected to be 0x2570 but was %h", SrcData1);
            $stop();
        end

        if (SrcData2 !== 16'hC130) begin
            $display("SrcData2 was expected to be 0xC130 but was %h", SrcData2);
            $stop();
        end

        $display("Yahoo! Tests Passed!!");
        $stop();

    end

    always
        #5 clk = ~clk;

endmodule