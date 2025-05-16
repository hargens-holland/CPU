module MEMORY (
    input clk,                     // Clock
    input rst_n,                   // Active-low reset
    input [15:0] Address,          // 16-bit address
    input [15:0] WriteData,        // Data to write
    input MemRead,                 // Read request
    input MemWrite,                // Write request
    input [15:0] mem_data,         // Data from main memory
    input memory_data_valid,       // Indicates valid memory data
    input D_mem_enable,            // D-Cache enable signal for memory access

    output [15:0] mem_address,     // Address to main memory
    output [15:0] ReadData,        // Data read from cache
    output cache_stall,                  // Stall signal
    output fsm_busy               // Busy signal from FSM
);
    
    // D-Cache instantiation
    d_cache d_cache_inst (
        .clk(clk),
        .rst_n(rst_n),
        .address(Address),
        .WriteData(WriteData),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .mem_data(mem_data),
        .memory_data_valid(memory_data_valid),
        .mem_address(mem_address),
        .Data_out(ReadData),
        .cache_stall(cache_stall),
        .fsm_busy(fsm_busy),
        .cache_enable(D_mem_enable)      // Memory request signal
    );
endmodule


module d_cache (
    input         clk,                     // Clock
    input         rst_n,                   // Active-low reset
    input  [15:0] address,                 // 16-bit address
    input         MemRead,                 // Read request 
    input         MemWrite,                // Write request 
    input  [15:0] WriteData,               // Data to write
    input  [15:0] mem_data,                // Data from main memory
    input         memory_data_valid,       // Indicates valid memory data
    input         cache_enable,          // D-Cache enable signal for memory access
    output [15:0] mem_address,             // Address to main memory
    output [15:0] Data_out,                // Data read from cache
    output reg    cache_stall,             // Stall signal (D_cacheMiss)
    output        fsm_busy             // Cache enable signal for memory access
    
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
    reg write_LRU, miss, select, hit, write_store;

    // Address decoding
    decoder3to8 word_decode (.in(fsm_busy ? memory_valid_address[3:1] : address[3:1]), .out(WordEnable));
    decoder6to128 block_decode (.in(address[9:4]), .out(BlockEnable));

    assign miss_way = hit ? select : way2_meta_data[7]; // Miss way (1 if way 2, 0 if way 1)

    // Data array
    DataArray i_data (
        .clk(clk),
        .rst(~rst_n),
        .DataIn(write_data_array ? write_cache_data : WriteData),
        .Write(write_data_array | write_store),
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

    // wire rep;
    // wire [15:0] address_out;

    // dff address_in_dff[15:0] (.q(address_out), .d(address), .wen(1'b1), .clk(clk), .rst(~rst_n));
    
    // assign rep = (address_out == address) ? 1'b1 : 1'b0; // Check if the address is the same as the previous one

    // Combinational logic for state machine
    always @* begin
        // Default values
        next_state = state;
        miss = 0;
        hit = 0;
        select = 0;
        write_LRU = 0;
        cache_stall = 0;
        write_store = 0;
        meta_data1_in = 0;
        meta_data2_in = 0;

            case (state) 

               IDLE: begin
                     case ((MemRead | MemWrite))// & ~rep)
                           1'b1: begin
                              next_state = WAY1;
                              cache_stall = 1;
                           end
                           1'b0: begin
                              next_state = IDLE;
                              cache_stall = 0;
                           end
                     endcase
               end

               WAY1: 
                    casex ((meta_data1[5:0] == address[15:10] & meta_data1[6]))
                        1'b1: begin
                            next_state = IDLE;
                            hit = 1;
                            write_store = MemWrite;
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
                            write_store = MemWrite;
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
                            select = way2_meta_data[7]; // Select the way that was written to
                            meta_data2_in = {1'b0, way2_meta_data[6:0]};
                            meta_data1_in = {2'b01, way1_meta_data[5:0]};
                            meta_data2_in = {1'b0, way2_meta_data[6:0]}; 
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

module decoder3to8 (
    input [2:0] in,
    output reg [7:0] out
);
    always @(*) begin
        out = 8'b0;
        case (in)
            3'd0: out = 8'b00000001; // Word 0
            3'd1: out = 8'b00000010; // Word 1
            3'd2: out = 8'b00000100; // Word 2
            3'd3: out = 8'b00001000; // Word 3
            3'd4: out = 8'b00010000; // Word 4
            3'd5: out = 8'b00100000; // Word 5
            3'd6: out = 8'b01000000; // Word 6
            3'd7: out = 8'b10000000; // Word 7
            default: out = 8'b0; // No word selected
        endcase
    end
endmodule

module decoder6to128 (
    input [5:0] in,
    output reg [127:0] out
);
    always @(*) begin
        out = 128'b0; // Default: all bits 0
        case (in)
            6'd0:  out[1:0]   = 2'b01; 
            6'd1:  out[3:2]   = 2'b01; 
            6'd2:  out[5:4]   = 2'b01; 
            6'd3:  out[7:6]   = 2'b01; 
            6'd4:  out[9:8]   = 2'b01;
            6'd5:  out[11:10] = 2'b01;
            6'd6:  out[13:12] = 2'b01;
            6'd7:  out[15:14] = 2'b01;
            6'd8:  out[17:16] = 2'b01;
            6'd9:  out[19:18] = 2'b01;
            6'd10: out[21:20] = 2'b01;
            6'd11: out[23:22] = 2'b01;
            6'd12: out[25:24] = 2'b01;
            6'd13: out[27:26] = 2'b01;
            6'd14: out[29:28] = 2'b01;
            6'd15: out[31:30] = 2'b01;
            6'd16: out[33:32] = 2'b01;
            6'd17: out[35:34] = 2'b01;
            6'd18: out[37:36] = 2'b01;
            6'd19: out[39:38] = 2'b01;
            6'd20: out[41:40] = 2'b01;
            6'd21: out[43:42] = 2'b01;
            6'd22: out[45:44] = 2'b01;
            6'd23: out[47:46] = 2'b01;
            6'd24: out[49:48] = 2'b01;
            6'd25: out[51:50] = 2'b01;
            6'd26: out[53:52] = 2'b01;
            6'd27: out[55:54] = 2'b01;
            6'd28: out[57:56] = 2'b01;
            6'd29: out[59:58] = 2'b01;
            6'd30: out[61:60] = 2'b01;
            6'd31: out[63:62] = 2'b01;
            6'd32: out[65:64] = 2'b01;
            6'd33: out[67:66] = 2'b01;
            6'd34: out[69:68] = 2'b01;
            6'd35: out[71:70] = 2'b01;
            6'd36: out[73:72] = 2'b01;
            6'd37: out[75:74] = 2'b01;
            6'd38: out[77:76] = 2'b01;
            6'd39: out[79:78] = 2'b01;
            6'd40: out[81:80] = 2'b01;
            6'd41: out[83:82] = 2'b01;
            6'd42: out[85:84] = 2'b01;
            6'd43: out[87:86] = 2'b01;
            6'd44: out[89:88] = 2'b01;
            6'd45: out[91:90] = 2'b01;
            6'd46: out[93:92] = 2'b01;
            6'd47: out[95:94] = 2'b01;
            6'd48: out[97:96] = 2'b01;
            6'd49: out[99:98] = 2'b01;
            6'd50: out[101:100] = 2'b01;
            6'd51: out[103:102] = 2'b01;
            6'd52: out[105:104] = 2'b01;
            6'd53: out[107:106] = 2'b01;
            6'd54: out[109:108] = 2'b01;
            6'd55: out[111:110] = 2'b01;
            6'd56: out[113:112] = 2'b01;
            6'd57: out[115:114] = 2'b01;
            6'd58: out[117:116] = 2'b01;
            6'd59: out[119:118] = 2'b01;
            6'd60: out[121:120] = 2'b01;
            6'd61: out[123:122] = 2'b01;
            6'd62: out[125:124] = 2'b01;
            6'd63: out[127:126] = 2'b01;
            default: out = 128'b0; // No blocks enabled
        endcase
    end
endmodule