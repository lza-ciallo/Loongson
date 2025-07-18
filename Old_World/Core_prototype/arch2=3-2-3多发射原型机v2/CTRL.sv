module CTRL (
    input           clk,
    input           rst,
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
    input           RegWr_x,
    input           RegWr_y,
    input           RegWr_z,
    input           exp_x,
    input           exp_y,
    input           exp_z,
    // 输出控制信号
    output          valid_issue_x,
    output          valid_issue_y,
    output          valid_issue_z,
    output          freeze_front,
    output          freeze_back,
    output  reg     flush
);

    assign  valid_issue_x = (valid_pc_r_r && (valid_add_x_r || valid_mul_x_r))? 1 : 0;
    assign  valid_issue_y = (valid_pc_r_r && (valid_add_y_r || valid_mul_y_r))? 1 : 0;
    assign  valid_issue_z = (valid_pc_r_r && (valid_add_z_r || valid_mul_z_r))? 1 : 0;

    assign  flush_wire = (RegWr_x & exp_x) | (RegWr_y & exp_y) | (RegWr_z & exp_z);
    assign  freeze_back = 0;
    assign  freeze_front = (full_PRF || full_ROB || full_RS_add || full_RS_mul)? 1 : 0;

    always @(posedge clk) begin
        flush <= flush_wire;
    end

endmodule