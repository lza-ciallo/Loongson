module CORE (
    input       clk,
    input       rst,
    output      stop
);

    wire    [3 : 0]     ARF_tag [7 : 0];

    wire    [3 : 0]     tag_PRF_add;
    wire    [3 : 0]     tag_PRF_mul;

    wire    [3 : 0]     tag_PRF_add_mid;
    wire    [3 : 0]     tag_ROB_add_mid;
    wire    [3 : 0]     tag_Ra_add_mid;
    wire    [3 : 0]     tag_Rb_add_mid;
    
    wire    [3 : 0]     tag_PRF_mul_mid;
    wire    [3 : 0]     tag_ROB_mul_mid;
    wire    [3 : 0]     tag_Ra_mul_mid;
    wire    [3 : 0]     tag_Rb_mul_mid;

    wire    [3 : 0]     tag_PRF;
    wire    [3 : 0]     tag_ROB;
    wire    [2 : 0]     Rw_reg;
    wire    [3 : 0]     tag_Rw_old;

    FRONT_END u_FRONT_END (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .full_PRF           (full_PRF),
        .full_ROB           (full_ROB),
        .ARF_tag            (ARF_tag),
        // 广播信号
        .valid_Result_add   (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul),
        // RS 输出信号
        .valid_add_out      (valid_add_mid),
        .tag_PRF_add_out    (tag_PRF_add_mid),
        .tag_ROB_add_out    (tag_ROB_add_mid),
        .tag_Ra_add_out     (tag_Ra_add_mid),
        .tag_Rb_add_out     (tag_Rb_add_mid),
        .valid_mul_out      (valid_mul_mid),
        .tag_PRF_mul_out    (tag_PRF_mul_mid),
        .tag_ROB_mul_out    (tag_ROB_mul_mid),
        .tag_Ra_mul_out     (tag_Ra_mul_mid),
        .tag_Rb_mul_out     (tag_Rb_mul_mid),
        // 预写入 ROB
        .tag_PRF_in         (tag_PRF),
        .tag_ROB_in         (tag_ROB),
        .Rw_reg             (Rw_reg),
        .valid_issue_reg    (valid_issue_reg),
        .tag_Rw_old         (tag_Rw_old)
    );

    BACK_END u_BACK_END (
        .clk                (clk),
        .rst                (rst),
        .stop               (stop),
        .valid_issue_reg    (valid_issue_reg),
        .full_PRF           (full_PRF),
        .full_ROB           (full_ROB),
        .tag_PRF            (tag_PRF),
        .tag_ROB            (tag_ROB),

        .tag_Ra_add         (tag_Ra_add_mid),
        .tag_Rb_add         (tag_Rb_add_mid),
        .tag_Ra_mul         (tag_Ra_mul_mid),
        .tag_Rb_mul         (tag_Rb_mul_mid),
        .tag_PRF_add_in     (tag_PRF_add_mid),
        .tag_PRF_mul_in     (tag_PRF_mul_mid),
        .tag_ROB_add_in     (tag_ROB_add_mid),
        .tag_ROB_mul_in     (tag_ROB_mul_mid),
        .valid_add          (valid_add_mid),
        .valid_mul          (valid_mul_mid),

        .valid_Result_add   (valid_Result_add),
        .tag_PRF_add        (tag_PRF_add),
        .valid_Result_mul   (valid_Result_mul),
        .tag_PRF_mul        (tag_PRF_mul),

        .ARF_tag            (ARF_tag),
        .Rw_reg             (Rw_reg),
        .tag_Rw_old         (tag_Rw_old)
    );

endmodule