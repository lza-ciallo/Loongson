module ISSUE (
    input       valid_add,
    input       valid_mul,
    input       full_add,
    input       full_mul,
    input       full_ROB,
    input       full_PRF,
    output      valid_issue
);

    assign valid_issue = (!full_ROB && !full_PRF && ((valid_add && !full_add) || (valid_mul && !full_mul)))? 1 : 0;

endmodule