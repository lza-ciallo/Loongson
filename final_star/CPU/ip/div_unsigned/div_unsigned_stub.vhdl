-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
-- Date        : Fri Aug  1 20:46:37 2025
-- Host        : yuan02 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/Users/yuanm/Chiplab/chiplab/IP/myCPU/A2/CPU/ip/div_unsigned/div_unsigned_stub.vhdl
-- Design      : div_unsigned
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a200tfbg676-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity div_unsigned is
  Port ( 
    aclk : in STD_LOGIC;
    aresetn : in STD_LOGIC;
    s_axis_divisor_tvalid : in STD_LOGIC;
    s_axis_divisor_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axis_dividend_tvalid : in STD_LOGIC;
    s_axis_dividend_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axis_dout_tvalid : out STD_LOGIC;
    m_axis_dout_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

  attribute CHECK_LICENSE_TYPE : string;
  attribute CHECK_LICENSE_TYPE of div_unsigned : entity is "div_unsigned,div_gen_v5_1_23,{}";
  attribute core_generation_info : string;
  attribute core_generation_info of div_unsigned : entity is "div_unsigned,div_gen_v5_1_23,{x_ipProduct=Vivado 2024.2,x_ipVendor=xilinx.com,x_ipLibrary=ip,x_ipName=div_gen,x_ipVersion=5.1,x_ipCoreRevision=23,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,C_XDEVICEFAMILY=artix7,C_HAS_ARESETN=1,C_HAS_ACLKEN=0,C_LATENCY=16,ALGORITHM_TYPE=1,DIVISOR_WIDTH=32,DIVIDEND_WIDTH=32,SIGNED_B=0,DIVCLK_SEL=1,FRACTIONAL_B=0,FRACTIONAL_WIDTH=32,C_HAS_DIV_BY_ZERO=0,C_THROTTLE_SCHEME=3,C_TLAST_RESOLUTION=0,C_HAS_S_AXIS_DIVISOR_TUSER=0,C_HAS_S_AXIS_DIVISOR_TLAST=0,C_S_AXIS_DIVISOR_TDATA_WIDTH=32,C_S_AXIS_DIVISOR_TUSER_WIDTH=1,C_HAS_S_AXIS_DIVIDEND_TUSER=0,C_HAS_S_AXIS_DIVIDEND_TLAST=0,C_S_AXIS_DIVIDEND_TDATA_WIDTH=32,C_S_AXIS_DIVIDEND_TUSER_WIDTH=1,C_M_AXIS_DOUT_TDATA_WIDTH=64,C_M_AXIS_DOUT_TUSER_WIDTH=1}";
  attribute downgradeipidentifiedwarnings : string;
  attribute downgradeipidentifiedwarnings of div_unsigned : entity is "yes";
end div_unsigned;

architecture stub of div_unsigned is
  attribute syn_black_box : boolean;
  attribute black_box_pad_pin : string;
  attribute syn_black_box of stub : architecture is true;
  attribute black_box_pad_pin of stub : architecture is "aclk,aresetn,s_axis_divisor_tvalid,s_axis_divisor_tdata[31:0],s_axis_dividend_tvalid,s_axis_dividend_tdata[31:0],m_axis_dout_tvalid,m_axis_dout_tdata[63:0]";
  attribute x_interface_info : string;
  attribute x_interface_info of aclk : signal is "xilinx.com:signal:clock:1.0 aclk_intf CLK";
  attribute x_interface_mode : string;
  attribute x_interface_mode of aclk : signal is "slave aclk_intf";
  attribute x_interface_parameter : string;
  attribute x_interface_parameter of aclk : signal is "XIL_INTERFACENAME aclk_intf, ASSOCIATED_BUSIF S_AXIS_DIVIDEND:S_AXIS_DIVISOR:M_AXIS_DOUT, ASSOCIATED_RESET aresetn, ASSOCIATED_CLKEN aclken, FREQ_HZ 1000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0";
  attribute x_interface_info of aresetn : signal is "xilinx.com:signal:reset:1.0 aresetn_intf RST";
  attribute x_interface_mode of aresetn : signal is "slave aresetn_intf";
  attribute x_interface_parameter of aresetn : signal is "XIL_INTERFACENAME aresetn_intf, POLARITY ACTIVE_LOW, INSERT_VIP 0";
  attribute x_interface_info of s_axis_divisor_tvalid : signal is "xilinx.com:interface:axis:1.0 S_AXIS_DIVISOR TVALID";
  attribute x_interface_mode of s_axis_divisor_tvalid : signal is "slave S_AXIS_DIVISOR";
  attribute x_interface_parameter of s_axis_divisor_tvalid : signal is "XIL_INTERFACENAME S_AXIS_DIVISOR, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute x_interface_info of s_axis_divisor_tdata : signal is "xilinx.com:interface:axis:1.0 S_AXIS_DIVISOR TDATA";
  attribute x_interface_info of s_axis_dividend_tvalid : signal is "xilinx.com:interface:axis:1.0 S_AXIS_DIVIDEND TVALID";
  attribute x_interface_mode of s_axis_dividend_tvalid : signal is "slave S_AXIS_DIVIDEND";
  attribute x_interface_parameter of s_axis_dividend_tvalid : signal is "XIL_INTERFACENAME S_AXIS_DIVIDEND, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute x_interface_info of s_axis_dividend_tdata : signal is "xilinx.com:interface:axis:1.0 S_AXIS_DIVIDEND TDATA";
  attribute x_interface_info of m_axis_dout_tvalid : signal is "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TVALID";
  attribute x_interface_mode of m_axis_dout_tvalid : signal is "master M_AXIS_DOUT";
  attribute x_interface_parameter of m_axis_dout_tvalid : signal is "XIL_INTERFACENAME M_AXIS_DOUT, TDATA_NUM_BYTES 8, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 0, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 100000000, PHASE 0.0, LAYERED_METADATA undef, INSERT_VIP 0";
  attribute x_interface_info of m_axis_dout_tdata : signal is "xilinx.com:interface:axis:1.0 M_AXIS_DOUT TDATA";
  attribute x_core_info : string;
  attribute x_core_info of stub : architecture is "div_gen_v5_1_23,Vivado 2024.2";
begin
end;
