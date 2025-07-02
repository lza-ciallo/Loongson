module PRF (
    input               clk,
    input               rst,
    output              full_PRF,
    // ADD 读出
    input   [4 : 0]     Pa_add,
    input   [4 : 0]     Pb_add,
    output  [15 : 0]    busA_add,
    output  [15 : 0]    busB_add,
    // MUL 读出
    input   [4 : 0]     Pa_mul,
    input   [4 : 0]     Pb_mul,
    output  [15 : 0]    busA_mul,
    output  [15 : 0]    busB_mul,
    // 广播写入
    input               valid_Result_add,
    input               valid_Result_mul,
    input   [4 : 0]     Pw_Result_add,
    input   [4 : 0]     Pw_Result_mul,
    input   [15 : 0]    Result_add,
    input   [15 : 0]    Result_mul
);

endmodule