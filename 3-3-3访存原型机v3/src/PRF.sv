module PRF (
    input               clk,
    input               rst,
    // ADD 读出
    input   [ 4 : 0]    Pa_add,
    input   [ 4 : 0]    Pb_add,
    output  [15 : 0]    busA_add,
    output  [15 : 0]    busB_add,
    // MUL 读出
    input   [ 4 : 0]    Pa_mul,
    input   [ 4 : 0]    Pb_mul,
    output  [15 : 0]    busA_mul,
    output  [15 : 0]    busB_mul,
    // AGU 读出
    input   [ 4 : 0]    Pa_agu,
    output  [15 : 0]    busA_agu,
    // LS 读出
    input   [ 4 : 0]    Px,
    output  [15 : 0]    busX,
    // 广播写入
    input   [ 4 : 0]    Pw_Result_add,
    input   [15 : 0]    Result_add,
    input               valid_Result_add,
    input   [ 4 : 0]    Pw_Result_mul,
    input   [15 : 0]    Result_mul,
    input               valid_Result_mul,
    input   [ 4 : 0]    Pw_Result_ls,
    input   [15 : 0]    Result_ls,
    input               valid_Result_ls,
    input               mode_ls
);

    reg     [15 : 0]    data    [31 : 0];

    integer i;

    // 组合逻辑读出
    assign  busA_add    =   data[Pa_add];
    assign  busB_add    =   data[Pb_add];
    assign  busA_mul    =   data[Pa_mul];
    assign  busB_mul    =   data[Pb_mul];
    assign  busA_agu    =   data[Pa_agu];
    assign  busX        =   data[Px];

    // 时序逻辑写入
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                data[i] <= i;
            end
        end
        else begin
            if (valid_Result_add && Pw_Result_add != 0) begin
                data[Pw_Result_add] <= Result_add;
            end
            if (valid_Result_mul && Pw_Result_mul != 0) begin
                data[Pw_Result_mul] <= Result_mul;
            end
            if (valid_Result_ls && mode_ls == 1 && Pw_Result_ls != 0) begin
                data[Pw_Result_ls] <= Result_ls;
            end
        end
    end

endmodule