`include "../defs.svh"

module  PREDECODER (
    input   [31 : 0]    pc              [3 : 0],
    input   [31 : 0]    inst            [3 : 0],
    input               find_inst       [3 : 0],
    input               hint,
    input               Hit             [3 : 0],
    input               Predict         [3 : 0],
    input   [31 : 0]    target_predict  [3 : 0],

    // to IFIFO
    output              valid_inst      [3 : 0],
    // to PC and CTRL
    output              Jump,
    output  [31 : 0]    target_jump,
    output              Miss,
    output  [31 : 0]    pc_miss,
    // to BPU
    output              dontWriteJIRL   [3 : 0],
    output              isBranch        [3 : 0],
    output  [31 : 0]    target_write    [3 : 0]
);

    reg                 isJump_r        [3 : 0];
    reg                 isBranch_r      [3 : 0];
    reg                 dontWriteJIRL_r [3 : 0];

    wire    [15 : 0]    offs_low        [3 : 0];
    wire    [ 9 : 0]    offs_high       [3 : 0];

    wire                token           [3 : 0];
    reg                 valid_inst_r    [3 : 0];
    
    // generate Jump and Branch info
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            always @(*) begin
                casez (inst[i])
                    `B, `BL:                                {isJump_r[i], isBranch_r[i], dontWriteJIRL_r[i]} =   3'b100;
                    `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU:   {isJump_r[i], isBranch_r[i], dontWriteJIRL_r[i]} =   3'b010;
                    `JIRL:                                  {isJump_r[i], isBranch_r[i], dontWriteJIRL_r[i]} =   3'b011;
                    default:                                {isJump_r[i], isBranch_r[i], dontWriteJIRL_r[i]} =   3'b000;
                endcase
            end

            assign  offs_low[i]     =   inst[i][25 : 10];
            assign  offs_high[i]    =   inst[i][9 : 0];

            // Branch
            assign  dontWriteJIRL[i]    =   dontWriteJIRL_r[i];
            assign  isBranch[i]         =   isBranch_r[i];
            assign  target_write[i]     =   dontWriteJIRL[i]? target_predict[i] : pc[i] + {{14{offs_low[i][15]}}, offs_low[i], 2'b0};
        end
    endgenerate
    // Jump
    assign  Jump            =   (valid_inst[3] & isJump_r[3]) | (valid_inst[2] & isJump_r[2]) |
                                (valid_inst[1] & isJump_r[1]) | (valid_inst[0] & isJump_r[0]);
    assign  target_jump     =   (Jump == 0)? '0 :
                                (isJump_r[0] == 1)? pc[0] + {{4{offs_high[0][9]}}, offs_high[0], offs_low[0], 2'b0} :
                                (isJump_r[1] == 1)? pc[1] + {{4{offs_high[1][9]}}, offs_high[1], offs_low[1], 2'b0} :
                                (isJump_r[2] == 1)? pc[2] + {{4{offs_high[2][9]}}, offs_high[2], offs_low[2], 2'b0} :
                                (isJump_r[3] == 1)? pc[3] + {{4{offs_high[3][9]}}, offs_high[3], offs_low[3], 2'b0} : '0;

    // generate valid_inst
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign token[i] = (Hit[i] & Predict[i]) | isJump_r[i];
        end
    endgenerate

    always @(*) begin
        casez ({token[3], token[2], token[1], token[0]})
            4'b???1:    {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} =   4'b0001;
            4'b??10:    {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} =   4'b0011;
            4'b?100:    {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} =   4'b0111;
            4'b1000:    {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} =   4'b1111;
            default:    {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} =   4'b1111;
        endcase
    end

    assign  {valid_inst[3], valid_inst[2], valid_inst[1], valid_inst[0]} = (~hint)? '0 : 
            {valid_inst_r[3], valid_inst_r[2], valid_inst_r[1], valid_inst_r[0]} &
            {find_inst[3], find_inst[2], find_inst[1], find_inst[0]};

    // Icache miss
    assign  Miss    =   (~hint)? '0 :
            (valid_inst_r[3] & ~find_inst[3]) | (valid_inst_r[2] & ~find_inst[2]) |
            (valid_inst_r[1] & ~find_inst[1]) | (valid_inst_r[0] & ~find_inst[0]);

    assign  pc_miss =   (~hint)? '0 :
            (valid_inst_r[0] & ~find_inst[0])? pc[0] :
            (valid_inst_r[1] & ~find_inst[1])? pc[1] :
            (valid_inst_r[2] & ~find_inst[2])? pc[2] :
            (valid_inst_r[3] & ~find_inst[3])? pc[3] : '0;

endmodule