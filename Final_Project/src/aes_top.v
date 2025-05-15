// AES Top-Level module
// Implements AES encryption/decryption with a serial interface
// for compatibility with ZYBO Z7-10 FPGA I/O constraints

`timescale 1ns / 1ps

module aes_top(
    input wire clk,              // System clock (125 MHz) - K17
    input wire rst,              // Reset button (BTN0) - K18
    input wire start,            // Start operation (BTN1) - P16
    input wire wr_en,            // Write enable for loading data (BTN2) - K19
    input wire [4:0] addr,       // Address bus (SW1-SW5)
    input wire [7:0] data_in,    // 8-bit input data bus (SW6-SW13)
    input wire decrypt,          // Decrypt mode select (SW0) - G15
    output wire [7:0] data_out,  // 8-bit output data bus (LED0-LED7)
    output wire busy,            // Busy indicator (LED8)
    output wire valid,           // Valid data indicator (LED9)
    output wire done             // Operation complete indicator (LED10)
);

    // Instantiate the AES serial interface
    aes_serial_interface aes_serial_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_out(data_out),
        .addr(addr),
        .wr_en(wr_en),
        .start(start),
        .decrypt(decrypt),
        .busy(busy),
        .valid(valid),
        .done(done)
    );

endmodule

/* 
IMPLEMENTATION NOTES:

This is a revised implementation of the AES-128 encryption/decryption module specifically 
for the ZYBO Z7-10 FPGA. The original wide parallel interface has been replaced with a 
serial interface to reduce I/O pin count from 381 to 24 pins, solving the overutilization issue.

The module uses the pipelined AES core internally but provides a byte-by-byte interface
for loading data/key and reading results.

USAGE INSTRUCTIONS:

1. Loading Data:
   - Set the address (addr[4:0]) to select which byte to load:
     * 0-15: Input data bytes (most significant byte first)
     * 16-31: Key bytes (most significant byte first)
   - Set the input data (data_in[7:0]) to the desired value
   - Assert wr_en (press BTN2) to store the byte
   - Repeat for all 32 bytes (16 for data, 16 for key)

2. Starting Operation:
   - Select encrypt/decrypt mode using decrypt switch (SW0)
   - Assert start (press BTN1) to begin operation
   - The busy LED will indicate the core is processing
   - Wait for done LED to indicate completion

3. Reading Results:
   - Set the address (addr[4:0]) to select which byte to read (0-15)
   - Observe the output byte on data_out LEDs (LED0-LED7)
   - The valid LED indicates output data is valid
   - Repeat for all 16 bytes of the result

Hardware Connections:
- Clock: Connect to 125MHz system clock (K17)
- Reset: Connect to BTN0 (K18)
- Start: Connect to BTN1 (P16)
- Write Enable: Connect to BTN2 (K19)
- Address[4:0]: Connect to SW1-SW5
- Data_in[7:0]: Connect to SW6-SW13
- Decrypt: Connect to SW0 (G15)
- Data_out[7:0]: Connect to LED0-LED7
- Busy: Connect to LED8
- Valid: Connect to LED9
- Done: Connect to LED10
*/