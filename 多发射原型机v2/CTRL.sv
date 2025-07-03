module CTRL (
    // 指令有效性
    input           valid_pc_r_r,
    input           valid_add_x_r,
    input           valid_mul_x_r,
    input           valid_add_y_r,
    input           valid_mul_y_r,
    input           valid_add_z_r,
    input           valid_mul_z_r,
    // 存储区域满
    input           full_RS_add,
    input           full_RS_mul,
    input           full_PRF,
    input           full_ROB,
    // 异常中断
    input           exp_x,
    input           exp_y,
    input           exp_z,
    // 输出控制信号
    output          valid_issue_x,
    output          valid_issue_y,
    output          valid_issue_z,
    output          freeze_front,
    output          freeze_back,
    output          flush
);

endmodule