module PRF (
    input               clk,
    input               rst,
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

    reg     [15 : 0]    data [31 : 0];

    integer i;

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
        end
    end

    assign  busA_add = data[Pa_add];
    assign  busB_add = data[Pb_add];
    assign  busA_mul = data[Pa_mul];
    assign  busB_mul = data[Pb_mul];

endmodule