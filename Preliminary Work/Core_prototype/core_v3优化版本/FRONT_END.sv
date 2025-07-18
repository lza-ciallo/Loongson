module FRONT_END (
    input               clk,
    input               rst,
    input               flush,
    input               freeze_front,
    input               freeze_back,
    output              full_PRF,
    output              full_RS_add,
    output              full_RS_mul,
    output              full_RS_agu,
    output              full_LSQ,
    // ROB 预写入
    output              valid_pc_r_r,
    output  [ 1 : 0]    Type_r      [2 : 0],
    output  [ 4 : 0]    Pw          [2 : 0],
    output  [ 4 : 0]    Pw_old      [2 : 0],
    output  [ 2 : 0]    Rw_r        [2 : 0],
    // ROB 分配条目
    input   [ 4 : 0]    tag_ROB     [2 : 0],
    // RS_ADD 发射
    output              valid_add_awake,
    output  [ 4 : 0]    Pa_add_awake,
    output  [ 4 : 0]    Pb_add_awake,
    output  [ 4 : 0]    Pw_add_awake,
    output  [ 4 : 0]    tag_ROB_add_awake,
    // RS_MUL 发射
    output              valid_mul_awake,
    output  [ 4 : 0]    Pa_mul_awake,
    output  [ 4 : 0]    Pb_mul_awake,
    output  [ 4 : 0]    Pw_mul_awake,
    output  [ 4 : 0]    tag_ROB_mul_awake,
    // RS_AGU 发射
    output              valid_agu_awake,
    output  [ 4 : 0]    Pa_agu_awake,
    output  [ 4 : 0]    Imm_awake,
    output  [ 4 : 0]    tag_ROB_agu_awake,
    // LSQ 发射
    output              valid_ls_awake,
    output              mode_awake,
    output  [ 4 : 0]    Px_awake,
    output  [15 : 0]    Addr_awake,
    output  [ 4 : 0]    tag_ROB_ls_awake,
    // 接收广播
    input   [ 4 : 0]    Pw_Result_add,
    input               valid_Result_add,
    input   [ 4 : 0]    Pw_Result_mul,
    input               valid_Result_mul,
    input   [ 4 : 0]    Pw_Result_ls,
    input               valid_Result_ls,
    input               mode_ls,
    // 接收 AGU 特殊广播
    input               valid_Addr_agu,
    input   [ 4 : 0]    tag_ROB_Result_agu,
    input   [15 : 0]    Addr_agu,
    // ROB 退休
    input               ready_ret   [2 : 0],
    input               excep_ret   [2 : 0],
    input   [ 1 : 0]    Type_ret    [2 : 0],
    input   [ 4 : 0]    Pw_old_ret  [2 : 0],
    // 精确异常恢复
    input   [ 4 : 0]    ARAT_P_list [7 : 0],
    input   [31 : 0]    ARAT_freelist,
    // (新增) oldest-first 实现
    input   [ 4 : 0]    ptr_old     // +
);



    // IF-ID

    wire    [ 7 : 0]    pc;

    wire    [12 : 0]    inst        [2 : 0];
    wire    [12 : 0]    inst_r      [2 : 0];

    wire    [38 : 0]    inst_unfold, inst_unfold_r;
    assign  inst_unfold = {<<{inst}};
    assign  inst_r = {<<{inst_unfold_r}};

    localparam  BW_IF   =   39 + 1;
    wire    [BW_IF - 1 : 0]     bunch_IF, bunch_IF_r;
    assign  bunch_IF = {inst_unfold, valid_pc};
    assign  {inst_unfold_r, valid_pc_r} = bunch_IF_r;

    // ID-RENAME

    wire    [ 1 : 0]    Type        [2 : 0];
    wire    [ 2 : 0]    Ra          [2 : 0];
    wire    [ 2 : 0]    Rb          [2 : 0];
    wire    [ 2 : 0]    Rw          [2 : 0];
    wire    [ 4 : 0]    Imm         [2 : 0];

    // wire    [ 1 : 0]    Type_r      [2 : 0];    // output 预写入 ROB
    wire    [ 2 : 0]    Ra_r        [2 : 0];
    wire    [ 2 : 0]    Rb_r        [2 : 0];
    // wire    [ 2 : 0]    Rw_r        [2 : 0];    // output 预写入 ROB
    wire    [ 4 : 0]    Imm_r       [2 : 0];

    wire    [ 5 : 0]    Type_unfold, Type_unfold_r;
    assign  Type_unfold = {<<{Type}};
    assign  Type_r = {<<{Type_unfold_r}};
    wire    [ 8 : 0]    Ra_unfold, Ra_unfold_r;
    assign  Ra_unfold = {<<{Ra}};
    assign  Ra_r = {<<{Ra_unfold_r}};
    wire    [ 8 : 0]    Rb_unfold, Rb_unfold_r;
    assign  Rb_unfold = {<<{Rb}};
    assign  Rb_r = {<<{Rb_unfold_r}};
    wire    [ 8 : 0]    Rw_unfold, Rw_unfold_r;
    assign  Rw_unfold = {<<{Rw}};
    assign  Rw_r = {<<{Rw_unfold_r}};
    wire    [14 : 0]    Imm_unfold, Imm_unfold_r;
    assign  Imm_unfold = {<<{Imm}};
    assign  Imm_r = {<<{Imm_unfold_r}};

    localparam  BW_ID   =   6 + 9*3 + 15 + 1;
    wire    [BW_ID - 1 : 0]     bunch_ID, bunch_ID_r;
    assign  bunch_ID = {Type_unfold, Ra_unfold, Rb_unfold, Rw_unfold, Imm_unfold, valid_pc_r};
    assign  {Type_unfold_r, Ra_unfold_r, Rb_unfold_r, Rw_unfold_r, Imm_unfold_r, valid_pc_r_r} = bunch_ID_r;

    // RENAME-ISSUE

    wire    [ 4 : 0]    Pa          [2 : 0];
    wire    [ 4 : 0]    Pb          [2 : 0];
    // wire    [ 4 : 0]    Pw          [2 : 0];    // output 预写入 ROB
    wire                valid_Pa    [2 : 0];
    wire                valid_Pb    [2 : 0];

    wire    [ 2 : 0]    tag_Addr    [2 : 0];

    wire    [ 1 : 0]    Type_ref_add, Type_ref_mul;
    assign  Type_ref_add = 2'b00;
    assign  Type_ref_mul = 2'b01;

    genvar  gv_i;



    PC u_PC (
        .clk                (clk),
        .rst                (rst),
        .freeze_front       (freeze_front),
        .pc                 (pc),
        .valid_pc           (valid_pc)
    );

    INST_MEM u_INST_MEM (
        .pc                 (pc),
        .inst               (inst)
    );

    REGISTER #(
        .BW                 (BW_IF)
    ) u_REG_IF_ID (
        .clk                (clk),
        .rst                (rst),
        .stall              (freeze_front),
        .flush              (flush),
        .data_in            (bunch_IF),
        .data_out           (bunch_IF_r)
    );

    generate
        for (gv_i = 0; gv_i < 3; gv_i = gv_i + 1) begin
            DECODER u_DECODER (
                .inst       (inst_r[gv_i]),
                .Type       (Type[gv_i]),
                .Ra         (Ra[gv_i]),
                .Rb         (Rb[gv_i]),
                .Rw         (Rw[gv_i]),
                .Imm        (Imm[gv_i])
            );
        end
    endgenerate

    REGISTER #(
        .BW                 (BW_ID)
    ) u_REG_ID_RENAME (
        .clk                (clk),
        .rst                (rst),
        .stall              (freeze_front),
        .flush              (flush),
        .data_in            (bunch_ID),
        .data_out           (bunch_ID_r)
    );

    SRAT u_SRAT (
        .clk                (clk),
        .rst                (rst),
        .freeze_front       (freeze_front),
        .valid_pc           (valid_pc_r_r),
        .full_PRF           (full_PRF),
        // x,y,z 端口读写
        .Type               (Type_r),
        .Ra                 (Ra_r),
        .Rb                 (Rb_r),
        .Rw                 (Rw_r),
        .Pa                 (Pa),
        .Pb                 (Pb),
        .Pw                 (Pw),
        .Pw_old             (Pw_old),
        .valid_Pa           (valid_Pa),
        .valid_Pb           (valid_Pb),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        // LS 广播
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // ROB 退休
        .ready_ret          (ready_ret),
        .excep_ret          (excep_ret),
        .Type_ret           (Type_ret),
        .Pw_old_ret         (Pw_old_ret),
        // 精确异常恢复
        .flush              (flush),
        .ARAT_P_list        (ARAT_P_list),
        .ARAT_freelist      (ARAT_freelist)
    );

    RS u_RS_ADD (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .valid_pc           (valid_pc_r_r),
        .full_RS            (full_RS_add),
        // RS 类型实例化, 仅 ADD / MUL
        .Type_ref           (Type_ref_add),
        // x,y,z 端口写入
        .Type               (Type_r),
        .Pa                 (Pa),
        .Pb                 (Pb),
        .Pw                 (Pw),
        .valid_Pa           (valid_Pa),
        .valid_Pb           (valid_Pb),
        .tag_ROB            (tag_ROB),
        // 唤醒
        .valid_op_awake     (valid_add_awake),
        .Pa_awake           (Pa_add_awake),
        .Pb_awake           (Pb_add_awake),
        .Pw_awake           (Pw_add_awake),
        .tag_ROB_awake      (tag_ROB_add_awake),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        // LS 广播
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // (新增) oldest-first 实现
        .ptr_old            (ptr_old)   // +
    );

    RS u_RS_MUL (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .valid_pc           (valid_pc_r_r),
        .full_RS            (full_RS_mul),
        // RS 类型实例化, 仅 ADD / MUL
        .Type_ref           (Type_ref_mul),
        // x,y,z 端口写入
        .Type               (Type_r),
        .Pa                 (Pa),
        .Pb                 (Pb),
        .Pw                 (Pw),
        .valid_Pa           (valid_Pa),
        .valid_Pb           (valid_Pb),
        .tag_ROB            (tag_ROB),
        // 唤醒
        .valid_op_awake     (valid_mul_awake),
        .Pa_awake           (Pa_mul_awake),
        .Pb_awake           (Pb_mul_awake),
        .Pw_awake           (Pw_mul_awake),
        .tag_ROB_awake      (tag_ROB_mul_awake),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        // LS 广播
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // (新增) oldest-first 实现
        .ptr_old            (ptr_old)   // +
    );

    RS_AGU u_RS_AGU (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .valid_pc           (valid_pc_r_r),
        .full_RS            (full_RS_agu),
        // x,y,z 端口写入
        .Type               (Type_r),
        .Pa                 (Pa),
        .valid_Pa           (valid_Pa),
        .Imm                (Imm_r),
        .tag_ROB            (tag_ROB),
        // 唤醒
        .valid_op_awake     (valid_agu_awake),
        .Pa_awake           (Pa_agu_awake),
        .Imm_awake          (Imm_awake),
        .tag_ROB_awake      (tag_ROB_agu_awake),
        // ADD 广播
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        // MUL 广播
        .Pw_Result_mul      (Pw_Result_add),
        .valid_Result_mul   (valid_Result_add),
        // LS 广播
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // (新增) oldest-first 实现
        .ptr_old            (ptr_old)   // +
    );

    LSQ u_LSQ (
        .clk                (clk),
        .rst                (rst),
        .flush              (flush),
        .freeze_front       (freeze_front),
        .freeze_back        (freeze_back),
        .valid_pc           (valid_pc_r_r),
        .full_LSQ           (full_LSQ),
        // x,y,z 端口写入
        .Type               (Type_r),
        .Pb                 (Pb),
        .valid_Pb           (valid_Pb),
        .Pw                 (Pw),
        .tag_ROB            (tag_ROB),
        // 唤醒
        .valid_op_awake     (valid_ls_awake),
        .mode_awake         (mode_awake),
        .Px_awake           (Px_awake),
        .Addr_awake         (Addr_awake),
        .tag_ROB_awake      (tag_ROB_ls_awake),
        // 来自 FU 的广播, 唤醒 Px
        .Pw_Result_add      (Pw_Result_add),
        .valid_Result_add   (valid_Result_add),
        .Pw_Result_mul      (Pw_Result_mul),
        .valid_Result_mul   (valid_Result_mul),
        .Pw_Result_ls       (Pw_Result_ls),
        .valid_Result_ls    (valid_Result_ls),
        .mode_ls            (mode_ls),
        // 来自 AGU 的广播, 唤醒 Addr
        .valid_Addr_agu     (valid_Addr_agu),
        .tag_ROB_Result_agu (tag_ROB_Result_agu),
        .Addr_agu           (Addr_agu)
    );

endmodule