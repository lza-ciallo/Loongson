module ADD_UNIT (
    input                   clk,
    input                   rst,
    input       [15 : 0]    busA,
    input       [15 : 0]    busB,
    input                   valid_add,
    input       [3 : 0]     tag_PRF_add,
    input       [3 : 0]     tag_ROB_add,

    output  reg [15 : 0]    Result_add,
    output  reg [3 : 0]     tag_PRF_add_reg,
    output  reg [3 : 0]     tag_ROB_add_reg,
    output  reg             valid_Result_add
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            Result_add <= '0;
            tag_PRF_add_reg <= '0;
            tag_ROB_add_reg <= '0;
            valid_Result_add <= 0;
        end
        else begin
            Result_add <= busA + busB;
            tag_PRF_add_reg <= tag_PRF_add;
            tag_ROB_add_reg <= tag_ROB_add;
            valid_Result_add <= valid_add;
        end
    end

endmodule