// AES Top Module Testbench
// Tests the top-level AES module with state machine interface for the ZYBO Z7-10 FPGA
// Enhanced to thoroughly test decryption functionality

`timescale 1ns / 1ps

module aes_top_tb;
    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg wr_en;
    reg mode_btn;
    reg [3:0] sw;
    
    // Outputs from the updated module interface
    wire [3:0] data_out;    // Data output LEDs (lower 4 bits)
    wire busy;              // Busy indicator - RGB LED
    wire valid;             // Valid indicator - RGB LED
    wire done;              // Done indicator - RGB LED
    
    // Virtual LED array to maintain backward compatibility with existing testbench code
    wire [7:0] led_out;
    assign led_out[3:0] = data_out;
    assign led_out[4] = busy;
    assign led_out[5] = valid;
    assign led_out[6] = done; 
    assign led_out[7] = 1'b0; // Monitor state indicator - no longer directly accessible
    
    // Test vector from NIST FIPS 197 Appendix C.1
    localparam [127:0] PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    // Variables to store results
    reg [127:0] read_data;
    reg [127:0] encrypted_data;
    reg [127:0] decrypted_data;
    integer i;
    integer errors;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #4 clk = ~clk; // 125 MHz clock
    end
    
    // Helper task: Input a byte
    task input_byte;
        input [7:0] byte_val;
        input [4:0] addr_val;
        input decrypt_val;
        begin
            // Input lower nibble
            sw = byte_val[3:0];
            #20;
            
            // Move to upper nibble state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Input upper nibble
            sw = byte_val[7:4];
            #20;
            
            // Move to address state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Input address and decrypt mode
            sw[2:0] = addr_val[2:0];
            sw[3] = addr_val[3];
            // SW0 is used for decrypt mode in this state
            sw[0] = decrypt_val;
            #20;
            
            // Write the byte
            wr_en = 1;
            #20;
            wr_en = 0;
            #20;
            
            // Return to data input state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
        end
    endtask
    
    // Helper task: Read a byte
    task read_byte;
        input [4:0] addr_val;
        output [7:0] data_val;
        begin
            // Set state to DATA_LOW
            // Note: We've changed led_out[7] to be always 0, so this loop may need adjustment in real testing
            while (led_out[7] == 1) begin
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
            end
            
            // Move to address state (need to go through DATA_HIGH first)
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Set address
            sw[2:0] = addr_val[2:0];
            sw[3] = addr_val[3];
            #20;
            
            // Move to monitor state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Read the data (only lower nibble is visible)
            data_val[3:0] = led_out[3:0];
            data_val[7:4] = 4'h0; // Upper nibble not directly visible
            #20;
        end
    endtask

    // Enhanced task to test encryption
    task test_encryption;
        begin
            $display("\n**********************************************");
            $display("Starting Full AES-128 Encryption Test");
            $display("**********************************************");
            
            // First reset the system
            rst = 1;
            #100;
            rst = 0;
            #20;
            
            // Load plaintext bytes (addresses 0-15)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(PLAINTEXT[127-8*i -: 8], i, 1'b0);
                $display("Loaded plaintext byte %d: %h", i, PLAINTEXT[127-8*i -: 8]);
            end
            
            // Load key bytes (addresses 16-31)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(KEY[127-8*i -: 8], i+16, 1'b0);
                $display("Loaded key byte %d: %h", i, KEY[127-8*i -: 8]);
            end
            
            // Enter monitor state and start encryption
            // Move to address state (need to go through DATA_LOW and DATA_HIGH first)
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Set address 0 and encrypt mode (sw[0] = 0)
            sw = 4'h0;
            #20;
            
            // Move to monitor state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Start encryption
            start = 1;
            #40;
            
            // Wait for operation to complete - monitor done signal (LED6)
            while (led_out[6] == 0) begin
                #10;
            end
            
            // Release start button
            start = 0;
            #40;
            
            $display("Encryption completed. Output in LEDs.");
            
            // For simulation only - store encrypted data for verification
            // In actual hardware, we'd need to read each byte
            for (i = 0; i < 16; i = i + 1) begin
                // Set address to read encrypted byte
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                // Set address
                sw[3:0] = i[3:0];
                #20;
                
                // Enter monitor state
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                // Read the data
                encrypted_data[127-8*i -: 8] = {4'h0, led_out[3:0]};
                $display("Read encrypted byte %d: %h", i, encrypted_data[127-8*i -: 8]);
            end
            
            $display("First byte of ciphertext: %h (expected: 69)", encrypted_data[127:120]);
        end
    endtask
    
    // Enhanced task to test decryption
    task test_decryption;
        begin
            $display("\n**********************************************");
            $display("Starting Full AES-128 Decryption Test");
            $display("**********************************************");
            
            // Reset the system
            rst = 1;
            #100;
            rst = 0;
            #20;
            
            // Load ciphertext bytes (addresses 0-15)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(EXPECTED_CIPHERTEXT[127-8*i -: 8], i, 1'b0);
                $display("Loaded ciphertext byte %d: %h", i, EXPECTED_CIPHERTEXT[127-8*i -: 8]);
            end
            
            // Load key bytes (addresses 16-31)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(KEY[127-8*i -: 8], i+16, 1'b0);
                $display("Loaded key byte %d: %h", i, KEY[127-8*i -: 8]);
            end
            
            // Enter monitor state and set decryption mode
            // Move to address state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Set address 0 and decrypt mode (sw[0] = 1)
            sw = 4'h1; // Address 0 with decrypt flag
            #20;
            
            // Move to monitor state
            mode_btn = 1;
            #20;
            mode_btn = 0;
            #20;
            
            // Start decryption
            start = 1;
            #40;
            
            // Wait for operation to complete - monitor done signal (LED6)
            while (led_out[6] == 0) begin
                #10;
            end
            
            // Release start button
            start = 0;
            #40;
            
            $display("Decryption completed. Output in LEDs.");
            
            // For simulation only - store decrypted data for verification
            for (i = 0; i < 16; i = i + 1) begin
                // Set address to read decrypted byte
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                // Set address
                sw[3:0] = i[3:0];
                #20;
                
                // Enter monitor state
                mode_btn = 1;
                #20;
                mode_btn = 0;
                #20;
                
                // Read the data
                decrypted_data[127-8*i -: 8] = {4'h0, led_out[3:0]};
                $display("Read decrypted byte %d: %h", i, decrypted_data[127-8*i -: 8]);
            end
            
            $display("First byte of decrypted text: %h (expected: 00)", decrypted_data[127:120]);
        end
    endtask
    
    // Instantiate the Unit Under Test (UUT) with updated port names
    aes_top uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .wr_en(wr_en),
        .mode_btn(mode_btn),
        .sw(sw),
        .data_out(data_out),
        .busy(busy),
        .valid(valid),
        .done(done)
    );
    
    // Test procedure
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        wr_en = 0;
        mode_btn = 0;
        sw = 4'h0;
        errors = 0;
        
        // Apply reset
        #100;
        rst = 0;
        #20;
        
        // Test 1: Basic Input Test
        $display("Starting Basic Input Test");
        
        // Input a test byte (0xA5) at address 0
        input_byte(8'hA5, 5'h00, 1'b0);
        $display("Loaded byte 0xA5 at address 0");
        
        // Move to monitor state to see the result
        mode_btn = 1;
        #20;
        mode_btn = 0;
        #20;
        
        mode_btn = 1;
        #20;
        mode_btn = 0;
        #20;
        
        $display("Lower nibble of output: %h", led_out[3:0]);
        
        // Test 2: Full Encryption Test
        test_encryption();
        
        // Test 3: Full Decryption Test
        test_decryption();
        
        // Finish simulation
        #200;
        $display("\n**********************************************");
        $display("Testbench Complete");
        $display("**********************************************");
        $finish;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%t, LEDs=%b, Busy=%b, Valid=%b, Done=%b",
                 $time, led_out[3:0], led_out[4], led_out[5], led_out[6]);
    end
endmodule
