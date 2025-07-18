    module MUL_UNIT (
    input                   clk,
    input                   rst,
    input                   flush,
    input                   freeze_back,
    // 输入
    input                   valid_mul,
    input       [ 4 : 0]    Pw_mul,
    input       [ 4 : 0]    tag_ROB_mul,
    input       [15 : 0]    busA_mul,
    input       [15 : 0]    busB_mul,
    // 输出
    output  reg             valid_Result_mul,
    output  reg [ 4 : 0]    Pw_Result_mul,
    output  reg [ 4 : 0]    tag_ROB_Result_mul,
    output  reg [15 : 0]    Result_mul
);

    reg                 valid_mul_temp;
    reg     [ 4 : 0]    Pw_mul_temp;
    reg     [ 4 : 0]    tag_ROB_mul_temp;
    reg     [15 : 0]    Result_mul_temp;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_Result_mul        <=  '0;
            Pw_Result_mul           <=  '0;
            tag_ROB_Result_mul      <=  '0;
            Result_mul              <=  '0;

            valid_mul_temp          <=  '0;
            Pw_mul_temp             <=  '0;
            tag_ROB_mul_temp        <=  '0;
            Result_mul_temp         <=  '0;
        end
        else begin
            if (flush) begin
                valid_Result_mul    <=  '0;
                Pw_Result_mul       <=  '0;
                tag_ROB_Result_mul  <=  '0;
                Result_mul          <=  '0;

                valid_mul_temp      <=  '0;
                Pw_mul_temp         <=  '0;
                tag_ROB_mul_temp    <=  '0;
                Result_mul_temp     <=  '0;
            end
            else if (freeze_back) begin
                valid_Result_mul    <=  valid_Result_mul;
                Pw_Result_mul       <=  Pw_Result_mul;
                tag_ROB_Result_mul  <=  tag_ROB_Result_mul;
                Result_mul          <=  Result_mul;

                valid_mul_temp      <=  valid_mul_temp;
                Pw_mul_temp         <=  Pw_mul_temp;
                tag_ROB_mul_temp    <=  tag_ROB_mul_temp;
                Result_mul_temp     <=  Result_mul_temp;
            end
            else begin
                valid_Result_mul    <=  valid_mul_temp;
                Pw_Result_mul       <=  Pw_mul_temp;
                tag_ROB_Result_mul  <=  tag_ROB_mul_temp;
                Result_mul          <=  Result_mul_temp;

                valid_mul_temp      <=  valid_mul;
                Pw_mul_temp         <=  Pw_mul;
                tag_ROB_mul_temp    <=  tag_ROB_mul;
                Result_mul_temp     <=  busA_mul * busB_mul;
            end
        end
    end
endmodule