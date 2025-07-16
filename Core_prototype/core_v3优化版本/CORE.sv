module CORE (
    input           clk,
    input           rst
);

    // 预写入
    wire    [ 1 : 0]    Type        [2 : 0];
    wire    [ 4 : 0]    Pw          [2 : 0];
    wire    [ 4 : 0]    Pw_old      [2 : 0];
    wire    [ 2 : 0]    Rw          [2 : 0];
    wire    [ 4 : 0]    tag_ROB     [2 : 0];

    // 发射
    wire    [ 4 : 0]    Pa_add;
    wire    [ 4 : 0]    Pb_add;
    wire    [ 4 : 0]    Pw_add;
    wire    [ 4 : 0]    tag_ROB_add;

    wire    [ 4 : 0]    Pa_mul;
    wire    [ 4 : 0]    Pb_mul;
    wire    [ 4 : 0]    Pw_mul;
    wire    [ 4 : 0]    tag_ROB_mul;

    wire    [ 4 : 0]    Pa_agu;
    wire    [ 4 : 0]    Imm;
    wire    [ 4 : 0]    tag_ROB_agu;

    wire    [ 4 : 0]    Px;
    wire    [15 : 0]    Addr;
    wire    [ 4 : 0]    tag_ROB_ls;

    // 广播
    wire    [ 4 : 0]    Pw_Result_add;
    wire    [ 4 : 0]    Pw_Result_mul;
    wire    [ 4 : 0]    Pw_Result_ls;

    wire    [ 4 : 0]    tag_ROB_Result_agu;
    wire    [15 : 0]    Addr_agu;

    // ROB 退休
    wire                ready_ret   [2 : 0];
    wire                excep_ret   [2 : 0];
    wire    [ 1 : 0]    Type_ret    [2 : 0];
    wire    [ 4 : 0]    Pw_old_ret  [2 : 0];

    // 精确异常恢复
    wire    [ 4 : 0]    ARAT_P_list [7 : 0];
    wire    [31 : 0]    ARAT_freelist;

    // (新增) oldest-first 实现
    wire    [ 4 : 0]    ptr_old;    // +

    FRONT_END u_FRONT_END (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .full_PRF           (full_PRF),
        .full_RS_add        (full_RS_add),
        .full_RS_mul        (full_RS_mul),
        .full_RS_agu        (full_RS_agu),
        .full_LSQ           (full_LSQ),
        // ROB 预写入
        .valid_pc_r_r       (valid_pc),
        .Type_r             (Type),
        .Pw                 (Pw),
        .Pw_old             (Pw_old),
        .Rw_r               (Rw),
        // ROB 分配条目
        .tag_ROB            (tag_ROB),
        // RS_ADD 发射
        .valid_add_awake    (valid_add),
        .Pa_add_awake       (Pa_add),
        .Pb_add_awake       (Pb_add),
        .Pw_add_awake       (Pw_add),
        .tag_ROB_add_awake  (tag_ROB_add),
        // RS_MUL 发射
        .valid_mul_awake    (valid_mul),
        .Pa_mul_awake       (Pa_mul),
        .Pb_mul_awake       (Pb_mul),
        .Pw_mul_awake       (Pw_mul),
        .tag_ROB_mul_awake  (tag_ROB_mul),
        // RS_AGU 发射
        .valid_agu_awake    (valid_agu),
        .Pa_agu_awake       (Pa_agu),
        .Imm_awake          (Imm),
        .tag_ROB_agu_awake  (tag_ROB_agu),
        // LSQ 发射
        .valid_ls_awake     (valid_ls),
        .mode_awake         (mode),
        .Px_awake           (Px),
        .Addr_awake         (Addr),
        .tag_ROB_ls_awake   (tag_ROB_ls),
        // 接收广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // 接收 AGU 特殊广播
        .valid_Addr_agu     (valid_Addr_agu),
        .tag_ROB_Result_agu (tag_ROB_Result_agu),
        .Addr_agu           (Addr_agu),
        // ROB 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret),
        .Pw_old_ret         (Pw_old_ret),
        // 精确异常恢复
        .ARAT_P_list        (ARAT_P_list),
        .ARAT_freelist      (ARAT_freelist),
        // (新增) oldest-first 实现
        .ptr_old            (ptr_old)   // +
    );

    BACK_END u_BACK_END (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .valid_pc           (valid_pc),
        .full_ROB           (full_ROB),
        .full_FIFO          (full_FIFO),
        // 预分配条目
        .tag_ROB            (tag_ROB),
        // 预写入
        .Type               (Type),
        .Pw                 (Pw),
        .Pw_old             (Pw_old),
        .Rw                 (Rw),
        // RS_ADD 发射
        .valid_add          (valid_add),
        .Pa_add             (Pa_add),
        .Pb_add             (Pb_add),
        .Pw_add             (Pw_add),
        .tag_ROB_add        (tag_ROB_add),
        // RS_MUL 发射
        .valid_mul          (valid_mul),
        .Pa_mul             (Pa_mul),
        .Pb_mul             (Pb_mul),
        .Pw_mul             (Pw_mul),
        .tag_ROB_mul        (tag_ROB_mul),
        // RS_AGU 发射
        .valid_agu          (valid_agu),
        .Pa_agu             (Pa_agu),
        .Imm                (Imm),
        .tag_ROB_agu        (tag_ROB_agu),
        // LSQ 发射
        .valid_ls           (valid_ls),
        .mode               (mode),
        .Px                 (Px),
        .Addr               (Addr),
        .tag_ROB_ls         (tag_ROB_ls),
        // 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // AGU 特殊广播
        .valid_Addr_agu     (valid_Addr_agu),
        .tag_ROB_Result_agu (tag_ROB_Result_agu),
        .Addr_agu           (Addr_agu),
        // ROB 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret),
        .Pw_old_ret         (Pw_old_ret),
        // 精确异常恢复
        .ARAT_P_list        (ARAT_P_list),
        .ARAT_freelist      (ARAT_freelist),
        // (新增) oldest-first 实现
        .ptr_old            (ptr_old)   // +
    );

    CTRL u_CTRL (
        .full_PRF           (full_PRF),
        .full_ROB           (full_ROB),
        .full_FIFO          (full_FIFO),
        .full_RS_add        (full_RS_add),
        .full_RS_mul        (full_RS_mul),
        .full_RS_agu        (full_RS_agu),
        .full_LSQ           (full_LSQ),
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back)
    );

endmodule