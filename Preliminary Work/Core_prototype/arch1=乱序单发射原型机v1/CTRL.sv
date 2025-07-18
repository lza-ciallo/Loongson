module CTRL (
    input       valid_pc_reg_reg,
    input       valid_add_reg,
    input       valid_mul_reg,
    input       full_add,
    input       full_mul,

    input       full_PRF,
    input       full_ROB,

    output      freeze_front,
    output      freeze_back,
    output      valid_issue
);

    assign  valid_issue = (valid_pc_reg_reg && (valid_add_reg || valid_mul_reg))? 1 : 0;
    assign  freeze_back = (full_PRF || full_ROB)? 1 : 0;
    assign  freeze_front = (freeze_back || (full_add || full_mul))? 1 : 0;

endmodule