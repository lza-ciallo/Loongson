module MUL_UNIT (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_back,
    // 输入
    input               valid_mul,
    input   [4 : 0]     Pw_mul,
    input   [15 : 0]    busA_mul,
    input   [15 : 0]    busB_mul,
    input   [3 : 0]     tag_ROB_mul,
    // 输出
    output              valid_Result_mul,
    output  [4 : 0]     Pw_Result_mul,
    output  [15 : 0]    Result_mul,
    output              exp_mul,
    output  [3 : 0]     tag_ROB_Result_mul
);

endmodule