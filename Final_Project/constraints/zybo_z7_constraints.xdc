## Zybo Z7-10 Constraints File for AES Implementation
## This file contains combined pin mappings for both the standard and serial interfaces

## ============================================================================
## Common Constraints (shared between both implementations)
## ============================================================================

## Clock signal 125 MHz
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Reset - BTN0
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { rst }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]

## Start operation - BTN1
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { start }]; #IO_L24N_T3_34 Sch=btn[1]

## Write Enable - BTN2
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { wr_en }]; #IO_L10P_T1_AD11P_35 Sch=btn[2]

## ============================================================================
## Standard AES Implementation Constraints
## Uncomment this section when using the standard AES implementation
## ============================================================================

## Mode Toggle - BTN3
#set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { mode_btn }]; #IO_L7P_T1_34 Sch=btn[3]

## Switches 0-3
#set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #IO_L19N_T3_VREF_35 Sch=sw[0]
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; #IO_L24P_T3_34 Sch=sw[1]
#set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #IO_L4N_T0_34 Sch=sw[2]
#set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]

## LEDs for output data and status
#set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led_out[0] }]; #IO_L23P_T3_35 Sch=led[0]
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led_out[1] }]; #IO_L23N_T3_35 Sch=led[1]
#set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led_out[2] }]; #IO_0_35 Sch=led[2]
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led_out[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { led_out[4] }]; #IO_L21P_T3_DQS_AD14P_35 Sch=led[4]
#set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { led_out[5] }]; #IO_L21N_T3_DQS_AD14N_35 Sch=led[5]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { led_out[6] }]; #IO_L22P_T3_AD7P_35 Sch=led[6]
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { led_out[7] }]; #IO_L25_35 Sch=led[7]

## ============================================================================
## Serial Interface AES Implementation Constraints
## Uncomment this section when using the serial interface implementation
## ============================================================================

## Decrypt mode select - SW0
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { decrypt }]; #IO_L19N_T3_VREF_35 Sch=sw[0]

## Address - SW1-SW3 (lower 3 bits of addr)
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { addr[0] }]; #IO_L24P_T3_34 Sch=sw[1]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { addr[1] }]; #IO_L4N_T0_34 Sch=sw[2]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { addr[2] }]; #IO_L9P_T1_DQS_34 Sch=sw[3]

## Additional address bits - BTN3 for addr[3] (use button press to toggle)
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { addr[3] }]; #IO_L7P_T1_34 Sch=btn[3]

## Data input - Use a combination of LEDs and buttons for feedback and input
## Note: these pins are shared with decrypt and address pins
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { data_in[0] }]; #IO_L19N_T3_VREF_35 Sch=sw[0] (shared with decrypt)
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { data_in[1] }]; #IO_L24P_T3_34 Sch=sw[1] (shared with addr[0])
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { data_in[2] }]; #IO_L4N_T0_34 Sch=sw[2] (shared with addr[1])
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { data_in[3] }]; #IO_L9P_T1_DQS_34 Sch=sw[3] (shared with addr[2])

## Data output - LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { data_out[0] }]; #IO_L23P_T3_35 Sch=led[0]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { data_out[1] }]; #IO_L23N_T3_35 Sch=led[1]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { data_out[2] }]; #IO_0_35 Sch=led[2]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { data_out[3] }]; #IO_L3N_T0_DQS_AD1N_35 Sch=led[3]

## Status indicators - RGB LEDs
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { busy }]; #IO_L18P_T2_34 Sch=led6_r
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { valid }]; #IO_L6N_T0_VREF_35 Sch=led6_g
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { done }]; #IO_L8P_T1_AD10P_35 Sch=led6_b

## ============================================================================
## Common Configuration Options
## ============================================================================

## Configuration options, can be used to reduce power consumption
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Timing constraints
# Set a reasonable maximum delay to ensure timing closure
set_max_delay 8.0 -from [all_registers] -to [all_registers]
