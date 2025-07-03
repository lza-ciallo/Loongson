module ROB (
    input               clk,
    input               rst,
    input               flush,
    output              full_ROB,
    // 预分配条目
    output  [3 : 0]     tag_ROB_x,
    output  [3 : 0]     tag_ROB_y,
    output  [3 : 0]     tag_ROB_z,
    // 预写入覆盖的 Pw_old
    input               freeze_front,
    input               valid_issue_x,
    input               valid_issue_y,
    input               valid_issue_z,
    input   [4 : 0]     Pw_old_x,
    input   [4 : 0]     Pw_old_y,
    input   [4 : 0]     Pw_old_z,
    // 写入执行结果
    input               valid_Result_add,
    input   [4 : 0]     Pw_Result_add,
    input   [15 : 0]    Result_add,
    input               exp_add,
    input   [3 : 0]     tag_ROB_Result_add,
    input               valid_Result_mul,
    input   [4 : 0]     Pw_Result_mul,
    input   [15 : 0]    Result_mul,
    input               exp_mul,
    input   [3 : 0]     tag_ROB_Result_mul,
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
    output  [4 : 0]     Pw_commit_x,
    output  [4 : 0]     Pw_commit_y,
    output  [4 : 0]     Pw_commit_z
);

endmodule