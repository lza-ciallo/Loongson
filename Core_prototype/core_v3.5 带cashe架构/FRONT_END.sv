`timescale 1ns / 1ps

module FRONT_END (
    // --- 顶层控制与时钟 ---
    input               clk,
    input               rst,
    input               flush_in,
    input               freeze_front_in,
    input               freeze_back_in,

    // --- 从 BACK_END 输入的信号 ---
    input               full_ROB_in,
    input               full_FIFO_in,
    input   [4 : 0]     tag_ROB_in      [2 : 0],
    input   [4 : 0]     Pw_Result_add_in,
    input               valid_Result_add_in,
    input   [4 : 0]     Pw_Result_mul_in,
    input               valid_Result_mul_in,
    input   [4 : 0]     Pw_Result_ls_in,
    input               valid_Result_ls_in,
    input               mode_ls_in,
    input               valid_Addr_agu_in,
    input   [4 : 0]     tag_ROB_Result_agu_in,
    input   [15 : 0]    Addr_agu_in,
    input   [4 : 0]     ARAT_P_list_in  [7 : 0],
    input   [31 : 0]    ARAT_freelist_in,
    input   [4 : 0]     ptr_old_in,
    input               ready_ret_in    [2 : 0],
    input               excep_ret_in    [2 : 0],
    input   [1 : 0]     Type_ret_in     [2 : 0],
    input   [4 : 0]     Pw_old_ret_in   [2 : 0],

    // --- Cache 接口 ---
    output              ic_read_req_out,
    output  [29:0]      ic_addr_out,
    input   [63:0]      ic_data_in,
    input               cache_stall_in,
    output              dc_read_req_out,
    output              dc_write_req_out,
    output  [3:0]       dc_byte_w_en_out,
    output  [29:0]      dc_addr_out,
    output  [31:0]      dc_wdata_out,
    input   [31:0]      dc_rdata_in,

    // --- 输出到 BACK_END 的信号 ---
    output              valid_pc_out,
    output              full_PRF_out,
    output              full_RS_add_out,
    output              full_RS_mul_out,
    output              full_RS_agu_out,
    output              full_LSQ_out,
    output  [1 : 0]     Type_out        [2 : 0],
    output  [4 : 0]     Pa_out          [2 : 0],
    output  [4 : 0]     Pb_out          [2 : 0],
    output  [4 : 0]     Pw_out          [2 : 0],
    output  [4 : 0]     Pw_old_out      [2 : 0],
    output  [2 : 0]     Rw_out          [2 : 0],
    output              valid_add_awake_out,
    output  [4 : 0]     Pa_add_awake_out,
    output  [4 : 0]     Pb_add_awake_out,
    output  [4 : 0]     Pw_add_awake_out,
    output  [4 : 0]     tag_ROB_add_awake_out,
    output              valid_mul_awake_out,
    output  [4 : 0]     Pa_mul_awake_out,
    output  [4 : 0]     Pb_mul_awake_out,
    output  [4 : 0]     Pw_mul_awake_out,
    output  [4 : 0]     tag_ROB_mul_awake_out,
    output              valid_agu_awake_out,
    output  [4 : 0]     Pa_agu_awake_out,
    output  [4 : 0]     Imm_awake_out,
    output  [4 : 0]     tag_ROB_agu_awake_out,
    output              valid_ls_awake_out,
    output              mode_awake_out,
    output  [4 : 0]     Px_awake_out,
    output  [15 : 0]    Addr_awake_out,
    output  [4 : 0]     tag_ROB_ls_awake_out,

    output              valid_Result_ls_to_broadcast,
    output  [4:0]       Pw_Result_ls_to_broadcast,
    output              mode_ls_to_broadcast,
    output Data_Result_ls_out 
);

    // --- 内部信号 ---
    wire    [7:0]     pc_from_pc_module;
    wire              valid_pc_from_pc_module;
    wire    [12:0]    inst[2:0];
    wire    [12:0]    inst_r[2:0];
    wire    [38:0]    inst_unfold, inst_unfold_r;
    wire    [39:0]    bunch_IF, bunch_IF_r;
    wire              valid_pc_r;
    wire    [1:0]     Type_r_internal [2:0];
    wire    [2:0]     Ra_r[2:0], Rb_r[2:0], Rw_r_internal[2:0];
    wire    [4:0]     Imm_r[2:0];
    wire    [5:0]     Type_unfold, Type_unfold_r;
    wire    [8:0]     Ra_unfold, Ra_unfold_r, Rb_unfold, Rb_unfold_r, Rw_unfold, Rw_unfold_r;
    wire    [14:0]    Imm_unfold, Imm_unfold_r;
    wire    [48:0]    bunch_ID, bunch_ID_r;
    wire              valid_pc_r_r_internal;
    wire    [4:0]     Pa_internal[2:0], Pb_internal[2:0], Pw_internal[2:0], Pw_old_internal[2:0];
    wire              valid_Pa[2:0], valid_Pb[2:0];
    wire    [1:0]     Type_ref_add, Type_ref_mul;
    genvar            gv_i;

    // --- 连接逻辑 ---
    assign valid_pc_out = valid_pc_r_r_internal;
    assign Type_out = Type_r_internal;
    assign Pa_out = Pa_internal;
    assign Pb_out = Pb_internal;
    assign Pw_out = Pw_internal;
    assign Pw_old_out = Pw_old_internal;
    assign Rw_out = Rw_r_internal;

    assign ic_read_req_out = valid_pc_from_pc_module && !(freeze_front_in | cache_stall_in);//modified
    assign ic_addr_out = {22'b0, pc_from_pc_module};
    assign inst[0] = ic_data_in[12:0];
    assign inst[1] = ic_data_in[25:13];
    assign inst[2] = ic_data_in[38:26];
    
    assign inst_unfold = {inst[2], inst[1], inst[0]};
    assign inst_r = {<<{inst_unfold_r}};
    assign bunch_IF = {inst_unfold, valid_pc_from_pc_module};
    assign {inst_unfold_r, valid_pc_r} = bunch_IF_r;

    assign Type_unfold = {<<{Type_r_internal}};
    assign Type_r_internal = {<<{Type_unfold_r}};
    assign Ra_unfold = {<<{Ra_r}};
    assign Ra_r = {<<{Ra_unfold_r}};
    assign Rb_unfold = {<<{Rb_r}};
    assign Rb_r = {<<{Rb_unfold_r}};
    assign Rw_unfold = {<<{Rw_r_internal}};
    assign Rw_r_internal = {<<{Rw_unfold_r}};
    assign Imm_unfold = {<<{Imm_r}};
    assign Imm_r = {<<{Imm_unfold_r}};
    
    assign bunch_ID = {Type_unfold, Ra_unfold, Rb_unfold, Rw_unfold, Imm_unfold, valid_pc_r};
    assign {Type_unfold_r, Ra_unfold_r, Rb_unfold_r, Rw_unfold_r, Imm_unfold_r, valid_pc_r_r_internal} = bunch_ID_r;

    assign Type_ref_add = 2'b00;
    assign Type_ref_mul = 2'b01;

    // --- 模块例化 ---
    PC u_PC (
        .clk(clk), .rst(rst), .freeze_front(freeze_front_in | cache_stall_in),
        .pc(pc_from_pc_module), .valid_pc(valid_pc_from_pc_module)
    );

    REGISTER #(.BW(40)) u_REG_IF_ID (
        .clk(clk), .rst(rst), .stall(freeze_front_in | cache_stall_in), .flush(flush_in),
        .data_in(bunch_IF), .data_out(bunch_IF_r)
    );

    generate
        for (gv_i = 0; gv_i < 3; gv_i = gv_i + 1) begin
            DECODER u_DECODER (
                .inst(inst_r[gv_i]), .Type(Type_r_internal[gv_i]), .Ra(Ra_r[gv_i]), 
                .Rb(Rb_r[gv_i]), .Rw(Rw_r_internal[gv_i]), .Imm(Imm_r[gv_i])
            );
        end
    endgenerate

    REGISTER #(.BW(49)) u_REG_ID_RENAME (
        .clk(clk), .rst(rst), .stall(freeze_front_in), .flush(flush_in),
        .data_in(bunch_ID), .data_out(bunch_ID_r)
    );

    SRAT u_SRAT (
        .clk(clk), .rst(rst), .freeze_front(freeze_front_in), .valid_pc(valid_pc_r_r_internal), .full_PRF(full_PRF_out),
        .Type(Type_r_internal), .Ra(Ra_r), .Rb(Rb_r), .Rw(Rw_r_internal), .Pa(Pa_internal), .Pb(Pb_internal), .Pw(Pw_internal), .Pw_old(Pw_old_internal), .valid_Pa(valid_Pa), .valid_Pb(valid_Pb),
        .Pw_Result_add(Pw_Result_add_in), .valid_Result_add(valid_Result_add_in),
        .Pw_Result_mul(Pw_Result_mul_in), .valid_Result_mul(valid_Result_mul_in),
        .Pw_Result_ls(Pw_Result_ls_in), .valid_Result_ls(valid_Result_ls_in), .mode_ls(mode_ls_in),
        .ready_ret(ready_ret_in), .excep_ret(excep_ret_in), .Type_ret(Type_ret_in), .Pw_old_ret(Pw_old_ret_in),
        .flush(flush_in), .ARAT_P_list(ARAT_P_list_in), .ARAT_freelist(ARAT_freelist_in)
    );

    RS u_RS_ADD (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_front(freeze_front_in), .freeze_back(freeze_back_in), .valid_pc(valid_pc_r_r_internal), .full_RS(full_RS_add_out),
        .Type_ref(Type_ref_add), .Type(Type_r_internal), .Pa(Pa_internal), .Pb(Pb_internal), .Pw(Pw_internal), .valid_Pa(valid_Pa), .valid_Pb(valid_Pb), .tag_ROB(tag_ROB_in),
        .valid_op_awake(valid_add_awake_out), .Pa_awake(Pa_add_awake_out), .Pb_awake(Pb_add_awake_out), .Pw_awake(Pw_add_awake_out), .tag_ROB_awake(tag_ROB_add_awake_out),
        .Pw_Result_add(Pw_Result_add_in), .valid_Result_add(valid_Result_add_in),
        .Pw_Result_mul(Pw_Result_mul_in), .valid_Result_mul(valid_Result_mul_in),
        .Pw_Result_ls(Pw_Result_ls_in), .valid_Result_ls(valid_Result_ls_in), .mode_ls(mode_ls_in), .ptr_old(ptr_old_in)
    );

    RS u_RS_MUL (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_front(freeze_front_in), .freeze_back(freeze_back_in), .valid_pc(valid_pc_r_r_internal), .full_RS(full_RS_mul_out),
        .Type_ref(Type_ref_mul), .Type(Type_r_internal), .Pa(Pa_internal), .Pb(Pb_internal), .Pw(Pw_internal), .valid_Pa(valid_Pa), .valid_Pb(valid_Pb), .tag_ROB(tag_ROB_in),
        .valid_op_awake(valid_mul_awake_out), .Pa_awake(Pa_mul_awake_out), .Pb_awake(Pb_mul_awake_out), .Pw_awake(Pw_mul_awake_out), .tag_ROB_awake(tag_ROB_mul_awake_out),
        .Pw_Result_add(Pw_Result_add_in), .valid_Result_add(valid_Result_add_in),
        .Pw_Result_mul(Pw_Result_mul_in), .valid_Result_mul(valid_Result_mul_in),
        .Pw_Result_ls(Pw_Result_ls_in), .valid_Result_ls(valid_Result_ls_in), .mode_ls(mode_ls_in), .ptr_old(ptr_old_in)
    );

    RS_AGU u_RS_AGU (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_front(freeze_front_in), .freeze_back(freeze_back_in), .valid_pc(valid_pc_r_r_internal), .full_RS(full_RS_agu_out),
        .Type(Type_r_internal), .Pa(Pa_internal), .valid_Pa(valid_Pa), .Imm(Imm_r), .tag_ROB(tag_ROB_in),
        .valid_op_awake(valid_agu_awake_out), .Pa_awake(Pa_agu_awake_out), .Imm_awake(Imm_awake_out), .tag_ROB_awake(tag_ROB_agu_awake_out),
        .Pw_Result_add(Pw_Result_add_in), .valid_Result_add(valid_Result_add_in),
        .Pw_Result_mul(Pw_Result_mul_in), .valid_Result_mul(valid_Result_mul_in), 
        .Pw_Result_ls(Pw_Result_ls_in), .valid_Result_ls(valid_Result_ls_in), .mode_ls(mode_ls_in), .ptr_old(ptr_old_in)
    );

    LSQ u_LSQ (
        .clk(clk), .rst(rst), .flush(flush_in), .freeze_front(freeze_front_in), .freeze_back(freeze_back_in), .valid_pc(valid_pc_r_r_internal), .full_LSQ(full_LSQ_out),
        .Type(Type_r_internal), .Pa(Pa_internal), .Pb(Pb_internal), .valid_Pa(valid_Pa), .valid_Pb(valid_Pb), .Pw(Pw_internal), .tag_ROB(tag_ROB_in),
        .valid_op_awake(valid_ls_awake_out), .mode_awake(mode_awake_out), .Px_awake(Px_awake_out), .Addr_awake(Addr_awake_out), .tag_ROB_awake(tag_ROB_ls_awake_out),
        .Pw_Result_add(Pw_Result_add_in), .valid_Result_add(valid_Result_add_in),
        .Pw_Result_mul(Pw_Result_mul_in), .valid_Result_mul(valid_Result_mul_in),
        .valid_Result_ls_out(valid_Result_ls_in), .Pw_Result_ls_out(Pw_Result_ls_in), .mode_ls_out(mode_ls_in),
        .valid_Addr_agu(valid_Addr_agu_in), .tag_ROB_Result_agu(tag_ROB_Result_agu_in), .Addr_agu(Addr_agu_in),
        .dc_read_req(dc_read_req_out), .dc_write_req(dc_write_req_out), .dc_addr(dc_addr_out), .dc_byte_w_en(dc_byte_w_en_out), .dc_wdata(dc_wdata_out), .dc_rdata(dc_rdata_in),
        .Data_Result_ls_out (Data_Result_ls_out)
    );
endmodule