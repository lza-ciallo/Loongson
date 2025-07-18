module BACK_END (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    input               valid_pc,
    output              full_ROB,
    output              full_FIFO,
    // 预分配条目
    output  [4 : 0]     tag_ROB [2 : 0],
    // 预写入
    input   [1 : 0]     Type    [2 : 0],
    input   [4 : 0]     Pw      [2 : 0],
    input   [4 : 0]     Pw_old  [2 : 0],
    input   [2 : 0]     Rw      [2 : 0],
    // RS_ADD 发射
    input               valid_add,
    input   [ 4 : 0]    Pa_add,
    input   [ 4 : 0]    Pb_add,
    input   [ 4 : 0]    Pw_add,
    input   [ 4 : 0]    tag_ROB_add,
    // RS_MUL 发射
    input               valid_mul,
    input   [ 4 : 0]    Pa_mul,
    input   [ 4 : 0]    Pb_mul,
    input   [ 4 : 0]    Pw_mul,
    input   [ 4 : 0]    tag_ROB_mul,
    // RS_AGU 发射
    input               valid_agu,
    input   [ 4 : 0]    Pa_agu,
    input   [ 4 : 0]    Imm,
    input   [ 4 : 0]    tag_ROB_agu,
    // LSQ 发射
    input               valid_ls,
    input               mode,
    input   [ 4 : 0]    Px,
    input   [15 : 0]    Addr,
    input   [ 4 : 0]    tag_ROB_ls,
    // 广播
    output  [ 4 : 0]    Pw_Result_add,
    output              valid_Result_add,
    output  [ 4 : 0]    Pw_Result_mul,
    output              valid_Result_mul,
    output  [ 4 : 0]    Pw_Result_ls,
    output              valid_Result_ls,
    output              mode_ls,
    // AGU 特殊广播
    output              valid_Addr_agu,
    output  [ 4 : 0]    tag_ROB_Result_agu,
    output  [15 : 0]    Addr_agu,
    // ROB 退休
    output              ready_ret   [2 : 0],
    output              excep_ret   [2 : 0],
    output  [ 1 : 0]    Type_ret    [2 : 0],
    output  [ 4 : 0]    Pw_old_ret  [2 : 0],
    // 精确异常恢复
    output  [ 4 : 0]    ARAT_P_list [7 : 0],
    output  [31 : 0]    ARAT_freelist
);



    // READ-EX

    wire    [15 : 0]    busA_add, busA_add_r;
    wire    [15 : 0]    busB_add, busB_add_r;
    wire    [15 : 0]    busA_mul, busA_mul_r;
    wire    [15 : 0]    busB_mul, busB_mul_r;
    wire    [15 : 0]    busA_agu, busA_agu_r;
    wire    [15 : 0]    busX, busX_r;
    wire    [15 : 0]    Addr_r;     // Addr input

    wire    [ 4 : 0]    Pw_add_r;
    wire    [ 4 : 0]    Pw_mul_r;
    wire    [ 4 : 0]    Px_r;
    wire    [ 4 : 0]    tag_ROB_add_r;
    wire    [ 4 : 0]    tag_ROB_mul_r;
    wire    [ 4 : 0]    tag_ROB_ls_r;
    wire    [ 4 : 0]    Imm_r;
    wire    [ 4 : 0]    tag_ROB_agu_r;

    localparam  BW_READ     =   16*7 + 1*5 + 5*3 + 5*3 + 5 + 5;
    wire    [BW_READ - 1 : 0]   bunch_READ, bunch_READ_r;
    assign  bunch_READ = {busA_add, busB_add, busA_mul, busB_mul, busA_agu, busX, Addr,
                          valid_add, valid_mul, valid_agu, valid_ls, mode,
                          Pw_add, Pw_mul, Px, tag_ROB_add, tag_ROB_mul, tag_ROB_ls, Imm, tag_ROB_agu};
    assign  {busA_add_r, busB_add_r, busA_mul_r, busB_mul_r, busA_agu_r, busX_r, Addr_r,
             valid_add_r, valid_mul_r, valid_agu_r, valid_ls_r, mode_r,
             Pw_add_r, Pw_mul_r, Px_r, tag_ROB_add_r, tag_ROB_mul_r, tag_ROB_ls_r, Imm_r, tag_ROB_agu_r} = bunch_READ_r;

    // EX-WB

    wire    [15 : 0]    Result_add;
    wire    [15 : 0]    Result_mul;
    wire    [15 : 0]    Result_ls;

    wire    [ 4 : 0]    tag_ROB_Result_add;
    wire    [ 4 : 0]    tag_ROB_Result_mul;
    wire    [ 4 : 0]    tag_ROB_Result_ls;

    wire    [ 4 : 0]    Pw_ret  [2 : 0];
    wire    [ 2 : 0]    Rw_ret  [2 : 0];



    PRF u_PRF (
        .clk                (clk),
        .rst                (rst),
        // ADD 读出
        .Pa_add             (Pa_add),
        .Pb_add             (Pb_add),
        .busA_add           (busA_add),
        .busB_add           (busB_add),
        // MUL 读出
        .Pa_mul             (Pa_mul),
        .Pb_mul             (Pb_mul),
        .busA_mul           (busA_mul),
        .busB_mul           (busB_mul),
        // AGU 读出
        .Pa_agu             (Pa_agu),
        .busA_agu           (busA_agu),
        // LS 读出
        .Px                 (Px),
        .busX               (busX),
        // 广播写入
        .Pw_Result_add      (Pw_Result_add),
        .Result_add         (Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .Result_mul         (Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_ls       (Pw_Result_ls),
        .Result_ls          (Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls)
    );

    REGISTER #(
        .BW                 (BW_READ)
    ) u_REG_READ_EX (
        .clk                (clk),
        .rst                (rst),
        .stall              (freeze_back),
        .flush              (flush),
        .data_in            (bunch_READ),
        .data_out           (bunch_READ_r)
    );

    ADD_UNIT u_ADD_UNIT (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_back        (freeze_back),
        // 输入
        .valid_add          (valid_add_r),
        .Pw_add             (Pw_add_r),
        .tag_ROB_add        (tag_ROB_add_r),
        .busA_add           (busA_add_r),
        .busB_add           (busB_add_r),
        // 输出
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_add      (Pw_Result_add),
        .tag_ROB_Result_add (tag_ROB_Result_add),
        .Result_add         (Result_add)
    );

    MUL_UNIT u_MUL_UNIT (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_back        (freeze_back),
        // 输入
        .valid_mul          (valid_mul_r),
        .Pw_mul             (Pw_mul_r),
        .tag_ROB_mul        (tag_ROB_mul_r),
        .busA_mul           (busA_mul_r),
        .busB_mul           (busB_mul_r),
        // 输出
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_mul      (Pw_Result_mul),
        .tag_ROB_Result_mul (tag_ROB_Result_mul),
        .Result_mul         (Result_mul)
    );

    AGU u_AGU (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_back        (freeze_back),
        // 输入
        .valid_agu          (valid_agu_r),
        .busA_agu           (busA_agu_r),
        .Imm                (Imm_r),
        .tag_ROB_agu        (tag_ROB_agu_r),
        // 输出
        .valid_Addr_agu     (valid_Addr_agu),
        .Addr_agu           (Addr_agu),
        .tag_ROB_Result_agu (tag_ROB_Result_agu)
    );

    DATA_MEM u_DATA_MEM (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_back        (freeze_back),
        .full_FIFO          (full_FIFO),
        // 输入
        .valid_ls           (valid_ls_r),
        .mode               (mode_r),
        .busX               (busX_r),
        .Addr               (Addr_r),
        .tag_ROB_ls         (tag_ROB_ls_r),
        .Px                 (Px_r),
        // 输出
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        .tag_ROB_Result_ls  (tag_ROB_Result_ls),
        .Result_ls          (Result_ls),
        .Pw_Result_ls       (Pw_Result_ls),
        // ROB 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret)
    );

    ROB u_ROB (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .full_ROB           (full_ROB),
        // 预分配条目
        .tag_ROB            (tag_ROB),
        // 预写入
        .valid_pc           (valid_pc),
        .freeze_front       (freeze_front),
        .Type               (Type),
        .Pw                 (Pw),
        .Pw_old             (Pw_old),
        .Rw                 (Rw),
        // 写入广播结果
        .valid_Result_add   (valid_Result_add),
        .tag_ROB_Result_add (tag_ROB_Result_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_ROB_Result_mul (tag_ROB_Result_mul),
        .valid_Result_ls    (valid_Result_ls),
        .tag_ROB_Result_ls  (tag_ROB_Result_ls),
        // 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret),
        .Pw_ret             (Pw_ret),
        .Pw_old_ret         (Pw_old_ret),
        .Rw_ret             (Rw_ret)
    );

    ARAT u_ARAT (
        .clk                (clk),
        .rst                (rst),
        // ROB 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret),
        .Pw_ret             (Pw_ret),
        .Rw_ret             (Rw_ret),
        // 精确异常恢复
        .ARAT_P_list        (ARAT_P_list),
        .ARAT_freelist      (ARAT_freelist)
    );

endmodule