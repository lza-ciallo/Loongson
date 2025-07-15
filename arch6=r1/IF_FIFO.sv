module IF_FIFO (
    input clk,
    input rst,
    
    input IF_pinch_off,
    input flush_IF_FIFO,

    input [31:0] pc[2:0],
    input [31:0] inst[2:0],
    input predict_valid[2:0],
    input predict[2:0],
    input [31:0] pc_unsel[2:0],
    input [9:0] pht_idx[2:0],

    output [31:0]   out_pc[2:0],
    output [31:0]   out_inst[2:0],
    output          out_predict_valid[2:0],
    output          out_predict[2:0],
    output [31:0]   out_pc_unsel[2:0],
    output [9:0]    out_pht_idx[2:0],

    output IF_FIFO_full
);


endmodule