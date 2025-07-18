module ImmEXT (
    input  wire [15:0] Imm,
    input  wire        ExtOp,
    output wire [31:0] ImmEXT
);

  assign ImmEXT = (ExtOp) ? {{16{Imm[15]}}, Imm[15:0]} : {16'b0, Imm[15:0]};

endmodule
