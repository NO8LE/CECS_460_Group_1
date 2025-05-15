## Clock signal 125 MHz
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Reset - BTN0
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { rst }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]

## Start - BTN1 (using BTN1 for start)
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { start }]; #IO_L24N_T3_34 Sch=btn[1]

## Write Enable - BTN2
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { wr_en }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]

## Decrypt mode select - SW0
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { decrypt }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

## Address bits [4:0] - SW1-SW5
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { addr[0] }]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { addr[1] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { addr[2] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { addr[3] }]; #IO_L6N_T0_VREF_34 Sch=sw[4]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { addr[4] }]; #IO_L7P_T1_34 Sch=sw[5]

## 8-bit data_in - SW6-SW13
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { data_in[0] }]; #IO_L7N_T1_34 Sch=sw[6]
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { data_in[1] }]; #IO_L17N_T2_34 Sch=sw[7]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { data_in[2] }]; #IO_L1P_T0_34 Sch=sw[8]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { data_in[3] }]; #IO_L1N_T0_34 Sch=sw[9]
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { data_in[4] }]; #IO_L2P_T0_34 Sch=sw[10]
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { data_in[5] }]; #IO_L3N_T0_DQS_34 Sch=sw[11]
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { data_in[6] }]; #IO_L9N_T1_DQS_34 Sch=sw[12]
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { data_in[7] }]; #IO_L20P_T3_34 Sch=sw[13]

## 8-bit data_out - LED0-LED7
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { data_out[0] }]; #IO_L23P_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { data_out[1] }]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { data_out[2] }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { data_out[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { data_out[4] }]; #IO_L18P_T2_34 Sch=led[4]
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { data_out[5] }]; #IO_L17P_T2_34 Sch=led[5]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { data_out[6] }]; #IO_L20N_T3_34 Sch=led[6]
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { data_out[7] }]; #IO_L21N_T3_DQS_34 Sch=led[7]

## Status indicators - LED8-LED10
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { busy }]; #IO_L5P_T0_34 Sch=led[8]
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { valid }]; #IO_L14P_T2_SRCC_34 Sch=led[9]
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { done }]; #IO_L14N_T2_SRCC_34 Sch=led[10]

## Configuration options, can be used to reduce power consumption
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Timing constraints
# Set a reasonable maximum delay to ensure timing closure
set_max_delay 8.0 -from [all_registers] -to [all_registers]

## False path constraints (when crossing clock domains, if any)
# No clock domain crossing in this design, so no false paths needed