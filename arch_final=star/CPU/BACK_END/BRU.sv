`include "../defs.svh"

module BRU (
    input                   clk,
    input                   rst,
    input                   flush_back,

    input       [31 : 0]    dataj,
    input       [31 : 0]    datad_old,
    input       [ 3 : 0]    Conf,
    input       [31 : 0]    imm,
    input       [31 : 0]    target_predict,
    output  reg             Branch_r,
    output  reg             isJIRL_r,
    output  reg [31 : 0]    target_real_r,

    input                   ready,
    input       [ 5 : 0]    tag_rob,
    output  reg             ready_r,
    output  reg [ 5 : 0]    tag_rob_r
);

    reg                     Branch;

    always @(*) begin
        case (Conf)
            `BEQ_CONF:  Branch  =   (dataj == datad_old)? 1 : 0;
            `BNE_CONF:  Branch  =   (dataj != datad_old)? 1 : 0;
            `BLT_CONF:  Branch  =   ($signed(dataj) < $signed(datad_old))? 1 : 0;
            `BGE_CONF:  Branch  =   ($signed(dataj) >= $signed(datad_old))? 1 : 0;
            `BLTU_CONF: Branch  =   ($unsigned(dataj) < $unsigned(datad_old))? 1 : 0;
            `BGEU_CONF: Branch  =   ($unsigned(dataj) >= $unsigned(datad_old))? 1 : 0;
            `JIRL_CONF: Branch  =   (dataj + imm == target_predict)? 1 : 0;     // 预测成功为 1, 预测失败为 0
            default:    Branch  =   0;
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            {Branch_r, ready_r, tag_rob_r, isJIRL_r, target_real_r}     <=  '0;
        end
        else begin
            if (flush_back) begin
                {Branch_r, ready_r, tag_rob_r, isJIRL_r, target_real_r} <=  '0;
            end
            else begin
                {Branch_r, ready_r, tag_rob_r}  <=  {Branch, ready, tag_rob};
                isJIRL_r                        <=  (Conf == `JIRL_CONF)? 1 : 0;
                target_real_r                   <=  dataj + imm;
            end
        end
    end

endmodule