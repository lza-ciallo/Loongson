module BACK_END (
    input               clk,
    input               rst,
    // 控制信号
    input               freeze_front,
    input               freeze_back,
    input               flush,
    input               valid_issue_x,
    input               valid_issue_y,
    input               valid_issue_z,
    output              full_ROB,
    // 预分配条目
    output  [4 : 0]     tag_ROB_x,
    output  [4 : 0]     tag_ROB_y,
    output  [4 : 0]     tag_ROB_z,
    // 预写入覆盖的 Pw_old, 预写入 Rw
    input   [4 : 0]     Pw_old_x,
    input   [4 : 0]     Pw_old_y,
    input   [4 : 0]     Pw_old_z,
    input   [2 : 0]     Rw_x,
    input   [2 : 0]     Rw_y,
    input   [2 : 0]     Rw_z,
    // RS_ADD 发射输入
    input               valid_add,
    input   [4 : 0]     tag_ROB_add,
    input   [4 : 0]     Pa_add,
    input   [4 : 0]     Pb_add,
    input   [4 : 0]     Pw_add,
    // RS_MUL 发射输入
    input               valid_mul,
    input   [4 : 0]     tag_ROB_mul,
    input   [4 : 0]     Pa_mul,
    input   [4 : 0]     Pb_mul,
    input   [4 : 0]     Pw_mul,
    // 广播输出
    output  [4 : 0]     Pw_Result_add,
    output              valid_Result_add,
    output  [4 : 0]     Pw_Result_mul,
    output              valid_Result_mul,
    // 退休
    output              RegWr_x,
    output              RegWr_y,
    output              RegWr_z,
    output              exp_x,
    output              exp_y,
    output              exp_z,
    output  [4 : 0]     Pw_retire_x,
    output  [4 : 0]     Pw_retire_y,
    output  [4 : 0]     Pw_retire_z,
    // 精确异常恢复
    output  [4 : 0]     ARAT_P_list [7 : 0]
);

    wire    [15 : 0]    busA_add, busA_add_r;
    wire    [15 : 0]    busB_add, busB_add_r;
    wire    [15 : 0]    busA_mul, busA_mul_r;
    wire    [15 : 0]    busB_mul, busB_mul_r;

    wire    [4 : 0]     Pw_add_r;
    wire    [4 : 0]     Pw_mul_r;

    wire    [4 : 0]     tag_ROB_add_r;
    wire    [4 : 0]     tag_ROB_mul_r;

    localparam  BW_READ =   16 * 4 + 5 * 2 + 4 * 2 + 1 * 2;
    wire    [BW_READ - 1 : 0]   bunch_READ, bunch_READ_r;
    assign  bunch_READ = {busA_add, busB_add, busA_mul, busB_mul,
                          Pw_add, Pw_mul, tag_ROB_add, tag_ROB_mul, valid_add, valid_mul};
    assign  {busA_add_r, busB_add_r, busA_mul_r, busB_mul_r,
             Pw_add_r, Pw_mul_r, tag_ROB_add_r, tag_ROB_mul_r, valid_add_r, valid_mul_r} = bunch_READ_r;

    wire    [15 : 0]    Result_add;
    wire    [15 : 0]    Result_mul;

    wire    [4 : 0]     tag_ROB_Result_add;
    wire    [4 : 0]     tag_ROB_Result_mul;

    wire    [2 : 0]     Rw_commit_x;
    wire    [2 : 0]     Rw_commit_y;
    wire    [2 : 0]     Rw_commit_z;

    wire    [4 : 0]     Pw_commit_x;
    wire    [4 : 0]     Pw_commit_y;
    wire    [4 : 0]     Pw_commit_z;

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
        // 广播写入
        .valid_Result_add   (valid_Result_add),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_add      (Pw_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .Result_add         (Result_add),
        .Result_mul         (Result_mul)
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
        .busA_add           (busA_add_r),
        .busB_add           (busB_add_r),
        .tag_ROB_add        (tag_ROB_add_r),
        // 输出
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_add      (Pw_Result_add),
        .Result_add         (Result_add),
        .exp_add            (exp_add),
        .tag_ROB_Result_add (tag_ROB_Result_add)
    );

    MUL_UNIT u_MUL_UNIT (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_back        (freeze_back),
        // 输入
        .valid_mul          (valid_mul_r),
        .Pw_mul             (Pw_mul_r),
        .busA_mul           (busA_mul_r),
        .busB_mul           (busB_mul_r),
        .tag_ROB_mul        (tag_ROB_mul_r),
        // 输出
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_mul      (Pw_Result_mul),
        .Result_mul         (Result_mul),
        .exp_mul            (exp_mul),
        .tag_ROB_Result_mul (tag_ROB_Result_mul)
    );

    ROB u_ROB (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .full_ROB           (full_ROB),
        // 预分配条目
        .tag_ROB_x          (tag_ROB_x),
        .tag_ROB_y          (tag_ROB_y),
        .tag_ROB_z          (tag_ROB_z),
        // 预写入覆盖的 Pw_old, 预写入 Rw
        .freeze_front       (freeze_front),
        .valid_issue_x      (valid_issue_x),
        .valid_issue_y      (valid_issue_y),
        .valid_issue_z      (valid_issue_z),
        .Pw_old_x           (Pw_old_x),
        .Pw_old_y           (Pw_old_y),
        .Pw_old_z           (Pw_old_z),
        .Rw_x               (Rw_x),
        .Rw_y               (Rw_y),
        .Rw_z               (Rw_z),
        // 写入执行结果
        .freeze_back        (freeze_back),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_add      (Pw_Result_add),
        .exp_add            (exp_add),
        .tag_ROB_Result_add (tag_ROB_Result_add),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_mul      (Pw_Result_mul),
        .exp_mul            (exp_mul),
        .tag_ROB_Result_mul (tag_ROB_Result_mul),
        // 退休
        .RegWr_x            (RegWr_x),
        .RegWr_y            (RegWr_y),
        .RegWr_z            (RegWr_z),
        .exp_x              (exp_x),
        .exp_y              (exp_y),
        .exp_z              (exp_z),
        .Pw_retire_x        (Pw_retire_x),
        .Pw_retire_y        (Pw_retire_y),
        .Pw_retire_z        (Pw_retire_z),
        .Rw_commit_x        (Rw_commit_x),
        .Rw_commit_y        (Rw_commit_y),
        .Rw_commit_z        (Rw_commit_z),
        .Pw_commit_x        (Pw_commit_x),
        .Pw_commit_y        (Pw_commit_y),
        .Pw_commit_z        (Pw_commit_z)
    );

    ARAT u_ARAT (
        .clk                (clk),
        .rst                (rst),
        // ROB 端输入
        .RegWr_x            (RegWr_x),
        .RegWr_y            (RegWr_y),
        .RegWr_z            (RegWr_z),
        .exp_x              (exp_x),
        .exp_y              (exp_y),
        .exp_z              (exp_z),
        .Rw_commit_x        (Rw_commit_x),
        .Rw_commit_y        (Rw_commit_y),
        .Rw_commit_z        (Rw_commit_z),
        .Pw_commit_x        (Pw_commit_x),
        .Pw_commit_y        (Pw_commit_y),
        .Pw_commit_z        (Pw_commit_z),
        // 精确异常恢复
        .ARAT_P_list        (ARAT_P_list)
    );

endmodule