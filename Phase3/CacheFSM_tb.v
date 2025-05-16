module cache_fill_FSM_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg miss_detected;
    reg [15:0] miss_address;
    reg [15:0] memory_data;
    reg memory_data_valid;
    wire fsm_busy;
    wire write_data_array;
    wire write_tag_array;
    wire [15:0] write_cache_data;
    wire [15:0] memory_address;

    // Instantiate the DUT (Device Under Test)
    cache_fill_FSM dut (
        .clk(clk),
        .rst_n(rst_n),
        .miss_detected(miss_detected),
        .miss_address(miss_address),
        .fsm_busy(fsm_busy),
        .write_data_array(write_data_array),
        .write_tag_array(write_tag_array),
        .write_cache_data(write_cache_data),
        .memory_address(memory_address),
        .memory_data(memory_data),
        .memory_data_valid(memory_data_valid)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory model: 4-cycle latency for each 2-byte read
    reg [15:0] mem_queue [0:7]; // Store 8 chunks
    reg [3:0] mem_delay;        // Track latency
    reg [15:0] last_addr;       // Track last requested address
    integer chunk_idx;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            memory_data_valid <= 0;
            memory_data <= 16'h0;
            mem_delay <= 0;
            chunk_idx <= 0;
            last_addr <= 16'h0;
        end else begin
            // Detect new memory address request
            if (memory_address != last_addr && fsm_busy) begin
                mem_queue[chunk_idx] = memory_address + 16'h1000; // Dummy data (address + offset)
                mem_delay <= 4; // Start 4-cycle countdown
                last_addr <= memory_address;
                chunk_idx <= chunk_idx + 1;
            end

            // Handle latency countdown
            if (mem_delay > 0) begin
                mem_delay <= mem_delay - 1;
                if (mem_delay == 1) begin
                    memory_data_valid <= 1;
                    memory_data <= mem_queue[chunk_idx - 1];
                end else begin
                    memory_data_valid <= 0;
                end
            end else begin
                memory_data_valid <= 0;
            end
        end
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        miss_detected = 0;
        miss_address = 16'h0;
        memory_data = 16'h0;
        memory_data_valid = 0;
        chunk_idx = 0;

        // Test 1: Reset behavior
        #20;
        rst_n = 1;
        #10;
        if (fsm_busy !== 0 || write_data_array !== 0 || write_tag_array !== 0 || memory_address !== 16'h0) begin
            $display("ERROR: Reset failed at %t", $time);
        end else begin
            $display("PASS: Reset successful at %t", $time);
        end

        // Test 2: Cache miss handling
        $display("Starting cache miss test at %t", $time);
        miss_address = 16'h1234; // Arbitrary address
        miss_detected = 1;
        #10;
        miss_detected = 0; // Pulse miss_detected for one cycle

        // Wait for FSM to process 8 chunks (expect ~32 cycles: 8 chunks x 4 cycles)
        repeat (50) @(posedge clk);
        if (fsm_busy !== 0) begin
            $display("ERROR: fsm_busy still high after miss handling at %t", $time);
        end else begin
            $display("PASS: Miss handling completed at %t", $time);
        end

        // Test 3: Second cache miss
        $display("Starting second cache miss test at %t", $time);
        miss_address = 16'h5678;
        miss_detected = 1;
        #10;
        miss_detected = 0;
        repeat (40) @(posedge clk);
        if (fsm_busy !== 0) begin
            $display("ERROR: fsm_busy still high after second miss at %t", $time);
        end else begin
            $display("PASS: Second miss handling completed at %t", $time);
        end

        // Test 4: Reset during operation
        $display("Starting reset during operation test at %t", $time);
        miss_address = 16'h9ABC;
        miss_detected = 1;
        #10;
        miss_detected = 0;
        #20; // Partway through miss handling
        rst_n = 0;
        #10;
        rst_n = 1;
        if (fsm_busy !== 0 || write_data_array !== 0 || write_tag_array !== 0) begin
            $display("ERROR: Reset during operation failed at %t", $time);
        end else begin
            $display("PASS: Reset during operation successful at %t", $time);
        end

        // End simulation
        #100;
        $display("Simulation completed at %t", $time);
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time=%t, state=%b, chunk_count=%d, fsm_busy=%b, write_data_array=%b, write_tag_array=%b, memory_address=%h, memory_data=%h, memory_data_valid=%b",
                 $time, dut.state, dut.chunk_count, fsm_busy, write_data_array, write_tag_array, memory_address, memory_data, memory_data_valid);
    end

    // Checker for expected behavior
    integer data_writes = 0;
    integer tag_writes = 0;
    reg [15:0] expected_addr;

    always @(posedge clk) begin
        // Count data and tag writes
        if (write_data_array) begin
            data_writes = data_writes + 1;
            if (write_cache_data !== memory_data) begin
                $display("ERROR: write_cache_data (%h) != memory_data (%h) at %t", write_cache_data, memory_data, $time);
            end
        end
        if (write_tag_array) begin
            tag_writes = tag_writes + 1;
        end

        // Check memory_address sequence
        if (fsm_busy && memory_address !== expected_addr && memory_address !== 16'h0) begin
            if (memory_address[3:0] % 2 != 0) begin
                $display("ERROR: memory_address (%h) not 2-byte aligned at %t", memory_address, $time);
            end
        end

        // Reset counters and expected address after miss handling
        if (fsm_busy && !dut.state && !miss_detected) begin
            if (data_writes !== 8) begin
                $display("ERROR: Expected 8 data writes, got %d at %t", data_writes, $time);
            end
            if (tag_writes !== 1) begin
                $display("ERROR: Expected 1 tag write, got %d at %t", tag_writes, $time);
            end
            data_writes = 0;
            tag_writes = 0;
            expected_addr = 16'h0;
        end
    end

    // Update expected address
    always @(posedge miss_detected) begin
        expected_addr = {miss_address[15:4], 4'h0};
    end

endmodule
