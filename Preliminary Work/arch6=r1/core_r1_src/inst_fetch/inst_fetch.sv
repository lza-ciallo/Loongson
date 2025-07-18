module inst_fetch (
    input               clk,
    input               rst,
    // 来自 CTRL 的控制信号
    input               stall_pc,
    input               flush_pc,
    input               stall_bpu,
    input               stall_ifr,
    input               flush_ifr,
    input               flush_ififo,
    input               stall_ififo,
    output              full_ififo,
    output              isJump_pre,
    output              valid_predict_pre,
    // 读出数据
    output  [31 : 0]    pc_ififo            [2 : 0],
    output  [31 : 0]    inst_ififo          [2 : 0],
    output  [31 : 0]    target_unsel_ififo  [2 : 0],
    output  [ 9 : 0]    index_ififo         [2 : 0],
    output              Predict_ififo       [2 : 0]
    // decoder 写入分支地址
    input   [31 : 0]    pc_decoder          [2 : 0],
    input               isBranch_decoder    [2 : 0],
    // ROB 退休更新 PHT
    input   [ 9 : 0]    index_rob           [4 : 0],
    input               Branch_rob          [4 : 0],
    // ROB 退休预测失败恢复
    input   [31 : 0]    target_unsel_rob
);

    wire    [31 : 0]    pc                  [2 : 0];
    wire    [31 : 0]    pc_ifr              [2 : 0];
    wire    [31 : 0]    inst                [2 : 0];
    
    wire    [31 : 0]    target_predict_bpu  [2 : 0];
    wire    [31 : 0]    target_unsel_bpu    [2 : 0];
    wire                valid_predict_bpu   [2 : 0];
    wire                Predict_bpu         [2 : 0];
    wire    [ 9 : 0]    index_bpu           [2 : 0];

    wire                valid_inst_pre      [2 : 0];

    wire    [31 : 0]    target_jump_pre;
    wire    [31 : 0]    target_predict_pre;

    PC u_PC (
        .clk                    (clk),
        .rst                    (rst),
        .stall_pc               (stall_pc),
        // 输出三条连续的 pc
        .pc                     (pc)
        // 分支预测失败
        .flush_pc               (flush_pc),
        .target_unsel_rob       (target_unsel_rob),
        // 预解码得跳转
        .isJump_pre             (isJump_pre),
        .target_jump_pre        (target_jump_pre),
        // 分支预测
        .valid_predict_pre      (valid_predict_pre),
        .target_predict_pre     (target_predict_pre)
        // 暂时无法处理 JIRL
    );

    inst_mem u_inst_mem (
        .clk                    (clk),
        .pc                     (pc[0]),
        .inst                   (inst)
    );

    BPU u_BPU (
        .clk                    (clk),
        .rst                    (rst),
        .stall_bpu              (stall_bpu),
        // 分支预测查查表
        .pc                     (pc),
        .target_predict         (target_predict_bpu),
        .target_unsel           (target_unsel_bpu),
        .valid_predict          (valid_predict_bpu),
        .Predict                (Predict_bpu),
        .index                  (index_bpu),
        // 解码得分支, 写入
        .pc_decoder             (pc_decoder),
        .isBranch_decoder       (isBranch_decoder),
        // ROB 退休更新 PHT
        .index_rob              (index_rob),
        .Branch_rob             (Branch_rob)
    );

    if_reg u_if_reg (
        .clk                    (clk),
        .rst                    (rst),
        .stall_ifr              (stall_ifr),
        .flush_ifr              (flush_ifr),
        // 管理跳转后下一周期的指令是否有效
        .pc                     (pc),
        .pc_ifr                 (pc_ifr),
        .valid_inst             (valid_inst_ifr)
    );

    pre_decoder u_pre_decoder (
        .inst                   (inst),
        .pc_ifr                 (pc_ifr),
        .valid_inst_ifr         (valid_inst_ifr),
        // 输入 BPU 的三条结果, 转换为一条
        .target_predict_bpu     (target_predict_bpu),
        .valid_predict_bpu      (valid_predict_bpu),
        // 发射最优先的分支跳转
        .isJump                 (isJump_pre),
        .target_jump            (target_jump_pre),
        .valid_predict          (valid_predict_pre),
        .target_predict         (target_predict_pre),
        // 写入 inst_fifo 的指令有效位
        .valid_inst             (valid_inst_pre)
    );

    inst_fifo u_inst_fifo (
        .clk                    (clk),
        .rst                    (rst),
        .flush_ififo            (flush_ififo),
        .stall_ififo            (stall_ififo),
        .full_ififo             (full_ififo),
        // 写入数据
        .pc_ifr                 (pc_ifr),
        .inst                   (inst),
        .target_unsel_bpu       (target_unsel_bpu),
        .index_bpu              (index_bpu),
        .Predict_bpu            (Predict_bpu),
        // 控制写入几条
        .valid_inst_pre         (valid_inst_pre),
        // 读出数据
        .pc_ififo               (pc_ififo),
        .inst_ififo             (inst_ififo),
        .target_unsel_ififo     (target_unsel_ififo),
        .index_ififo            (index_ififo),
        .Predict_ififo          (Predict_ififo)
    );

endmodule