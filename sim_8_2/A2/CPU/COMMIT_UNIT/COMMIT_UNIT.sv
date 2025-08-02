module COMMIT_UNIT (
    input               clk,
    input               rst,
    input               flush_rob,
    input               stall_in,
    input               Conf,
    output              full_rob,

    // from front_end
    input               ready_pc_front      [2 : 0],
    input               RegWr_front         [2 : 0],
    input               isStore_front       [2 : 0],
    input   [31 : 0]    pc_front            [2 : 0],
    input               isBranch_front      [2 : 0],
    input               Predict_front       [2 : 0],
    input   [31 : 0]    target_branch_front [2 : 0],
    input   [ 4 : 0]    Rd_front            [2 : 0],
    input   [ 5 : 0]    Pd_front            [2 : 0],
    input   [ 5 : 0]    Pd_old_front        [2 : 0],
    input               has_excp_front      [2 : 0],
    input   [ 4 : 0]    excp_code_front     [2 : 0],
    input               csrWr_front         [2 : 0],
    input               isErtn_front        [2 : 0],
    input               isIdle_front        [2 : 0],

    // from back_end
    input               ready_cdb           [4 : 0],    // ALU, MDU, LSU, DIR, CSR
    input   [ 5 : 0]    tag_rob_Result      [5 : 0],    // ALU, MDU, LSU, DIR, CSR, BRU
    // from BRU
    input               ready_Branch_back,
    input               Branch_back,
    input               isJIRL_back,
    input   [31 : 0]    target_real,
    input               isJIRL_dir,
    // from LSU
    input               has_excp_lsu_back,
    input               excp_level_lsu_back,

    // ROB to inst_fetch
    output              isJIRL_rob,
    output              isBranch_rob,
    output              Branch_rob,
    output              Predict_rob,
    output  [31 : 0]    target_rob,
    output  [31 : 0]    pc_rob,
    // ROB to front_end
    output              ready_rob           [4 : 0],
    output              RegWr_rob           [4 : 0],
    output  [ 5 : 0]    Pd_old_rob          [4 : 0],
    // ROB to issue_queue
    output  [ 5 : 0]    ptr_old_out,
    output  [ 5 : 0]    tag_rob             [2 : 0],
    // ROB to LSU
    output              isStore_rob,
    // ROB to CSR
    output              isExcp_rob,
    output  [ 4 : 0]    excp_code_rob,
    output  [31 : 0]    pc_ertn_rob,
    output              csrWr_rob,
    output              isErtn_rob,
    output              isIdle_rob,

    // aRAT to sRAT
    output  [ 5 : 0]    P_list_arat         [31: 0],
    output  [63 : 0]    free_list_arat
);

    // ROB to aRAT
    wire    [ 5 : 0]    Pd_rob              [4 : 0];
    wire    [ 4 : 0]    Rd_rob              [4 : 0];

    ROB u_ROB (
        .clk                    (clk),
        .rst                    (rst),
        .flush_rob              (flush_rob),
        .stall_in               (stall_in),
        .Conf                   (Conf),
        .full_rob               (full_rob),

        // from front_end
        .ready_pc_front         (ready_pc_front),
        .RegWr_front            (RegWr_front),
        .isStore_front          (isStore_front),
        .pc_front               (pc_front),
        .isBranch_front         (isBranch_front),
        .Predict_front          (Predict_front),
        .target_branch_front    (target_branch_front),
        .Rd_front               (Rd_front),
        .Pd_front               (Pd_front),
        .Pd_old_front           (Pd_old_front),
        .has_excp_front         (has_excp_front),
        .excp_code_front        (excp_code_front),
        .csrWr_front            (csrWr_front),
        .isErtn_front           (isErtn_front),
        .isIdle_front           (isIdle_front),

        // from back_end
        .ready_cdb              (ready_cdb),        // ALU, MDU, LSU, DIR, CSR
        .tag_rob_Result         (tag_rob_Result),   // ALU, MDU, LSU, DIR, CSR, BRU
        // from BRU
        .ready_Branch_back      (ready_Branch_back),
        .Branch_back            (Branch_back),
        .isJIRL_back            (isJIRL_back),
        .target_real            (target_real),
        .isJIRL_dir             (isJIRL_dir),
        // from LSU
        .has_excp_lsu_back      (has_excp_lsu_back),
        .excp_level_lsu_back    (excp_level_lsu_back),

        // ROB to inst_fetch
        .isJIRL_rob             (isJIRL_rob),
        .isBranch_rob           (isBranch_rob),
        .Branch_rob             (Branch_rob),
        .Predict_rob            (Predict_rob),
        .target_rob             (target_rob),
        .pc_rob                 (pc_rob),
        // ROB to front_end
        .ready_rob              (ready_rob),
        .RegWr_rob              (RegWr_rob),
        .Pd_old_rob             (Pd_old_rob),
        // ROB to aRAT
        .Pd_rob                 (Pd_rob),
        .Rd_rob                 (Rd_rob),
        // ROB to issue_queue
        .ptr_old_out            (ptr_old_out),
        .tag_rob                (tag_rob),
        // ROB to LSU
        .isStore_rob            (isStore_rob),
        // ROB to CSR
        .isExcp_rob             (isExcp_rob),
        .excp_code_rob          (excp_code_rob),
        .pc_ertn_rob            (pc_ertn_rob),
        .csrWr_rob              (csrWr_rob),
        .isErtn_rob             (isErtn_rob),
        .isIdle_rob             (isIdle_rob)
    );

    ARAT u_ARAT (
        .clk                    (clk),
        .rst                    (rst),

        .ready_rob              (ready_rob),
        .RegWr_rob              (RegWr_rob),
        .Rd_rob                 (Rd_rob),
        .Pd_rob                 (Pd_rob),
        .Pd_old_rob             (Pd_old_rob),

        .P_list_arat            (P_list_arat),
        .free_list_arat         (free_list_arat)
    );

endmodule