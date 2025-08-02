`include "../defs.svh"

module FRONT_END (
    input               clk,
    input               rst,
    input               flush_id,
    input               stall_id,
    input               flush_srat,
    input               stall_srat,
    output              full_prf,

    input               has_int,
    input   [ 1 : 0]    plv,

    input               ready_pc        [2 : 0],
    input   [31 : 0]    pc              [2 : 0],
    input   [31 : 0]    inst            [2 : 0],
    input               isBranch        [2 : 0],
    input               Predict         [2 : 0],
    input   [31 : 0]    target_branch   [2 : 0],
    input               has_excp        [2 : 0],
    input   [ 4 : 0]    excp_code       [2 : 0],

    output              ready_pc_r      [2 : 0],
    output  [31 : 0]    imm_r           [2 : 0],
    output  [ 2 : 0]    Type_r          [2 : 0],
    output  [ 3 : 0]    Conf_r          [2 : 0],
    output              isImm_r         [2 : 0],
    output              RegWr_r         [2 : 0],
    output  [ 5 : 0]    Pj              [2 : 0],
    output              valid_Pj        [2 : 0],
    output  [ 5 : 0]    Pk              [2 : 0],
    output              valid_Pk        [2 : 0],
    output  [ 5 : 0]    Pd              [2 : 0],
    output  [ 5 : 0]    Pd_old          [2 : 0],
    output              valid_Pd_old    [2 : 0],
    output              has_excp_r      [2 : 0],
    output  [ 4 : 0]    excp_code_r     [2 : 0],
    output  [13 : 0]    csr_addr_r      [2 : 0],
    output              csrWr_r         [2 : 0],
    output              isErtn_r        [2 : 0],
    output              isIdle_r        [2 : 0],

    // from CDB to sRAT
    input               ready_cdb       [4 : 0],
    input               RegWr_cdb       [4 : 0],
    input   [ 5 : 0]    Pd_cdb          [4 : 0],
    // from ROB to sRAT
    input               ready_rob       [4 : 0],
    input               RegWr_rob       [4 : 0],
    input   [ 5 : 0]    Pd_old_rob      [4 : 0],
    // from aRAT to sRAT
    input   [ 5 : 0]    P_list_arat     [31: 0],
    input   [63 : 0]    free_list_arat,

    // from sRAT to ROB
    output              isStore_r       [2 : 0],
    output  [31 : 0]    pc_r            [2 : 0],
    output              isBranch_r      [2 : 0],
    output              Predict_r       [2 : 0],
    output  [31 : 0]    target_branch_r [2 : 0],
    output  [ 4 : 0]    Rd_r            [2 : 0]
    // output              RegWr_r         [2 : 0],    // mentioned above
    // output  [ 5 : 0]    Pd              [2 : 0],    // mentioned above
    // output  [ 5 : 0]    Pd_old          [2 : 0]     // mentioned above
);

    // main datastream
    wire    [ 4 : 0]    Rj              [2 : 0];
    wire    [ 4 : 0]    Rj_r            [2 : 0];

    wire    [ 4 : 0]    Rk              [2 : 0];
    wire    [ 4 : 0]    Rk_r            [2 : 0];

    wire    [ 4 : 0]    Rd              [2 : 0];
    wire    [31 : 0]    imm             [2 : 0];
    wire    [ 2 : 0]    Type            [2 : 0];
    wire    [ 3 : 0]    Conf            [2 : 0];
    wire                isImm           [2 : 0];
    wire                RegWr           [2 : 0];
    wire                isStore         [2 : 0];
    wire    [13 : 0]    csr_addr        [2 : 0];
    wire                csrWr           [2 : 0];
    wire                isErtn          [2 : 0];
    wire                isIdle          [2 : 0];

    // excp_id
    wire                has_excp_temp   [2 : 0];
    wire    [ 4 : 0]    excp_code_temp  [2 : 0];

    wire                has_excp_id     [2 : 0];
    wire    [ 4 : 0]    excp_code_id    [2 : 0];

    wire                RegWr_id        [2 : 0];
    wire                csrWr_id        [2 : 0];

    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  has_excp_id[i]  =   has_int? 1    : has_excp[i]? has_excp[i]  : has_excp_temp[i];
            assign  excp_code_id[i] =   has_int? `INT : has_excp[i]? excp_code[i] : excp_code_temp[i];
            assign  RegWr_id[i]     =   (has_excp_id[i] | ~ready_pc[i])? 0 : RegWr[i];
            assign  csrWr_id[i]     =   (has_excp_id[i] | ~ready_pc[i])? 0 : csrWr[i];
        end
    endgenerate

    // ID-rename register
    localparam  BW_ID   =   (5*3 + 32*3 + 3 + 4 + 1*6 + 5 + 14 + 1*4) * 3;
    wire    [BW_ID - 1 : 0]     bunch_ID;
    wire    [BW_ID - 1 : 0]     bunch_ID_r;
    assign  bunch_ID    =   {Rj[2], Rj[1], Rj[0],
                            Rk[2], Rk[1], Rk[0],
                            Rd[2], Rd[1], Rd[0],
                            imm[2], imm[1], imm[0],
                            pc[2], pc[1], pc[0],
                            target_branch[2], target_branch[1], target_branch[0],
                            Type[2], Type[1], Type[0],
                            Conf[2], Conf[1], Conf[0],
                            isImm[2], isImm[1], isImm[0],
                            RegWr_id[2], RegWr_id[1], RegWr_id[0],
                            isBranch[2], isBranch[1], isBranch[0],
                            Predict[2], Predict[1], Predict[0],
                            isStore[2], isStore[1], isStore[0],
                            has_excp_id[2], has_excp_id[1], has_excp_id[0],
                            excp_code_id[2], excp_code_id[1], excp_code_id[0],
                            csr_addr[2], csr_addr[1], csr_addr[0],
                            csrWr_id[2], csrWr_id[1], csrWr_id[0],
                            isErtn[2], isErtn[1], isErtn[0],
                            ready_pc[2], ready_pc[1], ready_pc[0],
                            isIdle[2], isIdle[1], isIdle[0]};
    assign  {Rj_r[2], Rj_r[1], Rj_r[0],
            Rk_r[2], Rk_r[1], Rk_r[0],
            Rd_r[2], Rd_r[1], Rd_r[0],
            imm_r[2], imm_r[1], imm_r[0],
            pc_r[2], pc_r[1], pc_r[0],
            target_branch_r[2], target_branch_r[1], target_branch_r[0],
            Type_r[2], Type_r[1], Type_r[0],
            Conf_r[2], Conf_r[1], Conf_r[0],
            isImm_r[2], isImm_r[1], isImm_r[0],
            RegWr_r[2], RegWr_r[1], RegWr_r[0],
            isBranch_r[2], isBranch_r[1], isBranch_r[0],
            Predict_r[2], Predict_r[1], Predict_r[0],
            isStore_r[2], isStore_r[1], isStore_r[0],
            has_excp_r[2], has_excp_r[1], has_excp_r[0],
            excp_code_r[2], excp_code_r[1], excp_code_r[0],
            csr_addr_r[2], csr_addr_r[1], csr_addr_r[0],
            csrWr_r[2], csrWr_r[1], csrWr_r[0],
            isErtn_r[2], isErtn_r[1], isErtn_r[0],
            ready_pc_r[2], ready_pc_r[1], ready_pc_r[0],
            isIdle_r[2], isIdle_r[1], isIdle_r[0]}  =   bunch_ID_r;

    DECODER u_DECODER (
        .plv                (plv),
        .pc                 (pc),
        .inst               (inst),
        .Rj                 (Rj),
        .Rk                 (Rk),
        .Rd                 (Rd),
        .imm                (imm),
        .Type               (Type),
        .Conf               (Conf),
        .isImm              (isImm),
        .RegWr              (RegWr),
        .isStore            (isStore),
        .has_excp           (has_excp_temp),
        .excp_code          (excp_code_temp),
        .csr_addr           (csr_addr),
        .csrWr              (csrWr),
        .isErtn             (isErtn),
        .isIdle             (isIdle)
    );

    REGISTER #(
        .BW                 (BW_ID)
    ) u_REG_ID_RENAME (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush_id),
        .stall              (stall_id),

        .data_in            (bunch_ID),
        .data_out           (bunch_ID_r)
    );

    SRAT u_SRAT (
        .clk                (clk),
        .rst                (rst),
        .flush_srat         (flush_srat),
        .stall_srat         (stall_srat),
        .full_prf           (full_prf),

        .Rj                 (Rj_r),
        .Rk                 (Rk_r),
        .Rd                 (Rd_r),
        .RegWr              (RegWr_r),
        .Pj                 (Pj),
        .valid_Pj           (valid_Pj),
        .Pk                 (Pk),
        .valid_Pk           (valid_Pk),
        .Pd                 (Pd),
        .Pd_old             (Pd_old),
        .valid_Pd_old       (valid_Pd_old),

        // from CDB (broadcast)
        .ready_cdb          (ready_cdb),
        .RegWr_cdb          (RegWr_cdb),
        .Pd_cdb             (Pd_cdb),
        // from ROB
        .ready_rob          (ready_rob),
        .RegWr_rob          (RegWr_rob),
        .Pd_old_rob         (Pd_old_rob),
        // from aRAT
        .P_list_arat        (P_list_arat),
        .free_list_arat     (free_list_arat)
    );

endmodule