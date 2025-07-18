module BPU (
    input               clk,
    input               rst,
    input               stall_bpu,
    // 分支预测查查表
    input   [31 : 0]    pc                      [2 : 0],
    output  [31 : 0]    target_predict          [2 : 0],
    output  [31 : 0]    target_unsel            [2 : 0],
    output              valid_predict           [2 : 0],
    output              Predict                 [2 : 0],
    output  [ 9 : 0]    index                   [2 : 0],
    // 解码得分支, 写入
    input   [31 : 0]    pc_decoder              [2 : 0],
    input               isBranch_decoder        [2 : 0],
    // ROB 退休更新 PHT
    input   [ 9 : 0]    index_rob               [4 : 0],
    input               Branch_rob              [4 : 0]
);

endmodule