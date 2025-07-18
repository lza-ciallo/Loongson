module LSQ (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    input               valid_pc,
    output              full_LSQ,
    // x,y,z 端口写入
    input   [ 1 : 0]    Type        [2 : 0],
    input   [ 4 : 0]    Pb          [2 : 0],
    input               valid_Pb    [2 : 0],
    input   [ 4 : 0]    Pw          [2 : 0],
    input   [ 4 : 0]    tag_ROB     [2 : 0],
    // 唤醒
    output              valid_op_awake,
    output              mode_awake,
    output  [ 4 : 0]    Px_awake,
    output  [15 : 0]    Addr_awake,
    output  [ 4 : 0]    tag_ROB_awake,
    // 来自 FU 的广播, 唤醒 Px
    input   [ 4 : 0]    Pw_Result_add,
    input               valid_Result_add,
    input   [ 4 : 0]    Pw_Result_mul,
    input               valid_Result_mul,
    input   [ 4 : 0]    Pw_Result_ls,
    input               valid_Result_ls,
    input               mode_ls,
    // 来自 AGU 的广播, 唤醒 Addr
    input               valid_Addr_agu,
    input   [ 4 : 0]    tag_ROB_Result_agu,
    input   [15 : 0]    Addr_agu
);

    typedef struct packed {
        reg     [ 4 : 0]    Px;
        reg     [15 : 0]    Addr;
        reg     [ 4 : 0]    tag_ROB;
    } lsq_list;

    reg     [ 7 : 0]    valid_op_list;
    reg     [ 7 : 0]    mode_list;
    reg     [ 7 : 0]    valid_Px_list;//表示指令i所需的数据是否就绪
    reg     [ 7 : 0]    valid_Addr_list;//表示指令的内存地址是否已经由AGU计算完毕

    lsq_list            list            [7 : 0];

    reg     [ 2 : 0]    ptr_old;
    reg     [ 2 : 0]    ptr_young;
    wire    [ 2 : 0]    ptr_young_wire  [2 : 0];

    reg     [ 2 : 0]    ptr_awake;
    reg                 awake_exist;

    reg                 valid_op_awake_r;
    reg                 mode_awake_r;
    reg     [ 4 : 0]    Px_awake_r;
    reg     [15 : 0]    Addr_awake_r;
    reg     [ 4 : 0]    tag_ROB_awake_r;

    reg     [ 7 : 0]    token_list;     //  起始位置 ptr_old, 标记允许被乱序发射的条目
    reg     [ 7 : 0]    shift_list;     //  ptr_old->0 的 mode_list & valid_op_list
    reg     [ 7 : 0]    token_temp;     //  ptr_old->0
    reg     [ 7 : 0]    shift_temp;     //  起始位置 ptr_old

    integer i, j, k;
    genvar  gvi;

    // 生成循环队列的索引
    generate
        for (gvi = 0; gvi < 3; gvi = gvi + 1) begin
            assign  ptr_young_wire[gvi] =   ptr_young + gvi;
        end
    endgenerate

    // 满的判定
    assign  full_LSQ    =   (valid_op_list[ptr_old] == 1 &&
                            (ptr_young_wire[0] == ptr_old || ptr_young_wire[1] == ptr_old || ptr_young_wire[2] == ptr_old))? 1 : 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_op_list       <=  '0;
            mode_list           <=  '0;
            valid_Px_list       <=  '0;
            valid_Addr_list     <=  '0;
            for (i = 0; i < 8; i = i + 1) begin
                list[i]         <=  '0;
            end
            valid_op_awake_r    <=  '0;
            mode_awake_r        <=  '0;
            Px_awake_r          <=  '0;
            Addr_awake_r        <=  '0;
            tag_ROB_awake_r     <=  '0;
            ptr_old             <=  '0;
            ptr_young           <=  '0;
        end
        else begin
            if (!flush) begin
                
                // x,y,z 端口顺序写入, 允许气泡
                if (valid_pc && !freeze_front) begin
                    for (i = 0; i < 3; i = i + 1) begin
                        if (Type[i] == 2'b10 || Type[i] == 2'b11) begin
                            valid_op_list[ptr_young_wire[i]]    <=  1;
                            mode_list[ptr_young_wire[i]]        <=  ~Type[i][0];
                            valid_Px_list[ptr_young_wire[i]]    <=  (Type[i] == 2'b10)? 1 : valid_Pb[i];
                            valid_Addr_list[ptr_young_wire[i]]  <=  0;
                            list[ptr_young_wire[i]].Px          <=  (Type[i] == 2'b10)? Pw[i] : Pb[i];
                            list[ptr_young_wire[i]].Addr        <=  '0;
                            list[ptr_young_wire[i]].tag_ROB     <=  tag_ROB[i];
                        end
                    end
                    // 更新 ptr_young
                    if (Type[2] == 2'b10 || Type[2] == 2'b11) begin
                        ptr_young   <=  ptr_young + 3;
                    end
                    else if (Type[1] == 2'b10 || Type[1] == 2'b11) begin
                        ptr_young   <=  ptr_young + 2;
                    end
                    else if (Type[0] == 2'b10 || Type[0] == 2'b11) begin
                        ptr_young   <=  ptr_young + 1;
                    end
                    else begin
                        ptr_young   <=  ptr_young;
                    end
                end

                // 将已唤醒条目发射
                if (awake_exist && !freeze_back) begin
                    valid_op_awake_r            <=  valid_op_list[ptr_awake];
                    mode_awake_r                <=  mode_list[ptr_awake];
                    Px_awake_r                  <=  list[ptr_awake].Px;
                    Addr_awake_r                <=  list[ptr_awake].Addr;
                    tag_ROB_awake_r             <=  list[ptr_awake].tag_ROB;
                    // 发射清空
                    valid_op_list[ptr_awake]    <=  '0;
                    mode_list[ptr_awake]        <=  '0;
                    valid_Px_list[ptr_awake]    <=  '0;
                    valid_Addr_list[ptr_awake]  <=  '0;
                    list[ptr_awake]             <=  '0;
                    if (ptr_awake == ptr_old) begin
                        ptr_old                 <=  ptr_old + 1;
                    end
                end
                else begin
                    valid_op_awake_r            <=  '0;
                    mode_awake_r                <=  '0;
                    Px_awake_r                  <=  '0;
                    Addr_awake_r                <=  '0;
                    tag_ROB_awake_r             <=  '0;
                end

                // 接收 ADD,MUL,LS 广播, 唤醒 Px
                if (valid_Result_add) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Px == Pw_Result_add && valid_op_list[i] == 1) begin
                            //监听结果总线，如果广播的结果与某个Store指令等待的源操作数list[i].Px匹配，就将valid_Px_list[i]置为1
                            valid_Px_list[i]    <=  1;
                        end
                    end
                end
                if (valid_Result_mul) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Px == Pw_Result_mul && valid_op_list[i] == 1) begin
                            valid_Px_list[i]    <=  1;
                        end
                    end
                end
                if (valid_Result_ls && mode_ls == 1) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].Px == Pw_Result_ls && valid_op_list[i] == 1) begin
                            valid_Px_list[i]    <=  1;
                        end
                    end
                end
                // 接收 AGU 广播, 唤醒 Addr
                if (valid_Addr_agu) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        if (list[i].tag_ROB == tag_ROB_Result_agu && valid_op_list[i] == 1) begin
                            //监听AGU，如果广播的地址tag_ROB_Result_agu与队列中某个指令的tag_ROB匹配，就将valid_Addr_list[i]置为1
                            valid_Addr_list[i]  <=  1;
                            list[i].Addr        <=  Addr_agu;
                        end
                    end
                end
            end

            // 异常清空
            else begin
                valid_op_list       <=  '0;
                mode_list           <=  '0;
                valid_Px_list       <=  '0;
                valid_Addr_list     <=  '0;
                for (i = 0; i < 8; i = i + 1) begin
                    list[i]         <=  '0;
                end
                valid_op_awake_r    <=  '0;
                mode_awake_r        <=  '0;
                Px_awake_r          <=  '0;
                Addr_awake_r        <=  '0;
                tag_ROB_awake_r     <=  '0;
                ptr_old             <=  '0;
                ptr_young           <=  '0;
            end
        end
    end

    // 唤醒逻辑, 生成 ptr_awake, awake
    assign  valid_op_awake  =   valid_op_awake_r;
    assign  mode_awake      =   mode_awake_r;
    assign  Px_awake        =   Px_awake_r;
    assign  Addr_awake      =   Addr_awake_r;
    assign  tag_ROB_awake   =   tag_ROB_awake_r;


    always @(*) begin
        shift_temp  =   mode_list & valid_op_list;
        for (i = 0; i < 8; i = i + 1) begin
            //使得队列头 ptr_old 对齐到 shift_list 的第0位
            j   =   (i + ptr_old >= 8)? i + ptr_old - 8 : i + ptr_old;
            shift_list[i]   =   shift_temp[j];
            k   =   (i + 8 - ptr_old >= 8)? i - ptr_old : i + 8 - ptr_old;
            token_list[i]   =   token_temp[k];
        end

        //一个 Load 只有在它前面没有未确定地址的 Store 时才能被发射；一个 Store 只有当它是队列中最老的指令时才能被发射
        casez (shift_list)
            8'b????_???0:   token_temp  =   8'b0000_0001;
            8'b????_??01:   token_temp  =   8'b0000_0001;
            8'b????_?011:   token_temp  =   8'b0000_0011;
            8'b????_0111:   token_temp  =   8'b0000_0111;
            8'b???0_1111:   token_temp  =   8'b0000_1111;
            8'b??01_1111:   token_temp  =   8'b0001_1111;
            8'b?011_1111:   token_temp  =   8'b0011_1111;
            8'b0111_1111:   token_temp  =   8'b0111_1111;
            8'b1111_1111:   token_temp  =   8'b1111_1111;
            default:        token_temp  =   8'b0000_0000;
        endcase
    end

    // always @(*) begin
    //     token_list = 0;
    //     token_stop = 0;
    //     for (j = 0; j < 8; j = j + 1) begin
    //         k = (j + ptr_old >= 8)? j + ptr_old - 8 : j + ptr_old;
    //         if (token_stop == 0 && valid_op_list[k] == 1) begin
    //             if (mode_list[k] == 0) begin
    //                 if (k == ptr_old) begin
    //                     token_list[k] = 1;
    //                 end
    //                 token_stop = 1;
    //             end
    //             else begin
    //                 token_list[k] = 1;
    //             end
    //         end
    //     end
    // end

    always @(*) begin
        casez (valid_op_list & valid_Px_list & valid_Addr_list & token_list)//指令有效+数据已就绪+地址已就绪+已获得发射令牌
            8'b????_???1:   {ptr_awake, awake_exist}    =   {3'd0, 1'b1};
            8'b????_??10:   {ptr_awake, awake_exist}    =   {3'd1, 1'b1};
            8'b????_?100:   {ptr_awake, awake_exist}    =   {3'd2, 1'b1};
            8'b????_1000:   {ptr_awake, awake_exist}    =   {3'd3, 1'b1};
            8'b???1_0000:   {ptr_awake, awake_exist}    =   {3'd4, 1'b1};
            8'b??10_0000:   {ptr_awake, awake_exist}    =   {3'd5, 1'b1};
            8'b?100_0000:   {ptr_awake, awake_exist}    =   {3'd6, 1'b1};
            8'b1000_0000:   {ptr_awake, awake_exist}    =   {3'd7, 1'b1};
            default:        {ptr_awake, awake_exist}    =   {3'd0, 1'b0};
        endcase
    end

endmodule
