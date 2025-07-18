`include "../defines.svh"

module pre_decoder (
    input   [31 : 0]    inst                [2 : 0],
    input   [31 : 0]    pc_ifr              [2 : 0],
    input               valid_inst_ifr,
    // 输入 BPU 的三条结果, 转换为一条
    input   [31 : 0]    target_predict_bpu  [2 : 0],
    input               valid_predict_bpu   [2 : 0],
    // 发射最优先的分支跳转
    output              isJump,
    output  [31 : 0]    target_jump,
    output              valid_predict,
    output  [31 : 0]    target_predict,
    // 写入 inst_fifo 的指令有效位
    output              valid_inst          [2 : 0]
);
    
    reg     [31 : 0]    target_jump_r;
    reg     [31 : 0]    target_predict_r;

    wire    [31 : 0]    target_jump_wire    [2 : 0];
    wire    [25 : 0]    offs                [2 : 0];

    reg     [ 2 : 0]    isJump_r;
    wire    [ 2 : 0]    valid_predict_r;

    integer count;

    assign  target_jump     =   target_jump_r;
    assign  target_predict  =   target_predict_r;
    
    // 逐条预解码
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  valid_predict_r[i]  =   valid_predict_bpu[i];
            assign  offs[i]             =   {inst[i][9 : 0], inst[i][25 : 10]};
            assign  target_jump_wire[i] =   pc_ifr[i] + {{4{offs[i][25]}}, offs[i], 2'b00};
            always @(*) begin
                casez (inst[i])
                    `B, `BL:    isJump_r[i] =   1;
                    default:    isJump_r[i] =   0;
                endcase
            end
        end
    endgenerate

    // 跳转地址, 选择最优先的
    always @(*) begin
        casez (isJump_r)
            3'b??1:     target_jump_r       =   target_jump_wire[0];
            3'b?10:     target_jump_r       =   target_jump_wire[1];
            3'b100:     target_jump_r       =   target_jump_wire[2];
            default:    target_jump_r       =   '0;
        endcase
        casez (valid_predict_r)
            3'b??1:     target_predict_r    =   target_predict_bpu[0];
            3'b?10:     target_predict_r    =   target_predict_bpu[1];
            3'b100:     target_predict_r    =   target_predict_bpu[2];
            default:    target_predict_r    =   '0;
        endcase
    end

    // 还需要选择是分支还是跳转
    always @(*) begin
        casez (isJump_r & valid_predict_r)
            3'b??1:     count   =   0;
            3'b?10:     count   =   1;
            3'b100:     count   =   2;
            default:    count   =   3;
        endcase
    end
    assign  isJump          =   (valid_inst_ifr && count == 3)? 0 : isJump_r[count];
    assign  valid_predict   =   (valid_inst_ifr && count == 3)? 0 : valid_predict_r[count];

    // 写入 FIFO 的指令有效位
    assign  valid_inst[0]   =   (valid_inst_ifr && count >= 0)? 1 : 0;
    assign  valid_inst[1]   =   (valid_inst_ifr && count >= 1)? 1 : 0;
    assign  valid_inst[2]   =   (valid_inst_ifr && count >= 2)? 1 : 0;

endmodule