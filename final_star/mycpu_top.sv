module core_top (
    input               aclk,
    input               aresetn,
    input   [ 7 : 0]    intrpt,

    // AXIInerface
    //read reqest
    output  [ 3 : 0]    arid,
    output  [31 : 0]    araddr,
    output  [ 7 : 0]    arlen,
    output  [ 2 : 0]    arsize,
    output  [ 1 : 0]    arburst,
    output  [ 1 : 0]    arlock,//
    output  [ 3 : 0]    arcache,//
    output  [ 2 : 0]    arprot,
    output              arvalid,
    input               arready,
    //read back   
    input   [ 3 : 0]    rid,//
    input   [31 : 0]    rdata,
    input   [ 1 : 0]    rresp,
    input               rlast,
    input               rvalid,
    output              rready,
    //write request 
    output  [ 3 : 0]    awid,
    output  [31 : 0]    awaddr,
    output  [ 7 : 0]    awlen,
    output  [ 2 : 0]    awsize,
    output  [ 1 : 0]    awburst,
    output  [ 1 : 0]    awlock,//
    output  [ 3 : 0]    awcache,//
    output  [ 2 : 0]    awprot,
    output              awvalid,
    input               awready,
    //write data    
    output  [ 3 : 0]    wid,
    output  [31 : 0]    wdata,
    output  [ 3 : 0]    wstrb,
    output              wlast,
    output              wvalid,
    input               wready,
    //write back    
    input   [ 3 : 0]    bid,//
    input   [ 1 : 0]    bresp,
    input               bvalid,
    output              bready,

    //debug
    input           break_point,//无需实现功能，仅提供接口即可，输入1’b0
    input           infor_flag,//无需实现功能，仅提供接口即可，输入1’b0
    input  [ 4:0]   reg_num,//无需实现功能，仅提供接口即可，输入5’b0
    output          ws_valid,//无需实现功能，仅提供接口即可
    output [31:0]   rf_rdata,//无需实现功能，仅提供接口即可

    //debug interface
    output  [31 : 0]    debug0_wb_pc,
    output  [ 3 : 0]    debug0_wb_rf_wen,
    output  [ 4 : 0]    debug0_wb_rf_wnum,
    output  [31 : 0]    debug0_wb_rf_wdata
);

    wire                MemRd_imem;
    wire    [31 : 0]    pc_imem;
    wire    [31 : 0]    inst        [3 : 0];
    wire                find_inst   [3 : 0];

    wire                stall_if_request;

    wire                MemWr_dmem;
    wire                MemRd_dmem;
    wire    [31 : 0]    data_in_dmem;
    wire    [31 : 0]    Addr_dmem;
    wire    [ 3 : 0]    Conf_dmem;
    wire    [31 : 0]    data_out_dmem;

    wire                stall_mem_request;

    Cache_wrap u_cache (
        .clk                (aclk),
        .rst                (aresetn),

        // to/from IMEM
        .MemRd_imem         (MemRd_imem),
        .pc_imem            (pc_imem),
        .inst               (inst),
        .find_inst          (find_inst),
        
        // output              Rdone_inst,      //是不需要让外界知道的

        // icache to/from CTRL
        .stall_if_request   (stall_if_request),   //?外层ctrl等模块可能还要增加的端口
        .flush_ICache       (1'b0),       //?外层ctrl等模块可能还要增加的端口

        // to/from DMEM
        .MemWr_dmem         (MemWr_dmem),
        .MemRd_dmem         (MemRd_dmem),
        .data_in_dmem       (data_in_dmem),
        .Addr_dmem          (Addr_dmem),
        .Conf_dmem          (Conf_dmem),
        .data_out_dmem      (data_out_dmem),

        // output              Rdone_data,         //?外层ctrl等模块可能还要增加的端口
        // output              Wdone_data,         //?外层ctrl等模块可能还要增加的端口

        // dcache to/from CTRL
        .flush_DCache       (1'b0),
        .stall_mem_request  (stall_mem_request),

        // AXIInerface
        //read reqest
        .arid               (arid),
        .araddr             (araddr),
        .arlen              (arlen),
        .arsize             (arsize),
        .arburst            (arburst),
        .arlock             (arlock),//
        .arcache            (arcache),//
        .arprot             (arprot),
        .arvalid            (arvalid),
        .arready            (arready),
        //read back 
        .rid                (rid),//
        .rdata              (rdata),
        .rresp              (rresp),
        .rlast              (rlast),
        .rvalid             (rvalid),
        .rready             (rready),
        //write request 
        .awid               (awid),
        .awaddr             (awaddr),
        .awlen              (awlen),
        .awsize             (awsize),
        .awburst            (awburst),
        .awlock             (awlock),//
        .awcache            (awcache),//
        .awprot             (awprot),
        .awvalid            (awvalid),
        .awready            (awready),
        //write data    
        .wid                (wid),
        .wdata              (wdata),
        .wstrb              (wstrb),
        .wlast              (wlast),
        .wvalid             (wvalid),
        .wready             (wready),
        //write back    
        .bid                (bid),//
        .bresp              (bresp),
        .bvalid             (bvalid),
        .bready             (bready)
    );

    CPU u_cpu (
        .clk                (aclk),
        .rst                (aresetn),
        .interrupt          (intrpt),

        // to/from Icache
        .MemRd_imem         (MemRd_imem),
        .pc_imem            (pc_imem),
        .inst               (inst),
        .find_inst          (find_inst),
        .stall_if_request   (stall_if_request),

        // to/from Dcache
        .MemWr_dmem         (MemWr_dmem),
        .MemRd_dmem         (MemRd_dmem),
        .data_in_dmem       (data_in_dmem),
        .Addr_dmem          (Addr_dmem),
        .Conf_dmem          (Conf_dmem),
        .data_out_dmem      (data_out_dmem),
        .stall_mem_request  (stall_mem_request),

        //debug interface
        .debug_wb_pc        (debug0_wb_pc),
        .debug_wb_rf_wen    (debug0_wb_rf_wen),
        .debug_wb_rf_wnum   (debug0_wb_rf_wnum),
        .debug_wb_rf_wdata  (debug0_wb_rf_wdata)
    );

endmodule