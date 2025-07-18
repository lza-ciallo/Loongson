//////////////////////////////////////////////////////////////////////////////////
// Company: Tsinghua University Electronic Engineering
// Engineer: Yuan
// 
// Create Date: 2025/06/20 12:59:46
// Design Name: Data Memory
// Module Name: DM
// Project Name: CPU_3_ver620
// Target Devices: NULL
// Tool Versions: NULL
// Description: 
//      A simple 16KB Data Memory.
//        
// Dependencies: NULL
// 
// Revision:1
// Revision 0.01 - File Created
// Additional Comments:
// ! 理论上应该避免一个周期内同时进行读和写操作
// ! 假如如此使用，本模块将在同一个Address上进行读和写操作
// ! ReadData读到原值，并被写入新值
// TODO: 当前支持的是word读写，byte读、bit读该怎么做
//////////////////////////////////////////////////////////////////////////////////
module DM (
    input  wire        clk,
    input  wire [31:0] Addr,       // access by Bytes 
    input  wire [31:0] WriteData,
    input  wire        MemWr,
    input  wire        MemRead,
    output reg  [31:0] ReadData,
    output reg         DMExp
);

  // 4K * 4B = 16KB
  parameter MEM_SIZE = 1024 * 4;
  reg [31:0] data_array[0:MEM_SIZE-1];

  //INIT
  initial begin
    $readmemh("prog.mem", data_array);
  end

  // ACCESS
  always @(posedge clk) begin
    if (MemRead && Addr[31:2] < MEM_SIZE) begin
      ReadData <= data_array[Addr[31:2]];
    end
    if (MemWr && Addr[31:2] < MEM_SIZE) begin
      data_array[Addr[31:2]] <= WriteData;
    end

    // EXCEPTIONS
    if (Addr[31:2] >= MEM_SIZE) begin
      DMExp <= 1;
    end else begin
      DMExp <= 0;
    end
  end
endmodule
