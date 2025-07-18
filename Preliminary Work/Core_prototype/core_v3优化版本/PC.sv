module PC (
    input               clk,
    input               rst,
    input               freeze_front,
    output  reg [7 : 0] pc,
    output  reg         valid_pc        // 原型机 Rw=0 会造成异常, 未设 nop 指令, 需要额外信号标注初始化全0无效
);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            pc          <=  -3;
            valid_pc    <=  0;
        end
        else begin
            if (freeze_front) begin
                pc          <=  pc;
                valid_pc    <=  valid_pc;
            end
            else begin
                pc          <=  pc + 3;
                valid_pc    <=  1;
            end
        end
    end

endmodule