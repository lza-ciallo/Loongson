module CPU (
    input               clk,
    input               rst,
    input   [ 7 : 0]    interrupt,

    // to/from Icache
    output              MemRd_imem,
    output  [31 : 0]    pc_imem,
    input   [31 : 0]    inst        [3 : 0],
    input               find_inst   [3 : 0],
    input               stall_if_request,

    // to/from Dcache
    output              MemWr_dmem,
    output              MemRd_dmem,
    output  [31 : 0]    data_in_dmem,
    output  [31 : 0]    Addr_dmem,
    output  [ 3 : 0]    Conf_dmem,
    input   [31 : 0]    data_out_dmem,
    input               stall_mem_request,

    //debug interface
    output  [31 : 0]    debug_wb_pc,
    output  [ 3 : 0]    debug_wb_rf_wen,
    output  [ 4 : 0]    debug_wb_rf_wnum,
    output  [31 : 0]    debug_wb_rf_wdata
);

    // func test config
    wire    Conf_mask           =   1;      // 1: 配置 ROB.MASK 单提交; 0: 默认五提交
    assign  debug_wb_pc         =   u_COMMIT_UNIT.u_ROB.rob_list[u_COMMIT_UNIT.ptr_old_out].pc;
    assign  debug_wb_rf_wen     =   {4{u_COMMIT_UNIT.RegWr_rob[0]}};
    assign  debug_wb_rf_wnum    =   u_COMMIT_UNIT.u_ROB.Rd_rob[0];
    assign  debug_wb_rf_wdata   =   u_BACK_END.u_PRF.prf[u_COMMIT_UNIT.Pd_rob[0]];

    wire    [31 : 0]    Result_dmem;
    wire                va_error;
    wire    [31 : 0]    bad_va;

    // CSR
    wire                has_int;
    wire    [ 1 : 0]    plv;
    wire    [31 : 0]    target_excp;
    wire    [31 : 0]    target_ertn;
    wire    [63 : 0]    timer_64;
    wire    [31 : 0]    tid;

    wire    [13 : 0]    csrRd_addr;
    wire    [31 : 0]    data_csrRd;
    wire                csrWr;
    wire    [13 : 0]    csrWr_addr;
    wire    [31 : 0]    data_csrWr;

    wire    [ 4 : 0]    excp_code_rob;
    wire    [31 : 0]    pc_ertn_rob;
    wire                csrWr_rob;

    // CTRL
    wire                flush_pc_branch;
    wire                flush_pc_excp;
    wire                flush_pc_ertn;
    wire                flush_pc_idle;
    wire                stall_pc;
    wire                flush_ifr;
    wire                stall_ifr;
    wire                flush_ififo;
    wire                stall_ififo;
    wire                flush_id;
    wire                stall_id;
    wire                flush_srat;
    wire                stall_srat;
    wire                flush_queue;
    wire                stall_lsuq;
    wire                stall_csrq;
    wire                flush_back;
    wire                flush_lsu_out;
    wire                stall_in;
    wire                flush_rob;

    wire                Jump;
    wire                Miss;
    wire                full_ififo;
    wire                full_prf;
    wire                full_queue;
    wire                full_dfifo;
    wire                full_rob;
    wire                isExcp_rob;
    wire                isErtn_rob;
    wire                isIdle_rob;

    // inst_fetch to front_end
    wire                ready_pc_if         [2 : 0];
    wire    [31 : 0]    pc_if               [2 : 0];
    wire    [31 : 0]    inst_if             [2 : 0];
    wire                isBranch_if         [2 : 0];
    wire                Predict_if          [2 : 0];
    wire    [31 : 0]    target_branch_if    [2 : 0];
    wire                has_excp_if         [2 : 0];
    wire    [ 4 : 0]    excp_code_if        [2 : 0];

    // front_end to issue_queue
    wire                ready_pc_front      [2 : 0];
    wire    [31 : 0]    imm_front           [2 : 0];
    wire    [ 2 : 0]    Type_front          [2 : 0];
    wire    [ 3 : 0]    Conf_front          [2 : 0];
    wire                isImm_front         [2 : 0];
    wire                RegWr_front         [2 : 0];
    wire    [ 5 : 0]    Pj_front            [2 : 0];
    wire                valid_Pj_front      [2 : 0];
    wire    [ 5 : 0]    Pk_front            [2 : 0];
    wire                valid_Pk_front      [2 : 0];
    wire    [ 5 : 0]    Pd_front            [2 : 0];
    wire    [ 5 : 0]    Pd_old_front        [2 : 0];
    wire                valid_Pd_old_front  [2 : 0];
    wire                has_excp_front      [2 : 0];
    wire    [ 4 : 0]    excp_code_front     [2 : 0];
    wire    [13 : 0]    csr_addr_front      [2 : 0];
    wire                csrWr_front         [2 : 0];
    wire                isErtn_front        [2 : 0];
    wire                isIdle_front        [2 : 0];

    // issue_queue to back_end
    wire                ready_alu;
    wire    [ 5 : 0]    Pj_alu;
    wire    [ 5 : 0]    Pk_alu;
    wire    [ 5 : 0]    Pd_alu;
    wire    [31 : 0]    imm_alu;
    wire    [ 3 : 0]    Conf_alu;
    wire                isImm_alu;
    wire                RegWr_alu;
    wire    [ 5 : 0]    tag_rob_alu;

    wire                ready_mdu;
    wire    [ 5 : 0]    Pj_mdu;
    wire    [ 5 : 0]    Pk_mdu;
    wire    [ 5 : 0]    Pd_mdu;
    wire    [ 3 : 0]    Conf_mdu;
    wire                RegWr_mdu;
    wire    [ 5 : 0]    tag_rob_mdu;

    wire                ready_agu;
    wire    [ 5 : 0]    Pj_agu;
    wire    [31 : 0]    imm_agu;
    wire    [ 5 : 0]    tag_rob_agu;

    wire                ready_lsu;
    wire    [ 5 : 0]    Px_lsu;
    wire    [31 : 0]    Addr_lsu;
    wire    [ 3 : 0]    Conf_lsu;
    wire                RegWr_lsu;
    wire    [ 5 : 0]    tag_rob_lsu;
    wire                has_excp_lsu;

    wire                ready_bru;
    wire    [ 5 : 0]    Pj_bru;
    wire    [ 5 : 0]    Pd_old_bru;
    wire    [ 3 : 0]    Conf_bru;
    wire    [ 5 : 0]    tag_rob_bru;
    wire    [31 : 0]    target_predict_bru;
    wire    [31 : 0]    imm_bru;

    wire                ready_dir;
    wire    [31 : 0]    imm_dir;
    wire    [ 5 : 0]    Pd_dir;
    wire                RegWr_dir;
    wire    [ 3 : 0]    Conf_dir;
    wire    [ 5 : 0]    tag_rob_dir;
    wire                isJIRL_dir;     // 不经 back_end 直通 ROB, 对 DIR 来说是对的

    wire    [ 5 : 0]    tag_rob_csr;
    wire    [ 3 : 0]    Conf_csr;
    wire    [ 5 : 0]    Pj_csr;
    wire    [ 5 : 0]    Pd_old_csr;
    wire    [ 5 : 0]    Pd_csr;
    wire    [13 : 0]    csr_addr_csr;
    wire                ready_csr;
    wire                RegWr_csr;
    wire                csrWr_csr;

    // back_end to ROB
    wire    [ 5 : 0]    tag_rob_Result      [5 : 0];
    // BRU to ROB
    wire                ready_Branch_back;
    wire                Branch_back;
    wire                isJIRL_back;
    wire    [31 : 0]    target_real;
    // LSU to ROB
    wire                has_excp_lsu_back;
    wire                excp_level_lsu_back;

    // front_end to ROB
    wire                isStore_front       [2 : 0];
    wire    [31 : 0]    pc_front            [2 : 0];
    wire                isBranch_front      [2 : 0];
    wire                Predict_front       [2 : 0];
    wire    [31 : 0]    target_branch_front [2 : 0];
    wire    [ 4 : 0]    Rd_front            [2 : 0];

    // CDB to front_end & issue_queue & PRF & ROB
    wire                ready_cdb           [4 : 0];
    wire                RegWr_cdb           [4 : 0];
    wire    [ 5 : 0]    Pd_cdb              [4 : 0];

    // AGU to LSU_queue
    wire                ready_Addr;
    wire    [ 5 : 0]    tag_rob_Addr;
    wire    [31 : 0]    Addr;

    // ROB to inst_fetch
    wire                isJIRL_rob;
    wire                isBranch_rob;
    wire                Branch_rob;
    wire                Predict_rob;
    wire    [31 : 0]    target_rob;
    wire    [31 : 0]    pc_rob;
    // ROB to front_end
    wire                ready_rob           [4 : 0];
    wire                RegWr_rob           [4 : 0];
    wire    [ 5 : 0]    Pd_old_rob          [4 : 0];
    // ROB to issue_queue
    wire    [ 5 : 0]    ptr_old;
    wire    [ 5 : 0]    tag_rob             [2 : 0];
    // ROB to LSU
    wire                isStore_rob;

    // aRAT to front_end
    wire    [ 5 : 0]    P_list_arat         [31: 0];
    wire    [63 : 0]    free_list_arat;

    INST_FETCH u_INST_FETCH (
        .clk                (clk),
        .rst                (rst),
        .flush_pc_branch    (flush_pc_branch),
        .flush_pc_excp      (flush_pc_excp),
        .flush_pc_ertn      (flush_pc_ertn),
        .flush_pc_idle      (flush_pc_idle),
        .stall_pc           (stall_pc),
        .flush_ifr          (flush_ifr),
        .stall_ifr          (stall_ifr),
        .flush_ififo        (flush_ififo),
        .stall_ififo        (stall_ififo),
        .stall_if_request   (stall_if_request),
        .flush_back         (flush_back),
        .Jump               (Jump),
        .Miss               (Miss),
        .full_ififo         (full_ififo),

        .ready_pc_out       (ready_pc_if),
        .pc_out             (pc_if),
        .inst_out           (inst_if),
        .isBranch_out       (isBranch_if),
        .Predict_out        (Predict_if),
        .target_branch_out  (target_branch_if),
        .has_excp_out       (has_excp_if),
        .excp_code_out      (excp_code_if),

        // from ROB to PC & BPU
        .isJIRL_rob         (isJIRL_rob),
        .isBranch_rob       (isBranch_rob),
        .Branch_rob         (Branch_rob),
        .target_rob         (target_rob),
        .pc_rob             (pc_rob),

        // from CSR
        .target_excp        (target_excp),
        .target_ertn        (target_ertn),

        // to/from IMEM
        .MemRd_imem         (MemRd_imem),
        .pc_imem            (pc_imem),
        .inst               (inst),
        .find_inst          (find_inst)
    );

    FRONT_END u_FRONT_END (
        .clk                (clk),
        .rst                (rst),
        .flush_id           (flush_id),
        .stall_id           (stall_id),
        .flush_srat         (flush_srat),
        .stall_srat         (stall_srat),
        .full_prf           (full_prf),

        .has_int            (has_int),
        .plv                (plv),

        .ready_pc           (ready_pc_if),
        .pc                 (pc_if),
        .inst               (inst_if),
        .isBranch           (isBranch_if),
        .Predict            (Predict_if),
        .target_branch      (target_branch_if),
        .has_excp           (has_excp_if),
        .excp_code          (excp_code_if),

        .ready_pc_r         (ready_pc_front),
        .imm_r              (imm_front),
        .Type_r             (Type_front),
        .Conf_r             (Conf_front),
        .isImm_r            (isImm_front),
        .RegWr_r            (RegWr_front),
        .Pj                 (Pj_front),
        .valid_Pj           (valid_Pj_front),
        .Pk                 (Pk_front),
        .valid_Pk           (valid_Pk_front),
        .Pd                 (Pd_front),
        .Pd_old             (Pd_old_front),
        .valid_Pd_old       (valid_Pd_old_front),
        .has_excp_r         (has_excp_front),
        .excp_code_r        (excp_code_front),
        .csr_addr_r         (csr_addr_front),
        .csrWr_r            (csrWr_front),
        .isErtn_r           (isErtn_front),
        .isIdle_r           (isIdle_front),

        // from CDB to sRAT
        .ready_cdb          (ready_cdb),
        .RegWr_cdb          (RegWr_cdb),
        .Pd_cdb             (Pd_cdb),
        // from ROB to sRAT
        .ready_rob          (ready_rob),
        .RegWr_rob          (RegWr_rob),
        .Pd_old_rob         (Pd_old_rob),
        // from aRAT to sRAT
        .P_list_arat        (P_list_arat),
        .free_list_arat     (free_list_arat),

        // from sRAT to ROB
        .isStore_r          (isStore_front),
        .pc_r               (pc_front),
        .isBranch_r         (isBranch_front),
        .Predict_r          (Predict_front),
        .target_branch_r    (target_branch_front),
        .Rd_r               (Rd_front)
        // output              RegWr_r         [2 : 0],    // mentioned above
        // output  [ 5 : 0]    Pd              [2 : 0],    // mentioned above
        // output  [ 5 : 0]    Pd_old          [2 : 0]     // mentioned above
    );

    ISSUE_QUEUE u_ISSUE_QUEUE (
        .clk                (clk),
        .rst                (rst),
        .flush_queue        (flush_queue),
        .stall_in           (stall_in),
        .stall_lsuq         (stall_lsuq),
        .full_queue         (full_queue),

        .ready_pc           (ready_pc_front),
        .Pj                 (Pj_front),
        .valid_Pj           (valid_Pj_front),
        .Pk                 (Pk_front),
        .valid_Pk           (valid_Pk_front),
        .Pd                 (Pd_front),
        .Pd_old             (Pd_old_front),
        .valid_Pd_old       (valid_Pd_old_front),
        .imm                (imm_front),
        .Type               (Type_front),
        .Conf               (Conf_front),
        .isImm              (isImm_front),
        .RegWr              (RegWr_front),
        .pc                 (pc_front),
        .target_predict     (target_branch_front),
        .has_excp           (has_excp_front),
        .csr_addr           (csr_addr_front),
        .csrWr              (csrWr_front),

        .ready_alu          (ready_alu),
        .Pj_alu             (Pj_alu),
        .Pk_alu             (Pk_alu),
        .Pd_alu             (Pd_alu),
        .imm_alu            (imm_alu),
        .Conf_alu           (Conf_alu),
        .isImm_alu          (isImm_alu),
        .RegWr_alu          (RegWr_alu),
        .tag_rob_alu        (tag_rob_alu),

        .ready_mdu          (ready_mdu),
        .Pj_mdu             (Pj_mdu),
        .Pk_mdu             (Pk_mdu),
        .Pd_mdu             (Pd_mdu),
        .Conf_mdu           (Conf_mdu),
        .RegWr_mdu          (RegWr_mdu),
        .tag_rob_mdu        (tag_rob_mdu),

        .ready_agu          (ready_agu),
        .Pj_agu             (Pj_agu),
        .imm_agu            (imm_agu),
        .tag_rob_agu        (tag_rob_agu),

        .ready_lsu          (ready_lsu),
        .Px_lsu             (Px_lsu),
        .Addr_lsu           (Addr_lsu),
        .Conf_lsu           (Conf_lsu),
        .RegWr_lsu          (RegWr_lsu),
        .tag_rob_lsu        (tag_rob_lsu),
        .has_excp_lsu       (has_excp_lsu),

        .ready_bru          (ready_bru),
        .Pj_bru             (Pj_bru),
        .Pd_old_bru         (Pd_old_bru),
        .Conf_bru           (Conf_bru),
        .tag_rob_bru        (tag_rob_bru),
        .target_predict_bru (target_predict_bru),
        .imm_bru            (imm_bru),

        .ready_dir          (ready_dir),
        .imm_dir            (imm_dir),
        .Pd_dir             (Pd_dir),
        .RegWr_dir          (RegWr_dir),
        .Conf_dir           (Conf_dir),
        .tag_rob_dir        (tag_rob_dir),
        .isJIRL_dir         (isJIRL_dir),

        .tag_rob_csr        (tag_rob_csr),
        .Conf_csr           (Conf_csr),
        .Pj_csr             (Pj_csr),
        .Pd_old_csr         (Pd_old_csr),
        .Pd_csr             (Pd_csr),
        .csr_addr_csr       (csr_addr_csr),
        .ready_csr          (ready_csr),
        .RegWr_csr          (RegWr_csr),
        .csrWr_csr          (csrWr_csr),

        // from ROB
        .ptr_old            (ptr_old),
        .tag_rob            (tag_rob),
        .csrWr_rob          (csrWr_rob),

        // from CDB
        .ready_cdb          (ready_cdb),
        .RegWr_cdb          (RegWr_cdb),
        .Pd_cdb             (Pd_cdb),

        // from AGU
        .ready_Addr         (ready_Addr),
        .tag_rob_Addr       (tag_rob_Addr),
        .Addr               (Addr)
    );

    BACK_END u_BACK_END (
        .clk                (clk),
        .rst                (rst),
        .flush_back         (flush_back),
        .flush_lsu_out      (flush_lsu_out),
        .stall_lsuq         (stall_lsuq),
        .stall_mem_request  (stall_mem_request),
        .full_dfifo         (full_dfifo),

        .ready_alu          (ready_alu),
        .Pj_alu             (Pj_alu),
        .Pk_alu             (Pk_alu),
        .Pd_alu             (Pd_alu),
        .imm_alu            (imm_alu),
        .Conf_alu           (Conf_alu),
        .isImm_alu          (isImm_alu),
        .RegWr_alu          (RegWr_alu),
        .tag_rob_alu        (tag_rob_alu),

        .ready_mdu          (ready_mdu),
        .Pj_mdu             (Pj_mdu),
        .Pk_mdu             (Pk_mdu),
        .Pd_mdu             (Pd_mdu),
        .Conf_mdu           (Conf_mdu),
        .RegWr_mdu          (RegWr_mdu),
        .tag_rob_mdu        (tag_rob_mdu),

        .ready_agu          (ready_agu),
        .Pj_agu             (Pj_agu),
        .imm_agu            (imm_agu),
        .tag_rob_agu        (tag_rob_agu),

        .ready_lsu          (ready_lsu),
        .Px_lsu             (Px_lsu),
        .Addr_lsu           (Addr_lsu),
        .Conf_lsu           (Conf_lsu),
        .RegWr_lsu          (RegWr_lsu),
        .tag_rob_lsu        (tag_rob_lsu),
        .has_excp_lsu       (has_excp_lsu),

        .ready_bru          (ready_bru),
        .Pj_bru             (Pj_bru),
        .Pd_old_bru         (Pd_old_bru),
        .Conf_bru           (Conf_bru),
        .tag_rob_bru        (tag_rob_bru),
        .target_predict_bru (target_predict_bru),
        .imm_bru            (imm_bru),

        .ready_dir          (ready_dir),
        .imm_dir            (imm_dir),
        .Pd_dir             (Pd_dir),
        .RegWr_dir          (RegWr_dir),
        .Conf_dir           (Conf_dir),
        .tag_rob_dir        (tag_rob_dir),

        .tag_rob_csr        (tag_rob_csr),
        .Conf_csr           (Conf_csr),
        .Pj_csr             (Pj_csr),
        .Pd_old_csr         (Pd_old_csr),
        .Pd_csr             (Pd_csr),
        .csr_addr_csr       (csr_addr_csr),
        .ready_csr          (ready_csr),
        .RegWr_csr          (RegWr_csr),
        .csrWr_csr          (csrWr_csr),

        // CDB
        .ready_cdb          (ready_cdb),
        .RegWr_cdb          (RegWr_cdb),
        .Pd_cdb             (Pd_cdb),
        // back_end to ROB
        .tag_rob_Result     (tag_rob_Result),
        // BRU to ROB
        .ready_Branch       (ready_Branch_back),
        .Branch             (Branch_back),
        .isJIRL             (isJIRL_back),
        .target_real        (target_real),
        // LSU to ROB
        .has_excp_lsu_out   (has_excp_lsu_back),
        .excp_level_lsu_out (excp_level_lsu_back),

        // AGU to LSUQ
        .ready_Addr         (ready_Addr),
        .tag_rob_Addr       (tag_rob_Addr),
        .Addr               (Addr),
        // from ROB
        .isStore_rob        (isStore_rob),

        // to/from DMEM
        .MemWr_dmem         (MemWr_dmem),
        .MemRd_dmem         (MemRd_dmem),
        .data_in_dmem       (data_in_dmem),
        .Addr_dmem          (Addr_dmem),
        .Conf_dmem          (Conf_dmem),
        .data_out_dmem      (data_out_dmem),

        // CSR
        .timer_64           (timer_64),
        .tid                (tid),

        .csrRd_addr         (csrRd_addr),
        .data_csrRd         (data_csrRd),
        .csrWr              (csrWr),
        .csrWr_addr         (csrWr_addr),
        .data_csrWr         (data_csrWr),

        .Result_dmem        (Result_dmem)
    );

    COMMIT_UNIT u_COMMIT_UNIT (
        .clk                (clk),
        .rst                (rst),
        .flush_rob          (flush_rob),
        .stall_in           (stall_in),
        .Conf               (Conf_mask),
        .full_rob           (full_rob),

        // from front_end
        .ready_pc_front     (ready_pc_front),
        .RegWr_front        (RegWr_front),
        .isStore_front      (isStore_front),
        .pc_front           (pc_front),
        .isBranch_front     (isBranch_front),
        .Predict_front      (Predict_front),
        .target_branch_front(target_branch_front),
        .Rd_front           (Rd_front),
        .Pd_front           (Pd_front),
        .Pd_old_front       (Pd_old_front),
        .has_excp_front     (has_excp_front),
        .excp_code_front    (excp_code_front),
        .csrWr_front        (csrWr_front),
        .isErtn_front       (isErtn_front),
        .isIdle_front       (isIdle_front),

        // from back_end
        .ready_cdb          (ready_cdb),
        .tag_rob_Result     (tag_rob_Result),
        // from BRU
        .ready_Branch_back  (ready_Branch_back),
        .Branch_back        (Branch_back),
        .isJIRL_back        (isJIRL_back),
        .target_real        (target_real),
        .isJIRL_dir         (isJIRL_dir),
        // from LSU
        .has_excp_lsu_back  (has_excp_lsu_back),
        .excp_level_lsu_back(excp_level_lsu_back),

        // ROB to inst_fetch
        .isJIRL_rob         (isJIRL_rob),
        .isBranch_rob       (isBranch_rob),
        .Branch_rob         (Branch_rob),
        .Predict_rob        (Predict_rob),
        .target_rob         (target_rob),
        .pc_rob             (pc_rob),
        // ROB to front_end
        .ready_rob          (ready_rob),
        .RegWr_rob          (RegWr_rob),
        .Pd_old_rob         (Pd_old_rob),
        // ROB to issue_queue
        .ptr_old_out        (ptr_old),
        .tag_rob            (tag_rob),
        // ROB to LSU
        .isStore_rob        (isStore_rob),
        // ROB to CSR
        .isExcp_rob         (isExcp_rob),
        .excp_code_rob      (excp_code_rob),
        .pc_ertn_rob        (pc_ertn_rob),
        .csrWr_rob          (csrWr_rob),
        .isErtn_rob         (isErtn_rob),
        .isIdle_rob         (isIdle_rob),

        .Result_dmem        (Result_dmem),
        .va_error           (va_error),
        .bad_va             (bad_va),

        // aRAT to sRAT
        .P_list_arat        (P_list_arat),
        .free_list_arat     (free_list_arat)
    );

    CTRL u_CTRL (
        .clk                (clk),
        .rst                (rst),

        .stall_if_request   (stall_if_request),
        .stall_mem_request  (stall_mem_request),

        .Jump               (Jump),
        .Miss               (Miss),
        .full_ififo         (full_ififo),
        .full_prf           (full_prf),
        .full_queue         (full_queue),
        .full_dfifo         (full_dfifo),
        .full_rob           (full_rob),
        .isBranch_rob       (isBranch_rob),
        .Branch_rob         (Branch_rob),
        .Predict_rob        (Predict_rob),
        .isExcp_rob         (isExcp_rob),
        .isErtn_rob         (isErtn_rob),
        .isIdle_rob         (isIdle_rob),
        .has_int            (has_int),

        .flush_pc_branch    (flush_pc_branch),
        .flush_pc_excp      (flush_pc_excp),
        .flush_pc_ertn      (flush_pc_ertn),
        .flush_pc_idle      (flush_pc_idle),
        .stall_pc           (stall_pc),
        .flush_ifr          (flush_ifr),
        .stall_ifr          (stall_ifr),
        .flush_ififo        (flush_ififo),
        .stall_ififo        (stall_ififo),
        .flush_id           (flush_id),
        .stall_id           (stall_id),
        .flush_srat         (flush_srat),
        .stall_srat         (stall_srat),
        .flush_queue        (flush_queue),
        .stall_lsuq         (stall_lsuq),
        .flush_back         (flush_back),
        .flush_lsu_out      (flush_lsu_out),
        .stall_in           (stall_in),
        .flush_rob          (flush_rob)
    );
    
    csr_wrapper u_CSR (
        .clk                (clk),
        .rst                (rst),
        .flush_back         (flush_back),
        .csrWr_rob          (csrWr_rob),
        //from to ds 
        .rd_addr            (csrRd_addr),
        .rd_data            (data_csrRd),
        //timer 64
        .timer_64_out       (timer_64),
        .tid_out            (tid),
        //from ws
        .csr_wr_en          (csrWr),
        .wr_addr            (csrWr_addr),
        .wr_data            (data_csrWr),
        //interrupt
        .interrupt          (interrupt),
        .has_int            (has_int),
        //from ROB
        .excp_flush         (flush_pc_excp),
        .ertn_flush         (flush_pc_ertn),
        .era_in             (pc_ertn_rob),
        .excp_code_rob      (excp_code_rob),
        .va_error_in        (va_error),
        .bad_va_in          (bad_va),
        //to fs
        .eentry_out         (target_excp),
        .era_out            (target_ertn),
        //general use
        .plv_out            (plv)
    );

endmodule