module CTRL (
    input       clk,
    input       rst,

    input       stall_if_request,
    input       stall_mem_request,
    
    input       Jump,
    input       Miss,
    input       full_ififo,
    input       full_prf,
    input       full_queue,
    input       full_dfifo,
    input       full_csrfifo,
    input       full_rob,
    input       isBranch_rob,
    input       Branch_rob,
    input       Predict_rob,
    input       isExcp_rob,
    input       isErtn_rob,
    input       isIdle_rob,
    input       has_int,

    output      flush_pc_branch,
    output      flush_pc_excp,
    output      flush_pc_ertn,
    output      flush_pc_idle,
    output      stall_pc,
    output      flush_ifr,
    output      stall_ifr,
    output      flush_ififo,
    output      stall_ififo,
    output      flush_id,
    output      stall_id,
    output      flush_srat,
    output      stall_srat,
    output      flush_queue,
    output      stall_lsuq,
    output      stall_csrq,
    output      flush_back,
    output      flush_lsu_out,
    output      stall_in,
    output      flush_rob
);

    reg         idle_lock;

    // 分支预测失败, 全清空
    assign  flush_pc_branch =   (isBranch_rob == 1 && Branch_rob != Predict_rob)? 1 : 0;
    // 顶格触发例外
    assign  flush_pc_excp   =   (isExcp_rob == 1)? 1 : 0;
    // 触发 ERTN
    assign  flush_pc_ertn   =   (isErtn_rob == 1)? 1 : 0;
    // 触发 IDLE
    assign  flush_pc_idle   =   (isIdle_rob == 1)? 1 : 0;

    assign  flush_back      =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;
    assign  flush_rob       =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;
    assign  flush_queue     =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;
    assign  flush_srat      =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;
    assign  flush_id        =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;
    assign  flush_ififo     =   flush_pc_branch | flush_pc_excp | flush_pc_ertn | flush_pc_idle;

    // DMEM 缓冲队列满, 停缓存流水线; 或 Dcache 总线占用
    assign  stall_lsuq      =   full_dfifo | stall_mem_request;
    assign  flush_lsu_out   =   flush_back | stall_mem_request;
    // CSR 缓冲队列同理
    assign  stall_csrq      =   full_csrfifo;

    // 队列 / PRF / ROB 满, 停前端
    assign  stall_ififo     =   full_prf | full_queue | full_rob;
    assign  stall_id        =   full_prf | full_queue | full_rob;
    assign  stall_srat      =   full_prf | full_queue | full_rob;
    assign  stall_in        =   full_prf | full_queue | full_rob;

    // 取指队列满, 或 IDLE; 或 Icache 总线占用
    assign  stall_ifr       =   full_ififo;
    assign  stall_pc        =   full_ififo | idle_lock | stall_if_request;

    // 遇到取指模块内部跳转; 或 Icache 总线占用
    assign  flush_ifr       =   flush_back | Jump | Miss | idle_lock | stall_if_request;

    // IDLE, idle_lock 锁住后一直 stall PC 并 flush IFreg
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            idle_lock       <=  0;
        end
        else begin
            idle_lock       <=  (flush_pc_idle & ~has_int)? 1 :
                                has_int?                    0 : idle_lock;
        end
    end

endmodule