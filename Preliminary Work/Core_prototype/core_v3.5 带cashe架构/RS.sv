module RS (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    input               valid_pc,
    output              full_RS,
    // RS 类型实例化, 仅 ADD / MUL
    input   [1 : 0]     Type_ref,
    // x,y,z 端口写入
    input   [1 : 0]     Type        [2 : 0],
    input   [4 : 0]     Pa          [2 : 0],
    input   [4 : 0]     Pb          [2 : 0],
    input   [4 : 0]     Pw          [2 : 0],
    input               valid_Pa    [2 : 0],
    input               valid_Pb    [2 : 0],
    input   [4 : 0]     tag_ROB     [2 : 0],
    // 唤醒
    output              valid_op_awake,
    output  [4 : 0]     Pa_awake,
    output  [4 : 0]     Pb_awake,
    output  [4 : 0]     Pw_awake,
    output  [4 : 0]     tag_ROB_awake,
    // ADD 广播
    input   [4 : 0]     Pw_Result_add,
    input               valid_Result_add,
    // MUL 广播
    input   [4 : 0]     Pw_Result_mul,
    input               valid_Result_mul,
    // LS 广播
    input   [4 : 0]     Pw_Result_ls,
    input               valid_Result_ls,
    input               mode_ls,
    // (新增) oldest-first 实现
    input   [4 : 0]     ptr_old     // +
);

    typedef struct packed {
        reg     [4 : 0]     Pa;
        reg     [4 : 0]     Pb;
        reg     [4 : 0]     Pw;
        reg     [4 : 0]     tag_ROB;
    } rs_list;

    reg     [7 : 0]     valid_op_list;
    wire    [7 : 0]     valid_op_list_y;
    wire    [7 : 0]     valid_op_list_z;

    reg     [7 : 0]     valid_Pa_list;
    reg     [7 : 0]     valid_Pb_list;

    rs_list     list        [7 : 0];

    integer     empty_rs    [2 : 0];
    integer     awake_rs;

    reg                 valid_op_awake_r;
    reg     [4 : 0]     Pa_awake_r;
    reg     [4 : 0]     Pb_awake_r;
    reg     [4 : 0]     Pw_awake_r;
    reg     [4 : 0]     tag_ROB_awake_r;

    integer i;

    // (新增) oldest-first 实现
    reg     [5 : 0]     tag_ROB_shifted [7 : 0];    // +
    integer             compare_1       [3 : 0];    // +
    integer             compare_2       [1 : 0];    // +
    integer             compare_3;                  // +

    // 写入, 接收广播, 发射
    always @(posedge clk or negedge rst) begin
        if (rst) begin
            valid_op_list       <=  '0;
            valid_Pa_list       <=  '0;
            valid_Pb_list       <=  '0;
            for (i = 0; i < 8; i = i + 1) begin
                list[i]         <=  '0;
            end
            valid_op_awake_r    <=  '0;
            Pa_awake_r          <=  '0;
            Pb_awake_r          <=  '0;
            Pw_awake_r          <=  '0;
            tag_ROB_awake_r     <=  '0;
        end
        else begin
            if (!flush) begin

                // 三端口分发写入
                if (valid_pc && !freeze_front) begin
                    for (i = 0; i < 3; i = i + 1) begin
                        if (Type[i] == Type_ref) begin
                            valid_op_list[empty_rs[i]]  <=  1;
                            valid_Pa_list[empty_rs[i]]  <=  ((Pa[i] == Pw_Result_add && valid_Result_add) ||
                                                            (Pa[i] == Pw_Result_mul && valid_Result_mul))? 1 : valid_Pa[i];
                            valid_Pb_list[empty_rs[i]]  <=  ((Pb[i] == Pw_Result_add && valid_Result_add) ||
                                                            (Pb[i] == Pw_Result_mul && valid_Result_mul))? 1 : valid_Pb[i];
                            list[empty_rs[i]]           <=  {Pa[i], Pb[i], Pw[i], tag_ROB[i]};
                        end
                    end
                end

                // 一端口唤醒输出
                if (awake_rs != 8 && !freeze_back) begin
                    valid_op_awake_r                                        <=  valid_op_list[awake_rs];
                    {Pa_awake_r, Pb_awake_r, Pw_awake_r, tag_ROB_awake_r}   <=  list[awake_rs];
                    // 清空旧值
                    valid_op_list[awake_rs] <=  '0;
                    valid_Pa_list[awake_rs] <=  '0;
                    valid_Pb_list[awake_rs] <=  '0;
                    list[awake_rs]          <=  '0;
                end
                else begin
                    valid_op_awake_r        <=  '0;
                    Pa_awake_r              <=  '0;
                    Pb_awake_r              <=  '0;
                    Pw_awake_r              <=  '0;
                    tag_ROB_awake_r         <=  '0;
                end

                // 接收广播信号
                if (valid_Result_add) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Pa == Pw_Result_add && valid_op_list[i] == 1) begin
                            valid_Pa_list[i] <= 1;
                        end
                        if (list[i].Pb == Pw_Result_add && valid_op_list[i] == 1) begin
                            valid_Pb_list[i] <= 1;
                        end
                    end
                end
                if (valid_Result_mul) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Pa == Pw_Result_mul && valid_op_list[i] == 1) begin
                            valid_Pa_list[i] <= 1;
                        end
                        if (list[i].Pb == Pw_Result_mul && valid_op_list[i] == 1) begin
                            valid_Pb_list[i] <= 1;
                        end
                    end
                end
                if (valid_Result_ls && mode_ls == 1) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Pa == Pw_Result_ls && valid_op_list[i] == 1) begin
                            valid_Pa_list[i] <= 1;
                        end
                        if (list[i].Pb == Pw_Result_ls && valid_op_list[i] == 1) begin
                            valid_Pb_list[i] <= 1;
                        end
                    end
                end
            end

            // 异常清空
            else begin
                valid_op_list       <=  '0;
                valid_Pa_list       <=  '0;
                valid_Pb_list       <=  '0;
                for (i = 0; i < 8; i = i + 1) begin
                    list[i]         <=  '0;
                end
                valid_op_awake_r    <=  '0;
                Pa_awake_r          <=  '0;
                Pb_awake_r          <=  '0;
                Pw_awake_r          <=  '0;
                tag_ROB_awake_r     <=  '0;
            end
        end
    end

    // 分配 awake_rs
    assign  valid_op_awake  =   valid_op_awake_r;
    assign  Pa_awake        =   Pa_awake_r;
    assign  Pb_awake        =   Pb_awake_r;
    assign  Pw_awake        =   Pw_awake_r;
    assign  tag_ROB_awake   =   tag_ROB_awake_r;

    // always @(*) begin
    //     casez (valid_op_list & valid_Pa_list & valid_Pb_list)
    //         8'b????_???1:   awake_rs = 0;
    //         8'b????_??10:   awake_rs = 1;
    //         8'b????_?100:   awake_rs = 2;
    //         8'b????_1000:   awake_rs = 3;
    //         8'b???1_0000:   awake_rs = 4;
    //         8'b??10_0000:   awake_rs = 5;
    //         8'b?100_0000:   awake_rs = 6;
    //         8'b1000_0000:   awake_rs = 7;
    //         default:        awake_rs = 8;
    //     endcase
    // end

    // (新增) oldest-first 实现
    // +
    always @(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            tag_ROB_shifted[i]  =   ((valid_op_list[i] & valid_Pa_list[i] & valid_Pb_list[i]) == 1)? (list[i].tag_ROB - ptr_old) & 6'b01_1111 : 6'd32;
        end
        for (i = 0; i < 4; i = i + 1) begin
            compare_1[i]        =   (tag_ROB_shifted[2*i] < tag_ROB_shifted[2*i+1])? 2*i : 2*i+1;
        end
        for (i = 0; i < 2; i = i + 1) begin
            compare_2[i]        =   (tag_ROB_shifted[compare_1[2*i]] < tag_ROB_shifted[compare_1[2*i+1]])? compare_1[2*i] : compare_1[2*i+1];
        end
        compare_3               =   (tag_ROB_shifted[compare_2[0]] < tag_ROB_shifted[compare_2[1]])? compare_2[0] : compare_2[1];
        awake_rs                =   (tag_ROB_shifted[compare_3] == 6'd32)? 8 : compare_3;
    end
    // +

    // 分配 empty_rs, 生成 full_RS
    assign  valid_op_list_y =   valid_op_list   | (8'd1 << empty_rs[0]);
    assign  valid_op_list_z =   valid_op_list_y | (8'd1 << empty_rs[1]);

    assign  full_RS         =   (empty_rs[0] == 8 || empty_rs[1] == 8 || empty_rs[2] == 8)? 1 : 0;

    always @(*) begin
        // 计算 empty_rs[0] (原 empty_rs_x)
        casez (valid_op_list)
            8'b????_???0:   empty_rs[0] = 0;
            8'b????_??01:   empty_rs[0] = 1;
            8'b????_?011:   empty_rs[0] = 2;
            8'b????_0111:   empty_rs[0] = 3;
            8'b???0_1111:   empty_rs[0] = 4;
            8'b??01_1111:   empty_rs[0] = 5;
            8'b?011_1111:   empty_rs[0] = 6;
            8'b0111_1111:   empty_rs[0] = 7;
            default:        empty_rs[0] = 8;
        endcase

        // 计算 empty_rs[1] (原 empty_rs_y)
        casez (valid_op_list_y)
            8'b????_???0:   empty_rs[1] = 0;
            8'b????_??01:   empty_rs[1] = 1;
            8'b????_?011:   empty_rs[1] = 2;
            8'b????_0111:   empty_rs[1] = 3;
            8'b???0_1111:   empty_rs[1] = 4;
            8'b??01_1111:   empty_rs[1] = 5;
            8'b?011_1111:   empty_rs[1] = 6;
            8'b0111_1111:   empty_rs[1] = 7;
            default:        empty_rs[1] = 8;
        endcase

        // 计算 empty_rs[2] (原 empty_rs_z)
        casez (valid_op_list_z)
            8'b????_???0:   empty_rs[2] = 0;
            8'b????_??01:   empty_rs[2] = 1;
            8'b????_?011:   empty_rs[2] = 2;
            8'b????_0111:   empty_rs[2] = 3;
            8'b???0_1111:   empty_rs[2] = 4;
            8'b??01_1111:   empty_rs[2] = 5;
            8'b?011_1111:   empty_rs[2] = 6;
            8'b0111_1111:   empty_rs[2] = 7;
            default:        empty_rs[2] = 8;
        endcase
    end

endmodule