// top_module.v
// **确保已经移除了此文件中的 initial 块**

module Bramtop (
    input clk
);

    // ----------------------------------------------------
    // 1. 定义连接到 BRAM 的信号
    // ----------------------------------------------------
    // 这些信号将由 testbench 通过层级引用来驱动
    reg          ena_a;
    reg  [0:0]   wea_a;       
    reg  [9:0]   addra_a;     
    reg  [7:0]   dina_a;      
    wire [7:0]   douta_a;     

    reg          enb_b;
    reg  [0:0]   web_b;       
    reg  [9:0]   addrb_b;
    reg  [7:0]   dinb_b;      
    wire [7:0]   doutb_b;
    
    // ----------------------------------------------------
    // 2. 例化 BRAM IP 核
    // ----------------------------------------------------
test_bram u_bram (
  .clka(clk),    // input wire clka
  .ena(ena_a),      // input wire ena
  .wea(wea_a),      // input wire [0 : 0] wea
  .addra(addra_a),  // input wire [9 : 0] addra
  .dina(dina_a),    // input wire [7 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(enb_b),      // input wire enb
  .addrb(addrb_b),  // input wire [9 : 0] addrb
  .doutb(doutb_b)  // output wire [7 : 0] doutb
);

endmodule
