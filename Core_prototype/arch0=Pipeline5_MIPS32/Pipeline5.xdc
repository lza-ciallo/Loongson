set_property -dict {PACKAGE_PIN A2      IOSTANDARD LVCMOS33} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN D4      IOSTANDARD LVCMOS33} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN E5      IOSTANDARD LVCMOS33} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN B4      IOSTANDARD LVCMOS33} [get_ports {leds[3]}]
set_property -dict {PACKAGE_PIN B2      IOSTANDARD LVCMOS33} [get_ports {leds[4]}]
set_property -dict {PACKAGE_PIN E6      IOSTANDARD LVCMOS33} [get_ports {leds[5]}]
set_property -dict {PACKAGE_PIN C3      IOSTANDARD LVCMOS33} [get_ports {leds[6]}]
set_property -dict {PACKAGE_PIN C4      IOSTANDARD LVCMOS33} [get_ports {leds[7]}]

set_property -dict {PACKAGE_PIN H26     IOSTANDARD LVCMOS33} [get_ports {enable[0]}]
set_property -dict {PACKAGE_PIN G26     IOSTANDARD LVCMOS33} [get_ports {enable[1]}]
set_property -dict {PACKAGE_PIN G25     IOSTANDARD LVCMOS33} [get_ports {enable[2]}]
set_property -dict {PACKAGE_PIN E26     IOSTANDARD LVCMOS33} [get_ports {enable[3]}]

set_property -dict {PACKAGE_PIN Y3      IOSTANDARD LVCMOS33} [get_ports {rst}]
set_property -dict {PACKAGE_PIN AC19    IOSTANDARD LVCMOS33} [get_ports {clk}]

set_property -dict {PACKAGE_PIN K23     IOSTANDARD LVCMOS33} [get_ports {indicator[0]}]
set_property -dict {PACKAGE_PIN J21     IOSTANDARD LVCMOS33} [get_ports {indicator[1]}]
set_property -dict {PACKAGE_PIN H23     IOSTANDARD LVCMOS33} [get_ports {indicator[2]}]
set_property -dict {PACKAGE_PIN J19     IOSTANDARD LVCMOS33} [get_ports {indicator[3]}]

# set_property -dict {PACKAGE_PIN H7      IOSTANDARD LVCMOS33} [get_ports {locked}]