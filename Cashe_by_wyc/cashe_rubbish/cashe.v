`timescale 1ns/1ps

module cache #(
    parameter CACHE_DEPTH      = 16,
    parameter LINE_WIDTH_WORDS = 4,
    parameter IS_I_CACHE       = 0
) (
    input                 clk,
    input                 rst, 

    input                 cpu_req,
    input                 cpu_wr,
    input  [31:0] cpu_addr,
    input  [31:0] cpu_data_in,
    output reg [31:0] cpu_data_out,
    output reg          cpu_stall,

    output        mem_req,       
    output        mem_wr,        
    output        [31:0] mem_addr, 
    output        [31:0] mem_data_out, 
    input  [31:0] mem_data_in,
    input                 mem_ready      
);

    localparam OFFSET_BITS      = $clog2(LINE_WIDTH_WORDS);
    localparam CACHE_INDEX_BITS = $clog2(CACHE_DEPTH);
    localparam TAG_BITS         = 32 - CACHE_INDEX_BITS - OFFSET_BITS - 2;

    localparam S_IDLE       = 3'b000;
    localparam S_WRITE_MISS = 3'b011;
    localparam S_WRITE_BACK = 3'b100;
    localparam S_FETCH      = 3'b101;

    reg [2:0]  state, next_state;

    reg [31:0] data_lines [CACHE_DEPTH-1:0][LINE_WIDTH_WORDS-1:0];
    reg [TAG_BITS-1:0] tags [CACHE_DEPTH-1:0];
    reg          valid_bits [CACHE_DEPTH-1:0];
    reg          dirty_bits [CACHE_DEPTH-1:0];

    wire [TAG_BITS-1:0]    tag    = cpu_addr[31:CACHE_INDEX_BITS+OFFSET_BITS+2];
    wire [CACHE_INDEX_BITS-1:0] index  = cpu_addr[CACHE_INDEX_BITS+OFFSET_BITS+1:OFFSET_BITS+2];
    wire [OFFSET_BITS-1:0]      offset = cpu_addr[OFFSET_BITS+1:2];

    reg [TAG_BITS-1:0]     miss_tag_reg;
    reg [CACHE_INDEX_BITS-1:0] miss_index_reg;
    reg [OFFSET_BITS-1:0]      miss_offset_reg;
    reg                    miss_wr_reg;
    reg [31:0]             miss_data_in_reg;

    wire hit = (valid_bits[index] == 1'b1) && (tags[index] == tag);
    wire is_dirty = dirty_bits[index];

    reg [OFFSET_BITS-1:0] fetch_count;
    reg [OFFSET_BITS-1:0] wb_count;

    reg          mem_req_reg;
    reg          mem_wr_reg;
    reg [31:0] mem_addr_reg;
    reg [31:0] mem_data_out_reg;

    reg          next_mem_req_comb;
    reg          next_mem_wr_comb;
    reg [31:0] next_mem_addr_comb;
    reg [31:0] next_mem_data_out_comb;

    assign mem_req      = mem_req_reg;
    assign mem_wr       = mem_wr_reg;
    assign mem_addr     = mem_addr_reg;
    assign mem_data_out = mem_data_out_reg;

    wire handshake_go = mem_req_reg && mem_ready; 

    always @(posedge clk) begin
        if (rst) begin 
            state <= S_IDLE;
            cpu_stall <= 1'b0;
            fetch_count <= 0;
            wb_count <= 0;

            mem_req_reg <= 1'b0;
            mem_wr_reg <= 1'b0;
            mem_addr_reg <= 32'b0;
            mem_data_out_reg <= 32'b0;

            cpu_data_out <= 32'b0;

            miss_tag_reg      <= {TAG_BITS{1'b0}};
            miss_index_reg    <= {CACHE_INDEX_BITS{1'b0}};
            miss_offset_reg   <= {OFFSET_BITS{1'b0}};
            miss_wr_reg       <= 1'b0;
            miss_data_in_reg  <= 32'b0;

            for (integer i = 0; i < CACHE_DEPTH; i = i + 1) begin
                valid_bits[i] <= 1'b0;
                dirty_bits[i] <= 1'b0;
                tags[i] <= {TAG_BITS{1'b0}};
                for (integer j = 0; j < LINE_WIDTH_WORDS; j = j + 1) begin
                    data_lines[i][j] <= 32'b0;
                end
            end
        end else begin
            state <= next_state;

            mem_req_reg      <= next_mem_req_comb;
            mem_wr_reg       <= next_mem_wr_comb;
            mem_addr_reg     <= next_mem_addr_comb;
            mem_data_out_reg <= next_mem_data_out_comb;

            if (state == S_IDLE) begin
                if (cpu_req && !hit) begin
                    cpu_stall <= 1'b1; 
                end else begin
                    cpu_stall <= 1'b0; 
                end
            end else if ((next_state == S_IDLE) && (state != S_IDLE)) begin
                cpu_stall <= 1'b0;
            end else begin
                cpu_stall <= 1'b1;
            end

            case (state)
                S_IDLE: begin
                    if (cpu_req && hit) begin
                        if (!IS_I_CACHE) begin
                            if (cpu_wr) begin 
                                data_lines[index][offset] <= cpu_data_in;
                                dirty_bits[index]         <= 1'b1; 
                            end else begin 
                                cpu_data_out <= data_lines[index][offset];
                            end
                        end else begin 
                            cpu_data_out <= data_lines[index][offset];
                        end
                    end
                end

                S_WRITE_BACK: begin
                    if (handshake_go) begin 
                        wb_count <= wb_count + 1; 
                        $display("T=%t CACHE_WB_DATA: Sent data %h to addr %h. wb_count incremented to %0d.", $time, mem_data_out_reg, mem_addr_reg, wb_count+1);
                    end
                end

                S_FETCH: begin
                    if (handshake_go) begin 
                        data_lines[miss_index_reg][fetch_count] <= mem_data_in;
                        $display("T=%t CACHE_FETCH_DATA: Received data %h for addr %h. Writing to data_lines[%0d][%0d].",$time, mem_data_in, mem_addr_reg, miss_index_reg, fetch_count);
                        if (fetch_count == LINE_WIDTH_WORDS - 1) begin
                            fetch_count <= 0; 
                            $display("T=%t CACHE_INFO: FETCH_DONE. fetch_count reset to 0.", $time);
                        end else begin
                            fetch_count <= fetch_count + 1;
                            $display("T=%t CACHE_INFO: fetch_count incremented to %0d.", $time, fetch_count + 1);
                        end
                    end
                end

                S_WRITE_MISS: begin
                end

                default: begin
                end
            endcase

            if (state == S_FETCH && next_state == S_IDLE) begin
                valid_bits[miss_index_reg] <= 1'b1;        
                tags[miss_index_reg]       <= miss_tag_reg;   
                dirty_bits[miss_index_reg] <= 1'b0;           

                if (!IS_I_CACHE && !miss_wr_reg) begin
                    cpu_data_out <= data_lines[miss_index_reg][miss_offset_reg];
                    $display("T=%t CACHE_INFO: CPU Data Out = %h (from cache for addr %h).", $time, data_lines[miss_index_reg][miss_offset_reg], cpu_addr);
                end
            end
        end
    end

    always @(*) begin
        next_state             = state; 
        next_mem_req_comb      = 1'b0;  
        next_mem_wr_comb       = 1'b0;
        next_mem_addr_comb     = 32'b0;
        next_mem_data_out_comb = 32'b0;

        case (state)
            S_IDLE: begin
                if (cpu_req) begin
                    if (hit) begin
                        next_state = S_IDLE;
                    end else begin 
                        miss_tag_reg      = tag;
                        miss_index_reg    = index;
                        miss_offset_reg   = offset;
                        miss_wr_reg       = cpu_wr;
                        miss_data_in_reg  = cpu_data_in;

                        if (IS_I_CACHE) begin
                            next_state           = S_FETCH;
                            next_mem_req_comb    = 1'b1; 
                            next_mem_wr_comb     = 1'b0;
                            next_mem_addr_comb   = {tag, index, {OFFSET_BITS{1'b0}}, 2'b00}; 
                            $display("T=%t S_IDLE_MISS: New I-Cache miss. Requesting %h.", $time, next_mem_addr_comb);
                        end else begin 
                            if (cpu_wr) begin 
                                next_state           = S_WRITE_MISS;
                                next_mem_req_comb    = 1'b1; 
                                next_mem_wr_comb     = 1'b1;
                                next_mem_addr_comb   = {tag, index, offset, 2'b00}; 
                                next_mem_data_out_comb = cpu_data_in; 
                                $display("T=%t S_IDLE_MISS: New D-Cache write miss. Requesting write to %h.", $time, next_mem_addr_comb);
                            end else begin 
                                if (is_dirty) begin 
                                    next_state           = S_WRITE_BACK;
                                    next_mem_req_comb    = 1'b1; 
                                    next_mem_wr_comb     = 1'b1;
                                    next_mem_addr_comb   = {tags[index], index, {OFFSET_BITS{1'b0}}, 2'b00}; 
                                    next_mem_data_out_comb = data_lines[index][0]; 
                                    $display("T=%t S_IDLE_MISS: D-Cache read miss (dirty). Requesting write-back from %h.", $time, next_mem_addr_comb);
                                end else begin 
                                    next_state           = S_FETCH;
                                    next_mem_req_comb    = 1'b1; 
                                    next_mem_wr_comb     = 1'b0;
                                    next_mem_addr_comb   = {tag, index, {OFFSET_BITS{1'b0}}, 2'b00}; 
                                    $display("T=%t S_IDLE_MISS: D-Cache read miss (clean). Requesting fetch from %h.", $time, next_mem_addr_comb);
                                end
                            end
                        end
                    end
                end
            end

            S_WRITE_BACK: begin
                next_mem_req_comb  = 1'b1; 
                next_mem_wr_comb   = 1'b1;
                next_mem_addr_comb = {tags[miss_index_reg], miss_index_reg, wb_count, 2'b00}; 
                next_mem_data_out_comb = data_lines[miss_index_reg][wb_count]; 

                $display("T=%t S_WRITE_BACK_COMB: Current wb_count = %0d. Mem request for addr %h, data %h.", $time, wb_count, next_mem_addr_comb, next_mem_data_out_comb);

                if (handshake_go) begin 
                    if (wb_count == LINE_WIDTH_WORDS - 1) begin
                        next_state = S_FETCH; 
                        next_mem_req_comb    = 1'b1;
                        next_mem_wr_comb     = 1'b0;
                        next_mem_addr_comb   = {miss_tag_reg, miss_index_reg, {OFFSET_BITS{1'b0}}, 2'b00};
                        $display("T=%t S_WRITE_BACK_COMB: All WB done. Next state S_FETCH. Next Mem addr %h.", $time, next_mem_addr_comb);
                    end else begin
                        next_state = S_WRITE_BACK; 
                    end
                end else begin
                    next_state = S_WRITE_BACK; 
                end
            end

            S_FETCH: begin
                next_mem_req_comb  = 1'b1; 
                next_mem_wr_comb   = 1'b0;
                next_mem_addr_comb = {miss_tag_reg, miss_index_reg, fetch_count, 2'b00}; 

                $display("T=%t S_FETCH_COMB: Current fetch_count = %0d. Mem request for addr %h.", $time, fetch_count, next_mem_addr_comb);

                if (handshake_go) begin 
                    if (fetch_count == LINE_WIDTH_WORDS - 1) begin
                        next_state = S_IDLE; 
                        next_mem_req_comb = 1'b0; 
                        $display("T=%t S_FETCH_COMB: All fetch done. Next state IDLE. Mem_req_comb de-asserted.", $time);
                    end else begin
                        next_state = S_FETCH; 
                    end
                end else begin
                    next_state = S_FETCH; 
                end
            end

            S_WRITE_MISS: begin
                next_mem_req_comb    = 1'b1;
                next_mem_wr_comb     = 1'b1;
                next_mem_addr_comb   = {miss_tag_reg, miss_index_reg, miss_offset_reg, 2'b00};
                next_mem_data_out_comb = miss_data_in_reg;

                $display("T=%t S_WRITE_MISS_COMB: Mem request for addr %h, data %h.", $time, next_mem_addr_comb, next_mem_data_out_comb);

                if (handshake_go) begin 
                    next_state = S_IDLE; 
                    next_mem_req_comb = 1'b0; 
                end else begin
                    next_state = S_WRITE_MISS; 
                end
            end

            default: begin
                next_state = S_IDLE; 
                next_mem_req_comb = 1'b0;
                next_mem_wr_comb = 1'b0;
                next_mem_addr_comb = 32'b0;
                next_mem_data_out_comb = 32'b0;
            end
        endcase
    end

endmodule