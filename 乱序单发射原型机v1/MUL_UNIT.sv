module MUL_UNIT (
    input                   clk,
    input                   rst,
    input       [15 : 0]    busA,
    input       [15 : 0]    busB,
    input                   valid_mul,
    input       [4 : 0]     tag_PRF_mul,
    input       [3 : 0]     tag_ROB_mul,

    output  reg [15 : 0]    Result_mul,
    output  reg [4 : 0]     tag_PRF_mul_reg,
    output  reg [3 : 0]     tag_ROB_mul_reg,
    output  reg             valid_Result_mul,

    input                   freeze_back
);

    reg     [15 : 0]    Result_temp;
    reg     [4 : 0]     tag_PRF_temp;
    reg     [3 : 0]     tag_ROB_temp;
    reg                 valid_Result_temp;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            Result_mul <= '0;
            tag_PRF_mul_reg <= '0;
            tag_ROB_mul_reg <= '0;
            valid_Result_mul <= 0;

            Result_temp <= '0;
            tag_PRF_temp <= '0;
            tag_ROB_temp <= '0;
            valid_Result_temp <= 0;
        end
        else begin
            if (freeze_back) begin
                Result_temp <= Result_temp;
                tag_PRF_temp <= tag_PRF_temp;
                tag_ROB_temp <= tag_ROB_temp;
                valid_Result_temp <= valid_Result_temp;

                Result_mul <= Result_mul;
                tag_PRF_mul_reg <= tag_PRF_mul_reg;
                tag_ROB_mul_reg <= tag_ROB_mul_reg;
                valid_Result_mul <= valid_Result_mul;
            end
            else begin
                Result_temp <= busA * busB;
                tag_PRF_temp <= tag_PRF_mul;
                tag_ROB_temp <= tag_ROB_mul;
                valid_Result_temp <= valid_mul;

                Result_mul <= Result_temp;
                tag_PRF_mul_reg <= tag_PRF_temp;
                tag_ROB_mul_reg <= tag_ROB_temp;
                valid_Result_mul <= valid_Result_temp;
            end
        end
    end

endmodule