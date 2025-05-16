module FETCH (
    input         clk,
    input         rst_n,
    input         PCSrc,
    input         stall,           // Stall signal from hazard detection
    input  [15:0] pc_branch,       // Target address for branch
    output        branch_instr,
    output [15:0] pc_plus_two,
    output [15:0] instr,           // Instruction to decode stage
    output [15:0] pc,              // Current PC value
    output        cache_stall,     // Stall signal from I-cache

    // Memory interface
    input        I_mem_enable,  // Memory request
    output       fsm_busy,         // Busy signal from I-cache FSM
    output [15:0] mem_address,     // Address to main memory
    input  [15:0] mem_data,        // Data from main memory
    input         mem_data_valid,   // Indicates valid memory data
    input         mem_stall
);

    wire [15:0] pc_next, fetched_instruction;
    wire hlt;

    // PC increment
    cla_16bit cla1 (
        .A(pc), 
        .B(16'h0002), 
        .sub(1'b0), 
        .Sum_sat(pc_plus_two), 
        .Ovfl()
    );

    // Halt detection
    assign hlt = instr[15:12] == 4'b1111; // Halt instruction

    // Branch detection
    assign branch_instr = instr[15:13] == 3'b110; 

    // PC register
    dff pc_dff[15:0] (.q(pc), .d(pc_next), .wen(~(stall | cache_stall)), .clk(clk), .rst(~rst_n));

    // PC next value
    assign pc_next = PCSrc ? pc_branch : (hlt | cache_stall ? pc : pc_plus_two);

    // I-cache module
    i_cache instruction_cache (
        .clk(clk),
        .rst_n(rst_n),
        .address(pc),
        .MemRead(1'b1),            // Always read for instruction fetch
        .mem_data(mem_data),
        .memory_data_valid(mem_data_valid),
        .mem_address(mem_address),
        .Data_out(fetched_instruction),
        .cache_stall(cache_stall),
        .fsm_busy(fsm_busy),
        .cache_enable(I_mem_enable)     // Memory request signal
        //.mem_stall(mem_stall) // Memory stall signal
    );

    // Instruction output (NOP on stall)
    assign instr = (stall | cache_stall) ? 16'h7000 : fetched_instruction;

endmodule

module i_cache (
    input         clk,                     // Clock
    input         rst_n,                   // Active-low reset
    input  [15:0] address,                 // 16-bit address (from PC)
    input         MemRead,                 // Read request (always 1)
    input  [15:0] mem_data,                // Data from main memory
    input         memory_data_valid,       // Indicates valid memory data
    input         cache_enable,            // Enable from memory arbiter
    //input        mem_stall,               // Memory stall signal
    output [15:0] mem_address,             // Address to main memory
    output [15:0] Data_out,                // Instruction read from cache
    output reg    cache_stall,             // Stall signal (I_cacheMiss)
    output        fsm_busy                 // Busy signal from FSM
);

    // Internal wires
    wire [7:0]  WordEnable;
    wire [127:0] BlockEnable;
    wire [7:0]  meta_data1, meta_data2, way1_meta_data, way2_meta_data;
    wire [1:0]  state;
    wire [15:0] write_cache_data, memory_valid_address;
    wire        write_data_array, write_tag;

    // Registers
    reg [7:0] meta_data1_in, meta_data2_in;
    reg [1:0] next_state;
    reg write_LRU, miss, select, hit;

    // Address decoding
    decoder3to8 word_decode (.in(fsm_busy ? memory_valid_address[3:1] : address[3:1]), .out(WordEnable));
    decoder6to128 block_decode (.in(address[9:4]), .out(BlockEnable));

    assign miss_way = hit ? select : way2_meta_data[7]; // Miss way (1 if way 2, 0 if way 1)

    // Data array
    DataArray i_data (
        .clk(clk),
        .rst(~rst_n),
        .DataIn(write_cache_data), // Always from memory (no writes)
        .Write(write_data_array),
        .BlockEnable(miss_way ? BlockEnable << 1 : BlockEnable),
        .WordEnable(WordEnable),
        .DataOut(Data_out)
    );

    // Metadata input
    //assign meta_data1_in = (write_tag) ? {2'b01, address[15:10]} : {LRU_bit, select ? way1_meta_data_next[6:0] : way2_meta_data_next[6:0]};

    // Metadata arrays (LRU bit, Valid bit, Tag)
    MetaDataArray i_meta1 (
        .clk(clk),
        .rst(~rst_n),
        .DataIn(meta_data1_in),
        .Write(write_tag | write_LRU),
        .BlockEnable(BlockEnable),
        .DataOut(meta_data1)
    );

    MetaDataArray i_meta2 (
        .clk(clk),
        .rst(~rst_n),
        .DataIn(meta_data2_in),
        .Write(write_tag | write_LRU),
        .BlockEnable(BlockEnable << 1),
        .DataOut(meta_data2)
    );

    // Cache miss FSM
    cache_fill_FSM controller (
        .clk(clk),
        .rst_n(rst_n),
        .miss_detected(miss),
        .miss_address(address),
        .fsm_busy(fsm_busy),
        .write_data_array(write_data_array),
        .write_tag_array(write_tag),
        .write_cache_data(write_cache_data),
        .memory_address(mem_address),
        .memory_valid_address(memory_valid_address),
        .mem_enable(cache_enable),
        .memory_data(mem_data),
        .memory_data_valid(memory_data_valid)
    );

    // Way metadata registers
    dff meta_data_way1[7:0] (.q(way1_meta_data), .d(meta_data1), .wen(1'b1), .clk(clk), .rst(~rst_n));
    dff meta_data_way2[7:0] (.q(way2_meta_data), .d(meta_data2), .wen(1'b1), .clk(clk), .rst(~rst_n));

    // Registered signals
    // dff select_dff (.q(select), .d(select_next), .wen(1'b1), .clk(clk), .rst(~rst_n));
    // dff write_LRU_dff (.q(write_LRU), .d(write_LRU_next), .wen(1'b1), .clk(clk), .rst(~rst_n));
    // dff LRU_bit_dff (.q(LRU_bit), .d(LRU_bit_next), .wen(1'b1), .clk(clk), .rst(~rst_n));
    // dff stall_dff (.q(stall), .d(stall_next), .wen(1'b1), .clk(clk), .rst(~rst_n));

    // State machine for accessing cache
    parameter IDLE = 2'b00;
    parameter WAY1 = 2'b01;
    parameter WAY2 = 2'b10;
    parameter MISS = 2'b11;

    // Flip-flop for FSM state
    dff stateMachine_dff[1:0] (.q(state), .d(next_state), .wen(1'b1), .clk(clk), .rst(~rst_n));

    // Combinational logic for state machine
    always @* begin
        // Default values
        next_state = state;
        miss = 0;
        hit = 0;
        write_LRU = 0;
        cache_stall = 0;
        select = 0;
        meta_data1_in = 0;
        meta_data2_in = 0;  

            case (state) 

                IDLE: begin
                    //case (mem_stall)
                        //1'b1: begin
                            //next_state = IDLE;
                            //cache_stall = 0;
                        //end
                        //1'b0: begin
                            next_state = WAY1; // Start in WAY1
                            cache_stall = 1;
                        //end
                    //endcase
                end

                WAY1: 
                    case ((meta_data1[5:0] == address[15:10]) & meta_data1[6])
                        1'b1: begin
                            next_state = IDLE;
                            hit = 1;
                            select = 0;
                            write_LRU = 1;
                            meta_data1_in = {2'b01, way1_meta_data[5:0]};
                            meta_data2_in = {1'b0, way2_meta_data[6:0]};
                        end
                        1'b0: begin
                            next_state = WAY2;
                            hit = 0;
                            select = 1;
                            cache_stall = 1;
                        end
                    endcase

                WAY2: 
                    case ((meta_data2[5:0] == address[15:10] & meta_data2[6]))
                        1'b1: begin
                            next_state = IDLE;
                            hit = 1;
                            select = 1;
                            write_LRU = 1;
                            meta_data1_in = {1'b0, way1_meta_data[6:0]};
                            meta_data2_in = {2'b01, way2_meta_data[5:0]};
                        end
                        1'b0: begin
                            next_state = MISS;
                            miss = 1;
                            cache_stall = 1;
                            select = way2_meta_data[7]; // Select the way that has LRU bit set to 1
                        end
                    endcase

                MISS: begin
                    case (~fsm_busy)
                        1'b1: begin
                            next_state = IDLE;
                            select = meta_data2[7]; // Select the way that was written to
                            meta_data2_in = {1'b0, way2_meta_data[6:0]};
                            meta_data1_in = {2'b01, way1_meta_data[5:0]};
                        end
                        1'b0: begin
                            next_state = MISS;
                            cache_stall = 1;
                            select = way2_meta_data[7]; // Select the way that has LRU bit set to 1
                        end
                    endcase
                end

                default: $error("ERROR! Default case in state machine taken when not expected!");

            endcase
    end

endmodule