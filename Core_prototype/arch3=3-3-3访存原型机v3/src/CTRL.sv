module CTRL (
    input           full_PRF,
    input           full_ROB,
    input           full_FIFO,
    input           full_RS_add,
    input           full_RS_mul,
    input           full_RS_agu,
    input           full_LSQ,
    input           ready_ret   [2 : 0],
    input           excep_ret   [2 : 0],
    output          flush,
    output          freeze_front,
    output          freeze_back
);

    assign  flush           =   (ready_ret[0] == 1)? excep_ret[0] : 0;
    assign  freeze_front    =   full_PRF | full_ROB | full_FIFO | full_RS_add | full_RS_mul | full_RS_agu | full_LSQ;
    assign  freeze_back     =   full_FIFO;

endmodule