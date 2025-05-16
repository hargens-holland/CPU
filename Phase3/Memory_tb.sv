module MEMORY_tb;
    // Inputs
    reg clk;
    reg rst_n;
    reg [15:0] Address;
    reg [15:0] WriteData;
    reg MemRead;
    reg MemWrite;
    reg [15:0] mem_data;
    reg memory_data_valid;
    
    // Outputs
    wire [15:0] mem_address;
    wire [15:0] ReadData;
    wire stall;
    
    // Instantiate MEMORY module
    MEMORY dut (
        .clk(clk),
        .rst_n(rst_n),
        .Address(Address),
        .WriteData(WriteData),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .mem_data(mem_data),
        .memory_data_valid(memory_data_valid),
        .mem_address(mem_address),
        .ReadData(ReadData),
        .stall(stall)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end
    
    // Simulated main memory
    reg [15:0] memory [0:8191]; // 2^13 words (64 KB, word-aligned)
    reg [15:0] mem_addr_latched;
    integer mem_delay;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_data <= 16'h0;
            memory_data_valid <= 0;
            mem_delay <= 0;
            mem_addr_latched <= 16'h0;
        end else begin
            if (stall && !memory_data_valid) begin
                if (mem_delay == 0) begin
                    mem_addr_latched <= mem_address;
                    mem_delay <= 3; // 3-cycle delay
                end else if (mem_delay > 0) begin
                    mem_delay <= mem_delay - 1;
                    if (mem_delay == 1) begin
                        mem_data <= memory[mem_addr_latched[15:3]]; // Word-aligned
                        memory_data_valid <= 1;
                    end
                end
            end else begin
                mem_data <= 16'h0;
                memory_data_valid <= 0;
                mem_delay <= 0;
            end
        end
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        rst_n = 0;
        Address = 16'h0;
        WriteData = 16'h0;
        MemRead = 0;
        MemWrite = 0;
        mem_data = 16'h0;
        memory_data_valid = 0;
        
        // Initialize memory
        for (integer i = 0; i < 8192; i = i + 1) begin
            memory[i] = 16'hDEAD; // Default value
        end
        memory[0] = 16'h1234; // Address 0x0000 (set 0)
        memory[16] = 16'h5678; // Address 0x0080 (set 0)
        memory[8] = 16'h9ABC; // Address 0x0040 (set 1)
        
        // Reset
        #20 rst_n = 1;
        $display("Test: Reset completed");
        
        // Test 1: Read Miss (Address 0x0000, set 0, way 0)
        #10;
        Address = 16'h0000;
        MemRead = 1;
        MemWrite = 0;
        $display("Test 1: Read Miss at Address 0x%04h (set 0, way 0)", Address);
        wait (stall);
        $display("  Miss detected, stall = %b", stall);
        wait (!stall);
        #10;
        if (ReadData == 16'h1234 && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0x1234), stall = %b", ReadData, stall);
        end
        MemRead = 0;
        
        // Test 2: Read Hit (Address 0x0000, set 0, way 0, 1 cycle)
        #20;
        Address = 16'h0000;
        MemRead = 1;
        $display("Test 2: Read Hit at Address 0x%04h (set 0, way 0, expect 1 cycle)", Address);
        #10; // Check after 1 cycle
        if (ReadData == 16'h1234 && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b (1 cycle)", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0x1234), stall = %b (1 cycle)", ReadData, stall);
        end
        MemRead = 0;
        
        // Test 3: Write Hit (Address 0x0000, set 0, way 0, 1 cycle)
        #20;
        Address = 16'h0000;
        WriteData = 16'hABCD;
        MemWrite = 1;
        $display("Test 3: Write Hit at Address 0x%04h, WriteData = 0x%04h (set 0, way 0, expect 1 cycle)", Address, WriteData);
        #10; // Check after 1 cycle
        if (!stall) begin
            $display("  PASS: Write completed, stall = %b (1 cycle)", stall);
        end else begin
            $display("  FAIL: Write failed, stall = %b (1 cycle)", stall);
        end
        MemWrite = 0;
        
        // Test 4: Read Hit (Address 0x0000, set 0, way 0, verify write, 1 cycle)
        #20;
        Address = 16'h0000;
        MemRead = 1;
        $display("Test 4: Read Hit at Address 0x%04h (set 0, way 0, verify write, expect 1 cycle)", Address);
        #10; // Check after 1 cycle
        if (ReadData == 16'hABCD && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b (1 cycle)", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0xABCD), stall = %b (1 cycle)", ReadData, stall);
        end
        MemRead = 0;
        
        // Test 5: Read Miss (Address 0x0080, set 0, way 1)
        #20;
        Address = 16'h0080;
        MemRead = 1;
        $display("Test 5: Read Miss at Address 0x%04h (set 0, way 1)", Address);
        wait (stall);
        $display("  Miss detected, stall = %b", stall);
        wait (!stall);
        #10;
        if (ReadData == 16'h5678 && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0x5678), stall = %b", ReadData, stall);
        end
        MemRead = 0;
        
        // Test 6: Read Hit (Address 0x0080, set 0, way 1, 2 cycles)
        #20;
        Address = 16'h0080;
        MemRead = 1;
        $display("Test 6: Read Hit at Address 0x%04h (set 0, way 1, expect 2 cycles)", Address);
        #20; // Check after 2 cycles
        if (ReadData == 16'h5678 && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b (2 cycles)", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0x5678), stall = %b (2 cycles)", ReadData, stall);
        end
        MemRead = 0;
        
        // Test 7: Write Miss (Address 0x0040, set 1, way 0)
        #20;
        Address = 16'h0040;
        WriteData = 16'hDEF0;
        MemWrite = 1;
        $display("Test 7: Write Miss at Address 0x%04h, WriteData = 0x%04h (set 1, way 0)", Address, WriteData);
        wait (stall);
        $display("  Miss detected, stall = %b", stall);
        wait (!stall);
        #10;
        if (!stall) begin
            $display("  PASS: Write completed, stall = %b", stall);
        end else begin
            $display("  FAIL: Write failed, stall = %b", stall);
        end
        MemWrite = 0;
        
        // Test 8: Read Hit (Address 0x0040, set 1, way 0, verify write, 1 cycle)
        #20;
        Address = 16'h0040;
        MemRead = 1;
        $display("Test 8: Read Hit at Address 0x%04h (set 1, way 0, verify write, expect 1 cycle)", Address);
        #10; // Check after 1 cycle
        if (ReadData == 16'hDEF0 && !stall) begin
            $display("  PASS: ReadData = 0x%04h, stall = %b (1 cycle)", ReadData, stall);
        end else begin
            $display("  FAIL: ReadData = 0x%04h (expected 0xDEF0), stall = %b (1 cycle)", ReadData, stall);
        end
        MemRead = 0;
        
        // End simulation
        #100;
        $display("Testbench completed");
        $finish;
    end
    
    // Monitor signals
    initial begin
        $monitor("Time=%0t State=%b Address=0x%04h ReadData=0x%04h stall=%b", 
                 $time, dut.d_cache_inst.state, Address, ReadData, stall);
    end
endmodule