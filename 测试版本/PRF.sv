module PRF (
    input               clk,
    input               rst,
    input               stop,
    input               valid_issue_reg,
    output              full_PRF,
    output  [3 : 0]     tag_PRF,

    input   [3 : 0]     tag_Ra_add,
    input   [3 : 0]     tag_Rb_add,
    input   [3 : 0]     tag_Ra_mul,
    input   [3 : 0]     tag_Rb_mul,

    output  [15 : 0]    busA_add,
    output  [15 : 0]    busB_add,
    output  [15 : 0]    busA_mul,
    output  [15 : 0]    busB_mul,

    input               valid_Result_add,
    input   [15 : 0]    Result_add,
    input   [3 : 0]     tag_PRF_add,
    input               valid_Result_mul,
    input   [15 : 0]    Result_mul,
    input   [3 : 0]     tag_PRF_mul,

    input   [3 : 0]     ARF_tag [7 : 0],
    input               RegWr_ARF,
    input   [3 : 0]     tag_PRF_ARF,
    input   [3 : 0]     tag_Rw_old
);

    reg     [15 : 0]    data [15 : 0];
    reg     [15 : 0]    free_list;

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                data[i] <= i;
            end
            free_list <= 16'hff00;
        end
        else if (!stop) begin
            if (valid_issue_reg) begin
                free_list[tag_PRF] <= 0;
            end
            if (valid_Result_add && tag_PRF_add != 0) begin
                data[tag_PRF_add] <= Result_add;
            end
            if (valid_Result_mul && tag_PRF_mul != 0) begin
                data[tag_PRF_mul] <= Result_mul;
            end
            if (RegWr_ARF && tag_PRF_ARF != 0) begin
                free_list[tag_Rw_old] <= 1;
            end
        end
        else begin
            free_list <= 16'hffff;
            for (i = 0; i < 8; i = i + 1) begin
                free_list[ARF_tag[i]] <= 0;
            end
        end
    end

    assign  tag_PRF = (free_list[0] == 1)? 0 : (free_list[1] == 1)? 1 : (free_list[2] == 1)? 2 : (free_list[3] == 1)? 3 :
                      (free_list[4] == 1)? 4 : (free_list[5] == 1)? 5 : (free_list[6] == 1)? 6 : (free_list[7] == 1)? 7 :
                      (free_list[8] == 1)? 8 : (free_list[9] == 1)? 9 : (free_list[10] == 1)? 10 : (free_list[11] == 1)? 11 :
                      (free_list[12] == 1)? 12 : (free_list[13] == 1)? 13 : (free_list[14] == 1)? 14 : (free_list[15] == 1)? 15 : 0;

    assign  full_PRF = (free_list == 16'h0000)? 1 : 0;
    
    assign  busA_add = data[tag_Ra_add];
    assign  busB_add = data[tag_Rb_add];
    assign  busA_mul = data[tag_Ra_mul];
    assign  busB_mul = data[tag_Rb_mul];

endmodule