module RAT (
    input               clk,
    input               rst,
    input               stop,
    // ID 阶段, Ra, Rb 信息复制给 RS, 同时置 Rw 为等待状态
    input   [2 : 0]     Ra,
    input   [2 : 0]     Rb,
    input   [2 : 0]     Rw,
    input   [4 : 0]     tag_PRF,
    input               freeze_front,
    input               valid_issue,
    output              valid_Ra,
    output  [4 : 0]     tag_Ra,
    output              valid_Rb,
    output  [4 : 0]     tag_Rb,
    // 接收广播信号
    input               valid_Result_add,
    input   [4 : 0]     tag_PRF_add,
    input               valid_Result_mul,
    input   [4 : 0]     tag_PRF_mul,
    // stop 后复制 ARF
    input   [4 : 0]     ARF_tag [7 : 0],
    output  [4 : 0]     tag_Rw_old
);

    reg     [7 : 0]     valid_reg;
    reg     [4 : 0]     tag_reg [7 : 0];

    assign  valid_Ra = valid_reg[Ra];
    assign  tag_Ra = tag_reg[Ra];
    assign  valid_Rb = valid_reg[Rb];
    assign  tag_Rb = tag_reg[Rb];

    assign  tag_Rw_old = tag_reg[Rw];

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                valid_reg[i] <= 1;
                tag_reg[i] <= i;
            end
        end

        else if (!stop) begin
            if (valid_issue && !freeze_front && Rw != 0) begin
                valid_reg[Rw] <= 0;
                tag_reg[Rw] <= tag_PRF;
            end


            //监听CDB
            if (valid_Result_add) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (i != Rw || freeze_front || !valid_issue) begin
                        //重命名操作的优先级更高，如果 i == Rw 并且正在进行有效的重命名，那么即使CDB广播了 Rw 的旧标签，valid_reg[Rw]也应该保持为0，等待新指令的计算结果。
                        if (tag_reg[i] == tag_PRF_add && !valid_reg[i]) begin
                        //RAT中的某个条目 i 的标签与广播的标签匹配，并且该条目当前是无效状态（意味着它正在等待这个结果）
                            valid_reg[i] <= 1;
                        end
                    end
                end
            end
            if (valid_Result_mul) begin
                for (i = 0; i < 8; i = i + 1) begin
                    if (i != Rw || freeze_front || !valid_issue) begin
                        if (tag_reg[i] == tag_PRF_mul && !valid_reg[i]) begin
                            valid_reg[i] <= 1;
                        end
                    end
                end
            end
        end

        else begin
            tag_reg <= ARF_tag;
            valid_reg <= '0;
        end
    end

endmodule