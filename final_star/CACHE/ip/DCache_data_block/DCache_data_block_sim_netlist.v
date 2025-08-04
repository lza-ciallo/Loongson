// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
// Date        : Fri Aug  1 22:49:11 2025
// Host        : yuan02 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               d:/Users/yuanm/Chiplab/chiplab/IP/myCPU/A2/CACHE/ip/DCache_data_block/DCache_data_block_sim_netlist.v
// Design      : DCache_data_block
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "DCache_data_block,blk_mem_gen_v8_4_9,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_9,Vivado 2024.2" *) 
(* NotValidForBitStream *)
module DCache_data_block
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
  (* C_INIT_FILE = "DCache_data_block.mem" *) 
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
  DCache_data_block_blk_mem_gen_v8_4_9 U0
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
1xeoWKabo7htLqEfNgofralalqUTFA==
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
