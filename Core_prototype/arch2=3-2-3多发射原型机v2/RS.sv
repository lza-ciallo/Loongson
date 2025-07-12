module RS (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    output              full_RS,
    // 端口 x 写入
    input   [4 : 0]     Pa_x,
    input   [4 : 0]     Pb_x,
    input   [4 : 0]     Pw_x,
    input               valid_issue_x,
    input               valid_op_x,
    input               valid_Ra_x,
    input               valid_Rb_x,
    input   [4 : 0]     tag_ROB_x,
    // 端口 y 写入
    input   [4 : 0]     Pa_y,
    input   [4 : 0]     Pb_y,
    input   [4 : 0]     Pw_y,
    input               valid_issue_y,
    input               valid_op_y,
    input               valid_Ra_y,
    input               valid_Rb_y,
    input   [4 : 0]     tag_ROB_y,
    // 端口 z 写入
    input   [4 : 0]     Pa_z,
    input   [4 : 0]     Pb_z,
    input   [4 : 0]     Pw_z,
    input               valid_issue_z,
    input               valid_op_z,
    input               valid_Ra_z,
    input               valid_Rb_z,
    input   [4 : 0]     tag_ROB_z,
    // 唤醒后发射
    output  [4 : 0]     Pa_awake,
    output  [4 : 0]     Pb_awake,
    output  [4 : 0]     Pw_awake,
    output              valid_op_awake,
    output  [4 : 0]     tag_ROB_awake,
    // ADD 广播
    input   [4 : 0]     Pw_Result_add,
    input               valid_Result_add,
    // MUL 广播
    input   [4 : 0]     Pw_Result_mul,
    input               valid_Result_mul
);

    reg     [7 : 0]     valid_op_list;
    reg     [4 : 0]     Pw_list [7 : 0];
    reg     [4 : 0]     tag_ROB_list [7 : 0];
    reg     [7 : 0]     valid_Ra_list;
    reg     [7 : 0]     valid_Rb_list;
    reg     [4 : 0]     Pa_list [7 : 0];
    reg     [4 : 0]     Pb_list [7 : 0];

    wire    [7 : 0]     valid_op_list_y;
    wire    [7 : 0]     valid_op_list_z;

    assign  valid_op_list_y = valid_op_list | (1 << empty_rs_x);
    assign  valid_op_list_z = valid_op_list_y | (1 << empty_rs_y);

    assign  full_RS = (empty_rs_x == 8 || empty_rs_y == 8 || empty_rs_z == 8)? 1 : 0;

    integer empty_rs_x;
    integer empty_rs_y;
    integer empty_rs_z;

    always @(*) begin
        casez (valid_op_list)
            8'b????_???0:   empty_rs_x = 0;
            8'b????_??01:   empty_rs_x = 1;
            8'b????_?011:   empty_rs_x = 2;
            8'b????_0111:   empty_rs_x = 3;
            8'b???0_1111:   empty_rs_x = 4;
            8'b??01_1111:   empty_rs_x = 5;
            8'b?011_1111:   empty_rs_x = 6;
            8'b0111_1111:   empty_rs_x = 7;
            default:        empty_rs_x = 8;
        endcase

        casez (valid_op_list_y)
            8'b????_???0:   empty_rs_y = 0;
            8'b????_??01:   empty_rs_y = 1;
            8'b????_?011:   empty_rs_y = 2;
            8'b????_0111:   empty_rs_y = 3;
            8'b???0_1111:   empty_rs_y = 4;
            8'b??01_1111:   empty_rs_y = 5;
            8'b?011_1111:   empty_rs_y = 6;
            8'b0111_1111:   empty_rs_y = 7;
            default:        empty_rs_y = 8;
        endcase

        casez (valid_op_list_z)
            8'b????_???0:   empty_rs_z = 0;
            8'b????_??01:   empty_rs_z = 1;
            8'b????_?011:   empty_rs_z = 2;
            8'b????_0111:   empty_rs_z = 3;
            8'b???0_1111:   empty_rs_z = 4;
            8'b??01_1111:   empty_rs_z = 5;
            8'b?011_1111:   empty_rs_z = 6;
            8'b0111_1111:   empty_rs_z = 7;
            default:        empty_rs_z = 8;
        endcase
    end

    integer awake_rs;

    always @(*) begin
        casez (valid_op_list & valid_Ra_list & valid_Rb_list)
            8'b????_???1:   awake_rs = 0;
            8'b????_??10:   awake_rs = 1;
            8'b????_?100:   awake_rs = 2;
            8'b????_1000:   awake_rs = 3;
            8'b???1_0000:   awake_rs = 4;
            8'b??10_0000:   awake_rs = 5;
            8'b?100_0000:   awake_rs = 6;
            8'b1000_0000:   awake_rs = 7;
            default:        awake_rs = 8;
        endcase
    end

    reg     [4 : 0]     Pa_awake_r;
    reg     [4 : 0]     Pb_awake_r;
    reg     [4 : 0]     Pw_awake_r;
    reg                 valid_op_awake_r;
    reg     [4 : 0]     tag_ROB_awake_r;

    assign  Pa_awake = Pa_awake_r;
    assign  Pb_awake = Pb_awake_r;
    assign  Pw_awake = Pw_awake_r;
    assign  valid_op_awake = valid_op_awake_r;
    assign  tag_ROB_awake = tag_ROB_awake_r;

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_op_list <= '0;
            valid_Ra_list <= '0;
            valid_Rb_list <= '0;
            for (i = 0; i < 8; i = i + 1) begin
                Pw_list[i] <= '0;
                tag_ROB_list[i] <= '0;
                Pa_list[i] <= '0;
                Pb_list[i] <= '0;
            end
            Pa_awake_r <= '0;
            Pb_awake_r <= '0;
            Pw_awake_r <= '0;
            valid_op_awake_r <= '0;
            tag_ROB_awake_r <= '0;
        end
        else begin
            if (!flush) begin
                // 三端口分发写入
                if (!freeze_front) begin
                    if (valid_issue_x) begin
                        valid_op_list[empty_rs_x] <= valid_op_x;
                        Pw_list[empty_rs_x] <= Pw_x;
                        tag_ROB_list[empty_rs_x] <= tag_ROB_x;
                        Pa_list[empty_rs_x] <= Pa_x;
                        Pb_list[empty_rs_x] <= Pb_x;
                        valid_Ra_list[empty_rs_x] <= ((Pa_x == Pw_Result_add && valid_Result_add) ||
                            (Pa_x == Pw_Result_mul && valid_Result_mul))? 1 : valid_Ra_x;
                        valid_Rb_list[empty_rs_x] <= ((Pb_x == Pw_Result_add && valid_Result_add) ||
                            (Pb_x == Pw_Result_mul && valid_Result_mul))? 1 : valid_Rb_x;
                    end
                    if (valid_issue_y) begin
                        valid_op_list[empty_rs_y] <= valid_op_y;
                        Pw_list[empty_rs_y] <= Pw_y;
                        tag_ROB_list[empty_rs_y] <= tag_ROB_y;
                        Pa_list[empty_rs_y] <= Pa_y;
                        Pb_list[empty_rs_y] <= Pb_y;
                        valid_Ra_list[empty_rs_y] <= ((Pa_y == Pw_Result_add && valid_Result_add) ||
                            (Pa_y == Pw_Result_mul && valid_Result_mul))? 1 : valid_Ra_y;
                        valid_Rb_list[empty_rs_y] <= ((Pb_y == Pw_Result_add && valid_Result_add) ||
                            (Pb_y == Pw_Result_mul && valid_Result_mul))? 1 : valid_Rb_y;
                    end
                    if (valid_issue_z) begin
                        valid_op_list[empty_rs_z] <= valid_op_z;
                        Pw_list[empty_rs_z] <= Pw_z;
                        tag_ROB_list[empty_rs_z] <= tag_ROB_z;
                        Pa_list[empty_rs_z] <= Pa_z;
                        Pb_list[empty_rs_z] <= Pb_z;
                        valid_Ra_list[empty_rs_z] <= ((Pa_z == Pw_Result_add && valid_Result_add) ||
                            (Pa_z == Pw_Result_mul && valid_Result_mul))? 1 : valid_Ra_z;
                        valid_Rb_list[empty_rs_z] <= ((Pb_z == Pw_Result_add && valid_Result_add) ||
                            (Pb_z == Pw_Result_mul && valid_Result_mul))? 1 : valid_Rb_z;
                    end
                end
                // 一端口唤醒输出
                if (awake_rs != 8 && !freeze_back) begin
                    valid_op_awake_r <= valid_op_list[awake_rs];
                    Pw_awake_r <= Pw_list[awake_rs];
                    tag_ROB_awake_r <= tag_ROB_list[awake_rs];
                    Pa_awake_r <= Pa_list[awake_rs];
                    Pb_awake_r <= Pb_list[awake_rs];
                    // 清空旧值
                    valid_op_list[awake_rs] <= '0;
                    Pw_list[awake_rs] <= '0;
                    tag_ROB_list[awake_rs] <= '0;
                    Pa_list[awake_rs] <= '0;
                    Pb_list[awake_rs] <= '0;
                    valid_Ra_list[awake_rs] <= '0;
                    valid_Rb_list[awake_rs] <= '0;
                end
                else begin
                    valid_op_awake_r <= '0;
                    Pw_awake_r <= '0;
                    tag_ROB_awake_r <= '0;
                    Pa_awake_r <= '0;
                    Pb_awake_r <= '0;
                end
                // 接收广播信号
                if (valid_Result_add) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (Pa_list[i] == Pw_Result_add && valid_Ra_list[i] == 0 && valid_op_list[i] == 1) begin
                            valid_Ra_list[i] <= 1;
                        end
                        if (Pb_list[i] == Pw_Result_add && valid_Rb_list[i] == 0 && valid_op_list[i] == 1) begin
                            valid_Rb_list[i] <= 1;
                        end
                    end
                end
                if (valid_Result_mul) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (Pa_list[i] == Pw_Result_mul && valid_Ra_list[i] == 0 && valid_op_list[i] == 1) begin
                            valid_Ra_list[i] <= 1;
                        end
                        if (Pb_list[i] == Pw_Result_mul && valid_Rb_list[i] == 0 && valid_op_list[i] == 1) begin
                            valid_Rb_list[i] <= 1;
                        end
                    end
                end
            end
            // 异常清空
            else begin
                valid_op_list <= '0;
                valid_Ra_list <= '0;
                valid_Rb_list <= '0;
                for (i = 0; i < 8; i = i + 1) begin
                    Pw_list[i] <= '0;
                    tag_ROB_list[i] <= '0;
                    Pa_list[i] <= '0;
                    Pb_list[i] <= '0;
                end
                Pa_awake_r <= '0;
                Pb_awake_r <= '0;
                Pw_awake_r <= '0;
                valid_op_awake_r <= '0;
                tag_ROB_awake_r <= '0;
            end
        end
    end

endmodule