module ARAT (
    input               clk,
    input               rst,

    input               ready_rob       [4 : 0],
    input               RegWr_rob       [4 : 0],
    input   [ 4 : 0]    Rd_rob          [4 : 0],
    input   [ 5 : 0]    Pd_rob          [4 : 0],
    input   [ 5 : 0]    Pd_old_rob      [4 : 0],

    output  [ 5 : 0]    P_list_arat     [31: 0],
    output  [63 : 0]    free_list_arat
);

    reg     [ 5 : 0]    P_list_arat_r   [31: 0];
    reg     [63 : 0]    free_list_arat_r;

    // 分支预测失败可能并非第一条指令, 其前面几条指令来不及写入 aRAT 就要传给 sRAT, 故旁路

    wire    [ 5 : 0]    Pd_bypass       [31: 0];
    generate
        for (genvar i = 0; i < 32; i = i + 1) begin
            assign Pd_bypass[i] =   (ready_rob[4] && RegWr_rob[4] && Rd_rob[4] == i && Rd_rob[4] != 0) ? Pd_rob[4] :
                                    (ready_rob[3] && RegWr_rob[3] && Rd_rob[3] == i && Rd_rob[3] != 0) ? Pd_rob[3] :
                                    (ready_rob[2] && RegWr_rob[2] && Rd_rob[2] == i && Rd_rob[2] != 0) ? Pd_rob[2] :
                                    (ready_rob[1] && RegWr_rob[1] && Rd_rob[1] == i && Rd_rob[1] != 0) ? Pd_rob[1] :
                                    (ready_rob[0] && RegWr_rob[0] && Rd_rob[0] == i && Rd_rob[0] != 0) ? Pd_rob[0] : P_list_arat_r[i];
            assign P_list_arat[i] = Pd_bypass[i];
        end
    endgenerate

    wire                bypass_set      [63: 0];
    wire                bypass_clr      [63: 0];
    generate
        for (genvar i = 0; i < 64; i = i + 1) begin
            assign bypass_set[i] = ((ready_rob[4] && RegWr_rob[4] && Pd_old_rob[4] == i && Pd_old_rob[4] != 0) ||
                                    (ready_rob[3] && RegWr_rob[3] && Pd_old_rob[3] == i && Pd_old_rob[3] != 0) ||
                                    (ready_rob[2] && RegWr_rob[2] && Pd_old_rob[2] == i && Pd_old_rob[2] != 0) ||
                                    (ready_rob[1] && RegWr_rob[1] && Pd_old_rob[1] == i && Pd_old_rob[1] != 0) ||
                                    (ready_rob[0] && RegWr_rob[0] && Pd_old_rob[0] == i && Pd_old_rob[0] != 0));
            assign bypass_clr[i] = ((ready_rob[4] && RegWr_rob[4] && Pd_rob[4] == i && Pd_rob[4] != 0) ||
                                    (ready_rob[3] && RegWr_rob[3] && Pd_rob[3] == i && Pd_rob[3] != 0) ||
                                    (ready_rob[2] && RegWr_rob[2] && Pd_rob[2] == i && Pd_rob[2] != 0) ||
                                    (ready_rob[1] && RegWr_rob[1] && Pd_rob[1] == i && Pd_rob[1] != 0) ||
                                    (ready_rob[0] && RegWr_rob[0] && Pd_rob[0] == i && Pd_rob[0] != 0));
            assign free_list_arat[i] = bypass_set[i] ? 1'b1 : bypass_clr[i] ? 1'b0 : free_list_arat_r[i];
        end
    endgenerate

    // assign  P_list_arat     =   P_list_arat_r;
    // assign  free_list_arat  =   free_list_arat_r;

    // 疑似存在重复写入的不可综合的问题, 加入优先级检查, 类似旁路逻辑

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 32; i = i + 1) begin
                P_list_arat_r[i]    <=  i;
            end
            free_list_arat_r        <=  64'hffff_ffff_0000_0000;
        end
        else begin
            for (integer i = 1; i < 32; i = i + 1) begin
                P_list_arat_r[i]    <=  (ready_rob[4] && RegWr_rob[4] && Rd_rob[4] == i) ? Pd_rob[4] :
                                        (ready_rob[3] && RegWr_rob[3] && Rd_rob[3] == i) ? Pd_rob[3] :
                                        (ready_rob[2] && RegWr_rob[2] && Rd_rob[2] == i) ? Pd_rob[2] :
                                        (ready_rob[1] && RegWr_rob[1] && Rd_rob[1] == i) ? Pd_rob[1] :
                                        (ready_rob[0] && RegWr_rob[0] && Rd_rob[0] == i) ? Pd_rob[0] : P_list_arat_r[i];
            end
            for (integer i = 0; i < 5; i = i + 1) begin
                if (ready_rob[i] && RegWr_rob[i] && Rd_rob[i] != 0) begin
                    free_list_arat_r[Pd_old_rob[i]]   <=  1;
                    free_list_arat_r[Pd_rob[i]]       <=  0;
                end
            end
        end
    end

endmodule