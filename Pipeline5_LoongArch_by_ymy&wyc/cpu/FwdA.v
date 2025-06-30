module Forwarding_A (
    // IF/ID
    input  wire [4:0] IF_ID_Rs,
    input  wire [4:0] IF_ID_Rt,
    // EX/MEM
    input  wire       EX_MEM_RegWr,
    input  wire [4:0] EX_MEM_RegWrAddr,
    // SIGNALS
    input  wire       Branch,
    // FORWARDING
    output wire       forwardA1,
    output wire       forwardA2
);

  assign forwardA1 = (
    Branch
    & EX_MEM_RegWr
    & (EX_MEM_RegWrAddr!=5'b0)
    & (EX_MEM_RegWrAddr == IF_ID_Rs)
    )?1'b1:1'b0;
  assign forwardA2 = (
    Branch
    & EX_MEM_RegWr
    & (EX_MEM_RegWrAddr!=5'b0)
    & (EX_MEM_RegWrAddr == IF_ID_Rt)
    )?1'b1:1'b0;

endmodule
