module PC (
    input               clk,
    input               rst,
    input               stall_pc,
    // 输出三条连续的 pc
    output  [31 : 0]    pc      [2 : 0],
    // 分支预测失败
    input               flush_pc,
    input   [31 : 0]    target_unsel_rob,
    // 预解码得跳转
    input               isJump_pre,
    input   [31 : 0]    target_jump_pre,
    // 分支预测
    input               valid_predict_pre,
    input   [31 : 0]    target_predict_pre
    // 暂时无法处理 JIRL
);

    reg     [31 : 0]    pc_r;

    assign  pc[0]   =   pc_r;
    assign  pc[1]   =   pc_r + 4;
    assign  pc[2]   =   pc_r + 8;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc_r        <=  '0;
        end
        else begin
            if (flush_pc) begin
                pc_r    <=  target_unsel_rob;
            end
            else if (stall_pc) begin
                pc_r    <=  pc_r;
            end
            else if (isJump_pre) begin
                pc_r    <=  target_jump_pre;
            end
            else if (valid_predict_pre) begin
                pc_r    <=  target_predict_pre;
            end
            else begin
                pc_r    <=  pc_r + 12;
            end
        end
    end

endmodule