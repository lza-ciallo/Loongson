// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
// Date        : Fri Aug  1 22:49:28 2025
// Host        : yuan02 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Users/yuanm/Chiplab/chiplab/IP/myCPU/A2/CACHE/ip/ICache_inst_block/ICache_inst_block_sim_netlist.v
// Design      : ICache_inst_block
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "ICache_inst_block,blk_mem_gen_v8_4_9,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_9,Vivado 2024.2" *) 
(* NotValidForBitStream *)
module ICache_inst_block
   (clka,
    ena,
    wea,
    addra,
    dina,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_mode = "slave BRAM_PORTA" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_ADDRESS_MODE BYTE_ADDRESS, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [7:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [127:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [127:0]douta;

  wire [7:0]addra;
  wire clka;
  wire [127:0]dina;
  wire [127:0]douta;
  wire ena;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [127:0]NLW_U0_doutb_UNCONNECTED;
  wire [7:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [7:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [127:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "8" *) 
  (* C_ADDRB_WIDTH = "8" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     14.1319 mW" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "ICache_inst_block.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "0" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "256" *) 
  (* C_READ_DEPTH_B = "256" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "128" *) 
  (* C_READ_WIDTH_B = "128" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "256" *) 
  (* C_WRITE_DEPTH_B = "256" *) 
  (* C_WRITE_MODE_A = "READ_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "128" *) 
  (* C_WRITE_WIDTH_B = "128" *) 
  (* C_XDEVICEFAMILY = "artix7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  ICache_inst_block_blk_mem_gen_v8_4_9 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[127:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[7:0]),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[7:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[127:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2024.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
FPXllyX2NFs/RMngGqZy2bLYbZr92CdofeZrJOHklWXExpaPgHNYp2Lzm4MnflbnrfSkCmLwwKT5
zfRgEip7FKQ5Zhb73p0MAIADixBZ/ZRt4hQkJL0T9brm0waLHfanjnov2aCX6jN3LbQc3ujmDga6
Dd73k78u4xjRTDv1/P4=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kr7VKKvChFoiyRCReag+OvU3jnmG9pN0cv+BxhNmMKLthg/ksgNZyU3L+fQ7cmIQELtlUjwjkBAP
Jjq5RsCnHbJxj+Ys1GNhriiBsxLqxWCP8onhAVvgZN2xZFOih0UWpqlU8NVP8Eww1ohvkDgxTstC
3kDmYehxIUJjqCC/mgRZmuezqugrFdubYmBoz16tUvD17iA5qqCIMS9xSIXYp2LBNekmWEwrVqzu
R4koEo4UlXl/CEw0XY3QvMoHnlXgu6N/6sc+nxZtKSwjiMVvGnZE9UVvJPAC3Hn3zKFGlK53mmGO
Tj0dWzhwX0ahSYzkyJC/HLdbGZmriL2UNvDyFw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
CaLc9FGt3AdRHfNtGAsGFY/QEvHY1Vv4TvvgCDsdDMqiuDeLizFJDJeskBWjeKDoE2cufK8TxiBq
mySRQNJoeOKnxTiDdf+Rx6m0iR6h/YeswegYwgghpM5KVrl6mSwF3+4yEovPM7a+9ArDQ5vl+WT8
SilNGzyW0KnTwe7+szs=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
cEnudSW1X71p0Xuq6jrXOxHnBku87IA0RA3zKqmeZHZM0r+9rEm5MSzX8RecnQ994yiqeyxbIH2l
fGEzUzr0ZzryS3fkf2LnJuB39f2YARW9eVCSiaeWaraZuY1l89T+h3vgdlurS/1LIraYLS1MyOXa
6F1LAcQp3W4OO4ctc3q1FRMZGldRS1biMsKwJ8Lxj8NEOm67UfgFrJNQAxbVXEfbWRWhKtwNxcTB
JbgC8j4EHkIA46mzoHloeBAL6KieplQUBjKXSSTb66rxglbFhWLy+mirROHcocu9J4ZbvTRYZEww
4lso1lqAllVLAoKYqa3WImZuSRoTbGDngBt9Lg==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rOyI+x4PlmKcVSFoN3oKgSYpVlmYxc194Ej04il/YmBg10xopy4zmtu5sdCP/uGSNYcNGWeAiw01
mNf98KyNgTUFXruHCA38qjhhEIvl4vfWWn3W3mFRxrIuwmnreT6qTvgMaxIkCdVBDP7Iy7O6WmCf
3Va5X5hnCHhtXgX5UYniBHiLjmupv63B8XMAYDH2n6mQ3H0DF7mtb7psBafd0Z6+IWUbmzwMtKrf
ZrRJBGAhNT0i1KrEjEh/rWjN7Z7N32zQ+Pl1kc5gYCQIX5McfdTdqSaRVXZ/HF90ymS7/8d5LDyj
Er+ORdcjnOn6oAyY4PuUUl4OYUHv5k+RglTe5Q==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2023_11", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
bJa7kPSpDipzoJoQu1APEjc8vFLqBfQZK/grZvWijD7/FgMTerFCWLUY6n8DWeGdvjXvTeyrqCHE
2rP/H57wUqPC8tIJlGm6ZYQGjZ3TgYqLrJshDE5zYMTO//q0vuSraWvZP7A7SLuW6y7tFE/nplpx
L8gbYORx6j70okGUwnamCMS9yhFr7Z2QTJne1k4GNFGvy66URk3k5cBPl5j4/1yc4xGV+aWYl6L8
q8RorRU/CltObHKrji/jdiY1WtdGrkpRyCEFc+XNPazL9xSLLu5bz6XlvKwoks+8a5KYT/VFUovM
JbM0bpAXM8Z7rGaPuXjqXtZBg5praTZLu/WNcA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PYKBDinOGc/kIVdFzXrz2wA4/QNFxLDrQfTWfR5TjYE6bm49vrZi0bawcr9HXp4OP1+XxPLB3oCP
oV5e/rYeDln531ebt8yEg27XCoSHEX4FU8oG8aBJ8fqgWayOnAMJt025WodOxuZXbhT1zPo7J3uh
6iO9Mv7RtYE2fZ1W+G8oN//FTOEJYPWlKYnt0cDeZrN3I4rHHptZHuu7l8T+df0PYea3x6U3Mvkl
ojZ+TwQtdu0NuYY5j3QNgx3+W2XYq1M773FAnEz/deW54EjE+jf1jjrBk2pl8SYxeKuutS15oPVF
eHdqXYVcJxoUY5JH8z04lITKEnZ4oq6sYS6dog==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
tl+2vFCWZ583gQGsVC7oopz2NCKBiJ9uOHYBGzJZheOHJMqI/ehNvo25l710eBx00tztXzM30AH6
ZhAJg+kJwE2jO0MV5fmG5dnwXmLqoGEJMBs7xwWxvYK7w/0z9M0AJKD7HnuC+IiLhNU/fIxyuE+I
+vWqp//RcfY0tMMp2I2J1yEW6GUahS1ve/4JchssZ7Xu7VthoSDWXMQWATbvsUsDzeSo2+Ruz8Kq
Dc05HqEU8NgBxDPPEKLCcdKLp4byglwj7iCAtCjsPy8P18qjgb2sycFjNgmaiNMMB51WqeD+hneG
hLOue9bqVdEojkrb3q4WbsGZKz0bAGsryxslOlYHP1b8vey3yI2ixA80wyERe8d3GRIeZiSxGykH
qWxsE6x/iyi8QRb5mXZPMApA+Fln8tYmn7+1rFCm8gF4gJWhr1PsSJqTi658symGrzT0Ghjvf2QL
SvvoaeNdy0pOsWs7jLBFndd4GiFA+9K6Y33sziLToU9EvvFokENIslod

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
oYiCujFRj1F3wKsGZlHR9niEtR9MLXEVAVfy+f/3xrmpW6Ye5a+fBCvm4TH+iRQefGHNdMPnzTNW
K/pEPAS9uMJjOdFiu+APT+LYrSRnEg4W0dX5buSDGM6LBWAuMseoTMjbJJoYDGLRckJgW43E30mX
ej4823nkbfwc+Ecbrup825qLyv8RTQLNHafvJA5lSapdqXwnlOIYRmcHn+sfAh5pGv9kW9aokcdh
ObR2XYxX99rYloyvz3x0pmjxD5ILW4SQMB1IUEuuyqX6eb5IQ+kZ41hjvsHIuQH29vzpCfV9Jqha
WC5yxxK1R+cleZSKD1H1gVzbTei8uFs/91Bgeg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
urNc+S8AFPj+GVFdqJE5V7P8O6QI6MA3nkwYb8NKbYbVufnXKg6voJIRYYeYr7EOa8mrqirozWbY
Lln9SLWnkaAy2LvL/N6WahoQdCt++4RH+xe768XvSrVUFPrIwZRixqMLurc/tPov4i5P/ukZKl18
ZPZvXRzUNlvCZnMPcF+5QCQihqPbjcZ0YyGgWgX/ipTGG3sNqmylGN7qLa4Rgqu/mB5a2xVyu5Wc
911+/X3VVFx697WVaP5V0SbOzYN8R8+8B8kdznwixMA+f4lSbBXyRysVOSzYjo8bKEMqyKMVBQn9
xDmEuV0DvVWXdO7VPvWA1LuJFwS07OxeI2GCcQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QcP7fsLZxaDrG29e9HQeXfu2TsKsdyW7Yc1vWct6lbmDEfXkWMU1fFWSPIjPzRc9UOnfEu0bRn+B
D+8MWokqes3WF7txljBmgUPiNGZ8arUU6ENa/IY/Wv7iaB/ZKM5PtdnFAkjDIrYyKFCTz/U6Yzwi
hBGGarK/wYQOLzeeKRewiPTiNUL7tztWuMZ1t1msxD951EeKrwjrjcXIIuf/TzrOGUOlWgjHlnrl
4Q/lfMAnRLBNTSWG+5wWewCE8jK2X/gJ5AV4p3x1WP3+JglbxpP39l3pzedXqciZPbuz2XlFnRPV
KByaUaAShzJ56p8+0HjWebibqQdieGNPiPWW0Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 52576)
`pragma protect data_block
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
oWeuluHBdjdh+aBkr5dDXxmo+Mk/OQ==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
