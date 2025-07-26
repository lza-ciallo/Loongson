// `timescale 1ns/1ps
module cache_test_top (
    input         clk, 
    input         rst,
    // ICache测试接口
    output [31:0] inst [3:0],                  // 输出四条指令 [监视]
    output        stall_if_request,           // 面向控制单元的stall信号  [监视]
    output [ 2:0] inst_size,                  // 告知控制单元取来了几条有效指令  [监视]
    input  [31:0] pc,                         // 当前指令地址 [配置]
    input         Rena,                       // 读使能信号   [配置]
    output        Rdone,                      // 读完成信号   [监视]
    
    // DCache测试接口
    input  [31:0] dcache_wdata_in,            // DCache写数据输入
    input  [31:0] dcache_waddr_in,            // DCache写地址输入
    input         dcache_wena_in,             // DCache写使能输入
    input  [1:0]  dcache_wsize_in,            // DCache写大小输入
    input  [3:0]  dcache_wmask_in,            // DCache写掩码输入
    output        dcache_wdone,               // DCache写完成输出
    output [31:0] dcache_rdata_out,           // DCache读数据输出
    input  [31:0] dcache_raddr_in,            // DCache读地址输入
    input         dcache_rena_in,             // DCache读使能输入
    input  [1:0]  dcache_rsize_in,            // DCache读大小输入
    output [3:0]  dcache_rmask_out,           // DCache读掩码输出
    output        dcache_rdone,               // DCache读完成输出
    output        stall_mem_request           // DCache暂停请求输出
);
    
reg  [31:0] inst [3:0];                       // 输出四条指令 [监视]
wire        stall_if_request;                 // 面向控制单元的stall信号  [监视]
wire [ 2:0] inst_size;                        // 告知控制单元取来了几条有效指令  [监视]
wire        Rdone;                            // 读完成信号   [监视]

// ICache <-> AXI Interface 连接信号
wire         icache_req_valid;
wire         icache_req_ready;
wire [31:0]  icache_req_pc;
wire         icache_res_valid;
wire         icache_res_ready;
wire [127:0] icache_res_data;

// DCache <-> AXI Interface 连接信号
wire         dcache_req_valid;
wire         dcache_req_ready;
wire [31:0]  dcache_req_addr;
wire         dcache_write_en;
wire [127:0] dcache_req_wdata;
wire         dcache_res_valid;
wire         dcache_res_ready;
wire [127:0] dcache_res_rdata;
wire [1:0]   dcache_axi_wdone;

// AXI Interface <-> AXI RAM 连接信号
wire [3:0]   axi_arid;
wire [31:0]  axi_araddr;
// wire [7:0]   axi_arlen;      // 修正位宽：axi_wrap_ram 使用 8 位
 wire [3:0]   axi_arlen; 
wire [2:0]   axi_arsize;
wire [1:0]   axi_arburst;
wire [1:0]   axi_arlock;     // 添加缺失信号
wire [3:0]   axi_arcache;    // 添加缺失信号
wire [2:0]   axi_arprot;
wire         axi_arvalid;
wire         axi_arready;
wire [3:0]   axi_rid;        // 添加缺失信号
wire [31:0]  axi_rdata;
wire [1:0]   axi_rresp;
wire         axi_rlast;
wire         axi_rvalid;
wire         axi_rready;
wire [3:0]   axi_awid;
wire [31:0]  axi_awaddr;
// wire [7:0]   axi_awlen;      // 修正位宽：axi_wrap_ram 使用 8 位
wire [3:0]   axi_awlen;
wire [2:0]   axi_awsize;
wire [1:0]   axi_awburst;
wire [1:0]   axi_awlock;     // 添加缺失信号
wire [3:0]   axi_awcache;    // 添加缺失信号
wire [2:0]   axi_awprot;
wire         axi_awvalid;
wire         axi_awready;
wire [3:0]   axi_wid;
wire [31:0]  axi_wdata;
wire [3:0]   axi_wstrb;
wire         axi_wlast;
wire         axi_wvalid;
wire         axi_wready;
wire [3:0]   axi_bid;        // 添加缺失信号
wire [1:0]   axi_bresp;
wire         axi_bvalid;
wire         axi_bready;

// RAM 随机掩码信号
wire [4:0]   ram_random_mask;

// 为测试目的，将 ram_random_mask 设置为全1（不进行随机掩码）
assign ram_random_mask = 5'b11111;

ICache_top ICache_top_u(
    .clk(clk),
    .rst(rst),
    // 处理器接口
    .inst(inst),                            // 输出四条指令
    .stall_if_request(stall_if_request),    // 面向控制单元的stall信号
    .inst_size(inst_size),                  // 告知控制单元取来了几条有效指令
    .pc(pc),
    .Rena(Rena),                            // 读使能信号 
    .Rdone(Rdone),                          // 读完成信号
    // AXI接口信号
    .req_valid(icache_req_valid),
    .req_ready(icache_req_ready),
    .req_pc(icache_req_pc),
    .res_valid(icache_res_valid),
    .res_ready(icache_res_ready),
    .res_Rdata(icache_res_data)              // 添加缺失的数据输入端口
);

DCache_top #(
    .WAYS(2),
    .CACHELINE_WIDTH(128),
    .CACHELINE_NUMS(1024),
    .PC_WIDTH(10),
    .TAG_WIDTH(18)
) DCache_top_u (
    // 系统信号
    .clk(clk),
    .rst(rst),
    // 面向控制单元的信号
    .stall_mem_request(stall_mem_request),
    // 面向访存模块的数据传输线
    .Wdata(dcache_wdata_in),
    .Waddr(dcache_waddr_in),
    .Wena(dcache_wena_in),
    .Wsize(dcache_wsize_in),
    .Wmask(dcache_wmask_in),
    .Wdone(dcache_wdone),
    .Rdata(dcache_rdata_out),
    .Raddr(dcache_raddr_in),
    .Rena(dcache_rena_in),
    .Rsize(dcache_rsize_in),
    .Rmask(dcache_rmask_out),
    .Rdone(dcache_rdone),
    // 面向axi总线的相应信号
    .req_valid(dcache_req_valid),
    .req_ready(dcache_req_ready),
    .req_addr(dcache_req_addr),
    .write_en(dcache_write_en),
    .req_Wdata(dcache_req_wdata),
    .res_valid(dcache_res_valid),
    .res_ready(dcache_res_ready),
    .res_Rdata(dcache_res_rdata),
    .axi_Wdone(dcache_axi_wdone)
);

AXIInterface AXIInterface_u(
    .clk(clk),
    .rst(rst),
    // AXI总线信号
    .axi_arid(axi_arid),
    .axi_araddr(axi_araddr),
    .axi_arlen(axi_arlen[3:0]),      // 截取低4位连接到AXIInterface
    .axi_arsize(axi_arsize),
    .axi_arburst(axi_arburst),
    .axi_arprot(axi_arprot),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rlast(axi_rlast),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    .axi_awid(axi_awid),
    .axi_awaddr(axi_awaddr),
    .axi_awlen(axi_awlen[3:0]),      // 截取低4位连接到AXIInterface
    .axi_awsize(axi_awsize),
    .axi_awburst(axi_awburst),
    .axi_awprot(axi_awprot),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_wid(axi_wid),
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wlast(axi_wlast),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    
    // ICache <-> AXI Interface
    .inst_pc(icache_req_pc),
    .inst_req_valid(icache_req_valid),
    .inst_req_ready(icache_req_ready),
    .inst_resp_valid(icache_res_valid),
    .inst_resp_ready(icache_res_ready),
    .inst_cache_line(icache_res_data),
    
    // DCache <-> AXI Interface
    .dcache_addr(dcache_req_addr),
    .dcache_wdata(dcache_req_wdata),
    .dcache_write_en(dcache_write_en),
    .dcache_req_valid(dcache_req_valid),
    .dcache_req_ready(dcache_req_ready),
    .dcache_rdata(dcache_res_rdata),
    .dcache_resp_valid(dcache_res_valid),
    .dcache_resp_ready(dcache_res_ready),
    .dcache_wdone(dcache_axi_wdone)
);


axi_wrap_ram axi_wrap_ram_u(
    .aclk(clk),
    .aresetn(rst),              // 注意：aresetn 是低电平有效复位
    
    // AXI Read Address Channel
    .axi_arid(axi_arid),
    .axi_araddr(axi_araddr),
    .axi_arlen(axi_arlen),
    .axi_arsize(axi_arsize),
    .axi_arburst(axi_arburst),
    .axi_arlock(axi_arlock),
    .axi_arcache(axi_arcache),
    .axi_arprot(axi_arprot),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    
    // AXI Read Data Channel
    .axi_rid(axi_rid),
    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rlast(axi_rlast),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    
    // AXI Write Address Channel
    .axi_awid(axi_awid),
    .axi_awaddr(axi_awaddr),
    .axi_awlen(axi_awlen),
    .axi_awsize(axi_awsize),
    .axi_awburst(axi_awburst),
    .axi_awlock(axi_awlock),
    .axi_awcache(axi_awcache),
    .axi_awprot(axi_awprot),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    
    // AXI Write Data Channel
    .axi_wid(axi_wid),
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wlast(axi_wlast),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    
    // AXI Write Response Channel
    .axi_bid(axi_bid),
    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    
    // Random mask for testing
    .ram_random_mask(ram_random_mask)
);

endmodule