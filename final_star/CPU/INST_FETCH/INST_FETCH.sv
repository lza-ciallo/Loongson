`include "../defs.svh"

module INST_FETCH (
    input               clk,
    input               rst,
    input               flush_pc_branch,
    input               flush_pc_excp,
    input               flush_pc_ertn,
    input               flush_pc_idle,
    input               stall_pc,
    input               flush_ifr,
    input               stall_ifr,
    input               flush_ififo,
    input               stall_ififo,
    input               stall_if_request,
    input               flush_back,
    output              Jump,
    output              Miss,
    output              full_ififo,

    output              ready_pc_out        [2 : 0],
    output  [31 : 0]    pc_out              [2 : 0],
    output  [31 : 0]    inst_out            [2 : 0],
    output              isBranch_out        [2 : 0],
    output              Predict_out         [2 : 0],
    output  [31 : 0]    target_branch_out   [2 : 0],
    output              has_excp_out        [2 : 0],
    output  [ 4 : 0]    excp_code_out       [2 : 0],

    // from ROB to PC & BPU
    input               isJIRL_rob,
    input               isBranch_rob,
    input               Branch_rob,
    input   [31 : 0]    target_rob,
    input   [31 : 0]    pc_rob,

    // from CSR
    input   [31 : 0]    target_excp,
    input   [31 : 0]    target_ertn,

    // to/from IMEM
    output              MemRd_imem,
    output  [31 : 0]    pc_imem,
    input   [31 : 0]    inst                [3 : 0],
    input               find_inst           [3 : 0]
);

    // main datastream
    wire    [31 : 0]    pc                  [3 : 0];
    wire    [31 : 0]    pc_r                [3 : 0];

    wire                Hit                 [3 : 0];
    wire                Hit_r               [3 : 0];

    wire                Predict             [3 : 0];
    wire                Predict_r           [3 : 0];

    wire    [31 : 0]    target_branch       [3 : 0];
    wire    [31 : 0]    target_branch_r     [3 : 0];

    wire                has_excp            [3 : 0];
    wire                has_excp_r          [3 : 0];

    wire    [ 4 : 0]    excp_code           [3 : 0];
    wire    [ 4 : 0]    excp_code_r         [3 : 0];

    wire                Predict_shit        [3 : 0];
    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign  Predict_shit[i] =   Hit[i] & Predict[i];
        end
    endgenerate

    // to IMEM
    assign  MemRd_imem  =   (pc[0] < `IMEM_MIN || pc[3] > `IMEM_MAX || pc[0][1:0] != 2'b00)? 0 : 1;
    assign  pc_imem     =   pc[0];

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign  has_excp[i]     =   ~MemRd_imem;
            assign  excp_code[i]    =   has_excp[i]? `ADEF : '0;
        end
    endgenerate

    // from predecoder to PC
    wire    [31 : 0]    target_jump;
    wire    [31 : 0]    pc_miss;

    // from BPU to PC
    reg     [31 : 0]    target_branch_mask;

    assign  Predict_mask = (Hit[3] & Predict[3]) | (Hit[2] & Predict[2]) | (Hit[1] & Predict[1]) | (Hit[0] & Predict[0]);
    always @(*) begin
        casez ({Hit[3] & Predict[3], Hit[2] & Predict[2], Hit[1] & Predict[1], Hit[0] & Predict[0]})
            4'b???1:    target_branch_mask  =   target_branch[0];
            4'b??10:    target_branch_mask  =   target_branch[1];
            4'b?100:    target_branch_mask  =   target_branch[2];
            4'b1000:    target_branch_mask  =   target_branch[3];
            default:    target_branch_mask  =   '0;
        endcase
    end

    // from predecoder to BPU
    wire                dontWriteJIRL       [3 : 0];
    wire                isBranch            [3 : 0];
    wire    [31 : 0]    target_write        [3 : 0];

    // from predecoder to IFIFO
    wire                valid_inst          [3 : 0];

    PC u_PC (
        .clk                (clk),
        .rst                (rst),
        .flush_pc_branch    (flush_pc_branch),
        .flush_pc_excp      (flush_pc_excp),
        .flush_pc_ertn      (flush_pc_ertn),
        .flush_pc_idle      (flush_pc_idle),
        .stall_pc           (stall_pc),
        .full_ififo         (full_ififo),

        .pc                 (pc),

        // from ROB
        .Branch_rob         (Branch_rob),
        .target_rob         (target_rob),
        .pc_rob             (pc_rob),
        // from predecoder
        .Jump               (Jump),
        .target_jump        (target_jump),
        .Miss               (Miss),
        .pc_miss            (pc_miss),
        // from BPU
        .Predict            (Predict_mask),
        .target_branch      (target_branch_mask),
        // from CSR
        .target_excp        (target_excp),
        .target_ertn        (target_ertn)
    );

    BPU u_BPU (
        .clk                (clk),
        .rst                (rst),

        .pc                 (pc),
        .Hit                (Hit),
        .Predict            (Predict),
        .target_branch      (target_branch),
        
        // from ROB
        .isBranch_rob       (isBranch_rob),
        .Branch_rob         (Branch_rob),
        .pc_rob             (pc_rob),
        // from predecoder
        .dontWriteJIRL      (dontWriteJIRL),
        .isBranch           (isBranch),
        .pc_write           (pc_r),
        .target_write       (target_write),
        // JIRL from ROB
        .isJIRL_rob         (isJIRL_rob),
        .target_rob         (target_rob)
    );

    wire    [31 : 0]    inst_0          [3 : 0];
    wire                find_inst_0     [3 : 0];


    wire    [31 : 0]    inst_1          [3 : 0];
    wire                find_inst_1     [3 : 0];

    IFREG u_IFREG (
        .clk                (clk),
        .rst                (rst),
        .flush_ifr          (flush_ifr),
        .stall_ifr          (stall_ifr),
        .full_ififo         (full_ififo),
        .stall_if_request   (stall_if_request),
        .Jump               (Jump),
        .Miss               (Miss),
        .flush_back         (flush_back),

        .pc                 (pc),
        .Hit                (Hit),
        .Predict            (Predict_shit),
        .target_predict     (target_branch),
        .has_excp           (has_excp),
        .excp_code          (excp_code),
        .hint               (hint),
        .pc_out             (pc_r),
        .Hit_out            (Hit_r),
        .Predict_out        (Predict_r),
        .target_predict_out (target_branch_r),
        .has_excp_out       (has_excp_r),
        .excp_code_out      (excp_code_r),

        .inst               (inst),
        .find_inst          (find_inst),
        .inst_out           (inst_0),
        .find_inst_out      (find_inst_0),
        .cache_lock         (cache_lock)
    );

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            assign  find_inst_1[i]  =   cache_lock? find_inst_0[i] : find_inst[i];
            assign  inst_1[i]  =   cache_lock? inst_0[i] : inst[i];
        end
    endgenerate

    PREDECODER u_PREDECODER (
        .pc                 (pc_r),
        .inst               (inst_1),
        .find_inst          (find_inst_1),
        .hint               (hint),
        .Hit                (Hit_r),
        .Predict            (Predict_r),
        .target_predict     (target_branch_r),

        // to IFIFO
        .valid_inst         (valid_inst),
        // to PC and CTRL
        .Jump               (Jump),
        .target_jump        (target_jump),
        .Miss               (Miss),
        .pc_miss            (pc_miss),
        // to BPU
        .dontWriteJIRL      (dontWriteJIRL),
        .isBranch           (isBranch),
        .target_write       (target_write)
    );

    IFIFO u_IFIFO (
        .clk                (clk),
        .rst                (rst),
        .flush_ififo        (flush_ififo),
        .stall_ififo        (stall_ififo),
        .full_ififo         (full_ififo),

        .pc                 (pc_r),
        .inst               (inst_1),
        .isBranch           (isBranch),
        .Predict            (Predict_r),
        .target_branch      (target_write),
        .has_excp           (has_excp_r),
        .excp_code          (excp_code_r),
        .valid_inst         (valid_inst),

        .ready_pc_out       (ready_pc_out),
        .pc_out             (pc_out),
        .inst_out           (inst_out),
        .isBranch_out       (isBranch_out),
        .Predict_out        (Predict_out),
        .target_branch_out  (target_branch_out),
        .has_excp_out       (has_excp_out),
        .excp_code_out      (excp_code_out)
    );

endmodule