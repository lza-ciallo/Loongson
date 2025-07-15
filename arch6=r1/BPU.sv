module BPU (
    input clk,
    input rst,
    input [31:0] pc[2:0],
    output [31:0] pc_predict[2:0],
    output predict_valid[2:0],
    output predict[2:0],
    output [31:0] pc_unsel[2:0],
    output [9:0] pht_idx[2:0],
    // BPU RENEW
    input [31:0] pc_decode[2:0],
    input [31:0] pc_branch[2:0],
    input btb_renew_en[2:0],
    input pht_renew_idx[4:0],
    input branch[4:0]
);


endmodule