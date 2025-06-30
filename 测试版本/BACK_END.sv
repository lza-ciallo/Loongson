module BACK_END (
    input               clk,
    input               rst,
    output              stop,
    input               valid_issue_reg,
    output              full_PRF,
    output              full_ROB,
    output  [3 : 0]     tag_PRF,
    output  [3 : 0]     tag_ROB,

    input   [3 : 0]     tag_Ra_add,
    input   [3 : 0]     tag_Rb_add,
    input   [3 : 0]     tag_Ra_mul,
    input   [3 : 0]     tag_Rb_mul,
    input   [3 : 0]     tag_PRF_add_in,
    input   [3 : 0]     tag_PRF_mul_in,
    input   [3 : 0]     tag_ROB_add_in,
    input   [3 : 0]     tag_ROB_mul_in,
    input               valid_add,
    input               valid_mul,

    output              valid_Result_add,
    output  [3 : 0]     tag_PRF_add,
    output              valid_Result_mul,
    output  [3 : 0]     tag_PRF_mul,

    output  [3 : 0]     ARF_tag [7 : 0],

    input   [2 : 0]     Rw_reg,
    input   [3 : 0]     tag_Rw_old
);

    wire    [15 : 0]    busA_add;
    wire    [15 : 0]    busB_add;
    wire    [15 : 0]    busA_mul;
    wire    [15 : 0]    busB_mul;
    wire    [15 : 0]    busA_add_reg;
    wire    [15 : 0]    busB_add_reg;
    wire    [15 : 0]    busA_mul_reg;
    wire    [15 : 0]    busB_mul_reg;

    wire    [3 : 0]     tag_PRF_add_reg;
    wire    [3 : 0]     tag_PRF_mul_reg;
    wire    [3 : 0]     tag_ROB_add_reg;
    wire    [3 : 0]     tag_ROB_mul_reg;

    wire    [3 : 0]     tag_ROB_add;
    wire    [3 : 0]     tag_ROB_mul;

    localparam      READ_W  =   16 * 4 + 4 * 4 + 1 * 2;
    wire    [READ_W - 1 : 0]    bunch_READ;
    wire    [READ_W - 1 : 0]    bunch_READ_reg;
    assign  bunch_READ = {busA_add, busB_add, busA_mul, busB_mul, tag_PRF_add_in, tag_PRF_mul_in,
                            tag_ROB_add_in, tag_ROB_mul_in, valid_add, valid_mul};
    assign  {busA_add_reg, busB_add_reg, busA_mul_reg, busB_mul_reg, tag_PRF_add_reg, tag_PRF_mul_reg,
                            tag_ROB_add_reg, tag_ROB_mul_reg, valid_add_reg, valid_mul_reg} = bunch_READ_reg;

    wire    [15 : 0]    Result_add;
    wire    [15 : 0]    Result_mul;

    wire    [2 : 0]     Rw_ARF;
    wire    [3 : 0]     tag_PRF_ARF;
    wire    [3 : 0]     tag_Rw_old_out;

    assign  nop = 0;

    PRF u_PRF (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .valid_issue_reg    (valid_issue_reg),
        .full_PRF           (full_PRF),
        .tag_PRF            (tag_PRF),

        .tag_Ra_add         (tag_Ra_add),
        .tag_Rb_add         (tag_Rb_add),
        .tag_Ra_mul         (tag_Ra_mul),
        .tag_Rb_mul         (tag_Rb_mul),

        .busA_add           (busA_add),
        .busB_add           (busB_add),
        .busA_mul           (busA_mul),
        .busB_mul           (busB_mul),

        .valid_Result_add   (valid_Result_add),
        .Result_add         (Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .Result_mul         (Result_mul),
        .tag_PRF_mul        (tag_PRF_mul),

        .ARF_tag            (ARF_tag),
        .RegWr_ARF          (RegWr_ARF),
        .tag_PRF_ARF        (tag_PRF_ARF),
        .tag_Rw_old         (tag_Rw_old_out)
    );

    REGISTER #(
        .WIDTH              (READ_W)
    ) u_REG_READ_EX (
        .clk                (clk),
        .rst                (rst),
        .stall              (nop),
        .data_in            (bunch_READ),
        .data_out           (bunch_READ_reg)
    );

    ADD_UNIT u_ADD_UNIT (
        .clk                (clk),
        .rst                (rst),
        .busA               (busA_add_reg),
        .busB               (busB_add_reg),
        .valid_add          (valid_add_reg),
        .tag_PRF_add        (tag_PRF_add_reg),
        .tag_ROB_add        (tag_ROB_add_reg),

        .Result_add         (Result_add),
        .tag_PRF_add_reg    (tag_PRF_add),
        .tag_ROB_add_reg    (tag_ROB_add),
        .valid_Result_add   (valid_Result_add)
    );

    MUL_UNIT u_MUL_UNIT (
        .clk                (clk),
        .rst                (rst),
        .busA               (busA_mul_reg),
        .busB               (busB_mul_reg),
        .valid_mul          (valid_mul_reg),
        .tag_PRF_mul        (tag_PRF_mul_reg),
        .tag_ROB_mul        (tag_ROB_mul_reg),

        .Result_mul         (Result_mul),
        .tag_PRF_mul_reg    (tag_PRF_mul),
        .tag_ROB_mul_reg    (tag_ROB_mul),
        .valid_Result_mul   (valid_Result_mul)
    );

    ROB u_ROB (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .full               (full_ROB),
        // 预写入 ROB
        .Rw_reg             (Rw_reg),
        .valid_issue_reg    (valid_issue_reg),
        .tag_PRF            (tag_PRF),
        .tag_ROB            (tag_ROB),
        // 执行模块正式写入
        .valid_add          (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .tag_ROB_add        (tag_ROB_add),
        .valid_mul          (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul),
        .tag_ROB_mul        (tag_ROB_mul),
        .tag_Rw_old         (tag_Rw_old),
        // 写入 ARF 并 retire
        .RegWr_out          (RegWr_ARF),
        .Rw_out             (Rw_ARF),
        .tag_PRF_out        (tag_PRF_ARF),
        .tag_Rw_old_out     (tag_Rw_old_out)
    );

    ARF u_ARF (
        .clk                (clk),
        .rst                (rst),
        .RegWr              (RegWr_ARF),
        .Rw                 (Rw_ARF),
        .tag_PRF            (tag_PRF_ARF),

        .ARF_tag            (ARF_tag)
    );

endmodule