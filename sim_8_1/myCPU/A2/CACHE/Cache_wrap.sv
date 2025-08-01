module Cache_wrap(
    input               clk,
    input               rst,

    // to/from IMEM
    input               MemRd_imem,
    input   [31 : 0]    pc_imem,
    output  [31 : 0]    inst        [3 : 0],
    output              find_inst   [3 : 0],
    
    // output              Rdone_inst,      //是不需要让外界知道的

    // icache to/from CTRL
    output              stall_if_request,   //?外层ctrl等模块可能还要增加的端口
    input               flush_ICache,       //?外层ctrl等模块可能还要增加的端口

    // to/from DMEM
    input               MemWr_dmem,
    input               MemRd_dmem,
    input   [31 : 0]    data_in_dmem,
    input   [31 : 0]    Addr_dmem,
    input   [ 3 : 0]    Conf_dmem,
    output  [31 : 0]    data_out_dmem,

    output              Rdone_data,         //?外层ctrl等模块可能还要增加的端口
    output              Wdone_data,         //?外层ctrl等模块可能还要增加的端口

    // dcache to/from CTRL
    input               flush_DCache,
    output              stall_mem_request,

    // AXIInerface
    //read reqest
    output   [ 3:0]     arid,
    output   [31:0]     araddr,
    output   [ 7:0]     arlen,
    output   [ 2:0]     arsize,
    output   [ 1:0]     arburst,
    output   [ 1:0]     arlock,//
    output   [ 3:0]     arcache,//
    output   [ 2:0]     arprot,
    output              arvalid,
    input               arready,
    //read back 
    input    [ 3:0]     rid,//
    input    [31:0]     rdata,
    input    [ 1:0]     rresp,
    input               rlast,
    input               rvalid,
    output              rready,
    //write request 
    output   [ 3:0]     awid,
    output   [31:0]     awaddr,
    output   [ 7:0]     awlen,
    output   [ 2:0]     awsize,
    output   [ 1:0]     awburst,
    output   [ 1:0]     awlock,//
    output   [ 3:0]     awcache,//
    output   [ 2:0]     awprot,
    output              awvalid,
    input               awready,
    //write data    
    output   [ 3:0]     wid,
    output   [31:0]     wdata,
    output   [ 3:0]     wstrb,
    output              wlast,
    output              wvalid,
    input               wready,
    //write back    
    input    [ 3:0]     bid,//
    input    [ 1:0]     bresp,
    input               bvalid,
    output              bready
);

    // AXI协议标准端口赋值
    // 读锁，正常访问
    assign   arlock  = 2'b00;
    // 读缓存，可缓存可缓冲的正常内存
    assign   arcache = 4'b0011;
    // 写锁，正常访问  
    assign   awlock  = 2'b00;
    // 写缓存，可缓存可缓冲的正常内存
    assign   awcache = 4'b0011;

    // rid, bid输入后，axiinterface没有接收，不知道后面是否需要补充

    assign  arlen[7:4]  =   4'b0;

// 一个虚假的占位线
wire                Rdone_inst;

// axiinterface to icache_top
wire    [31 : 0]    inst_pc;
wire                inst_req_valid;
wire                inst_req_ready;
wire    [127: 0]    inst_cache_line;
wire                inst_resp_valid;
wire                inst_resp_ready;
// axiinterface to dcache_top
wire    [31 : 0]    dcache_addr;
wire    [127: 0]    dcache_wdata;    
wire                dcache_write_en; 
wire                dcache_req_valid;
wire                dcache_req_ready;
wire    [127: 0]    dcache_rdata;
wire                dcache_resp_valid;
wire                dcache_resp_ready;
wire    [ 1 : 0]    dcache_wdone;

AXIInterface u_AXIInterface(
    .clk                (clk),
    .rst                (rst),

    // ========= to AXI ============
    // AXI 读地址通道信号 (原 axiReadAddr)
    .axi_arid           (arid),
    .axi_araddr         (araddr),
    .axi_arlen          (arlen[3:0]),
    .axi_arsize         (arsize),
    .axi_arburst        (arburst),
    .axi_arprot         (arprot),
    .axi_arvalid        (arvalid),
    .axi_arready        (arready),
    //arlock?
    //arcache?
    
    // AXI 读数据通道信号 (原 axiReadData)
    .axi_rdata          (rdata),
    .axi_rresp          (rresp),
    .axi_rlast          (rlast),
    .axi_rvalid         (rvalid),
    .axi_rready         (rready),
    //input rid?
    
    // AXI 写地址通道信号 (原 axiWriteAddr)
    .axi_awid           (awid),
    .axi_awaddr         (awaddr),
    .axi_awlen          (awlen[3:0]),
    .axi_awsize         (awsize),
    .axi_awburst        (awburst),
    .axi_awprot         (awprot),
    .axi_awvalid        (awvalid),
    .axi_awready        (awready),
    //awlock?
    //awcache?
    
    // AXI 写数据通道信号 (原 axiWriteData)
    .axi_wid            (wid),
    .axi_wdata          (wdata),
    .axi_wstrb          (wstrb),
    .axi_wlast          (wlast),
    .axi_wvalid         (wvalid),
    .axi_wready         (wready),
    
    // AXI 写响应通道信号 (原 axiWriteResp)
    .axi_bresp          (bresp),
    .axi_bvalid         (bvalid),
    .axi_bready         (bready),
    //bid?
    
    // ========= to cache ==========
    // 指令请求接口 (原 instReq)
    .inst_pc            (inst_pc),
    .inst_req_valid     (inst_req_valid),
    .inst_req_ready     (inst_req_ready),
    
    // 指令响应接口 (原 instResp)
    .inst_cache_line    (inst_cache_line),
    .inst_resp_valid    (inst_resp_valid),
    .inst_resp_ready    (inst_resp_ready),
    
    // DCache 请求接口 (原 dCacheReq)
    .dcache_addr        (dcache_addr),
    .dcache_wdata       (dcache_wdata),
    .dcache_write_en    (dcache_write_en),
    .dcache_req_valid   (dcache_req_valid),
    .dcache_req_ready   (dcache_req_ready),
    
    // DCache 响应接口 (原 dCacheResp)
    .dcache_rdata       (dcache_rdata),
    .dcache_resp_valid  (dcache_resp_valid),
    .dcache_resp_ready  (dcache_resp_ready),
    // 反馈给Dcache的写响应, 拉高成11表示成功
   .dcache_wdone        (dcache_wdone)
);

ICache_top u_icache_top(
    // 系统信号
    .clk                (clk),
    .rst                (rst),
    // 面向控制单元的信号
    .stall_if_request   (stall_if_request),
    .flush_ICache       (flush_ICache),
    // 面向取指模块的数据传输线
    .inst               (inst),
    .find_inst          (find_inst),
    .pc                 (pc_imem),
    .Rena               (MemRd_imem),
    .Rdone              (Rdone_inst),
    // 面向axi总线的相应信号
    // 指令请求
    .req_valid          (inst_req_valid),
    .req_ready          (inst_req_ready),
    .req_pc             (inst_pc),
    // 指令响应
    .res_valid          (inst_resp_valid),
    .res_ready          (inst_resp_ready),
    .res_Rdata          (inst_cache_line)
);


DCache_top u_dcache_top(
    // 系统信号
    .clk                 (clk),
    .rst                 (rst),
    // 面向控制单元的信号
    .flush_DCache        (flush_DCache),
    .stall_mem_request   (stall_mem_request),
    // 面向取指模块的数据传输线
    .addr                (Addr_dmem),
    .Conf_dmem           (Conf_dmem),
    .Wdata               (data_in_dmem),
    .Wena                (MemWr_dmem),
    .Wdone               (Wdone_data),
    .Rdata               (data_out_dmem),
    .Rena                (MemRd_dmem),
    .Rdone               (Rdone_data),
    // 面向axi总线的相应信号
    .req_valid           (dcache_req_valid),
    .req_ready           (dcache_req_ready),
    .req_addr            (dcache_addr),
    .write_en            (dcache_write_en),
    .req_Wdata           (dcache_wdata),
    .res_valid           (dcache_resp_valid),
    .res_ready           (dcache_resp_ready),
    .res_Rdata           (dcache_rdata),
    .axi_Wdone           (dcache_wdone)
);


endmodule