module RS (
    input                   clk,
    input                   rst,
    input                   stop,
    output  reg             full,
    // ID 时, Ra, Rb, 信息写入 RS
    input                   freeze_front,
    input                   freeze_back,
    input                   valid_issue,
    input                   valid_opcode,
    input       [4 : 0]     tag_PRF,
    input       [3 : 0]     tag_ROB,
    input                   valid_Ra,
    input       [4 : 0]     tag_Ra,
    input                   valid_Rb,
    input       [4 : 0]     tag_Rb,
    // 唤醒逻辑, 并retire
    output  reg             valid_opcode_awake,
    output  reg [4 : 0]     tag_PRF_awake,
    output  reg [3 : 0]     tag_ROB_awake,
    output  reg [4 : 0]     tag_Ra_awake,
    output  reg [4 : 0]     tag_Rb_awake,
    // 接受广播
    input                   valid_Result_add,
    input       [4 : 0]     tag_PRF_add,
    input                   valid_Result_mul,
    input       [4 : 0]     tag_PRF_mul
);

    reg         [3 : 0]     valid_opcode_reg;
    reg         [4 : 0]     tag_PRF_reg [3 : 0];
    reg         [3 : 0]     tag_ROB_reg [3 : 0];
    reg         [3 : 0]     valid_Ra_reg;
    reg         [4 : 0]     tag_Ra_reg [3 : 0];
    reg         [3 : 0]     valid_Rb_reg;
    reg         [4 : 0]     tag_Rb_reg [3 : 0];

    integer empty_rs;

    always @(*) begin
        empty_rs = (valid_opcode_reg[0] == 0)? 0 :
                   (valid_opcode_reg[1] == 0)? 1 :
                   (valid_opcode_reg[2] == 0)? 2 :
                   (valid_opcode_reg[3] == 0)? 3 : 4;
        full = (empty_rs == 4)? 1 : 0;
    end

    integer awake_rs;

    always @(*) begin
        awake_rs = (valid_opcode_reg[0] && valid_Ra_reg[0] && valid_Rb_reg[0])? 0 :
                   (valid_opcode_reg[1] && valid_Ra_reg[1] && valid_Rb_reg[1])? 1 :
                   (valid_opcode_reg[2] && valid_Ra_reg[2] && valid_Rb_reg[2])? 2 :
                   (valid_opcode_reg[3] && valid_Ra_reg[3] && valid_Rb_reg[3])? 3 : 4;
    end

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst || stop) begin
            for (i = 0; i < 4; i = i + 1) begin
                valid_opcode_reg[i] <= 0;
                tag_PRF_reg[i] <= '0;
                tag_ROB_reg[i] <= '0;
                valid_Ra_reg[i] <= 0;
                tag_Ra_reg[i] <= '0;
                valid_Rb_reg[i] <= 0;
                tag_Rb_reg[i] <= '0;
            end
            valid_opcode_awake <= 0;
            tag_PRF_awake <= '0;
            tag_ROB_awake <= '0;
            tag_Ra_awake <= '0;
            tag_Rb_awake <= '0;
        end

        else begin
            if (!freeze_front && valid_issue) begin
                valid_opcode_reg[empty_rs] <= valid_opcode;
                tag_PRF_reg[empty_rs] <= tag_PRF;
                tag_ROB_reg[empty_rs] <= tag_ROB;
                //在将指令写入保留站的同一周期，如果正好有执行单元（加法器或乘法器）广播了这条指令所等待的结果，那么就不需要等待了，可以直接将操作数标记为就绪
                valid_Ra_reg[empty_rs] <= (valid_Ra == 0)? ((tag_Ra == tag_PRF_add && valid_Result_add)? 1 : ((tag_Ra == tag_PRF_mul && valid_Result_mul)? 1 : valid_Ra)): valid_Ra;
                tag_Ra_reg[empty_rs] <= (valid_Ra == 0)? ((tag_Ra == tag_PRF_add && valid_Result_add)? tag_PRF_add : ((tag_Ra == tag_PRF_mul && valid_Result_mul)? tag_PRF_mul : tag_Ra)): tag_Ra;
                valid_Rb_reg[empty_rs] <= (valid_Rb == 0)? ((tag_Rb == tag_PRF_add && valid_Result_add)? 1 : ((tag_Rb == tag_PRF_mul && valid_Result_mul)? 1 : valid_Rb)): valid_Rb;
                tag_Rb_reg[empty_rs] <= (valid_Rb == 0)? ((tag_Rb == tag_PRF_add && valid_Result_add)? tag_PRF_add : ((tag_Rb == tag_PRF_mul && valid_Result_mul)? tag_PRF_mul : tag_Rb)): tag_Rb;
            end

            if (awake_rs != 4 && !freeze_back) begin
                valid_opcode_awake <= valid_opcode_reg[awake_rs];
                tag_PRF_awake <= tag_PRF_reg[awake_rs];
                tag_ROB_awake <= tag_ROB_reg[awake_rs];
                tag_Ra_awake <= tag_Ra_reg[awake_rs];
                tag_Rb_awake <= tag_Rb_reg[awake_rs];
                //清空awake_rs所指向的槽位的所有寄存器,从保留站中移除了这条指令，使该槽位可以被后续的新指令使用
                valid_opcode_reg[awake_rs] <= 0;
                tag_PRF_reg[awake_rs] <= '0;
                tag_ROB_reg[awake_rs] <= '0;
                valid_Ra_reg[awake_rs] <= 0;
                tag_Ra_reg[awake_rs] <= '0;
                valid_Rb_reg[awake_rs] <= 0;
                tag_Rb_reg[awake_rs] <= '0;
            end
            else begin
                valid_opcode_awake <= 0;
                tag_PRF_awake <= '0;
                tag_ROB_awake <= '0;
                tag_Ra_awake <= '0;
                tag_Rb_awake <= '0;
            end
            //唤醒逻辑：该槽位是否有效+该槽位是否正在等待某个操作数+等待的操作数标签是否与当前广播的结果标签匹配
            if (valid_Result_add) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (tag_Ra_reg[i] == tag_PRF_add && valid_Ra_reg[i] == 0 && valid_opcode_reg[i] == 1) begin
                        valid_Ra_reg[i] <= 1;
                    end
                    if (tag_Rb_reg[i] == tag_PRF_add && valid_Rb_reg[i] == 0 && valid_opcode_reg[i] == 1) begin
                        valid_Rb_reg[i] <= 1;
                    end
                end
            end
            if (valid_Result_mul) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (tag_Ra_reg[i] == tag_PRF_mul && valid_Ra_reg[i] == 0 && valid_opcode_reg[i] == 1) begin
                        valid_Ra_reg[i] <= 1;
                    end
                    if (tag_Rb_reg[i] == tag_PRF_mul && valid_Rb_reg[i] == 0 && valid_opcode_reg[i] == 1) begin
                        valid_Rb_reg[i] <= 1;
                    end
                end
            end
        end
    end

endmodule