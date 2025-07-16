module inst_fifo (
    input               clk,
    input               rst,
    input               flush_ififo,
    input               stall_ififo,
    output              full_ififo,
    // 写入数据
    input   [31 : 0]    pc_ifr              [2 : 0],
    input   [31 : 0]    inst                [2 : 0],
    input   [31 : 0]    target_unsel_bpu    [2 : 0],
    input   [ 9 : 0]    index_bpu           [2 : 0],
    input               Predict_bpu         [2 : 0],
    // 控制写入几条
    input               valid_inst_pre      [2 : 0],
    // 读出数据
    output  [31 : 0]    pc_ififo            [2 : 0],
    output  [31 : 0]    inst_ififo          [2 : 0],
    output  [31 : 0]    target_unsel_ififo  [2 : 0],
    output  [ 9 : 0]    index_ififo         [2 : 0],
    output              Predict_ififo       [2 : 0]
);

    typedef struct packed {
        reg     [31 : 0]    pc;
        reg     [31 : 0]    inst;
        reg     [31 : 0]    target_unsel;
        reg     [ 9 : 0]    index;
        reg                 Predict;
    } fifo_entry;

    reg         [ 3 : 0]    ptr_old;
    reg         [ 3 : 0]    ptr_young;
    reg         [15 : 0]    valid_entry;
    fifo_entry  [15 : 0]    fifo;

    wire        [ 3 : 0]    ptr_old_wire    [2 : 0];
    wire        [ 3 : 0]    ptr_young_wire  [2 : 0];

    // 产生不溢出 4bit 的有效索引
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  ptr_old_wire[i]     =   ptr_old + i;
            assign  ptr_young_wire[i]   =   ptr_young + i;
        end
    endgenerate

    // 组合逻辑读出指令数据
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  {pc_ififo[i], inst_ififo[i], target_unsel_ififo[i], index_ififo[i], Predict_ififo[i]}   =
                        (!stall_ififo && valid_entry[ptr_old_wire[i]])? fifo[ptr_old_wire[i]] : '0;
        end
    endgenerate

    // 判断队列是否满
    assign  full_ififo  =   ((ptr_young_wire[0] == ptr_old || ptr_young_wire[1] == ptr_old || ptr_young_wire[2] == ptr_old) &&
                valid_entry[ptr_old] == 1)? 1 : 0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            ptr_old     <=  '0;
            ptr_young   <=  '0;
            valid_entry <=  '0;
            for (integer i = 0; i < 16; i = i + 1) begin
                fifo[i] <=  '0;
            end
        end
        else begin
            if (flush_ififo) begin
                ptr_old     <=  '0;
                ptr_young   <=  '0;
                valid_entry <=  '0;
                for (integer i = 0; i < 16; i = i + 1) begin
                    fifo[i] <=  '0;
                end
            end
            else begin
                // 写入至多三条指令
                if (!full_ififo) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (valid_inst_pre[i]) begin
                            fifo[ptr_young_wire[i]]         <=
                                        {pc_ifr[i], inst[i], target_unsel_bpu[i], index_bpu[i], Predict_bpu[i]};
                            valid_entry[ptr_young_wire[i]]  <=  1;
                        end
                    end
                    // 更新 ptr_young
                    casez (valid_inst_pre)
                        3'b?01:     ptr_young   <=  ptr_young + 1;
                        3'b011:     ptr_young   <=  ptr_young + 2;
                        3'b111:     ptr_young   <=  ptr_young + 3;
                        default:    ptr_young   <=  ptr_young;
                    endcase
                end
                // 读出三条指令, 清空对应条目
                if (!stall_ififo) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (valid_entry[ptr_old_wire[i]]) begin
                            valid_entry[ptr_old_wire[i]]    <=  '0;
                            fifo[ptr_old_wire[i]]           <=  '0;
                        end
                    end
                    casez ({valid_entry[ptr_old_wire[2]], valid_entry[ptr_old_wire[1]], valid_entry[ptr_old_wire[0]]})
                        3'b?01:     ptr_old     <=  ptr_old + 1;
                        3'b011:     ptr_old     <=  ptr_old + 2;
                        3'b111:     ptr_old     <=  ptr_old + 3; 
                        default:    ptr_old     <=  ptr_old;
                    endcase
                end
            end
        end
    end

endmodule