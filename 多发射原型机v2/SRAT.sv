module SRAT (
    input               clk,
    input               rst,
    input               freeze_front,
    // 端口 x 读写
    input               valid_issue_x,
    input   [2 : 0]     Ra_x,
    input   [2 : 0]     Rb_x,
    input   [2 : 0]     Rw_x,
    output  [4 : 0]     Pw_x,
    output  [4 : 0]     Pa_x,
    output  [4 : 0]     Pb_x,
    output  [4 : 0]     Pw_old_x,
    output              valid_Ra_x,
    output              valid_Rb_x,
    // 端口 y 读写
    input               valid_issue_y,
    input   [2 : 0]     Ra_y,
    input   [2 : 0]     Rb_y,
    input   [2 : 0]     Rw_y,
    output  [4 : 0]     Pw_y,
    output  [4 : 0]     Pa_y,
    output  [4 : 0]     Pb_y,
    output  [4 : 0]     Pw_old_y,
    output              valid_Ra_y,
    output              valid_Rb_y,
    // 端口 z 读写
    input               valid_issue_z,
    input   [2 : 0]     Ra_z,
    input   [2 : 0]     Rb_z,
    input   [2 : 0]     Rw_z,
    output  [4 : 0]     Pw_z,
    output  [4 : 0]     Pa_z,
    output  [4 : 0]     Pb_z,
    output  [4 : 0]     Pw_old_z,
    output              valid_Ra_z,
    output              valid_Rb_z,
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
    input   [4 : 0]     Pw_old_ROB_x,
    input   [4 : 0]     Pw_old_ROB_y,
    input   [4 : 0]     Pw_old_ROB_z,
    // 精确异常恢复
    input               flush,
    input   [4 : 0]     ARAT_P_list [7 : 0]
);

endmodule