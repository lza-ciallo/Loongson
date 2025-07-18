module Forwarding_B (
    // ID/EX
    input  wire [4:0] ID_EX_Rs,
    input  wire [4:0] ID_EX_Rt,
    // EX/MEM
    input  wire       EX_MEM_RegWr,
    input  wire [4:0] EX_MEM_RegWrAddr,
    // MEM/WB
    input  wire       MEM_WB_RegWr,
    input  wire [4:0] MEM_WB_RegWrAddr,
    // SIGNALS
    input  wire       Branch,
    // DORWARDING
    output wire [1:0] forwardB1,
    output wire [1:0] forwardB2
);

  wire fwd11;
  wire fwd12;
  wire fwd21;
  wire fwd22;

  assign fwd11 = EX_MEM_RegWr & (EX_MEM_RegWrAddr != 5'b0) & (EX_MEM_RegWrAddr == ID_EX_Rs);
  assign fwd12 = EX_MEM_RegWr & (EX_MEM_RegWrAddr != 5'b0) & (EX_MEM_RegWrAddr == ID_EX_Rt);
  assign fwd21 = MEM_WB_RegWr & (MEM_WB_RegWrAddr != 5'b0) & (MEM_WB_RegWrAddr == ID_EX_Rs);
  assign fwd22 = MEM_WB_RegWr & (MEM_WB_RegWrAddr != 5'b0) & (MEM_WB_RegWrAddr == ID_EX_Rt);

  assign forwardB1 = fwd11 ? 2'b01 : fwd21 ? 2'b10 : 2'b00;

  assign forwardB2 = fwd12 ? 2'b01 : fwd22 ? 2'b10 : 2'b00;

endmodule
