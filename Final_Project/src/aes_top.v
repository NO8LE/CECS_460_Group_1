// AES Top-Level module
// Supports both direct mode and state-machine mode for the ZYBO Z7-10 FPGA
// with limited I/O resources

`timescale 1ns / 1ps

module aes_top(
    input wire clk,                  // System clock (125 MHz) - K17
    input wire rst,                  // Reset button (BTN0) - K18
    input wire start,                // Start operation (BTN1) - P16
    input wire wr_en,                // Write enable for loading data (BTN2) - K19
    input wire mode_btn,             // Mode toggle button (BTN3) - Y16
    input wire [3:0] sw,             // 4 switches (SW0-SW3)
    output wire [7:0] led_out        // 8 LEDs for output data and status
);

    // Internal signals
    reg [7:0] data_in;               // Data input to AES core
    reg [4:0] addr;                  // Address for AES core
    wire [7:0] data_out;             // Data output from AES core
    wire busy, valid, done;          // Status signals
    reg decrypt;                     // Decrypt mode select
    
    // State machine states
    localparam STATE_DATA_LOW  = 2'd0;  // Input lower nibble of data
    localparam STATE_DATA_HIGH = 2'd1;  // Input upper nibble of data
    localparam STATE_ADDR      = 2'd2;  // Input address
    localparam STATE_MONITOR   = 2'd3;  // Monitor/display output
    
    // State registers
    reg [1:0] state;
    reg mode_btn_prev;
    
    // Initialize state
    initial begin
        state = STATE_DATA_LOW;
        data_in = 8'h00;
        addr = 5'h00;
        mode_btn_prev = 1'b0;
        decrypt = 1'b0;
    end
    
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
    
    // State machine for input handling
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_DATA_LOW;
            data_in <= 8'h00;
            addr <= 5'h00;
            mode_btn_prev <= 1'b0;
            decrypt <= 1'b0;
        end else begin
            // Detect button press (rising edge)
            mode_btn_prev <= mode_btn;
            
            // State machine
            case (state)
                STATE_DATA_LOW: begin
                    // Lower nibble of data comes from switches
                    data_in[3:0] <= sw;
                    
                    // If mode button pressed, move to next state
                    if (mode_btn && !mode_btn_prev) begin
                        state <= STATE_DATA_HIGH;
                    end
                end
                
                STATE_DATA_HIGH: begin
                    // Upper nibble of data comes from switches
                    data_in[7:4] <= sw;
                    
                    // If mode button pressed, move to next state
                    if (mode_btn && !mode_btn_prev) begin
                        state <= STATE_ADDR;
                    end
                end
                
                STATE_ADDR: begin
                    // Lower 3 bits of address come from switches
                    addr[2:0] <= sw[2:0];
                    // SW3 can be used for addr bit 3
                    addr[3] <= sw[3];
                    // Use decrypt mode bit from SW0 when in this state
                    decrypt <= sw[0];
                    
                    // If mode button pressed, move to next state
                    if (mode_btn && !mode_btn_prev) begin
                        state <= STATE_MONITOR;
                    end
                end
                
                STATE_MONITOR: begin
                    // In monitor state, user can observe outputs
                    // If mode button pressed, cycle back to first state
                    if (mode_btn && !mode_btn_prev) begin
                        state <= STATE_DATA_LOW;
                    end
                end
            endcase
        end
    end
    
    // Output assignment
    // LEDs 0-3: Current data output nibble
    // LEDs 4-6: Status indicators (busy, valid, done)
    // LED 7: Current state indicator
    assign led_out[3:0] = data_out[3:0];  // Show lower nibble of output data
    assign led_out[4] = busy;             // LED4 shows busy status
    assign led_out[5] = valid;            // LED5 shows valid status
    assign led_out[6] = done;             // LED6 shows done status
    assign led_out[7] = (state == STATE_MONITOR); // LED7 on when in monitor state
    
endmodule

/* 
IMPLEMENTATION NOTES:

This is a revised implementation of the AES-128 encryption/decryption module specifically 
for the ZYBO Z7-10 FPGA. It addresses the limited I/O capabilities of the board by
implementing a state machine approach that maximizes the use of the available buttons
and switches.

USAGE INSTRUCTIONS:

The module uses a state machine with four states, controlled by the mode button (BTN3):

1. DATA_LOW State:
   - Set the lower 4 bits of data using the switches (SW0-SW3)
   - Press mode button (BTN3) to advance to DATA_HIGH state

2. DATA_HIGH State:
   - Set the upper 4 bits of data using the switches (SW0-SW3)
   - Press mode button (BTN3) to advance to ADDR state

3. ADDR State:
   - Set the address bits using switches:
     * SW0: Set decrypt mode (1=decrypt, 0=encrypt)
     * SW1-SW3: Lower 3 bits of address
     * SW4: 4th bit of address (if needed)
   - Press write enable (BTN2) to store the byte at the selected address
   - Press mode button (BTN3) to advance to MONITOR state

4. MONITOR State:
   - View the output data on LEDs 0-3 (lower nibble of the output byte)
   - Status indicators:
     * LED4: Busy
     * LED5: Valid
     * LED6: Done
     * LED7: Monitor state indicator (on when in MONITOR state)
   - Press start (BTN1) to begin encryption/decryption
   - Press mode button (BTN3) to return to DATA_LOW state

Loading process:
1. Load all 16 data bytes (address 0-15)
2. Load all 16 key bytes (address 16-31)
3. Enter monitor state, select decrypt mode if needed
4. Press start button to begin operation
5. After operation completes, set address (0-15) to view results

Hardware Connections:
- Clock: Connect to 125MHz system clock (K17)
- Reset: Connect to BTN0 (K18)
- Start: Connect to BTN1 (P16)
- Write Enable: Connect to BTN2 (K19)
- Mode Button: Connect to BTN3 (Y16)
- Switches: Connect to SW0-SW3
- LED Output: Connect to LED0-LED7
*/
