## Clock signal 125 MHz
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Reset - BTN0
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { rst }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]

## Start - BTN1
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { start }]; #IO_L24N_T3_34 Sch=btn[1]

## Mode select - SW0
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sel_pipelined }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

## Done indicator - LD0
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { done }]; #IO_L23P_T3_35 Sch=led[0]

## Cycle count debug - LD1-LD3 (connect to MSBs of cycle_count for visualization)
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { cycle_count[29] }]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { cycle_count[30] }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { cycle_count[31] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]

## Configuration options, can be used to reduce power consumption
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Timing constraints
# Set a reasonable maximum delay to ensure timing closure
set_max_delay 8.0 -from [all_registers] -to [all_registers]

## False path constraints (when crossing clock domains, if any)
# No clock domain crossing in this design, so no false paths needed
