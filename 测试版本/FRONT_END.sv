module FRONT_END (
    input               clk,
    input               rst,
    input               stop,
    input               full_PRF,
    input               full_ROB,
    input   [3 : 0]     ARF_tag [7 : 0],
    // 广播信号
    input               valid_Result_add,
    input   [3 : 0]     tag_PRF_add,
    input               valid_Result_mul,
    input   [3 : 0]     tag_PRF_mul,
    // RS 输出信号
    output              valid_add_out,
    output  [3 : 0]     tag_PRF_add_out,
    output  [3 : 0]     tag_ROB_add_out,
    output  [3 : 0]     tag_Ra_add_out,
    output  [3 : 0]     tag_Rb_add_out,
    output              valid_mul_out,
    output  [3 : 0]     tag_PRF_mul_out,
    output  [3 : 0]     tag_ROB_mul_out,
    output  [3 : 0]     tag_Ra_mul_out,
    output  [3 : 0]     tag_Rb_mul_out,
    // 预写入 ROB
    input   [3 : 0]     tag_PRF_in,
    input   [3 : 0]     tag_ROB_in,
    output  [2 : 0]     Rw_reg,
    
    output              valid_issue_reg,
    output  [3 : 0]     tag_Rw_old
);

    wire    [7 : 0]     pc;
    wire    [9 : 0]     inst;
    wire    [9 : 0]     inst_reg;

    wire    [2 : 0]     Ra;
    wire    [2 : 0]     Rb;
    wire    [2 : 0]     Ra_reg;
    wire    [2 : 0]     Rb_reg;
    wire    [2 : 0]     Rw;

    wire    [3 : 0]     tag_Ra;
    wire    [3 : 0]     tag_Rb;

    localparam      IF_W    =   10 + 1;
    wire    [IF_W - 1 : 0]  bunch_IF;
    wire    [IF_W - 1 : 0]  bunch_IF_reg;
    assign  bunch_IF = {inst, valid_pc};
    assign  {inst_reg, valid_pc_reg} = bunch_IF_reg;

    localparam      ID_W    =   3 * 3 + 1 * 3;
    wire    [ID_W - 1 : 0]  bunch_ID;
    wire    [ID_W - 1 : 0]  bunch_ID_reg;
    assign  bunch_ID = {Ra, Rb, Rw, valid_issue, valid_add, valid_mul};
    assign  {Ra_reg, Rb_reg, Rw_reg, valid_issue_reg, valid_add_reg, valid_mul_reg} = bunch_ID_reg;

    assign stall = ((valid_pc_reg && !valid_issue) || stop)? 1 : 0;

    PC u_PC (
        .clk                (clk),
        .rst                (rst),
        .stall              (stall),
        .pc                 (pc),
        .valid_pc           (valid_pc)
    );

    INST_MEM u_INST_MEM (
        .rst                (rst),
        .pc                 (pc),
        .inst               (inst)
    );

    REGISTER #(
        .WIDTH              (IF_W)
    ) u_REG_IF_ID (
        .clk                (clk),
        .rst                (rst),
        .stall              (stall),
        .data_in            (bunch_IF),
        .data_out           (bunch_IF_reg)
    );

    DECODER u_DECODER (
        .inst               (inst_reg),
        .valid_pc           (valid_pc_reg),
        .Ra                 (Ra),
        .Rb                 (Rb),
        .Rw                 (Rw),
        .valid_add          (valid_add),
        .valid_mul          (valid_mul)
    );

    REGISTER #(
        .WIDTH              (ID_W)
    ) u_REG_ID_RENAME (
        .clk                (clk),
        .rst                (rst),
        .stall              (stall),
        .data_in            (bunch_ID),
        .data_out           (bunch_ID_reg)
    );

    RAT u_RAT (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .Ra                 (Ra_reg),
        .Rb                 (Rb_reg),
        .Rw                 (Rw_reg),
        .tag_PRF            (tag_PRF_in),
        .valid_issue        (valid_issue_reg),
        .valid_Ra           (valid_Ra),
        .tag_Ra             (tag_Ra),
        .valid_Rb           (valid_Rb),
        .tag_Rb             (tag_Rb),
        .valid_Result_add   (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul),
        .ARF_tag            (ARF_tag),
        .tag_Rw_old         (tag_Rw_old)
    );

    RS u_RS_ADD (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .full               (full_add),
        .valid_issue        (valid_issue_reg),
        .valid_opcode       (valid_add_reg),
        .tag_PRF            (tag_PRF_in),
        .tag_ROB            (tag_ROB_in),
        .valid_Ra           (valid_Ra),
        .tag_Ra             (tag_Ra),
        .valid_Rb           (valid_Rb),
        .tag_Rb             (tag_Rb),
        .valid_opcode_awake (valid_add_out),
        .tag_PRF_awake      (tag_PRF_add_out),
        .tag_ROB_awake      (tag_ROB_add_out),
        .tag_Ra_awake       (tag_Ra_add_out),
        .tag_Rb_awake       (tag_Rb_add_out),
        .valid_Result_add   (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul)
    );

    RS u_RS_MUL (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .full               (full_mul),
        .valid_issue        (valid_issue_reg),
        .valid_opcode       (valid_mul_reg),
        .tag_PRF            (tag_PRF_in),
        .tag_ROB            (tag_ROB_in),
        .valid_Ra           (valid_Ra),
        .tag_Ra             (tag_Ra),
        .valid_Rb           (valid_Rb),
        .tag_Rb             (tag_Rb),
        .valid_opcode_awake (valid_mul_out),
        .tag_PRF_awake      (tag_PRF_mul_out),
        .tag_ROB_awake      (tag_ROB_mul_out),
        .tag_Ra_awake       (tag_Ra_mul_out),
        .tag_Rb_awake       (tag_Rb_mul_out),
        .valid_Result_add   (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul)
    );

    ISSUE u_ISSUE (
        .valid_add          (valid_add),
        .valid_mul          (valid_mul),
        .full_add           (full_add),
        .full_mul           (full_mul),
        .full_ROB           (full_ROB),
        .full_PRF           (full_PRF),
        .valid_issue        (valid_issue)
    );

endmodule