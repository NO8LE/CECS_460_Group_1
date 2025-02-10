## Clock Signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {clk}]; # System Clock

## Switches (Inputs)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## Button (Input)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {btn}];

## LEDs for Feedback
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {led_red}];   # Red LED
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports {led_green}]; # Green LED

## Reset Button
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports {rst}];

## LED Display (Shows correct answer)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led_display[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led_display[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led_display[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led_display[3] }];
