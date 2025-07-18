module ADD_UNIT (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_back,
    // 输入
    input               valid_add,
    input       [4 : 0] Pw_add,
    input       [15 : 0]busA_add,
    input       [15 : 0]busB_add,
    input       [4 : 0] tag_ROB_add,
    // 输出
    output  reg         valid_Result_add,
    output  reg [4 : 0] Pw_Result_add,
    output  reg [15 : 0]Result_add,
    output  reg         exp_add,
    output  reg [4 : 0] tag_ROB_Result_add
);

    always @(posedge clk or negedge rst) begin
        if (!rst || flush) begin
            valid_Result_add <= '0;
            Pw_Result_add <= '0;
            Result_add <= '0;
            exp_add <= '0;
            tag_ROB_Result_add <= '0;
        end
        else begin
            if (freeze_back) begin
                valid_Result_add <= valid_Result_add;
                Pw_Result_add <= Pw_Result_add;
                Result_add <= Result_add;
                exp_add <= exp_add;
                tag_ROB_Result_add <= tag_ROB_Result_add;
            end
            else begin
                valid_Result_add <= valid_add;
                Pw_Result_add <= Pw_add;
                Result_add <= busA_add + busB_add;
                exp_add <= (valid_add && Pw_add == 0)? 1 : 0;
                tag_ROB_Result_add <= tag_ROB_add;
            end
        end
    end

endmodule