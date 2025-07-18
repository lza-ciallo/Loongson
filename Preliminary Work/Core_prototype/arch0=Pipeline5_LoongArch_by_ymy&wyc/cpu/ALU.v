//////////////////////////////////////////////////////////////////////////////////
// Company: Tsinghua University
// Engineer: Yuan
// 
// Create Date: 2025/06/20 13:54:10
// Design Name: Algorithmic Logic Unit (ALU)
// Module Name: ALU
// Project Name: CPU_3_ver620
// Target Devices: NULL
// Tool Versions: NULL
// Description: 
//      This module implements the Algorithmic Logic Unit (ALU) for a CPU.
//      It supports plus, minus, and bitwise operations.
// Dependencies: NULL
// 
// Revision:1
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

`include "../defines/defines.v"

module ALU (
    // CONF
    input wire [4:0] ALUOp,
    // INPUT
    input wire [31:0] A,
    input wire [31:0] B,
    // OUTPUT
    output wire [31:0] Result,
    // EXCEPT
    output wire ALUExp
    // output reg Zero  //? 由于采用了提前分支预测，或许不需要zero
);





  // RESULTS
  wire [31:0] add_sub_res;
  wire [31:0] slt_res;
  wire [31:0] sltu_res;
  wire [31:0] and_res;
  wire [31:0] nor_res;
  wire [31:0] or_res;
  wire [31:0] xor_res;
  wire [31:0] sll_res;
  wire [31:0] sr_res;
  wire [31:0] lui_res;
  wire [31:0] mul_res;  // temp
  wire [31:0] andn_res;
  wire [31:0] orn_res;
  wire [63:0] sr64_result;
  wire [63:0] mul64_res;  // temp
  wire [31:0] div_res;  // temp

  // OVERFLOWS & EXCEPTIONS
  wire        add_ovf;
  wire        sub_ovf;
  wire        div_exc;


  // 32BIT ADDER
  wire [31:0] adder_a;
  wire [31:0] adder_b;
  wire        adder_cin;
  wire [31:0] adder_res;
  wire        adder_cout;

  assign adder_a = A;
  assign adder_b = (ALUOp == `ALU_SUB | ALUOp == `ALU_SLT | ALUOp == `ALU_SLTU) ? ~B : B;
  assign adder_cin = (ALUOp == `ALU_SUB | ALUOp == `ALU_SLT | ALUOp == `ALU_SLTU) ? 1'b1 : 1'b0;
  assign {adder_cout, adder_res} = adder_a + adder_b + adder_cin;


  // ADD, SUB  
  assign add_sub_res = adder_res;
  assign add_exc = (adder_a[31] ~^ adder_b[31]) & (adder_a[31] ^ adder_res[31]);
  assign sub_exc = (adder_a[31] ^ adder_b[31]) & (adder_a[31] ^ adder_res[31]);

  // SLT 
  assign slt_res = {31'b0, ((A[31] & ~B[31]) | ((A[31] ~^ B[31]) & A[31]))};

  // SLTU 
  assign sltu_res = {31'b0, ~adder_cout};

  // AND 
  assign and_res = A & B;

  // OR 
  assign or_res = A | B;

  // ANDN  
  assign andn_res = A & ~B;

  // ORN 
  assign orn_res = A | ~B;

  // NOR 
  assign nor_res = ~(A | B);

  // XOR 
  assign xor_res = A ^ B;

  // LUI 
  assign lui_res = B;

  // SLL 
  assign sll_res = A << B;

  // SRL, SRA 
  assign sr64_result = {{32{(ALUOp == `ALU_SRA) & A[31]}}, A[31:0]} >> B[4:0];
  assign sr_res = sr64_result[31:0];

  // MUL  //TODO
  assign mul64_res = A * B;
  assign mul_res = mul64_res[31:0];

  // DIV  //TODO
  assign div_res = A / B;
  assign div_exc = (B == 32'b0);

  // ALU result
  assign Result = ({32{ALUOp == `ALU_ADD}}   & add_sub_res
                  |{32{ALUOp == `ALU_SUB}}   & add_sub_res
                  |{32{ALUOp == `ALU_SLT}}   & slt_res
                  |{32{ALUOp == `ALU_SLTU}}  & sltu_res
                  |{32{ALUOp == `ALU_AND}}   & and_res
                  |{32{ALUOp == `ALU_NOR}}   & nor_res
                  |{32{ALUOp == `ALU_OR}}    & or_res
                  |{32{ALUOp == `ALU_XOR}}   & xor_res
                  |{32{ALUOp == `ALU_SLL}}   & sll_res
                  |{32{ALUOp == `ALU_SRL}}   & sr_res
                  |{32{ALUOp == `ALU_SRA}}   & sr_res
                  |{32{ALUOp == `ALU_LUI}}   & lui_res
                  |{32{ALUOp == `ALU_ANDN}}  & andn_res
                  |{32{ALUOp == `ALU_ORN}}   & orn_res
                  |{32{ALUOp == `ALU_MUL}}   & mul_res
                  |{32{ALUOp == `ALU_DIV}}   & div_res
                  |{32{ALUOp == `ALU_DEFAULT}} & 32'b0);

  // ALU exceptions
  assign ALUExp = ({1{ALUOp == `ALU_ADD}}    & add_ovf
                  |{1{ALUOp == `ALU_SUB}}    & sub_ovf
                  |{1{ALUOp == `ALU_DIV}}    & div_exc);


endmodule
