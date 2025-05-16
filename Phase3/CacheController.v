module cache_fill_FSM(clk, rst_n, miss_detected, miss_address, fsm_busy, write_data_array, write_tag_array, write_cache_data, memory_address, memory_valid_address, memory_data, memory_data_valid, mem_enable);
input clk, rst_n;
input miss_detected; // active high when tag match logic detects a miss
input [15:0] miss_address; // address that missed the cache
output reg fsm_busy; // asserted while FSM is busy handling the miss (can be used as pipeline stall signal)
output write_data_array; // write enable to cache data array to signal when filling with memory_data
output reg write_tag_array; // write enable to cache tag array to signal when all words are filled in to data array
output [15:0] write_cache_data; // data to be written to cache
output [15:0] memory_address; // address to read from memory
output [15:0] memory_valid_address; // address to be used with memory data valid signal
input [15:0] memory_data; // data returned by memory (after  delay)
input memory_data_valid; // active high indicates valid data returning on memory bus
input mem_enable; // active high indicates memory returning is for this cache


parameter IDLE = 1'b0;
parameter WAIT = 1'b1;

wire state; 
reg next_state;

wire [3:0] offset, chunk_count_in;
wire [3:0] chunk_count, mem_valids, memory_valid_in;
reg chunk_count_rst, memory_data_valid_rst;

// Flip Flop for FSM state
dff stateMachine_dff (.q(state), .d(next_state), .wen(1'b1), .clk(clk), .rst(~rst_n));

// Flip Flop for memory_data_valid
dff memory_data_valid_dff[3:0] (.q(mem_valids), .d(memory_valid_in), .wen(memory_data_valid & mem_enable & ((chunk_count & 4'b1100) != 4'b0000)), .clk(clk), .rst(memory_data_valid_rst));

cla_4bit cla1(.A(mem_valids), .B(4'b0001), .Cin(1'b0), .sum(memory_valid_in), .Cout());

// Flip Flop for chunk_count
dff chunkCount_dff[3:0] (.q(chunk_count), .d(chunk_count_in), .wen(mem_enable), .clk(clk), .rst(chunk_count_rst));

// Adder for chunk_count
cla_4bit cla2(.A(chunk_count), .B(4'b0001), .Cin(1'b0), .sum(chunk_count_in), .Cout());

assign offset = chunk_count << 1; // offset = chunk_count * 2, since each word is 2 bytes

assign memory_valid_address = {miss_address[15:4], mem_valids << 1}; // address to be used with memory data valid signal

assign memory_address = {miss_address[15:4], offset}; // address to read from memory

assign write_cache_data = memory_data; // data to be written to cache

assign write_data_array = memory_data_valid & mem_enable & ((chunk_count & 4'b1100) != 4'b0000); // write enable to cache data array to signal when filling with memory_data

//Combinational logic for state machine
always @* begin
    fsm_busy = 0;
    write_tag_array = 0;
    chunk_count_rst = 0;
    memory_data_valid_rst = 0;

    next_state = IDLE;
    
    case (state)
        IDLE: begin
            case (miss_detected)
                1'b1: begin
                    next_state = WAIT;
                    fsm_busy = 1;
                end

                1'b0: begin 
                    chunk_count_rst = 1;
                    memory_data_valid_rst = 1;
                end
            endcase

        end

        WAIT: begin
            casex (mem_valids == 4'h8)
                1'b1: begin
                    next_state = IDLE;

                    fsm_busy = 0;
                    chunk_count_rst = 1;
                    memory_data_valid_rst = 1;
                    write_tag_array = 1;
                end

                1'b0: begin
                    next_state = WAIT;
                    fsm_busy = 1;
                end
            endcase
        end

        // WAIT2: begin
        //     case (mem_valids == 4'h8)
        //         1'b1: begin
        //             next_state = IDLE;

        //             write_tag_array = 1;

        //             fsm_busy = 0;
        //             chunk_count_rst = 1;
        //             memory_data_valid_rst = 1;
        //             cache_enable = 0;
        //         end

        //         1'b0: begin
        //             next_state = WAIT2;
                    
        //             fsm_busy = 1;
        //             chunk_count_rst = 1;
        //             cache_enable = 0;
        //         end
        //     endcase
        // end
    endcase

end

endmodule