module ARAT (
    input               clk,
    input               rst,
    // ROB 端输入
    input               RegWr_x,
    input               RegWr_y,
    input               RegWr_z,
    input               exp_x,
    input               exp_y,
    input               exp_z,
    input       [4 : 0] Pw_commit_x,
    input       [4 : 0] Pw_commit_y,
    input       [4 : 0] Pw_commit_z,
    // 精确异常恢复
    output  reg [4 : 0] ARAT_P_list [7 : 0]
);

endmodule