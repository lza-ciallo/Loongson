//////////////////////////////////////////////////////////////////////////////////
// Company: Tsinghua University Electronic Engineering
// Engineer: Yuan
// 
// Create Date: 2025/06/20 12:59:46
// Design Name: Instruction Memory
// Module Name: IM
// Project Name: CPU_3_ver620
// Target Devices: NULL
// Tool Versions: NULL
// Description: 
//      A simple 4KB instruction memory       
//        
// Dependencies: NULL
// 
// Revision:1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IM (
    input wire clk,
    input wire [31:0] ReadAddr,  // access by Bytes 
    output reg [31:0] ReadInstr,
    output reg IMExp
);

  // 1024 * 4B = 4KB
  parameter IM_SIZE = 1024;
  reg [31:0] instr_array[0:IM_SIZE-1];

  // INIT
  initial begin
    $readmemh("prog.instr", instr_array);  // TODO
  end

  // ACCESS
  always @(posedge clk) begin
    if (ReadAddr[31:2] < IM_SIZE) begin
      ReadInstr <= instr_array[ReadAddr[31:2]];
      IMExp <= 0;
    end else begin  // EXCEPTIONS
      IMExp <= 1;
      ReadInstr <= 32'h00000000;
    end
  end
endmodule
