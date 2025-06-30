module Forwarding_C (
    // EX/MEM
    input  wire [4:0] EX_MEM_Rt,
    // MEM/WB 
    input  wire       MEM_WB_RegWr,
    input  wire [4:0] MEM_WB_RegWrAddr,
    // FORWARDING
    output wire       forwardC1
);

  assign forwardC1 = (
    & MEM_WB_RegWr
    & (MEM_WB_RegWrAddr!=5'b0)
    & (MEM_WB_RegWrAddr == EX_MEM_Rt)
    )?1'b1:1'b0;

endmodule
