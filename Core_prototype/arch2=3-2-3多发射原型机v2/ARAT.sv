module ARAT (
    input               clk,
    input               rst,
    // ROB 端输入
    input               RegWr_x,
    input               RegWr_y,
    input               RegWr_z,
    input               exp_x,
    input               exp_y,
    input               exp_z,
    input       [2 : 0] Rw_commit_x,
    input       [2 : 0] Rw_commit_y,
    input       [2 : 0] Rw_commit_z,
    input       [4 : 0] Pw_commit_x,
    input       [4 : 0] Pw_commit_y,
    input       [4 : 0] Pw_commit_z,
    // 精确异常恢复
    output  reg [4 : 0] ARAT_P_list [7 : 0]
);

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                ARAT_P_list[i] <= i;
            end
        end
        else begin
            if (RegWr_x && !exp_x) begin
                if (!((RegWr_y && !exp_y && Rw_commit_x == Rw_commit_y) || (RegWr_z && !exp_z && Rw_commit_x == Rw_commit_z))) begin
                    ARAT_P_list[Rw_commit_x] <= Pw_commit_x;
                end
                if (RegWr_y && !exp_y) begin
                    if (!(RegWr_z && !exp_z && Rw_commit_y == Rw_commit_z)) begin
                        ARAT_P_list[Rw_commit_y] <= Pw_commit_y;
                    end
                    if (RegWr_z && !exp_z) begin
                        ARAT_P_list[Rw_commit_z] <= Pw_commit_z;
                    end
                end
            end
        end
    end

endmodule