module ROB (
    input               clk,
    input               rst,
    output  reg         stop,
    output              full,
    input               freeze_front,
    input               freeze_back,
    input               valid_issue,
    // 预写入 ROB
    input   [2 : 0]     Rw_reg,
    input   [4 : 0]     tag_PRF,
    output  [3 : 0]     tag_ROB,
    // 执行模块正式写入
    input               valid_add,
    input   [4 : 0]     tag_PRF_add,
    input   [3 : 0]     tag_ROB_add,
    input               valid_mul,
    input   [4 : 0]     tag_PRF_mul,
    input   [3 : 0]     tag_ROB_mul,
    input   [4 : 0]     tag_Rw_old,
    // 写入 ARF 并 retire
    output              RegWr_out,
    output  [2 : 0]     Rw_out,
    output  [4 : 0]     tag_PRF_out,
    output  [4 : 0]     tag_Rw_old_out
);

    reg     [15 : 0]    valid_list;
    reg     [15 : 0]    RegWr_list;
    reg     [2 : 0]     Rw_list [15 : 0];
    reg     [4 : 0]     tag_PRF_list [15 : 0];
    reg     [4 : 0]     tag_Rw_old_list [15 : 0];

    reg     [3 : 0]     ptr_old;
    reg     [3 : 0]     ptr_young;

    assign full = &valid_list;

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                valid_list[i] <= 0;
                RegWr_list[i] <= 0;
                Rw_list[i] <= '0;
                tag_PRF_list[i] <= '0;
                tag_Rw_old_list[i] <= '0;
            end
            ptr_old <= '0;
            ptr_young <= '0;
            stop <= 0;
        end

        else if (!stop) begin
            if (!freeze_front && valid_issue) begin
                valid_list[ptr_young] <= 1;
                Rw_list[ptr_young] <= Rw_reg;
                tag_Rw_old_list[ptr_young] <= tag_Rw_old;
                ptr_young <= ptr_young + 1;
            end

            if (!freeze_back && valid_add && valid_list[tag_ROB_add]) begin
                RegWr_list[tag_ROB_add] <= 1;
                tag_PRF_list[tag_ROB_add] <= tag_PRF_add;
            end
            if (!freeze_back && valid_mul && valid_list[tag_ROB_mul]) begin
                RegWr_list[tag_ROB_mul] <= 1;
                tag_PRF_list[tag_ROB_mul] <= tag_PRF_mul;
            end

            if (valid_list[ptr_old] == 1 && RegWr_list[ptr_old] == 1) begin
                if (Rw_list[ptr_old] == 0) begin
                    stop <= 1;
                end
                else begin
                    valid_list[ptr_old] <= 0;
                    RegWr_list[ptr_old] <= 0;
                    tag_PRF_list[ptr_old] <= '0;
                    Rw_list[ptr_old] <= '0;
                    tag_Rw_old_list[ptr_old] <= '0;
                    ptr_old <= ptr_old + 1;
                end
            end
        end

        else begin
            for (i = 0; i < 16; i = i + 1) begin
                valid_list[i] <= 0;
                RegWr_list[i] <= 0;
                Rw_list[i] <= '0;
                tag_Rw_old_list[i] <= '0;
                tag_PRF_list[i] <= '0;
            end
            ptr_old <= '0;
            ptr_young <= '0;
        end
    end

    assign  tag_ROB = ptr_young;
    assign  RegWr_out = RegWr_list[ptr_old];
    assign  Rw_out = Rw_list[ptr_old];
    assign  tag_PRF_out = tag_PRF_list[ptr_old];
    assign  tag_Rw_old_out = tag_Rw_old_list[ptr_old];
    
endmodule