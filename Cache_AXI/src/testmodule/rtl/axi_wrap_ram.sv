/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/
//for func test, no define RUN_PERF_TEST
//`define _RUN_PERF_TEST
`define RUN_PERF_TEST

module axi_wrap_ram(
  input  wire        aclk,
  input  wire        aresetn,
  //ar
  input  wire [3 :0] axi_arid   ,
  input  wire [31:0] axi_araddr ,
  // input  wire [7 :0] axi_arlen  ,
  input  wire [3 :0] axi_arlen  ,
  input  wire [2 :0] axi_arsize ,
  input  wire [1 :0] axi_arburst,
  input  wire [1 :0] axi_arlock ,
  input  wire [3 :0] axi_arcache,
  input  wire [2 :0] axi_arprot ,
  input  wire        axi_arvalid,
  output wire        axi_arready,
  //r
  output wire [3 :0] axi_rid    ,
  output wire [31:0] axi_rdata  ,
  output wire [1 :0] axi_rresp  ,
  output wire        axi_rlast  ,
  output wire        axi_rvalid ,
  input  wire        axi_rready ,
  //aw
  input  wire [3 :0] axi_awid   ,
  input  wire [31:0] axi_awaddr ,
  // input  wire [7 :0] axi_awlen  ,
  input  wire [3 :0] axi_awlen  ,
  input  wire [2 :0] axi_awsize ,
  input  wire [1 :0] axi_awburst,
  input  wire [1 :0] axi_awlock ,
  input  wire [3 :0] axi_awcache,
  input  wire [2 :0] axi_awprot ,
  input  wire        axi_awvalid,
  output wire        axi_awready,
  //w
  input  wire [3 :0] axi_wid    ,
  input  wire [31:0] axi_wdata  ,
  input  wire [3 :0] axi_wstrb  ,
  input  wire        axi_wlast  ,
  input  wire        axi_wvalid ,
  output wire        axi_wready ,
  //b
  output wire [3 :0] axi_bid    ,
  output wire [1 :0] axi_bresp  ,
  output wire        axi_bvalid ,
  input  wire        axi_bready ,

  //from confreg
  input  wire [4 :0] ram_random_mask
);
wire axi_arvalid_m_masked;
wire axi_rready_m_masked;
wire axi_awvalid_m_masked;
wire axi_wvalid_m_masked;
wire axi_bready_m_masked;

wire axi_arready_s_unmasked;
wire axi_rvalid_s_unmasked;
wire axi_awready_s_unmasked;
wire axi_wready_s_unmasked;
wire axi_bvalid_s_unmasked;

wire ar_and;
wire  r_and;
wire aw_and;
wire  w_and;
wire  b_and;
reg ar_nomask;
reg aw_nomask;
reg w_nomask;
reg [4:0] pf_r2r;
reg [1:0] pf_b2b;
wire pf_r2r_nomask= pf_r2r==5'd0;
wire pf_b2b_nomask= pf_b2b==2'd0;

//mask
`ifdef RUN_PERF_TEST
    assign ar_and = 1'b1;
    assign  r_and = pf_r2r_nomask;
    assign aw_and = 1'b1;
    assign  w_and = 1'b1;
    assign  b_and = pf_b2b_nomask;
`else
    assign ar_and = ram_random_mask[4] | ar_nomask;
    assign  r_and = ram_random_mask[3]            ;
    assign aw_and = ram_random_mask[2] | aw_nomask;
    assign  w_and = ram_random_mask[1] |  w_nomask;
    assign  b_and = ram_random_mask[0]            ;
`endif
always @(posedge aclk)
begin
    //for func test, random mask
    ar_nomask <= !aresetn             ? 1'b0 :
                 axi_arvalid_m_masked&&axi_arready ? 1'b0 :
                 axi_arvalid_m_masked ? 1'b1 : ar_nomask;

    aw_nomask <= !aresetn             ? 1'b0 :
                 axi_awvalid_m_masked&&axi_awready ? 1'b0 :
                 axi_awvalid_m_masked ? 1'b1 : aw_nomask;

    w_nomask  <= !aresetn             ? 1'b0 :
                 axi_wvalid_m_masked&&axi_wready ? 1'b0 :
                 axi_wvalid_m_masked  ? 1'b1 : w_nomask;
    //for perf test
    pf_r2r    <= !aresetn             ? 5'd0 : 
                 axi_arvalid_m_masked&&axi_arready ? 5'd25 :
                 !pf_r2r_nomask       ? pf_r2r-1'b1 : pf_r2r;
    pf_b2b    <= !aresetn             ? 2'd0 : 
                 axi_awvalid_m_masked&&axi_awready ? 2'd3 :
                 !pf_b2b_nomask       ? pf_b2b-1'b1 : pf_b2b;
end


//-----{master -> slave}-----
assign axi_arvalid_m_masked = axi_arvalid & ar_and;
assign axi_rready_m_masked  = axi_rready  &  r_and;
assign axi_awvalid_m_masked = axi_awvalid & aw_and;
assign axi_wvalid_m_masked  = axi_wvalid  &  w_and;
assign axi_bready_m_masked  = axi_bready  &  b_and;

//-----{slave -> master}-----
assign axi_arready = axi_arready_s_unmasked & ar_and;
assign axi_rvalid  = axi_rvalid_s_unmasked  &  r_and;
assign axi_awready = axi_awready_s_unmasked & aw_and;
assign axi_wready  = axi_wready_s_unmasked  &  w_and;
assign axi_bvalid  = axi_bvalid_s_unmasked  &  b_and;
     
//ram axi
//ar
wire [3 :0] ram_arid   ;
wire [31:0] ram_araddr ;
wire [7 :0] ram_arlen  ;
wire [2 :0] ram_arsize ;
wire [1 :0] ram_arburst;
wire [1 :0] ram_arlock ;
wire [3 :0] ram_arcache;
wire [2 :0] ram_arprot ;
wire        ram_arvalid;
wire        ram_arready;
//r
wire [3 :0] ram_rid    ;
wire [31:0] ram_rdata  ;
wire [1 :0] ram_rresp  ;
wire        ram_rlast  ;
wire        ram_rvalid ;
wire        ram_rready ;
//aw
wire [3 :0] ram_awid   ;
wire [31:0] ram_awaddr ;
wire [7 :0] ram_awlen  ;
wire [2 :0] ram_awsize ;
wire [1 :0] ram_awburst;
wire [1 :0] ram_awlock ;
wire [3 :0] ram_awcache;
wire [2 :0] ram_awprot ;
wire        ram_awvalid;
wire        ram_awready;
//w
wire [3 :0] ram_wid    ;
wire [31:0] ram_wdata  ;
wire [3 :0] ram_wstrb  ;
wire        ram_wlast  ;
wire        ram_wvalid ;
wire        ram_wready ;
//b
wire [3 :0] ram_bid    ;
wire [1 :0] ram_bresp  ;
wire        ram_bvalid ;
wire        ram_bready ;


// inst ram axi
blk_mem_gen_0 ram(
    .s_aclk         (aclk         ),
    .s_aresetn      (aresetn      ),

    //ar
    .s_axi_arid     (ram_arid     ),
    .s_axi_araddr   (ram_araddr   ),
    .s_axi_arlen    (ram_arlen    ),
    .s_axi_arsize   (ram_arsize   ),
    .s_axi_arburst  (ram_arburst  ),
    .s_axi_arvalid  (ram_arvalid  ),
    .s_axi_arready  (ram_arready  ),
    //r
    .s_axi_rid      (ram_rid      ),
    .s_axi_rdata    (ram_rdata    ),
    .s_axi_rresp    (ram_rresp    ),
    .s_axi_rlast    (ram_rlast    ),
    .s_axi_rvalid   (ram_rvalid   ),
    .s_axi_rready   (ram_rready   ),
    //aw
    .s_axi_awid     (ram_awid     ),
    .s_axi_awaddr   (ram_awaddr   ),
    .s_axi_awlen    (ram_awlen    ),
    .s_axi_awsize   (ram_awsize   ),
    .s_axi_awburst  (ram_awburst  ),
    .s_axi_awvalid  (ram_awvalid  ),
    .s_axi_awready  (ram_awready  ),
    //w
    .s_axi_wdata    (ram_wdata    ),
    .s_axi_wstrb    (ram_wstrb    ),
    .s_axi_wlast    (ram_wlast    ),
    .s_axi_wvalid   (ram_wvalid   ),
    .s_axi_wready   (ram_wready   ),
    //b
    .s_axi_bid      (ram_bid      ),
    .s_axi_bresp    (ram_bresp    ),
    .s_axi_bvalid   (ram_bvalid   ),
    .s_axi_bready   (ram_bready   )
);

//ar
assign ram_arid    = axi_arid   ;
assign ram_araddr  = (axi_araddr[31:28] == 4'h0 ||
                      axi_araddr[31:28] == 4'h1 ||
                      axi_araddr[31:28] == 4'h7) ? axi_araddr :
                      {12'b0, 4'hf, axi_araddr[31:28], axi_araddr[11:0]};
assign ram_arlen   = {4'b0000, axi_arlen}  ;
assign ram_arsize  = axi_arsize ;
assign ram_arburst = axi_arburst;
assign ram_arlock  = axi_arlock ;
assign ram_arcache = axi_arcache;
assign ram_arprot  = axi_arprot ;
assign ram_arvalid = axi_arvalid_m_masked;
assign axi_arready_s_unmasked = ram_arready;
//r
assign axi_rid    = axi_rvalid ? ram_rid   :  4'd0 ;
assign axi_rdata  = axi_rvalid ? ram_rdata : 32'd0 ;
assign axi_rresp  = axi_rvalid ? ram_rresp :  2'd0 ;
assign axi_rlast  = axi_rvalid ? ram_rlast :  1'd0 ;
assign axi_rvalid_s_unmasked = ram_rvalid;
assign ram_rready = axi_rready_m_masked;
//aw
assign ram_awid    = axi_awid   ;
assign ram_awaddr  = (axi_awaddr[31:28] == 4'h0 ||
                      axi_awaddr[31:28] == 4'h1 ||
                      axi_awaddr[31:28] == 4'h7) ? axi_awaddr :
                      {12'b0, 4'hf, axi_awaddr[31:28], axi_awaddr[11:0]};
assign ram_awlen   = {4'b0000, axi_awlen}  ;
assign ram_awsize  = axi_awsize ;
assign ram_awburst = axi_awburst;
assign ram_awlock  = axi_awlock ;
assign ram_awcache = axi_awcache;
assign ram_awprot  = axi_awprot ;
assign ram_awvalid = axi_awvalid_m_masked;
assign axi_awready_s_unmasked = ram_awready;
//w
assign ram_wid    = axi_wid    ;
assign ram_wdata  = axi_wdata  ;
assign ram_wstrb  = axi_wstrb  ;
assign ram_wlast  = axi_wlast  ;
assign ram_wvalid = axi_wvalid_m_masked;
assign axi_wready_s_unmasked = ram_wready ;
//b
assign axi_bid    = axi_bvalid ? ram_bid   : 4'd0 ;
assign axi_bresp  = axi_bvalid ? ram_bresp : 2'd0 ;
assign axi_bvalid_s_unmasked = ram_bvalid ;
assign ram_bready = axi_bready_m_masked;
endmodule
