`timescale 1ns / 1ps

module clock_gen(
    input wire clk_in,     // 125 MHz board clock
    input wire rst_n,      // Active low reset
    output wire clk_90mhz, // 90 MHz output clock
    output wire clk_65mhz, // 65 MHz output clock
    output wire locked     // PLL lock status
);

    // Use Xilinx MMCM (Mixed-Mode Clock Manager)
    // Calculations:
    // Input: 125 MHz
    // For 90 MHz: 125 * 9 / 15.625 = 72 MHz
    // For 65 MHz: 125 * 13 / 25 = 65 MHz

    // MMCM instance for Xilinx 7-series
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),        // Jitter programming (OPTIMIZED, HIGH, LOW)
        .CLKFBOUT_MULT_F(9.0),         // Multiply value for all CLKOUT (2.000-64.000)
        .CLKFBOUT_PHASE(0.0),           // Phase offset in degrees of CLKFB (-360.000-360.000)
        .CLKIN1_PERIOD(8.0),            // Input clock period in ns (125 MHz = 8 ns)
        
        // CLKOUT0 - 90 MHz
        .CLKOUT0_DIVIDE_F(12.5),        // Divide amount for CLKOUT0 (1.000-128.000)
        .CLKOUT0_DUTY_CYCLE(0.5),       // Duty cycle for CLKOUT0 (0.01-0.99)
        .CLKOUT0_PHASE(0.0),            // Phase offset for CLKOUT0 (-360.000-360.000)
        
        // CLKOUT1 - 65 MHz
        .CLKOUT1_DIVIDE(17),            // Divide amount for CLKOUT1 (1-128)
        .CLKOUT1_DUTY_CYCLE(0.5),       // Duty cycle for CLKOUT1 (0.01-0.99)
        .CLKOUT1_PHASE(0.0),            // Phase offset for CLKOUT1 (-360.000-360.000)
        
        .DIVCLK_DIVIDE(1),              // Master division value (1-106)
        .REF_JITTER1(0.01),             // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE")          // Delays DONE until MMCM is locked (FALSE, TRUE)
    ) mmcm_inst (
        .CLKIN1(clk_in),                // 1-bit input: Clock input
        .CLKFBIN(clkfb),                // 1-bit input: Feedback clock
        .RST(~rst_n),                   // 1-bit input: Reset (active high)
        .PWRDWN(1'b0),                  // 1-bit input: Power-down
        
        .CLKOUT0(clk_90mhz_unbuf),      // 1-bit output: CLKOUT0
        .CLKOUT1(clk_65mhz_unbuf),      // 1-bit output: CLKOUT1
        .CLKFBOUT(clkfb),               // 1-bit output: Feedback clock
        .LOCKED(locked)                 // 1-bit output: LOCK status
    );
    
    // Output buffers for generated clocks
    BUFG bufg_90mhz (
        .I(clk_90mhz_unbuf),
        .O(clk_90mhz)
    );
    
    BUFG bufg_65mhz (
        .I(clk_65mhz_unbuf),
        .O(clk_65mhz)
    );
    
    // Internal signals
    wire clkfb;
    wire clk_90mhz_unbuf;
    wire clk_65mhz_unbuf;

endmodule