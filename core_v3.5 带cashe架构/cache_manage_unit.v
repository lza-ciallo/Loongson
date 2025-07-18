`timescale 1ns / 1ps

module cache_manage_unit #(
    parameter OFFSET_WIDTH = 3,                                        
    parameter INDEX_WIDTH  = 6,                                       
    parameter ADDR_WIDTH   = 30,                                    
    parameter DATA_WIDTH   = 32,                                 
    parameter BLOCK_SIZE   = 1 << OFFSET_WIDTH,                  
    parameter CACHE_DEPTH  = 1 << INDEX_WIDTH,                         
    parameter BLOCK_WIDTH  = DATA_WIDTH * BLOCK_SIZE,               
    parameter TAG_WIDTH    = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH    
) (

    input                        clk,
    input                        rst,
    input                        ic_read_in,
    input                        dc_read_in,
    input                        dc_write_in,
    input [3 : 0]                dc_byte_w_en_in,//数据缓存写入时的字节使能信号
    input [ADDR_WIDTH - 1 : 0]   ic_addr,//30 位的字地址
    input [ADDR_WIDTH - 1 : 0]   dc_addr,//30 位的字地址
    input [DATA_WIDTH - 1 : 0]   data_from_reg,

    input                        ram_ready, 
    input [BLOCK_WIDTH - 1 : 0]  block_from_ram,//缺失时的整个数据块

    output                       mem_stall,
    output [DATA_WIDTH - 1 : 0]  dc_data_out,
    output [63:0] ic_data_out,

    output reg  [2:0] status,//调试输出，表示缓存的当前状态
    // Cache 当前状态，表明 cache 是否*已经*发生缺失以及缺失类型，具体取值参见 status.vh.
    output reg  [2:0] counter,
    // 块内偏移指针，用于载入块时逐字写入。

    output                       ram_en_out,          // RAM 使能输出信号
    output                       ram_write_out,       //RAM 写入使能信号
    output [ADDR_WIDTH - 1  : 0] ram_addr_out,        //发送到RAM的字地址
    output [BLOCK_WIDTH - 1 : 0] dc_data_wb           // 需要写回主内存的整个数据块
);

  wire [31:0]   dc_addr_t, ic_addr_t, ram_addr_out_t;//字地址
  assign    dc_addr_t =  {dc_addr, 2'b0};
  assign    ic_addr_t =  {ic_addr, 2'b0};
  assign    ram_addr_out = ram_addr_out_t[31:2];
  wire          response_inst_cache_to_core, response_data_cache_to_core;

  wire d_cache_is_busy;
  wire i_cache_is_busy;

  cache_top  cache_top(
                .rst(rst),
                .clk(clk),
                .d_cache_read(dc_read_in),
                .d_cache_write(dc_write_in),
                .i_cache_read(ic_read_in),
                .response_ram_to_cache(ram_ready),
                .byte_w_en(dc_byte_w_en_in),
                .data_core_to_dcache_i(data_from_reg),
                .address_core_to_dcache(dc_addr_t),
                .address_core_to_icache(ic_addr_t),
                .data_ram_to_cache_i(block_from_ram),
                
                .response_inst_cache_to_core(response_inst_cache_to_core),
                .response_data_cache_to_core(response_data_cache_to_core),
                .enable_cache_to_ram(ram_en_out),
                .write_cache_to_ram(ram_write_out),
                .data_cache_to_core_o(dc_data_out),
                .inst_cache_to_core_o(ic_data_out),
                .address_cache_to_ram(ram_addr_out_t),
                .data_cache_to_ram_o(dc_data_wb),

                .d_cache_busy_out(d_cache_is_busy),
                .i_cache_busy_out(i_cache_is_busy)
            );
        
        assign    mem_stall = d_cache_is_busy | i_cache_is_busy;
  

endmodule
