## Clock signal 125 MHz - Map to clk_A
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk_A }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk_A }];

## Clock signal for clk_B - We'll derive this from clk_A using MMCM in the design
## Or we can use the FCLK_CLK0 from the processing system for clk_B if this is on a Zynq device
## Alternatively create a virtual clock with a different period for simulation
create_clock -add -name clk_B_pin -period 12.00 -waveform {0 6} [get_ports { clk_B }];
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk_B }]; #Using another available clock pin

## Reset - BTN0
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]

## Input signal - Using switch SW0
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { IN }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

## Output signal B - Using LED LD0
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { B }]; #IO_L23P_T3_35 Sch=led[0]

## Monitor outputs
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { A_mon }]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { B1_mon }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=led[2]

## Configuration options, can be used to reduce power consumption
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## CDC Timing constraints
## Declare clock domains as asynchronous to each other
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks clk_B_pin]

## Set false paths for CDC signals (optional additional constraints)
set_false_path -from [get_cells */A_reg] -to [get_cells */B1_reg]