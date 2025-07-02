module CORE (
    input       clk,
    input       rst
);

    wire    [4 : 0]     Pw_old_x;
    wire    [4 : 0]     Pw_old_y;
    wire    [4 : 0]     Pw_old_z;

    wire    [3 : 0]     tag_ROB_x;
    wire    [3 : 0]     tag_ROB_y;
    wire    [3 : 0]     tag_ROB_z;

    wire    [4 : 0]     Pa_add;
    wire    [4 : 0]     Pb_add;
    wire    [4 : 0]     Pw_add;
    wire    [3 : 0]     tag_ROB_add;

    wire    [4 : 0]     Pa_mul;
    wire    [4 : 0]     Pb_mul;
    wire    [4 : 0]     Pw_mul;
    wire    [4 : 0]     tag_ROB_mul;

    wire    [4 : 0]     Pw_Result_add;
    wire    [4 : 0]     Pw_Result_mul;

    wire    [4 : 0]     Pw_retire_x;
    wire    [4 : 0]     Pw_retire_y;
    wire    [4 : 0]     Pw_retire_z;

    wire    [4 : 0]     ARAT_P_list [7 : 0];

    FRONT_END u_FRONT_END (
        .clk                (clk),
        .rst                (rst),
        // 控制信号
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .flush              (flush),
        .valid_pc_r_r       (valid_pc_r_r),
        .valid_add_x_r      (valid_add_x_r),
        .valid_mul_x_r      (valid_mul_x_r),
        .valid_add_y_r      (valid_add_y_r),
        .valid_mul_y_r      (valid_mul_y_r),
        .valid_add_z_r      (valid_add_z_r),
        .valid_mul_z_r      (valid_mul_z_r),
        .valid_issue_x      (valid_issue_x),
        .valid_issue_y      (valid_issue_y),
        .valid_issue_z      (valid_issue_z),
        .full_RS_add        (full_RS_add),
        .full_RS_mul        (full_RS_mul),
        // 覆盖 Pw_old 提前写入 ROB
        .Pw_old_x           (Pw_old_x),
        .Pw_old_y           (Pw_old_y),
        .Pw_old_z           (Pw_old_z),
        // ROB 分配条目
        .tag_ROB_x          (tag_ROB_x),
        .tag_ROB_y          (tag_ROB_y),
        .tag_ROB_z          (tag_ROB_z),
        // RS_ADD 发射
        .Pa_add_awake       (Pa_add),
        .Pb_add_awake       (Pb_add),
        .Pw_add_awake       (Pw_add),
        .valid_add_awake    (valid_add),
        .tag_ROB_add_awake  (tag_ROB_add),
        // RS_MUL 发射
        .Pa_mul_awake       (Pa_mul),
        .Pb_mul_awake       (Pb_mul),
        .Pw_mul_awake       (Pw_mul),
        .valid_mul_awake    (valid_mul),
        .tag_ROB_mul_awake  (tag_ROB_mul),
        // 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        // ROB 退休释放 free_list
        .RegWr_x            (RegWr_x),
        .RegWr_y            (RegWr_y),
        .RegWr_z            (RegWr_z),
        .exp_x              (exp_x),
        .exp_y              (exp_y),
        .exp_z              (exp_z),
        .Pw_retire_x        (Pw_retire_x),
        .Pw_retire_y        (Pw_retire_y),
        .Pw_retire_z        (Pw_retire_z),
        // SRAT 精确异常恢复
        .ARAT_P_list        (ARAT_P_list)
    );

    BACK_END u_BACK_END (
        .clk                (clk),
        .rst                (rst),
        // 控制信号
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .flush              (flush),
        .valid_issue_x      (valid_issue_x),
        .valid_issue_y      (valid_issue_y),
        .valid_issue_z      (valid_issue_z),
        .full_PRF           (full_PRF),
        .full_ROB           (full_ROB),
        .exp_x              (exp_x),
        .exp_y              (exp_y),
        .exp_z              (exp_z),
        // 预分配条目
        .tag_ROB_x          (tag_ROB_x),
        .tag_ROB_y          (tag_ROB_y),
        .tag_ROB_z          (tag_ROB_z),
        // 预写入覆盖的 Pw_old
        .Pw_old_x           (Pw_old_x),
        .Pw_old_y           (Pw_old_y),
        .Pw_old_z           (Pw_old_z),
        // RS_ADD 发射输入
        .valid_add          (valid_add),
        .tag_ROB_add        (tag_ROB_add),
        .Pa_add             (Pa_add),
        .Pb_add             (Pb_add),
        .Pw_add             (Pw_add),
        // RS_MUL 发射输入
        .valid_mul          (valid_mul),
        .tag_ROB_mul        (tag_ROB_mul),
        .Pa_mul             (Pa_mul),
        .Pb_mul             (Pb_mul),
        .Pw_mul             (Pw_mul),
        // 广播输出
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
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
        // 精确异常恢复
        .ARAT_P_list        (ARAT_P_list)
    );

    CTRL u_CTRL (
        // 指令有效性
        .valid_pc_r_r       (valid_pc_r_r),
        .valid_add_x_r      (valid_add_x_r),
        .valid_mul_x_r      (valid_mul_x_r),
        .valid_add_y_r      (valid_add_y_r),
        .valid_mul_y_r      (valid_mul_y_r),
        .valid_add_z_r      (valid_add_z_r),
        .valid_mul_z_r      (valid_mul_z_r),
        // 存储区域满
        .full_RS_add        (full_RS_add),
        .full_RS_mul        (full_RS_mul),
        .full_PRF           (full_PRF),
        .full_ROB           (full_ROB),
        // 异常中断
        .exp_x              (exp_x),
        .exp_y              (exp_y),
        .exp_z              (exp_z),
        // 输出控制信号
        .valid_issue_x      (valid_issue_x),
        .valid_issue_y      (valid_issue_y),
        .valid_issue_z      (valid_issue_z),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .flush              (flush)
    );

endmodule