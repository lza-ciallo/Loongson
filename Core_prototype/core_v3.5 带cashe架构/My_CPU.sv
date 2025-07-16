`timescale 1ns / 1ps

module My_CPU (
    input clk,
    input rst
);

    // =================================================================
    // 1. 模块间连接信号 (Wires)
    // =================================================================

    // --- 控制信号 ---
    wire        flush_signal;
    wire        freeze_front_signal;
    wire        freeze_back_signal;

    // --- FRONT_END -> BACK_END ---
    wire        valid_pc_fe2be;
    wire        full_PRF_fe2be;
    wire        full_RS_add_fe2be, full_RS_mul_fe2be, full_RS_agu_fe2be, full_LSQ_fe2be;
    wire [1:0]  Type_fe2be        [2:0];
    wire [4:0]  Pa_fe2be          [2:0];
    wire [4:0]  Pb_fe2be          [2:0];
    wire [4:0]  Pw_fe2be          [2:0];
    wire [4:0]  Pw_old_fe2be      [2:0];
    wire [2:0]  Rw_fe2be          [2:0];
    wire        valid_add_awake_fe2be, valid_mul_awake_fe2be, valid_agu_awake_fe2be, valid_ls_awake_fe2be;
    wire [4:0]  Pa_add_awake_fe2be, Pb_add_awake_fe2be, Pw_add_awake_fe2be, tag_ROB_add_awake_fe2be;
    wire [4:0]  Pa_mul_awake_fe2be, Pb_mul_awake_fe2be, Pw_mul_awake_fe2be, tag_ROB_mul_awake_fe2be;
    wire [4:0]  Pa_agu_awake_fe2be, Imm_awake_fe2be, tag_ROB_agu_awake_fe2be;
    wire        mode_awake_fe2be;
    wire [4:0]  Px_awake_fe2be;
    wire [15:0] Addr_awake_fe2be;
    wire [4:0]  tag_ROB_ls_awake_fe2be;
    
    // --- BACK_END -> FRONT_END ---
    wire        full_ROB_be2fe, full_FIFO_be2fe;
    wire [4:0]  tag_ROB_be2fe       [2:0];
    wire [4:0]  Pw_Result_add_be2fe, Pw_Result_mul_be2fe, Pw_Result_ls_be2fe;
    wire        valid_Result_add_be2fe, valid_Result_mul_be2fe, valid_Result_ls_be2fe;
    wire        mode_ls_be2fe;
    wire        valid_Addr_agu_be2fe;
    wire [4:0]  tag_ROB_Result_agu_be2fe;
    wire [15:0] Addr_agu_be2fe;
    wire        ready_ret_be2fe     [2:0];
    wire        excep_ret_be2fe     [2:0];
    wire [1:0]  Type_ret_be2fe      [2:0];
    wire [4:0]  Pw_old_ret_be2fe    [2:0];
    wire [4:0]  ARAT_P_list_be2fe   [7:0];
    wire [31:0] ARAT_freelist_be2fe;
    wire [4:0]  ptr_old_be2fe;

    // --- Cache & Memory System ---
    wire        ic_read_req, dc_read_req, dc_write_req;
    wire [29:0] ic_addr, dc_addr;
    wire [63:0] ic_data_from_cache;
    wire [31:0] dc_rdata_from_cache, dc_wdata_to_cache;
    wire [3:0]  dc_byte_en_to_cache;
    wire        cache_stall;
    wire        ram_en, ram_write;
    wire [29:0] ram_addr;
    wire [255:0]ram_wdata, ram_rdata;
    wire        ram_ready;



    assign flush_signal = (ready_ret_be2fe[0] == 1'b1) ? excep_ret_be2fe[0] : 1'b0;

    // freeze_front_signal: 当任何一个关键的队列或保留站满了，就暂停前端取指和分发。
    // 使用来自前端的 full_*_fe2be 和来自后端的 full_ROB_be2fe, full_FIFO_be2fe 信号。
    assign freeze_front_signal = full_PRF_fe2be | full_ROB_be2fe | full_FIFO_be2fe | 
                                 full_RS_add_fe2be | full_RS_mul_fe2be | 
                                 full_RS_agu_fe2be | full_LSQ_fe2be;

    // freeze_back_signal: 当后端的数据通路（例如写回FIFO）满了，暂停后端执行阶段。
    // 使用来自后端的 full_FIFO_be2fe 信号。
    assign freeze_back_signal = full_FIFO_be2fe;


    cache_manage_unit u_cache_manager (
        .clk(clk), .rst(rst),
        .ic_read_in(ic_read_req), .ic_addr(ic_addr), .ic_data_out(ic_data_from_cache),
        .dc_read_in(dc_read_req), .dc_write_in(dc_write_req), .dc_byte_w_en_in(dc_byte_en_to_cache),
        .dc_addr(dc_addr), .data_from_reg(dc_wdata_to_cache), .dc_data_out(dc_rdata_from_cache),
        .ram_ready(ram_ready), .block_from_ram(ram_rdata), .ram_en_out(ram_en), .ram_write_out(ram_write),
        .ram_addr_out(ram_addr), .dc_data_wb(ram_wdata), .mem_stall(cache_stall)
    );

    main_memory u_main_memory (
        .clk(clk), .req(ram_en), .we(ram_write), .addr(ram_addr[14:3]),
        .wdata(ram_wdata), .rdata(ram_rdata), .ready(ram_ready)
    );

    FRONT_END u_FRONT_END (
        .clk(clk), .rst(rst),
        .flush_in(flush_signal), .freeze_front_in(freeze_front_signal), .freeze_back_in(freeze_back_signal),
        .full_ROB_in(full_ROB_be2fe), .full_FIFO_in(full_FIFO_be2fe), .tag_ROB_in(tag_ROB_be2fe),
        .Pw_Result_add_in(Pw_Result_add_be2fe), .valid_Result_add_in(valid_Result_add_be2fe),
        .Pw_Result_mul_in(Pw_Result_mul_be2fe), .valid_Result_mul_in(valid_Result_mul_be2fe),
        .Pw_Result_ls_in(Pw_Result_ls_be2fe), .valid_Result_ls_in(valid_Result_ls_be2fe), .mode_ls_in(mode_ls_be2fe),
        .valid_Addr_agu_in(valid_Addr_agu_be2fe), .tag_ROB_Result_agu_in(tag_ROB_Result_agu_be2fe), .Addr_agu_in(Addr_agu_be2fe),
        .ARAT_P_list_in(ARAT_P_list_be2fe), .ARAT_freelist_in(ARAT_freelist_be2fe), .ptr_old_in(ptr_old_be2fe),
        .ready_ret_in(ready_ret_be2fe), .excep_ret_in(excep_ret_be2fe), .Type_ret_in(Type_ret_be2fe), .Pw_old_ret_in(Pw_old_ret_be2fe),
        .ic_read_req_out(ic_read_req), .ic_addr_out(ic_addr), .ic_data_in(ic_data_from_cache), .cache_stall_in(cache_stall),
        .dc_read_req_out(dc_read_req), .dc_write_req_out(dc_write_req), .dc_byte_w_en_out(dc_byte_en_to_cache),
        .dc_addr_out(dc_addr), .dc_wdata_out(dc_wdata_to_cache), .dc_rdata_in(dc_rdata_from_cache),
        .valid_pc_out(valid_pc_to_backend), .full_PRF_out(full_PRF_fe2be),
        .full_RS_add_out(full_RS_add_fe2be), .full_RS_mul_out(full_RS_mul_fe2be), .full_RS_agu_out(full_RS_agu_fe2be), .full_LSQ_out(full_LSQ_fe2be),
        .Type_out(Type_fe2be), .Pa_out(Pa_fe2be), .Pb_out(Pb_fe2be), .Pw_out(Pw_fe2be), .Pw_old_out(Pw_old_fe2be), .Rw_out(Rw_fe2be),
        .valid_add_awake_out(valid_add_awake_fe2be), .Pa_add_awake_out(Pa_add_awake_fe2be), .Pb_add_awake_out(Pb_add_awake_fe2be), .Pw_add_awake_out(Pw_add_awake_fe2be), .tag_ROB_add_awake_out(tag_ROB_add_awake_fe2be),
        .valid_mul_awake_out(valid_mul_awake_fe2be), .Pa_mul_awake_out(Pa_mul_awake_fe2be), .Pb_mul_awake_out(Pb_mul_awake_fe2be), .Pw_mul_awake_out(Pw_mul_awake_fe2be), .tag_ROB_mul_awake_out(tag_ROB_mul_awake_fe2be),
        .valid_agu_awake_out(valid_agu_awake_fe2be), .Pa_agu_awake_out(Pa_agu_awake_fe2be), .Imm_awake_out(Imm_awake_fe2be), .tag_ROB_agu_awake_out(tag_ROB_agu_awake_fe2be),
        .valid_ls_awake_out(valid_ls_awake_fe2be), .mode_awake_out(mode_awake_fe2be), .Px_awake_out(Px_awake_fe2be), .Addr_awake_out(Addr_awake_fe2be), .tag_ROB_ls_awake_out(tag_ROB_ls_awake_fe2be)
    );

    BACK_END u_BACK_END (
        .clk(clk), .rst(rst),
        .flush_in(flush_signal), .freeze_front_in(freeze_front_signal), .freeze_back_in(freeze_back_signal),
        .valid_pc_in(valid_pc_to_backend),
        .Type_in(Type_fe2be), .Pa_in(Pa_fe2be), .Pb_in(Pb_fe2be), .Pw_in(Pw_fe2be), .Pw_old_in(Pw_old_fe2be), .Rw_in(Rw_fe2be),
        .valid_add_in(valid_add_awake_fe2be), .Pa_add_in(Pa_add_awake_fe2be), .Pb_add_in(Pb_add_awake_fe2be), .Pw_add_in(Pw_add_awake_fe2be), .tag_ROB_add_in(tag_ROB_add_awake_fe2be),
        .valid_mul_in(valid_mul_awake_fe2be), .Pa_mul_in(Pa_mul_awake_fe2be), .Pb_mul_in(Pb_mul_awake_fe2be), .Pw_mul_in(Pw_mul_awake_fe2be), .tag_ROB_mul_in(tag_ROB_mul_awake_fe2be),
        .valid_agu_in(valid_agu_awake_fe2be), .Pa_agu_in(Pa_agu_awake_fe2be), .Imm_in(Imm_awake_fe2be), .tag_ROB_agu_in(tag_ROB_agu_awake_fe2be),
        .valid_ls_in(valid_ls_awake_fe2be), .mode_in(mode_awake_fe2be), .Px_in(Px_awake_fe2be), .Addr_in(Addr_awake_fe2be), .tag_ROB_ls_in(tag_ROB_ls_awake_fe2be),
        .dc_read_req_out(dc_read_req), .dc_write_req_out(dc_write_req), .dc_addr_out(dc_addr), .dc_byte_w_en_out(dc_byte_en_to_cache), .dc_wdata_out(dc_wdata_to_cache), .dc_rdata_in(dc_rdata_from_cache),
        .full_ROB_out(full_ROB_be2fe), .full_FIFO_out(full_FIFO_be2fe), .tag_ROB_out(tag_ROB_be2fe),
        .Pw_Result_add_out(Pw_Result_add_be2fe), .valid_Result_add_out(valid_Result_add_be2fe),
        .Pw_Result_mul_out(Pw_Result_mul_be2fe), .valid_Result_mul_out(valid_Result_mul_be2fe),
        .Pw_Result_ls_out(Pw_Result_ls_be2fe), .valid_Result_ls_out(valid_Result_ls_be2fe), .mode_ls_out(mode_ls_be2fe),
        .valid_Addr_agu_out(valid_Addr_agu_be2fe), .tag_ROB_Result_agu_out(tag_ROB_Result_agu_be2fe), .Addr_agu_out(Addr_agu_be2fe),
        .ready_ret_out(ready_ret_be2fe), .excep_ret_out(excep_ret_be2fe), .Type_ret_out(Type_ret_be2fe), .Pw_old_ret_out(Pw_old_ret_be2fe),
        .ARAT_P_list_out(ARAT_P_list_be2fe), .ARAT_freelist_out(ARAT_freelist_be2fe), .ptr_old_out(ptr_old_be2fe)
    );

endmodule