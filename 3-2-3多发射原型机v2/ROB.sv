module ROB (
    input               clk,
    input               rst,
    input               flush,
    output              full_ROB,
    // 预分配条目
    output  [4 : 0]     tag_ROB_x,
    output  [4 : 0]     tag_ROB_y,
    output  [4 : 0]     tag_ROB_z,
    // 预写入覆盖的 Pw_old, 预写入 Rw
    input               freeze_front,
    input               valid_issue_x,
    input               valid_issue_y,
    input               valid_issue_z,
    input   [4 : 0]     Pw_old_x,
    input   [4 : 0]     Pw_old_y,
    input   [4 : 0]     Pw_old_z,
    input   [2 : 0]     Rw_x,
    input   [2 : 0]     Rw_y,
    input   [2 : 0]     Rw_z,
    // 写入执行结果
    input               freeze_back,
    input               valid_Result_add,
    input   [4 : 0]     Pw_Result_add,
    input               exp_add,
    input   [4 : 0]     tag_ROB_Result_add,
    input               valid_Result_mul,
    input   [4 : 0]     Pw_Result_mul,
    input               exp_mul,
    input   [4 : 0]     tag_ROB_Result_mul,
    // 退休
    output              RegWr_x,
    output              RegWr_y,
    output              RegWr_z,
    output              exp_x,
    output              exp_y,
    output              exp_z,
    output  [4 : 0]     Pw_retire_x,
    output  [4 : 0]     Pw_retire_y,
    output  [4 : 0]     Pw_retire_z,
    output  [2 : 0]     Rw_commit_x,
    output  [2 : 0]     Rw_commit_y,
    output  [2 : 0]     Rw_commit_z,
    output  [4 : 0]     Pw_commit_x,
    output  [4 : 0]     Pw_commit_y,
    output  [4 : 0]     Pw_commit_z
);

    reg     [31 : 0]    valid_list;
    reg     [31 : 0]    RegWr_list;
    reg     [31 : 0]    exp_list;
    reg     [2 : 0]     Rw_list [31 : 0];
    reg     [4 : 0]     Pw_list [31 : 0];
    reg     [4 : 0]     Pw_old_list [31 : 0];

    reg     [4 : 0]     ptr_old;
    reg     [4 : 0]     ptr_young;

    wire    [31 : 0]    full_temp;

    assign  full_temp = valid_list | (1 << tag_ROB_x) | (1 << tag_ROB_y) | (1 << tag_ROB_z);
    assign  full_ROB = &full_temp;

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst || flush) begin
            valid_list <= '0;
            RegWr_list <= '0;
            exp_list <= '0;
            for (i = 0; i < 32; i = i + 1) begin
                Rw_list[i] <= '0;
                Pw_list[i] <= '0;
                Pw_old_list[i] <= '0;
            end
            ptr_old <= '0;
            ptr_young <= '0;
        end
        else begin
            // 预写入
            if (!freeze_front && valid_issue_x && valid_issue_y && valid_issue_z) begin
                valid_list[tag_ROB_x] <= valid_issue_x;
                Rw_list[tag_ROB_x] <= Rw_x;
                Pw_old_list[tag_ROB_x] <= Pw_old_x;
                valid_list[tag_ROB_y] <= valid_issue_y;
                Rw_list[tag_ROB_y] <= Rw_y;
                Pw_old_list[tag_ROB_y] <= Pw_old_y;
                valid_list[tag_ROB_z] <= valid_issue_z;
                Rw_list[tag_ROB_z] <= Rw_z;
                Pw_old_list[tag_ROB_z] <= Pw_old_z;
                ptr_young <= ptr_young + 3;
            end
            // 执行结果
            if (!freeze_back && valid_Result_add && valid_list[tag_ROB_Result_add]) begin
                RegWr_list[tag_ROB_Result_add] <= valid_Result_add;
                exp_list[tag_ROB_Result_add] <= exp_add;
                Pw_list[tag_ROB_Result_add] <= Pw_Result_add;
            end
            if (!freeze_back && valid_Result_mul && valid_list[tag_ROB_Result_mul]) begin
                RegWr_list[tag_ROB_Result_mul] <= valid_Result_mul;
                exp_list[tag_ROB_Result_mul] <= exp_mul;
                Pw_list[tag_ROB_Result_mul] <= Pw_Result_mul;
            end
            // 退休释放
            casez ({RegWr_z, RegWr_y, RegWr_x})
                3'b??0:     ptr_old <= ptr_old;
                3'b?01: begin
                            ptr_old <= ptr_old + 1;
                            {valid_list[ptr_old], RegWr_list[ptr_old], exp_list[ptr_old],
                                Rw_list[ptr_old], Pw_list[ptr_old], Pw_old_list[ptr_old]} <= '0;
                        end
                3'b011: begin
                            ptr_old <= ptr_old + 2;
                            {valid_list[ptr_old], RegWr_list[ptr_old], exp_list[ptr_old],
                                Rw_list[ptr_old], Pw_list[ptr_old], Pw_old_list[ptr_old]} <= '0;
                            {valid_list[ptr_old + 1], RegWr_list[ptr_old + 1], exp_list[ptr_old + 1],
                                Rw_list[ptr_old + 1], Pw_list[ptr_old + 1], Pw_old_list[ptr_old + 1]} <= '0;
                        end
                3'b111: begin
                            ptr_old <= ptr_old + 3;
                            {valid_list[ptr_old], RegWr_list[ptr_old], exp_list[ptr_old],
                                Rw_list[ptr_old], Pw_list[ptr_old], Pw_old_list[ptr_old]} <= '0;
                            {valid_list[ptr_old + 1], RegWr_list[ptr_old + 1], exp_list[ptr_old + 1],
                                Rw_list[ptr_old + 1], Pw_list[ptr_old + 1], Pw_old_list[ptr_old + 1]} <= '0;
                            {valid_list[ptr_old + 2], RegWr_list[ptr_old + 2], exp_list[ptr_old + 2],
                                Rw_list[ptr_old + 2], Pw_list[ptr_old + 2], Pw_old_list[ptr_old + 2]} <= '0;
                        end
                default:    ptr_old <= ptr_old;
            endcase
        end
    end

    assign  tag_ROB_x = ptr_young;
    assign  tag_ROB_y = ptr_young + 1;
    assign  tag_ROB_z = ptr_young + 2;

    assign  RegWr_x = RegWr_list[ptr_old];
    assign  RegWr_y = RegWr_x? RegWr_list[ptr_old + 1] : 0;
    assign  RegWr_z = (RegWr_x & RegWr_y)? RegWr_list[ptr_old + 2] : 0;

    assign  exp_x = exp_list[ptr_old];
    assign  exp_y = RegWr_x? exp_list[ptr_old + 1] : 0;
    assign  exp_z = (RegWr_x & RegWr_y)? exp_list[ptr_old + 2] : 0;

    assign  Pw_retire_x = Pw_old_list[ptr_old];
    assign  Pw_retire_y = RegWr_x? Pw_old_list[ptr_old + 1] : 0;
    assign  Pw_retire_z = (RegWr_x & RegWr_y)? Pw_old_list[ptr_old + 2] : 0;

    assign  Rw_commit_x = Rw_list[ptr_old];
    assign  Rw_commit_y = RegWr_x? Rw_list[ptr_old + 1] : 0;
    assign  Rw_commit_z = (RegWr_x & RegWr_y)? Rw_list[ptr_old + 2] : 0;

    assign  Pw_commit_x = Pw_list[ptr_old];
    assign  Pw_commit_y = RegWr_x? Pw_list[ptr_old + 1] : 0;
    assign  Pw_commit_z = (RegWr_x & RegWr_y)? Pw_list[ptr_old + 2] : 0;

endmodule