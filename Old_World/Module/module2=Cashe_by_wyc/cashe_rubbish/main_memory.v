`timescale 1ns/1ps 

module main_memory #( 
    parameter MEM_SIZE_WORDS = 256, 
    parameter MEM_LATENCY    = 4 
) ( 
    input                 clk, 
    input                 rst, 

    input          d_mem_req, 
    input          d_mem_wr, 
    input  [31:0] d_mem_addr, 
    input  [31:0] d_mem_data_out, 
    output wire [31:0] d_mem_data_in, 
    output reg          d_mem_ready, 

    input                 i_mem_req, 
    input                 i_mem_wr, 
    input  [31:0] i_mem_addr, 
    input  [31:0] i_mem_data_out, 
    output reg [31:0] i_mem_data_in, 
    output reg          i_mem_ready 
); 

    reg [31:0] mem [MEM_SIZE_WORDS-1:0]; 

    reg [MEM_LATENCY-1:0] latency_count; 
    reg                   mem_busy; 
    reg                   current_req_is_write; 
    reg           [31:0]  current_req_addr;     
    reg           [31:0]  current_req_data_out; 


    initial begin 
        for (integer i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin 
            mem[i] = i; 
        end 
        mem[0] = 32'h00000003; 
        mem[1] = 32'h00000001; 
        mem[2] = 32'h5555aaaa; 
        mem[3] = 32'h00000002; 
        $display("T=%t Main Memory Initialized Manually.", $time); 
        $display("Main Memory content at 0x00000000 (word_idx 0): %h", mem[0]); 
        $display("Main Memory content at 0x00000004 (word_idx 1): %h", mem[1]); 
        $display("Main Memory content at 0x00000008 (word_idx 2): %h", mem[2]); 
        $display("Main Memory content at 0x0000000C (word_idx 3): %h", mem[3]); 
    end 

    assign d_mem_data_in = 
        (!mem_busy && d_mem_ready && !current_req_is_write) ? mem[current_req_addr[31:2]] : 
        (mem_busy && latency_count == MEM_LATENCY - 1 && !current_req_is_write) ? mem[current_req_addr[31:2]] : 
        32'b0; 

    always @(posedge clk) begin 
        if (rst) begin 
            mem_busy              <= 1'b0; 
            latency_count         <= 0; 
            d_mem_ready           <= 1'b0; 
            i_mem_ready           <= 1'b0; 
            i_mem_data_in         <= 32'b0; 
            current_req_is_write  <= 1'b0; 
            current_req_addr      <= 32'b0; 
            current_req_data_out  <= 32'b0; 
        end else begin 
            if (mem_busy) begin 
                if (latency_count == MEM_LATENCY - 1) begin 
                    mem_busy <= 1'b0; 
                    d_mem_ready <= 1'b1; 

                    if (current_req_is_write) begin 
                        mem[current_req_addr[31:2]] <= current_req_data_out; 
                        $display("T=%t MAIN_MEM_WRITE_COMPLETE: Wrote %h to addr %h.", 
                                 $time, current_req_data_out, current_req_addr); 
                    end else begin 
                        $display("T=%t MAIN_MEM_READ_COMPLETE: Read %h from addr %h.", 
                                 $time, mem[current_req_addr[31:2]], current_req_addr); 
                    end 
                end else begin 
                    latency_count <= latency_count + 1; 
                    d_mem_ready   <= 1'b0; 
                    $display("T=%t MAIN_MEM_BUSY: Latency count=%0d.", $time, latency_count); 
                end 
            end else begin 
                d_mem_ready <= 1'b1; 

                if (d_mem_req) begin 
                    mem_busy             <= 1'b1; 
                    latency_count        <= 0; 
                    current_req_is_write <= d_mem_wr; 
                    current_req_addr     <= d_mem_addr; 
                    current_req_data_out <= d_mem_data_out; 
                    d_mem_ready          <= 1'b0; 
                    $display("T=%t MAIN_MEM: Accepted D-Mem Request: addr=%h, wr=%0d, data_out=%h. Starting latency.", 
                             $time, d_mem_addr, d_mem_wr, d_mem_data_out); 
                end 
            end 

            if (i_mem_req) begin 
                i_mem_ready <= 1'b1; 
                i_mem_data_in <= mem[i_mem_addr[31:2]]; 
            end else begin 
                i_mem_ready <= 1'b0; 
            end 
        end 
    end 

endmodule