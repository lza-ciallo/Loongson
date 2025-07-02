module RS (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    output              full_RS,
    // 端口 x 写入
    input   [4 : 0]     Pa_x,
    input   [4 : 0]     Pb_x,
    input   [4 : 0]     Pw_x,
    input               valid_issue_x,
    input               valid_op_x,
    input               valid_Ra_x,
    input               valid_Rb_x,
    input   [3 : 0]     tag_ROB_x,
    // 端口 y 写入
    input   [4 : 0]     Pa_y,
    input   [4 : 0]     Pb_y,
    input   [4 : 0]     Pw_y,
    input               valid_issue_y,
    input               valid_op_y,
    input               valid_Ra_y,
    input               valid_Rb_y,
    input   [3 : 0]     tag_ROB_y,
    // 端口 z 写入
    input   [4 : 0]     Pa_z,
    input   [4 : 0]     Pb_z,
    input   [4 : 0]     Pw_z,
    input               valid_issue_z,
    input               valid_op_z,
    input               valid_Ra_z,
    input               valid_Rb_z,
    input   [3 : 0]     tag_ROB_z,
    // 唤醒后发射
    output  [4 : 0]     Pa_awake,
    output  [4 : 0]     Pb_awake,
    output  [4 : 0]     Pw_awake,
    output              valid_op_awake,
    output  [3 : 0]     tag_ROB_awake,
    // ADD 广播
    input   [4 : 0]     Pw_Result_add,
    input               valid_Result_add,
    // MUL 广播
    input   [4 : 0]     Pw_Result_mul,
    input               valid_Result_mul
);

endmodule