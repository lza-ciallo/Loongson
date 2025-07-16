`timescale 1ns / 1ps

module BACK_END (
    // --- 控制信号输入 ---
    input               clk,
    input               rst,
    input               flush_in,
    input               freeze_front_in,
    input               freeze_back_in,

    // --- 从 FRONT_END 输入 ---
    input               valid_pc_in,
    input   [1 : 0]     Type_in         [2 : 0],
    input   [4 : 0]     Pa_in           [2 : 0],
    input   [4 : 0]     Pb_in           [2 : 0],
    input   [4 : 0]     Pw_in           [2 : 0],
    input   [4 : 0]     Pw_old_in       [2 : 0],
    input   [2 : 0]     Rw_in           [2 : 0],
    input               valid_add_in,
    input   [4 : 0]     Pa_add_in,
    input   [4 : 0]     Pb_add_in,
    input   [4 : 0]     Pw_add_in,
    input   [4 : 0]     tag_ROB_add_in,
    input               valid_mul_in,
    input   [4 : 0]     Pa_mul_in,
    input   [4 : 0]     Pb_mul_in,
    input   [4 : 0]     Pw_mul_in,
    input   [4 : 0]     tag_ROB_mul_in,
    input               valid_agu_in,
    input   [4 : 0]     Pa_agu_in,
    input   [4 : 0]     Imm_in,
    input   [4 : 0]     tag_ROB_agu_in,
    input               valid_ls_in,
    input               mode_in,
    input   [4 : 0]     Px_in,
    input   [15 : 0]    Addr_in,
    input   [4 : 0]     tag_ROB_ls_in,

    // --- Cache 接口 ---
    output              dc_read_req_out,
    output              dc_write_req_out,
    output  [29:0]      dc_addr_out,
    output  [3:0]       dc_byte_w_en_out,
    output  [31:0]      dc_wdata_out,
    input   [31:0]      dc_rdata_in,

    // --- 输出到 FRONT_END ---
    output              full_ROB_out,
    output              full_FIFO_out,
    output  [4 : 0]     tag_ROB_out     [2 : 0],
    output  [4 : 0]     Pw_Result_add_out,
    output              valid_Result_add_out,
    output  [4 : 0]     Pw_Result_mul_out,
    output              valid_Result_mul_out,
    output  [4 : 0]     Pw_Result_ls_out,
    output              valid_Result_ls_out,
    output              mode_ls_out,
    output              valid_Addr_agu_out,
    output  [4 : 0]     tag_ROB_Result_agu_out,
    output  [15 : 0]    Addr_agu_out,
    output              ready_ret_out   [2 : 0],
    output              excep_ret_out   [2 : 0],
    output  [1 : 0]     Type_ret_out    [2 : 0],
    output  [4 : 0]     Pw_old_ret_out  [2 : 0],
    output  [4 : 0]     ARAT_P_list_out [7 : 0],
    output  [31 : 0]    ARAT_freelist_out,
    output  [4 : 0]     ptr_old_out
);

    // --- 内部信号 ---
    wire    [15:0]    busA_add, busA_add_r, busB_add, busB_add_r;
    wire    [15:0]    busA_mul, busA_mul_r, busB_mul, busB_mul_r;
    wire    [15:0]    busA_agu, busA_agu_r;
    wire    [15:0]    busX, busX_r;
    wire    [15:0]    Addr_r;
    wire              valid_add_r, valid_mul_r, valid_agu_r, valid_ls_r, mode_r;
    wire    [4:0]     Pw_add_r, Pw_mul_r, Px_r;
    wire    [4:0]     tag_ROB_add_r, tag_ROB_mul_r, tag_ROB_ls_r;
    wire    [4:0]     Imm_r, tag_ROB_agu_r;
    wire    [151:0]   bunch_READ, bunch_READ_r;

    wire    [15:0]    Result_add, Result_mul, Result_ls;
    wire    [4:0]     tag_ROB_Result_add, tag_ROB_Result_mul, tag_ROB_Result_ls;
    wire    [4:0]     Pw_ret[2:0];
    wire    [2:0]     Rw_ret[2:0];

    // --- 连接逻辑 ---
    assign bunch_READ = {busA_add, busB_add, busA_mul, busB_mul, busA_agu, busX, Addr_in,
                         valid_add_in, valid_mul_in, valid_agu_in, valid_ls_in, mode_in,
                         Pw_add_in, Pw_mul_in, Px_in, tag_ROB_add_in, tag_ROB_mul_in, tag_ROB_ls_in, Imm_in, tag_ROB_agu_in};
    assign {busA_add_r, busB_add_r, busA_mul_r, busB_mul_r, busA_agu_r, busX_r, Addr_r,
            valid_add_r, valid_mul_r, valid_agu_r, valid_ls_r, mode_r,
            Pw_add_r, Pw_mul_r, Px_r, tag_ROB_add_r, tag_ROB_mul_r, tag_ROB_ls_r, Imm_r, tag_ROB_agu_r} = bunch_READ_r;
    
    // --- 新增: D-Cache 请求生成 ---
    assign dc_read_req_out = valid_ls_r && mode_r;
    assign dc_write_req_out = valid_ls_r && !mode_r;
    assign dc_addr_out = {14'b0, Addr_r};
    assign dc_wdata_out = {16'b0, busX_r}; // busX来自PRF, 是Store的数据源
    assign dc_byte_w_en_out = (valid_ls_r && !mode_r) ? 4'b1111 : 4'b0;

    // --- 新增: Load结果广播生成 ---
    reg load_req_sent;
    reg [4:0] load_pending_px;
    reg [4:0] load_pending_tag_rob;

    always @(posedge clk or negedge rst) begin
        if(!rst) load_req_sent <= 1'b0;
        else if(dc_read_req_out) begin
            load_req_sent <= 1'b1;
            load_pending_px <= Px_r;
            load_pending_tag_rob <= tag_ROB_ls_r;
        end else if(load_req_sent) begin
            load_req_sent <= 1'b0;
        end
    end
    
    assign valid_Result_ls_out = load_req_sent && !dc_read_req_out;
    assign mode_ls_out = 1'b1;
    assign Pw_Result_ls_out = load_pending_px;
    assign tag_ROB_Result_ls = load_pending_tag_rob;
    assign Result_ls = dc_rdata_in;

    // --- 模块例化 ---
    PRF u_PRF (
        .clk(clk), .rst(rst),
        .Pa_add(Pa_add_in), .Pb_add(Pb_add_in), .busA_add(busA_add), .busB_add(busB_add),
        .Pa_mul(Pa_mul_in), .Pb_mul(Pb_mul_in), .busA_mul(busA_mul), .busB_mul(busB_mul),
        .Pa_agu(Pa_agu_in), .busA_agu(busA_agu),
        .Px(Px_in), .busX(busX),
        .Pw_Result_add(Pw_Result_add_out), .Result_add(Result_add), .valid_Result_add(valid_Result_add_out),
        .Pw_Result_mul(Pw_Result_mul_out), .Result_mul(Result_mul), .valid_Result_mul(valid_Result_mul_out),
        .Pw_Result_ls(Pw_Result_ls_out), .Result_ls(Result_ls), .valid_Result_ls(valid_Result_ls_out), .mode_ls(mode_ls_out)
    );

    REGISTER #(.BW(152)) u_REG_READ_EX (
        .clk(clk), .rst(rst), .stall(freeze_back_in), .flush(flush_in),
        .data_in(bunch_READ), .data_out(bunch_READ_r)
    );

    ADD_UNIT u_ADD_UNIT (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_back(freeze_back_in),
        .valid_add(valid_add_r), .Pw_add(Pw_add_r), .tag_ROB_add(tag_ROB_add_r), .busA_add(busA_add_r), .busB_add(busB_add_r),
        .valid_Result_add(valid_Result_add_out), .Pw_Result_add(Pw_Result_add_out), .tag_ROB_Result_add(tag_ROB_Result_add), .Result_add(Result_add)
    );

    MUL_UNIT u_MUL_UNIT (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_back(freeze_back_in),
        .valid_mul(valid_mul_r), .Pw_mul(Pw_mul_r), .tag_ROB_mul(tag_ROB_mul_r), .busA_mul(busA_mul_r), .busB_mul(busB_mul_r),
        .valid_Result_mul(valid_Result_mul_out), .Pw_Result_mul(Pw_Result_mul_out), .tag_ROB_Result_mul(tag_ROB_Result_mul), .Result_mul(Result_mul)
    );

    AGU u_AGU (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_back(freeze_back_in),
        .valid_agu(valid_agu_r), .busA_agu(busA_agu_r), .Imm(Imm_r), .tag_ROB_agu(tag_ROB_agu_r),
        .valid_Addr_agu(valid_Addr_agu_out), .Addr_agu(Addr_agu_out), .tag_ROB_Result_agu(tag_ROB_Result_agu_out)
    );
    

    ROB u_ROB (
        .clk(clk), .rst(rst), .flush(flush_in), .full_ROB(full_ROB_out),
        .tag_ROB(tag_ROB_out), .valid_pc(valid_pc_in), .freeze_front(freeze_front_in),
        .Type(Type_in), .Pw(Pw_in), .Pw_old(Pw_old_in), .Rw(Rw_in),
        .valid_Result_add(valid_Result_add_out), .tag_ROB_Result_add(tag_ROB_Result_add),
        .valid_Result_mul(valid_Result_mul_out), .tag_ROB_Result_mul(tag_ROB_Result_mul),
        .valid_Result_ls(valid_Result_ls_out), .tag_ROB_Result_ls(tag_ROB_Result_ls),
        .ready_ret(ready_ret_out), .excep_ret(excep_ret_out), .Type_ret(Type_ret_out),
        .Pw_ret(Pw_ret), .Pw_old_ret(Pw_old_ret_out), .Rw_ret(Rw_ret), .ptr_old_out(ptr_old_out)
    );

    ARAT u_ARAT (
        .clk(clk), .rst(rst),
        .ready_ret(ready_ret_out), .excep_ret(excep_ret_out), .Type_ret(Type_ret_out),
        .Pw_ret(Pw_ret), .Rw_ret(Rw_ret),
        .ARAT_P_list(ARAT_P_list_out), .ARAT_freelist(ARAT_freelist_out)
    );
endmodule