module if_reg (
    input               clk,
    input               rst,
    input               stall_ifr,
    input               flush_ifr,
    // 管理跳转后下一周期的指令是否有效
    input   [31 : 0]    pc          [2 : 0],
    output  [31 : 0]    pc_ifr      [2 : 0],
    output              valid_inst
);

    reg     valid_inst_r;

    assign  valid_inst  =   valid_inst_r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            valid_inst_r        <=  '0;
            for (integer i = 0; i < 3; i = i + 1) begin
                pc_ifr[i]       <=  '0;
            end
        end
        else begin
            if (flush_ifr) begin
                valid_inst_r    <=  0;
                for (integer i = 0; i < 3; i = i + 1) begin
                    pc_ifr[i]   <=  '0;
                end
            end
            else if (stall_ifr) begin
                valid_inst_r    <=  valid_inst_r;
                for (integer i = 0; i < 3; i = i + 1) begin
                    pc_ifr[i]   <=  pc_ifr[i];
                end
            end
            else begin
                valid_inst_r    <=  1;
                for (integer i = 0; i < 3; i = i + 1) begin
                    pc_ifr[i]   <=  pc[i];
                end
            end
        end
    end

endmodule