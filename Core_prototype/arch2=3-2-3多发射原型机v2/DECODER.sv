module DECODER (
    input   [9 : 0]     inst,
    output  [2 : 0]     Ra,
    output  [2 : 0]     Rb,
    output  [2 : 0]     Rw,
    input               valid_pc,
    output              valid_add,
    output              valid_mul
);

    assign  {Rw, Ra, Rb} = inst[8 : 0];
    assign  valid_add = (valid_pc && inst[9] == 0)? 1 : 0;
    assign  valid_mul = (valid_pc && inst[9] == 1)? 1 : 0;

endmodule