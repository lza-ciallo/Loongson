module ROB (
    input               clk,
    input               rst,
    input               flush,
    output              full_ROB,
    // 预分配条目
    output  [4 : 0]     tag_ROB     [2 : 0],
    // 预写入
    input               valid_pc,
    input               freeze_front,
    input   [1 : 0]     Type        [2 : 0],
    input   [4 : 0]     Pw          [2 : 0],
    input   [4 : 0]     Pw_old      [2 : 0],
    input   [2 : 0]     Rw          [2 : 0],
    // 写入广播结果
    input               valid_Result_add,
    input   [4 : 0]     tag_ROB_Result_add,
    input               valid_Result_mul,
    input   [4 : 0]     tag_ROB_Result_mul,
    input               valid_Result_ls,
    input   [4 : 0]     tag_ROB_Result_ls,
    // 退休
    output              ready_ret   [2 : 0],
    output              excep_ret   [2 : 0],
    output  [1 : 0]     Type_ret    [2 : 0],
    output  [4 : 0]     Pw_ret      [2 : 0],
    output  [4 : 0]     Pw_old_ret  [2 : 0],
    output  [2 : 0]     Rw_ret      [2 : 0]
);

    typedef struct packed {
        reg                 ready;
        reg                 excep;
        reg     [1 : 0]     Type;
        reg     [4 : 0]     Pw;
        reg     [4 : 0]     Pw_old;
        reg     [2 : 0]     Rw;
    } rob_list;

    rob_list            list            [31 : 0];

    reg     [31 : 0]    valid_list;
    reg     [ 4 : 0]    ptr_old;
    reg     [ 4 : 0]    ptr_young;

    wire    [31 : 0]    full_temp;

    wire    [ 4 : 0]    ptr_old_wire    [ 2 : 0];

    integer i;
    genvar  gvi;

    // 满的判定
    assign  full_temp   =   valid_list | (1 << tag_ROB[0]) | (1 << tag_ROB[1]) | (1 << tag_ROB[2]);
    assign  full_ROB    =   &full_temp;

    // 预分配条目

    generate
        for (gvi = 0; gvi < 3; gvi = gvi + 1) begin
            assign  ptr_old_wire[gvi]   =   ptr_old     +   gvi;
            assign  tag_ROB[gvi]        =   ptr_young   +   gvi;
        end
    endgenerate

    // 提交退休指令
    assign  ready_ret[0]    =   list[ptr_old_wire[0]].ready;
    assign  ready_ret[1]    =   ready_ret[0]? list[ptr_old_wire[1]].ready : 0;//取决于它自己是否 ready 并且前一条指令也正在退休
    assign  ready_ret[2]    =   (ready_ret[0] & ready_ret[1])? list[ptr_old_wire[2]].ready : 0;

    generate
        for (gvi = 0; gvi < 3; gvi = gvi + 1) begin
            assign  excep_ret[gvi]  =   list[ptr_old_wire[gvi]].excep;
            assign  Type_ret[gvi]   =   list[ptr_old_wire[gvi]].Type;
            assign  Pw_ret[gvi]     =   list[ptr_old_wire[gvi]].Pw;
            assign  Pw_old_ret[gvi] =   list[ptr_old_wire[gvi]].Pw_old;
            assign  Rw_ret[gvi]     =   list[ptr_old_wire[gvi]].Rw;
        end
    endgenerate

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_list  <=  '0;
            for (i = 0; i < 32; i = i + 1) begin
                list[i] <=  '0;
            end
            ptr_old     <=  '0;
            ptr_young   <=  '0;
        end
        else begin

            // 预写入
            if (valid_pc && !freeze_front) begin
                for (i = 0; i < 3; i = i + 1) begin
                    valid_list[tag_ROB[i]]      <=  1;
                    list[tag_ROB[i]].excep      <=  (Rw[i] == 0 && Type[i] != 2'b11)? 1 : 0;
                    list[tag_ROB[i]].Type       <=  Type[i];
                    list[tag_ROB[i]].Pw         <=  Pw[i];
                    list[tag_ROB[i]].Pw_old     <=  Pw_old[i];
                    list[tag_ROB[i]].Rw         <=  Rw[i];
                end
                ptr_young   <=  ptr_young + 3;
            end

            // 写入广播结果
            if (valid_Result_add) begin
                list[tag_ROB_Result_add].ready  <=  1;
            end
            if (valid_Result_mul) begin
                list[tag_ROB_Result_mul].ready  <=  1;
            end
            if (valid_Result_ls) begin
                list[tag_ROB_Result_ls].ready   <=  1;
            end

            // 退休释放资源
            casez({ready_ret[2] & ~excep_ret[2], ready_ret[1] & ~excep_ret[1], ready_ret[0] & ~excep_ret[0]})
                3'b??0:     ptr_old                     <=  ptr_old;
                3'b?01: begin
                            ptr_old                     <=  ptr_old + 1;
                            valid_list[ptr_old_wire[0]] <=  '0;
                            list[ptr_old_wire[0]]       <=  '0;
                        end
                3'b011: begin
                            ptr_old                     <=  ptr_old + 2;
                            valid_list[ptr_old_wire[0]] <=  '0;
                            valid_list[ptr_old_wire[1]] <=  '0;
                            list[ptr_old_wire[0]]       <=  '0;
                            list[ptr_old_wire[1]]       <=  '0;
                        end
                3'b111: begin
                            ptr_old                     <=  ptr_old + 3;
                            valid_list[ptr_old_wire[0]] <=  '0;
                            valid_list[ptr_old_wire[1]] <=  '0;
                            valid_list[ptr_old_wire[2]] <=  '0;
                            list[ptr_old_wire[0]]       <=  '0;
                            list[ptr_old_wire[1]]       <=  '0;
                            list[ptr_old_wire[2]]       <=  '0;
                        end
                default:    ptr_old                     <=  ptr_old;
            endcase
        end
    end

endmodule