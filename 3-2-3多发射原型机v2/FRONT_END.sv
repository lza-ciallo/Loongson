module FRONT_END (
    input               clk,
    input               rst,
    // 控制信号
    input               freeze_front,
    input               freeze_back,
    input               flush,
    output              valid_pc_r_r,
    output              valid_add_x_r,
    output              valid_mul_x_r,
    output              valid_add_y_r,
    output              valid_mul_y_r,
    output              valid_add_z_r,
    output              valid_mul_z_r,
    input               valid_issue_x,
    input               valid_issue_y,
    input               valid_issue_z,
    output              full_RS_add,
    output              full_RS_mul,
    output              full_PRF,
    // 覆盖的 Pw_old, Rw 提前写入 ROB
    output  [4 : 0]     Pw_old_x,
    output  [4 : 0]     Pw_old_y,
    output  [4 : 0]     Pw_old_z,
    output  [2 : 0]     Rw_x_r,
    output  [2 : 0]     Rw_y_r,
    output  [2 : 0]     Rw_z_r,
    // ROB 分配条目
    input   [4 : 0]     tag_ROB_x,
    input   [4 : 0]     tag_ROB_y,
    input   [4 : 0]     tag_ROB_z,
    // RS_ADD 发射
    output  [4 : 0]     Pa_add_awake,
    output  [4 : 0]     Pb_add_awake,
    output  [4 : 0]     Pw_add_awake,
    output              valid_add_awake,
    output  [4 : 0]     tag_ROB_add_awake,
    // RS_MUL 发射
    output  [4 : 0]     Pa_mul_awake,
    output  [4 : 0]     Pb_mul_awake,
    output  [4 : 0]     Pw_mul_awake,
    output              valid_mul_awake,
    output  [4 : 0]     tag_ROB_mul_awake,
    // 广播
    input   [4 : 0]     Pw_Result_add,
    input               valid_Result_add,
    input   [4 : 0]     Pw_Result_mul,
    input               valid_Result_mul,
    // ROB 退休释放 free_list
    input               RegWr_x,
    input               RegWr_y,
    input               RegWr_z,
    input               exp_x,
    input               exp_y,
    input               exp_z,
    input   [4 : 0]     Pw_retire_x,
    input   [4 : 0]     Pw_retire_y,
    input   [4 : 0]     Pw_retire_z,
    // SRAT 精确异常恢复
    input   [4 : 0]     ARAT_P_list [7 : 0]
);

    wire    [7 : 0]     pc;

    wire    [9 : 0]     inst_x, inst_x_r;
    wire    [9 : 0]     inst_y, inst_y_r;
    wire    [9 : 0]     inst_z, inst_z_r;

    localparam  BW_IF   =   3 * 10 + 1;
    wire    [BW_IF - 1 : 0]     bunch_IF, bunch_IF_r;
    assign  bunch_IF = {inst_x, inst_y, inst_z, valid_pc};
    assign  {inst_x_r, inst_y_r, inst_z_r, valid_pc_r} = bunch_IF_r;

    wire    [2 : 0]     Ra_x, Ra_x_r;
    wire    [2 : 0]     Rb_x, Rb_x_r;
    wire    [2 : 0]     Rw_x;
    wire    [2 : 0]     Ra_y, Ra_y_r;
    wire    [2 : 0]     Rb_y, Rb_y_r;
    wire    [2 : 0]     Rw_y;
    wire    [2 : 0]     Ra_z, Ra_z_r;
    wire    [2 : 0]     Rb_z, Rb_z_r;
    wire    [2 : 0]     Rw_z;

    localparam  BW_ID   =   3 * (3 * 3 + 1 * 2) + 1;
    wire    [BW_ID - 1 : 0]     bunch_ID, bunch_ID_r;
    assign  bunch_ID = {Ra_x, Rb_x, Rw_x, valid_add_x, valid_mul_x,
                        Ra_y, Rb_y, Rw_y, valid_add_y, valid_mul_y,
                        Ra_z, Rb_z, Rw_z, valid_add_z, valid_mul_z, valid_pc_r};
    assign  {Ra_x_r, Rb_x_r, Rw_x_r, valid_add_x_r, valid_mul_x_r,
             Ra_y_r, Rb_y_r, Rw_y_r, valid_add_y_r, valid_mul_y_r,
             Ra_z_r, Rb_z_r, Rw_z_r, valid_add_z_r, valid_mul_z_r, valid_pc_r_r} = bunch_ID_r;
    
    wire    [4 : 0]     Pa_x;
    wire    [4 : 0]     Pb_x;
    wire    [4 : 0]     Pw_x;
    wire    [4 : 0]     Pa_y;
    wire    [4 : 0]     Pb_y;
    wire    [4 : 0]     Pw_y;
    wire    [4 : 0]     Pa_z;
    wire    [4 : 0]     Pb_z;
    wire    [4 : 0]     Pw_z;

    PC u_PC (
        .clk                (clk),
        .rst                (rst),
        .freeze_front       (freeze_front),
        .pc                 (pc),
        .valid_pc           (valid_pc)
    );

    INST_MEM u_INST_MEM (
        .rst                (rst),
        .pc                 (pc),
        .inst_x             (inst_x),
        .inst_y             (inst_y),
        .inst_z             (inst_z)
    );

    REGISTER #(
        .BW                 (BW_IF)
    ) u_REG_IF_ID (
        .clk                (clk),
        .rst                (rst),
        .stall              (freeze_front),
        .flush              (flush),
        .data_in            (bunch_IF),
        .data_out           (bunch_IF_r)
    );

    DECODER u_DECODER_x (
        .inst               (inst_x_r),
        .Ra                 (Ra_x),
        .Rb                 (Rb_x),
        .Rw                 (Rw_x),
        .valid_pc           (valid_pc_r),
        .valid_add          (valid_add_x),
        .valid_mul          (valid_mul_x)
    );

    DECODER u_DECODER_y (
        .inst               (inst_y_r),
        .Ra                 (Ra_y),
        .Rb                 (Rb_y),
        .Rw                 (Rw_y),
        .valid_pc           (valid_pc_r),
        .valid_add          (valid_add_y),
        .valid_mul          (valid_mul_y)
    );

    DECODER u_DECODER_z (
        .inst               (inst_z_r),
        .Ra                 (Ra_z),
        .Rb                 (Rb_z),
        .Rw                 (Rw_z),
        .valid_pc           (valid_pc_r),
        .valid_add          (valid_add_z),
        .valid_mul          (valid_mul_z)
    );

    REGISTER #(
        .BW                 (BW_ID)
    ) u_REG_ID_RENAME (
        .clk                (clk),
        .rst                (rst),
        .stall              (freeze_front),
        .flush              (flush),
        .data_in            (bunch_ID),
        .data_out           (bunch_ID_r)
    );

    SRAT u_SRAT (
        .clk                (clk),
        .rst                (rst),
        .freeze_front       (freeze_front),
        .full_PRF           (full_PRF),
        // 端口 x 读写
        .valid_issue_x      (valid_issue_x),
        .Ra_x               (Ra_x_r),
        .Rb_x               (Rb_x_r),
        .Rw_x               (Rw_x_r),
        .Pw_x               (Pw_x),
        .Pa_x               (Pa_x),
        .Pb_x               (Pb_x),
        .Pw_old_x           (Pw_old_x),
        .valid_Ra_x         (valid_Ra_x),
        .valid_Rb_x         (valid_Rb_x),
        // 端口 y 读写
        .valid_issue_y      (valid_issue_y),
        .Ra_y               (Ra_y_r),
        .Rb_y               (Rb_y_r),
        .Rw_y               (Rw_y_r),
        .Pw_y               (Pw_y),
        .Pa_y               (Pa_y),
        .Pb_y               (Pb_y),
        .Pw_old_y           (Pw_old_y),
        .valid_Ra_y         (valid_Ra_y),
        .valid_Rb_y         (valid_Rb_y),
        // 端口 z 读写
        .valid_issue_z      (valid_issue_z),
        .Ra_z               (Ra_z_r),
        .Rb_z               (Rb_z_r),
        .Rw_z               (Rw_z_r),
        .Pw_z               (Pw_z),
        .Pa_z               (Pa_z),
        .Pb_z               (Pb_z),
        .Pw_old_z           (Pw_old_z),
        .valid_Ra_z         (valid_Ra_z),
        .valid_Rb_z         (valid_Rb_z),
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
        // 精确异常恢复
        .flush              (flush),
        .ARAT_P_list        (ARAT_P_list)
    );

    RS u_RS_ADD (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .full_RS            (full_RS_add),
        // 端口 x 写入
        .Pa_x               (Pa_x),
        .Pb_x               (Pb_x),
        .Pw_x               (Pw_x),
        .valid_issue_x      (valid_issue_x),
        .valid_op_x         (valid_add_x_r),
        .valid_Ra_x         (valid_Ra_x),
        .valid_Rb_x         (valid_Rb_x),
        .tag_ROB_x          (tag_ROB_x),
        // 端口 y 写入
        .Pa_y               (Pa_y),
        .Pb_y               (Pb_y),
        .Pw_y               (Pw_y),
        .valid_issue_y      (valid_issue_y),
        .valid_op_y         (valid_add_y_r),
        .valid_Ra_y         (valid_Ra_y),
        .valid_Rb_y         (valid_Rb_y),
        .tag_ROB_y          (tag_ROB_y),
        // 端口 z 写入
        .Pa_z               (Pa_z),
        .Pb_z               (Pb_z),
        .Pw_z               (Pw_z),
        .valid_issue_z      (valid_issue_z),
        .valid_op_z         (valid_add_z_r),
        .valid_Ra_z         (valid_Ra_z),
        .valid_Rb_z         (valid_Rb_z),
        .tag_ROB_z          (tag_ROB_z),
        // 唤醒后发射
        .Pa_awake           (Pa_add_awake),
        .Pb_awake           (Pb_add_awake),
        .Pw_awake           (Pw_add_awake),
        .valid_op_awake     (valid_add_awake),
        .tag_ROB_awake      (tag_ROB_add_awake),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul)
    );

    RS u_RS_MUL (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .full_RS            (full_RS_mul),
        // 端口 x 写入
        .Pa_x               (Pa_x),
        .Pb_x               (Pb_x),
        .Pw_x               (Pw_x),
        .valid_issue_x      (valid_issue_x),
        .valid_op_x         (valid_mul_x_r),
        .valid_Ra_x         (valid_Ra_x),
        .valid_Rb_x         (valid_Rb_x),
        .tag_ROB_x          (tag_ROB_x),
        // 端口 y 写入
        .Pa_y               (Pa_y),
        .Pb_y               (Pb_y),
        .Pw_y               (Pw_y),
        .valid_issue_y      (valid_issue_y),
        .valid_op_y         (valid_mul_y_r),
        .valid_Ra_y         (valid_Ra_y),
        .valid_Rb_y         (valid_Rb_y),
        .tag_ROB_y          (tag_ROB_y),
        // 端口 z 写入
        .Pa_z               (Pa_z),
        .Pb_z               (Pb_z),
        .Pw_z               (Pw_z),
        .valid_issue_z      (valid_issue_z),
        .valid_op_z         (valid_mul_z_r),
        .valid_Ra_z         (valid_Ra_z),
        .valid_Rb_z         (valid_Rb_z),
        .tag_ROB_z          (tag_ROB_z),
        // 唤醒后发射
        .Pa_awake           (Pa_mul_awake),
        .Pb_awake           (Pb_mul_awake),
        .Pw_awake           (Pw_mul_awake),
        .valid_op_awake     (valid_mul_awake),
        .tag_ROB_awake      (tag_ROB_mul_awake),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul)
    );

endmodule