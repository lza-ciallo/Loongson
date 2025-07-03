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
    input   [4 : 0]     tag_ROB_mul,
    // 输出
    output  reg         valid_Result_mul,
    output  reg [4 : 0] Pw_Result_mul,
    output  reg [15 : 0]Result_mul,
    output  reg         exp_mul,
    output  reg [4 : 0] tag_ROB_Result_mul
);

    reg                 valid_temp;
    reg     [4 : 0]     Pw_temp;
    reg     [15 : 0]    Result_temp;
    reg                 exp_temp;
    reg     [4 : 0]     tag_ROB_temp;

    always @(posedge clk or negedge rst) begin
        if (!rst || flush) begin
            valid_Result_mul <= '0;
            Pw_Result_mul <= '0;
            Result_mul <= '0;
            exp_mul <= '0;
            tag_ROB_Result_mul <= '0;

            valid_temp <= '0;
            Pw_temp <= '0;
            Result_temp <= '0;
            exp_temp <= '0;
            tag_ROB_temp <= '0;
        end
        else begin
            if (freeze_back) begin
            valid_Result_mul <= valid_Result_mul;
            Pw_Result_mul <= Pw_Result_mul;
            Result_mul <= Result_mul;
            exp_mul <= exp_mul;
            tag_ROB_Result_mul <= tag_ROB_Result_mul;

            valid_temp <= valid_temp;
            Pw_temp <= Pw_temp;
            Result_temp <= Result_temp;
            exp_temp <= exp_temp;
            tag_ROB_temp <= tag_ROB_temp;
            end
            else begin
            valid_Result_mul <= valid_temp;
            Pw_Result_mul <= Pw_temp;
            Result_mul <= Result_temp;
            exp_mul <= exp_temp;
            tag_ROB_Result_mul <= tag_ROB_temp;

            valid_temp <= valid_mul;
            Pw_temp <= Pw_mul;
            Result_temp <= busA_mul * busB_mul;
            exp_temp <= (valid_mul && Pw_mul == 0)? 1 : 0;
            tag_ROB_temp <= tag_ROB_mul;
            end
        end
    end

endmodule