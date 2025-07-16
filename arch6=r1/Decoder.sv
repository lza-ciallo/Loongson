module Decoder (
    input [31:0] inst [2:0],
    input [31:0] pc [2:0],
    input predict_valid [2:0],
    // to FU
    output [2:0] fu_type[2:0],
    output [3:0] fu_conf[2:0],
    output [4:0] rk[2:0],
    output [4:0] rj[2:0],
    output [4:0] rd[2:0],
    output [31:0] imm[2:0],
    output is_imm[2:0],
    output regwr[2:0],
    // BTB RENEW
    output [31:0] pc_decode[2:0],
    output [31:0] pc_branch[2:0],
    output btb_renew_en[2:0]
);

endmodule
