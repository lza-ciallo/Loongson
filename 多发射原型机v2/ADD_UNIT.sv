module ADD_UNIT (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_back,
    // 输入
    input               valid_add,
    input   [4 : 0]     Pw_add,
    input   [15 : 0]    busA_add,
    input   [15 : 0]    busB_add,
    input   [3 : 0]     tag_ROB_add,
    // 输出
    output              valid_Result_add,
    output  [4 : 0]     Pw_Result_add,
    output  [15 : 0]    Result_add,
    output              exp_add,
    output  [3 : 0]     tag_ROB_Result_add
);

endmodule