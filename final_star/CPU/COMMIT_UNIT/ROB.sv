`include "../defs.svh"

module ROB (
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
    // ROB to aRAT
    output  [ 5 : 0]    Pd_rob              [4 : 0],
    output  [ 4 : 0]    Rd_rob              [4 : 0],
    // ROB to issue_queue
    output  [ 5 : 0]    ptr_old_out,
    output  [ 5 : 0]    tag_rob             [2 : 0],
    // ROB to LSU
    output              isStore_rob,
    // ROB to CSR
    output              isExcp_rob,
    output  [ 4 : 0]    excp_code_rob,
    output  [31 : 0]    pc_ertn_rob,    // 发生例外后存到 CSR 里, ERTN 以之为跳转地址
    output              csrWr_rob,
    output              isErtn_rob,
    output              isIdle_rob,

    input   [31 : 0]    Result_dmem,
    output              va_error,
    output  [31 : 0]    bad_va
);

    typedef struct packed {
        reg     [31 : 0]    pc;
        reg     [31 : 0]    target_branch;
        reg     [ 4 : 0]    Rd;
        reg     [ 5 : 0]    Pd;
        reg     [ 5 : 0]    Pd_old;
        reg                 entry_occipied;
        reg                 ready;
        reg                 RegWr;
        reg                 isStore;
        reg                 isBranch;
        reg                 isJIRL;
        reg                 Predict;
        reg                 Branch;
        reg                 has_excp;
        reg     [ 4 : 0]    excp_code;
        reg                 csrWr;
        reg                 isErtn;
        reg                 isIdle;
    } rob_entry;

    rob_entry   rob_list    [63 : 0];

    reg     [5 : 0]     ptr_old;
    reg     [5 : 0]     ptr_young;

    assign  full_rob    =   ((tag_rob[0] == ptr_old || tag_rob[1] == ptr_old || tag_rob[2] == ptr_old) &&
                            (rob_list[ptr_old].entry_occipied == 1))? 1 : 0;
    assign  ptr_old_out =   ptr_old;

    // 预分配条目
    generate
        for (genvar i = 0; i < 3; i = i + 1) begin
            assign  tag_rob[i]  =   ptr_young + i;
        end
    endgenerate

    // 退休经过一层掩码
    wire    [5 : 0]     ptr_commit  [4 : 0];

    generate
        for (genvar i = 0; i < 5; i = i + 1) begin
            assign  ptr_commit[i]   =   ptr_old + i;
            assign  Pd_old_rob[i]   =   rob_list[ptr_commit[i]].Pd_old;
            assign  Pd_rob[i]       =   rob_list[ptr_commit[i]].Pd;
            assign  Rd_rob[i]       =   rob_list[ptr_commit[i]].Rd;
        end
    endgenerate
    
    assign  va_error    =   (rob_list[ptr_commit[0]].has_excp == 1) && (rob_list[ptr_commit[0]].excp_code == `ALE || rob_list[ptr_commit[0]].excp_code == `ADEF)? 1 : 0;
    assign  bad_va      =   (rob_list[ptr_commit[0]].excp_code == `ADEF)? rob_list[ptr_commit[0]].pc : rob_list[ptr_commit[0]].target_branch;

    reg     [4 : 0]     ready_vec;
    reg     [4 : 0]     RegWr_vec;
    reg     [4 : 0]     isBranch_vec;
    reg     [4 : 0]     isStore_vec;
    reg     [4 : 0]     isExcp_vec;
    reg     [4 : 0]     csrWr_vec;
    reg     [4 : 0]     isErtn_vec;
    reg     [4 : 0]     isIdle_vec;

    wire    [4 : 0]     ready_mask;
    wire    [2 : 0]     Branch_num;

    always @(*) begin
        casez ({rob_list[ptr_commit[4]].ready, rob_list[ptr_commit[3]].ready, rob_list[ptr_commit[2]].ready,
                rob_list[ptr_commit[1]].ready, rob_list[ptr_commit[0]].ready} &
               {rob_list[ptr_commit[4]].entry_occipied, rob_list[ptr_commit[3]].entry_occipied, rob_list[ptr_commit[2]].entry_occipied,
                rob_list[ptr_commit[1]].entry_occipied, rob_list[ptr_commit[0]].entry_occipied})
            5'b????0:   ready_vec   =   5'b00000;
            5'b???01:   ready_vec   =   5'b00001;
            5'b??011:   ready_vec   =   5'b00011;
            5'b?0111:   ready_vec   =   5'b00111;
            5'b01111:   ready_vec   =   5'b01111;
            5'b11111:   ready_vec   =   5'b11111;
            default:    ready_vec   =   5'b00000;
        endcase

        RegWr_vec       =   {rob_list[ptr_commit[4]].RegWr, rob_list[ptr_commit[3]].RegWr, rob_list[ptr_commit[2]].RegWr,
                             rob_list[ptr_commit[1]].RegWr, rob_list[ptr_commit[0]].RegWr};
        isBranch_vec    =   {rob_list[ptr_commit[4]].isBranch, rob_list[ptr_commit[3]].isBranch, rob_list[ptr_commit[2]].isBranch,
                             rob_list[ptr_commit[1]].isBranch, rob_list[ptr_commit[0]].isBranch};
        isStore_vec     =   {rob_list[ptr_commit[4]].isStore, rob_list[ptr_commit[3]].isStore, rob_list[ptr_commit[2]].isStore,
                             rob_list[ptr_commit[1]].isStore, rob_list[ptr_commit[0]].isStore};
        isExcp_vec      =   {rob_list[ptr_commit[4]].has_excp, rob_list[ptr_commit[3]].has_excp, rob_list[ptr_commit[2]].has_excp,
                             rob_list[ptr_commit[1]].has_excp, rob_list[ptr_commit[0]].has_excp};
        csrWr_vec       =   {rob_list[ptr_commit[4]].csrWr, rob_list[ptr_commit[3]].csrWr, rob_list[ptr_commit[2]].csrWr,
                             rob_list[ptr_commit[1]].csrWr, rob_list[ptr_commit[0]].csrWr};
        isErtn_vec      =   {rob_list[ptr_commit[4]].isErtn, rob_list[ptr_commit[3]].isErtn, rob_list[ptr_commit[2]].isErtn,
                             rob_list[ptr_commit[1]].isErtn, rob_list[ptr_commit[0]].isErtn};
        isIdle_vec      =   {rob_list[ptr_commit[4]].isIdle, rob_list[ptr_commit[3]].isIdle, rob_list[ptr_commit[2]].isIdle,
                             rob_list[ptr_commit[1]].isIdle, rob_list[ptr_commit[0]].isIdle};
    end

    MASK u_MASK (
        .Conf           (Conf),
        .ready_vec      (ready_vec),
        .isBranch_vec   (isBranch_vec),
        .isStore_vec    (isStore_vec),
        .isExcp_vec     (isExcp_vec),
        .csrWr_vec      (csrWr_vec),
        .isErtn_vec     (isErtn_vec),
        .isIdle_vec     (isIdle_vec),
        .ready_mask     (ready_mask),
        .Branch_num     (Branch_num),
        .find_Branch    (isBranch_rob),
        .find_Store     (isStore_rob),
        .find_Excp      (isExcp_rob),
        .find_csrWr     (csrWr_rob),
        .find_Ertn      (isErtn_rob),
        .find_Idle      (isIdle_rob)
    );

    assign  isJIRL_rob  =   isBranch_rob ? rob_list[ptr_commit[Branch_num]].isJIRL           : 0;
    assign  Branch_rob  =   isBranch_rob ? rob_list[ptr_commit[Branch_num]].Branch           : 0;
    assign  Predict_rob =   isBranch_rob ? rob_list[ptr_commit[Branch_num]].Predict          : 0;
    assign  target_rob  =   isBranch_rob ? rob_list[ptr_commit[Branch_num]].target_branch    : '0;
    assign  pc_rob      =   isBranch_rob ? rob_list[ptr_commit[Branch_num]].pc               : isIdle_rob? rob_list[ptr_commit[0]].pc : '0;
    
    assign  excp_code_rob   =   isExcp_rob? rob_list[ptr_commit[0]].excp_code   : '0;
    assign  pc_ertn_rob     =   isExcp_rob? rob_list[ptr_commit[0]].pc          : '0;

    generate
        for (genvar i = 0; i < 5; i = i + 1) begin
            assign  ready_rob[i]    =   (~(isBranch_rob && i > Branch_num && Branch_rob != Predict_rob))? ready_mask[i] : 0;
            assign  RegWr_rob[i]    =   RegWr_vec[i] & ready_mask[i] & ~isExcp_rob;
        end
    endgenerate

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (integer i = 0; i < 64; i = i + 1) begin
                rob_list[i]     <=  '0;
            end
            ptr_old             <=  '0;
            ptr_young           <=  '0;
        end
        else begin
            if (flush_rob) begin
                for (integer i = 0; i < 64; i = i + 1) begin
                    rob_list[i] <=  '0;
                end
                ptr_old         <=  '0;
                ptr_young       <=  '0;
            end
            else begin

                // 预写入
                if (!full_rob && !stall_in) begin
                    for (integer i = 0; i < 3; i = i + 1) begin
                        if (ready_pc_front[i]) begin
                            rob_list[tag_rob[i]]    <=  {pc_front[i], target_branch_front[i], Rd_front[i], Pd_front[i], Pd_old_front[i],
                                                        1'b1, 1'b0, RegWr_front[i], isStore_front[i], isBranch_front[i], 1'b0, Predict_front[i],
                                                        1'b0, has_excp_front[i], excp_code_front[i], csrWr_front[i], isErtn_front[i], isIdle_front[i]};
                        end
                    end
                    case ({ready_pc_front[2], ready_pc_front[1], ready_pc_front[0]})
                        3'b111:     ptr_young       <=  ptr_young + 3;
                        3'b011:     ptr_young       <=  ptr_young + 2;
                        3'b001:     ptr_young       <=  ptr_young + 1;
                        default:    ptr_young       <=  ptr_young;
                    endcase
                end

                // 写入广播结果
                for (integer i = 0; i < 5; i = i + 1) begin
                    if (ready_cdb[i] && !(i == 3 && isJIRL_dir)) begin
                        rob_list[tag_rob_Result[i]].ready           <=  1;
                    end
                end
                // JIRL 特殊写入
                if (ready_Branch_back) begin
                    rob_list[tag_rob_Result[5]].ready               <=  1;
                    if (isJIRL_back) begin
                        rob_list[tag_rob_Result[5]].isJIRL          <=  1;
                        rob_list[tag_rob_Result[5]].Branch          <=  1;
                        rob_list[tag_rob_Result[5]].Predict         <=  Branch_back;
                        rob_list[tag_rob_Result[5]].target_branch   <=  target_real;
                    end
                    else begin
                        rob_list[tag_rob_Result[5]].Branch          <=  Branch_back;
                    end
                end
                // LSU 异常特殊写入
                if (ready_cdb[2] && has_excp_lsu_back && rob_list[tag_rob_Result[2]].has_excp == 0) begin
                    rob_list[tag_rob_Result[2]].has_excp    <=  1;
                    rob_list[tag_rob_Result[2]].excp_code   <=  excp_level_lsu_back? `ALE : `ADEM;
                    rob_list[tag_rob_Result[2]].target_branch   <=  Result_dmem;
                end

                // 退休释放
                case ({ready_rob[4], ready_rob[3], ready_rob[2], ready_rob[1], ready_rob[0]})
                    5'b00001:   begin
                                rob_list[ptr_commit[0]]     <=  '0;
                                ptr_old                     <=  ptr_old + 1;
                                end
                    5'b00011:   begin
                                rob_list[ptr_commit[0]]     <=  '0;
                                rob_list[ptr_commit[1]]     <=  '0;
                                ptr_old                     <=  ptr_old + 2;
                                end
                    5'b00111:   begin
                                rob_list[ptr_commit[0]]     <=  '0;
                                rob_list[ptr_commit[1]]     <=  '0;
                                rob_list[ptr_commit[2]]     <=  '0;
                                ptr_old                     <=  ptr_old + 3;
                                end
                    5'b01111:   begin
                                rob_list[ptr_commit[0]]     <=  '0;
                                rob_list[ptr_commit[1]]     <=  '0;
                                rob_list[ptr_commit[2]]     <=  '0;
                                rob_list[ptr_commit[3]]     <=  '0;
                                ptr_old                     <=  ptr_old + 4;
                                end
                    5'b11111:   begin
                                rob_list[ptr_commit[0]]     <=  '0;
                                rob_list[ptr_commit[1]]     <=  '0;
                                rob_list[ptr_commit[2]]     <=  '0;
                                rob_list[ptr_commit[3]]     <=  '0;
                                rob_list[ptr_commit[4]]     <=  '0;
                                ptr_old                     <=  ptr_old + 5;
                                end
                    default:    ptr_old                     <=  ptr_old;
                endcase
            end
        end
    end

endmodule