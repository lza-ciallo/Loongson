module ADD_UNIT (
    input                   clk,
    input                   rst,
    input                   flush,
    input                   freeze_back,
    // 输入
    input                   valid_add,
    input       [ 4 : 0]    Pw_add,
    input       [ 4 : 0]    tag_ROB_add,
    input       [15 : 0]    busA_add,
    input       [15 : 0]    busB_add,
    // 输出
    output  reg             valid_Result_add,
    output  reg [ 4 : 0]    Pw_Result_add,
    output  reg [ 4 : 0]    tag_ROB_Result_add,
    output  reg [15 : 0]    Result_add
);

    always @(posedge clk or negedge rst) begin
        if (rst) begin
            valid_Result_add        <=  '0;
            Pw_Result_add           <=  '0;
            tag_ROB_Result_add      <=  '0;
            Result_add              <=  '0;
        end
        else begin
            if (flush) begin
                valid_Result_add    <=  '0;
                Pw_Result_add       <=  '0;
                tag_ROB_Result_add  <=  '0;
                Result_add          <=  '0;
            end
            else if (freeze_back) begin
                valid_Result_add    <=  valid_Result_add;
                Pw_Result_add       <=  Pw_Result_add;
                tag_ROB_Result_add  <=  tag_ROB_Result_add;
                Result_add          <=  Result_add;
            end
            else begin
                valid_Result_add    <=  valid_add;
                Pw_Result_add       <=  Pw_add;
                tag_ROB_Result_add  <=  tag_ROB_add;
                Result_add          <=  busA_add + busB_add;
            end
        end
    end

endmodule