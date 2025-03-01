## Part specification
## Zynq-7010 FPGA on ZYBO-Z7-10 board
set_property PART xc7z010clg400-1 [current_project]

## Clock Signal
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports {clk}]; # 125 MHz system clock
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports {clk}]

## Basic I/O - Verified for ZYBO Z7-10 board with xc7z010clg400
## Reset - BTN0 (BTNR)
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports {rst_n}];

## Start Button - BTN1 (BTNL)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports {start_test}];

## Status LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports {busy}];      # LD0
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports {success}];   # LD1

## CDC Timing Constraints
# Identify clock domains
create_generated_clock -name clk_90mhz -source [get_pins clock_gen_inst/mmcm_inst/CLKOUT0] -divide_by 1 [get_nets clk_90mhz]
create_generated_clock -name clk_65mhz -source [get_pins clock_gen_inst/mmcm_inst/CLKOUT1] -divide_by 1 [get_nets clk_65mhz]

# Set asynchronous clock groups
set_clock_groups -asynchronous -group {sys_clk_pin} -group {clk_90mhz}
set_clock_groups -asynchronous -group {sys_clk_pin} -group {clk_65mhz}
set_clock_groups -asynchronous -group {clk_90mhz} -group {clk_65mhz}

# Set false paths for CDC synchronization registers
set_false_path -from [get_cells -hierarchical *wr_ptr_gray_reg*] -to [get_cells -hierarchical *wr_ptr_gray_sync1_reg*]
set_false_path -from [get_cells -hierarchical *rd_ptr_gray_reg*] -to [get_cells -hierarchical *rd_ptr_gray_sync1_reg*]

# Additional false paths for control signal synchronizers
set_false_path -from [get_cells -hierarchical *rst_sync*[0]_reg*] -to [get_cells -hierarchical *rst_sync*[1]_reg*]
set_false_path -from [get_cells -hierarchical *start_sync*[0]_reg*] -to [get_cells -hierarchical *start_sync*[1]_reg*]