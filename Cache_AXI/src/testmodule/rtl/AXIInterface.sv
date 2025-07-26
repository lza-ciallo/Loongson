`timescale 1ns / 1ps

module AXIInterface(
    input clk,
    input rst,
    
    // AXI 读地址通道信号 (原 axiReadAddr)
    output logic [3:0]   axi_arid,
    output logic [31:0]  axi_araddr,
    output logic [3:0]   axi_arlen,
    output logic [2:0]   axi_arsize,
    output logic [1:0]   axi_arburst,
    output logic [2:0]   axi_arprot,
    output logic         axi_arvalid,
    input                axi_arready,
    //output arcache?
    
    // AXI 读数据通道信号 (原 axiReadData)
    input  logic [31:0]  axi_rdata,
    input  logic [1:0]   axi_rresp,
    input  logic         axi_rlast,
    input                axi_rvalid,
    output logic         axi_rready,
    //input rid?
    
    // AXI 写地址通道信号 (原 axiWriteAddr)
    output logic [3:0]   axi_awid,
    output logic [31:0]  axi_awaddr,
    output logic [3:0]   axi_awlen,
    output logic [2:0]   axi_awsize,
    output logic [1:0]   axi_awburst,
    output logic [2:0]   axi_awprot,
    output logic         axi_awvalid,
    input                axi_awready,
    //output  axi_awlock?
    //output  axi_awcache?
    
    // AXI 写数据通道信号 (原 axiWriteData)
    output logic [3:0]   axi_wid,
    output logic [31:0]  axi_wdata,
    output logic [3:0]   axi_wstrb,
    output logic         axi_wlast,
    output logic         axi_wvalid,
    input                axi_wready,
    
    // AXI 写响应通道信号 (原 axiWriteResp)
    input  logic [1:0]   axi_bresp,
    input                axi_bvalid,
    output logic         axi_bready,
    //input bid?
    
    // 指令请求接口 (原 instReq)
    input  logic [31:0]  inst_pc,
    input                inst_req_valid,
    output logic         inst_req_ready,
    
    // 指令响应接口 (原 instResp)
    output logic [127:0] inst_cache_line,
    output logic         inst_resp_valid,
    input                inst_resp_ready,
    
    // DCache 请求接口 (原 dCacheReq)
    input  logic [31:0]  dcache_addr,
    input  logic [127:0] dcache_wdata,
    input                dcache_write_en,
    input                dcache_req_valid,
    output logic         dcache_req_ready,
    
    // DCache 响应接口 (原 dCacheResp)
    output logic [127:0] dcache_rdata,
    output logic         dcache_resp_valid,
    input                dcache_resp_ready,
    // 反馈给Dcache的写响应, 拉高成11表示成功
    output logic [1:0]   dcache_wdone
    
);

    // 状态机定义
    typedef enum  { sRAddr, sRInst, sRDCache, sRPendingResp, sRRst } AXIRState;
    typedef enum  { sWAddr, sWDCache, sWDCResp, sWRst } AXIWState;

    AXIRState   rState, nextRState, lastRState;
    AXIWState   wState, nextWState, lastWState;
    
    // 请求处理信号
    logic           instReqBusy;
    logic [31:0]    instReqPC;
    logic [31:0]    lastInstReqPC;

    logic           dCacheReqBusy;
    logic [31:0]    dCacheReqAddr;
    logic [127:0]   dCacheReqData;
    logic           dCacheReqWEn;
    logic [31:0]    lastDCacheReqAddr;
    logic [127:0]   lastDCacheReqData;
    logic           lastDCacheReqWEn;

    // 响应信号
    logic           iReadReady;
    logic [127:0]   iReadRes;

    logic           dcReadReady;
    logic [127:0]   dcReadRes;

    // 计数器
    logic [1:0]     instRespCounter;
    logic [1:0]     dCacheRespCounter;
    logic [1:0]     dCacheDataCounter;

    // 状态保持信号
    logic           lastInstBusy;
    logic           lastDCacheBusy;

    // 待处理响应逻辑
    logic           instPendingReadResp;
    logic           dCPendingReadResp;


    // 待处理响应逻辑
    always_ff @(posedge clk) begin
        if(!rst) begin
            instPendingReadResp <= 0;
            dCPendingReadResp   <= 0;
        end else if(rState == sRDCache && axi_rvalid && axi_rready && axi_rlast) begin
            instPendingReadResp <= 0;
            dCPendingReadResp   <= 1;
        end else if(rState == sRInst && axi_rvalid && axi_rready && axi_rlast) begin
            instPendingReadResp <= 1;
            dCPendingReadResp   <= 0;
        end else if(rState == sRAddr) begin
            instPendingReadResp <= 0;
            dCPendingReadResp   <= 0;
        end
    end

    // 读地址通道有效信号
    assign axi_arvalid = rState == sRAddr && 
                        ((instReqBusy ) || 
                         (dCacheReqBusy && !dCacheReqWEn));

    // 写地址通道有效信号
    assign axi_awvalid = wState == sWAddr && 
                        (dCacheReqBusy && dCacheReqWEn);

    // 请求接口就绪信号
    assign inst_req_ready   = ~lastInstBusy;
    assign dcache_req_ready = ~lastDCacheBusy;

    // 响应接口有效信号
    assign inst_resp_valid   = iReadReady;
    assign dcache_resp_valid = dcReadReady;

    // 指令请求处理逻辑
    always_comb begin
        instReqBusy     = lastInstBusy;
        instReqPC       = lastInstReqPC;
        
        if(!rst) begin
            instReqBusy = 0;
        end else if(inst_req_valid && !lastInstBusy) begin
            instReqBusy = 1;
            instReqPC   = inst_pc;
        end else if(rState == sRInst && lastRState == sRAddr) begin
            instReqBusy = 0;
        end else begin
            instReqBusy = lastInstBusy;
        end
    end
    // DCache 请求处理逻辑
    always_comb begin
        dCacheReqBusy = lastDCacheBusy;
        dCacheReqAddr = lastDCacheReqAddr;
        dCacheReqData = lastDCacheReqData;
        dCacheReqWEn  = lastDCacheReqWEn;
        
        if(!rst) begin
            dCacheReqBusy = 0;
            dCacheReqWEn  = 0;
        end else if(dcache_req_valid && !lastDCacheBusy) begin
            dCacheReqBusy = 1;
            dCacheReqAddr = dcache_addr;
            dCacheReqWEn  = dcache_write_en;
            dCacheReqData = dcache_wdata;
        end else if ((rState == sRDCache && lastRState == sRAddr) || 
                    (wState == sWDCResp && lastWState == sWDCache)) begin
            dCacheReqBusy = 0;
            dCacheReqWEn  = 0;
        end else begin
            dCacheReqBusy = lastDCacheBusy;
        end
    end

    // 请求参数锁存
    always_ff @ (posedge clk) begin
        lastInstBusy        <= instReqBusy;
        lastInstReqPC       <= instReqPC;
        lastDCacheBusy      <= dCacheReqBusy;
        lastDCacheReqAddr   <= dCacheReqAddr;
        lastDCacheReqData   <= dCacheReqData;
        lastDCacheReqWEn    <= dCacheReqWEn;
    end

    // 读状态机转移逻辑
    always_comb begin
        unique case(rState)
            sRAddr: begin
                if(!rst) begin
                    nextRState = sRRst;
                end else if(axi_arvalid && axi_arready) begin
                    if(dCacheReqBusy && !dCacheReqWEn) begin
                        nextRState = sRDCache;
                    end else begin
                        nextRState = sRInst;
                    end
                end else begin
                    nextRState = sRAddr;
                end
            end
            sRDCache: begin
                if(!rst) begin
                    nextRState = sRRst;
                end else if(dcReadReady && dcache_resp_ready) begin
                    nextRState = sRAddr;
                end else begin
                    nextRState = sRDCache;
                end
            end
            sRInst: begin
                if(!rst) begin
                    nextRState = sRRst;
                end else if(iReadReady && inst_resp_ready) begin
                    nextRState = sRAddr;
                end else begin
                    nextRState = sRInst;
                end
            end
            sRRst: begin
                if(!rst) begin
                    nextRState = sRRst;
                end else begin
                    nextRState = sRAddr;
                end
            end
            default: begin
                nextRState = sRRst;
            end
        endcase
    end

    // 写状态机转移逻辑
    always_comb begin
        unique case(wState)
            sWAddr: begin
                if(!rst) begin
                    nextWState = sWRst;
                end else if(axi_awvalid && axi_awready && dCacheReqBusy && dCacheReqWEn) begin
                    nextWState = sWDCache;
                end else begin
                    nextWState = sWAddr;
                end
            end
            sWDCache: begin
                if(!rst) begin
                    nextWState = sWRst;
                end else if(axi_wvalid && axi_wready && axi_wlast) begin
                    nextWState = sWDCResp;
                end else begin
                    nextWState = sWDCache;
                end
            end
            sWRst: begin
                if(!rst) begin
                    nextWState = sWRst;
                end else begin
                    nextWState = sWAddr;
                end
            end
            default: begin
                nextWState = sWRst;
            end
        endcase
    end

    // 状态寄存器更新
    always_ff @(posedge clk) begin
        rState <= nextRState;
        wState <= nextWState;
        lastRState <= rState;
        lastWState <= wState;
    end

    // 指令响应计数器
    always_ff @(posedge clk) begin
        if(!rst) begin
            instRespCounter <= 0;
        end else if(rState == sRInst) begin
            if(axi_rready && axi_rvalid) begin
                instRespCounter <= instRespCounter + 1;
                unique case(instRespCounter)
                    2'b00: iReadRes[31:0]   <= axi_rdata;
                    2'b01: iReadRes[63:32]  <= axi_rdata;
                    2'b10: iReadRes[95:64]  <= axi_rdata;
                    2'b11: iReadRes[127:96] <= axi_rdata;
                endcase
            end
        end else begin
            instRespCounter <= 0;
        end
    end

    // DCache 响应计数器
    //堆序在这里可能是一个问题，后面debug的时候要注意

    always_ff @(posedge clk) begin
        if(!rst) begin
            dCacheRespCounter <= 0;
        end else if(rState == sRDCache) begin
            if(axi_rready && axi_rvalid) begin
                dCacheRespCounter <= dCacheRespCounter + 1;
                unique case(dCacheRespCounter)
                    2'b00: dcReadRes[31:0]   <= axi_rdata;
                    2'b01: dcReadRes[63:32]  <= axi_rdata;
                    2'b10: dcReadRes[95:64]  <= axi_rdata;
                    2'b11: dcReadRes[127:96] <= axi_rdata;
                endcase
            end
        end else begin
            dCacheRespCounter <= 0;
        end
    end

    // DCache 写数据计数器
    always_ff @(posedge clk) begin
        if(!rst) begin
            dCacheDataCounter <= 0;
        end else if(wState == sWDCache) begin
            if(axi_wready && axi_wvalid) begin
                dCacheDataCounter <= dCacheDataCounter + 1;
            end
        end else begin
            dCacheDataCounter <= 0;
        end
    end

    // 读通道组合逻辑
    always_comb begin
        // 默认值
        axi_arid     = 4'h1;
        axi_araddr   = 0;
        axi_arlen    = 4'b0011;  // burst 4
        axi_arsize   = 3'b010;
        axi_arburst  = 2'b10;
        axi_arprot   = 3'b101;
                
        iReadReady   = 0;
        dcReadReady  = 0;

        inst_cache_line = iReadRes;
        dcache_rdata    = dcReadRes;
        
        axi_rready = 0;

        unique case(rState)
            sRAddr: begin
                if(dCacheReqBusy && !dCacheReqWEn) begin
                    axi_arid     = 4'h1;
                    axi_araddr   = dCacheReqAddr & 32'hFFFF_FFF0;
                    axi_arlen    = 4'b0011;  // burst 4
                    axi_arsize   = 3'b010;
                    axi_arburst  = 2'b10;
                    axi_arprot   = 3'b001;
                
                end else if(instReqBusy) begin
                    axi_arid     = 4'h0;
                    axi_araddr   = instReqPC & 32'hFFFF_FFF0;
                    axi_arlen    = 4'b0011;  // burst 4
                    axi_arsize   = 3'b010;
                    axi_arburst  = 2'b10;
                    axi_arprot   = 3'b101;
                end
                
                iReadReady  = 0;
                dcReadReady = 0;
            end
            sRInst: begin
                axi_rready = 1;
                if(axi_rlast && axi_rvalid && axi_rready) begin
                    iReadReady = 1;
                    inst_cache_line = {axi_rdata, iReadRes[95:0]};
                end else if(instPendingReadResp) begin
                    iReadReady = 1;
                    inst_cache_line = iReadRes;
                end
                dcReadReady = 0;
            end
            sRDCache: begin
                axi_rready = 1;
                if(axi_rlast && axi_rvalid && axi_rready) begin
                    dcReadReady     = 1;
                    dcache_rdata = {axi_rdata, dcReadRes[95:0]};
                end else if(dCPendingReadResp) begin
                    dcReadReady = 1;
                    dcache_rdata = dcReadRes;
                end
                iReadReady  = 0;
            end
            sRRst: begin
                axi_rready = 0;
                iReadReady  = 0;
                dcReadReady = 0;

                axi_arid     = 4'h0;
                axi_araddr   = 32'h00000000;
                axi_arlen    = 4'b0000;
                axi_arsize   = 3'b000;
                axi_arburst  = 2'b10;
            end
        endcase
    end

    // 写通道组合逻辑
    always_comb begin
        // 默认值
        axi_awid        = 4'h0;
        axi_awaddr      = dCacheReqAddr;
        axi_awlen       = 4'b0011;
        axi_awsize      = 3'b010;
        axi_awburst     = 2'b10;
        axi_awprot      = 3'b001;
        
        axi_wid         = 4'h0;
        axi_wstrb       = 4'b1111;
        axi_wdata       = 0;
        axi_wlast       = 0; 
        
        axi_bready      = 0;
        
        axi_wvalid      = 0;

        dcache_wdone    = 2'b00;

        unique case(wState)
            sWAddr: begin
                if(dCacheReqBusy && dCacheReqWEn) begin
                    axi_awid        = 4'h1;
                    axi_awaddr      = dCacheReqAddr;
                    axi_awlen       = 4'b0011;
                    axi_awsize      = 3'b010;
                    axi_awburst     = 2'b10;
                end 
                axi_wvalid = 0;
            end
            sWDCache: begin
                axi_wid     = 4'h0;
                axi_wstrb   = 4'b1111;
                case(dCacheDataCounter)
                    2'b00: begin
                        axi_wdata   = dCacheReqData[31:0];
                        axi_wlast   = 0; 
                    end
                    2'b01: begin
                        axi_wdata   = dCacheReqData[63:32];
                        axi_wlast   = 0; 
                    end
                    2'b10: begin
                        axi_wdata   = dCacheReqData[95:64];
                        axi_wlast   = 0; 
                    end
                    2'b11: begin
                        axi_wdata   = dCacheReqData[127:96];
                        axi_wlast   = 1; 
                    end
                endcase
                axi_wstrb   = 4'b1111;
                axi_wvalid  = 1;
            end
            sWDCResp: begin
                axi_wvalid  = 0;
                axi_bready  = 1;
                dcache_wdone= 2'b11;
            end
            sWRst: begin
                axi_awid    = 4'h0;
                axi_awaddr  = dCacheReqAddr;
                axi_awlen   = 4'b0000;
                axi_awsize  = 3'b010;
                axi_awburst = 2'b01;

                axi_wvalid  = 0;
                axi_bready  = 0;
            end
        endcase
    end

endmodule