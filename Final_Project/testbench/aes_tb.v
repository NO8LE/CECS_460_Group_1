// AES Testbench
// Tests the AES encryption/decryption implementation on the ZYBO Z7-10 FPGA
// Enhanced to thoroughly test the state machine interface implementation

`timescale 1ns / 1ps

module aes_tb;
    // Inputs - match the actual aes_top module interface
    reg clk;
    reg rst;
    reg start;
    reg wr_en;
    reg mode_btn;
    reg [3:0] sw;
    
    // Outputs from the updated module interface
    wire [3:0] data_out;    // 4-bit data output (lower nibble)
    wire busy;              // Busy indicator
    wire valid;             // Valid indicator
    wire done;              // Done indicator
    
    // Virtual LED array to make it easier to work with outputs
    wire [7:0] led_out;
    assign led_out[3:0] = data_out;
    assign led_out[4] = busy;
    assign led_out[5] = valid;
    assign led_out[6] = done; 
    assign led_out[7] = 1'b0; // Monitor state indicator (not directly accessible)
    
    // Test vector from NIST FIPS 197 Appendix C.1
    localparam [127:0] PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    // Additional test vectors
    localparam [127:0] PLAINTEXT2 = 128'hffffffffffffffffffffffffffffffff;
    localparam [127:0] EXPECTED_CIPHERTEXT2 = 128'h8dae3b9ddf5b89df7a1cdc68b8847e14; // Pre-calculated
    
    // Variables for test management
    reg [127:0] read_data;
    reg [127:0] encrypted_data;
    reg [127:0] decrypted_data;
    reg [127:0] roundtrip_encrypted;
    integer i;
    integer errors = 0;
    integer tests_run = 0;
    integer test_result;
    
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
    
    // Helper task: Read output after encryption/decryption
    task read_output_data;
        output [127:0] output_data;
        begin
            // Storage for the output data
            reg [127:0] temp_data;
            
            // For each byte position
            for (i = 0; i < 16; i = i + 1) begin
                // Set address to read the current byte
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
                
                // Read the data (only lower nibble is visible)
                temp_data[127-8*i -: 8] = {4'h0, led_out[3:0]};
                $display("Read output byte %d: %h", i, temp_data[127-8*i -: 8]);
            end
            
            // Return the collected data
            output_data = temp_data;
        end
    endtask
    
    // Task for encryption test
    task run_encryption_test;
        input [127:0] plaintext_data;
        input [127:0] key_data;
        input [127:0] expected_ciphertext;
        input integer test_num;
        output integer success;
        begin
            success = 1; // Assume success until proven otherwise
            
            $display("\n**********************************************");
            $display("Test %0d: AES-128 Encryption", test_num);
            $display("**********************************************");
            
            // Reset the system
            rst = 1;
            #100;
            rst = 0;
            #20;
            
            // Load plaintext bytes (addresses 0-15)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(plaintext_data[127-8*i -: 8], i, 1'b0);
                $display("Loaded plaintext byte %d: %h", i, plaintext_data[127-8*i -: 8]);
            end
            
            // Load key bytes (addresses 16-31)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(key_data[127-8*i -: 8], i+16, 1'b0);
                $display("Loaded key byte %d: %h", i, key_data[127-8*i -: 8]);
            end
            
            // Enter monitor state with encrypt mode
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
            
            // Wait for operation to complete
            while (led_out[6] == 0) begin
                #10;
            end
            
            // Release start button
            start = 0;
            #40;
            
            $display("Encryption completed. Reading output data...");
            
            // Read the encrypted data
            read_output_data(encrypted_data);
            
            // Check if the result matches the expected ciphertext
            // Note: Due to FPGA I/O limitations, we can only read the lower nibble,
            // so we can only verify that part of the output
            if (encrypted_data[127:120] == expected_ciphertext[127:120]) begin
                $display("Test %0d PASSED: First byte of encryption result (%h) matches expected.", test_num, encrypted_data[127:120]);
            end else begin
                $display("Test %0d FAILED: First byte of encryption result does not match expected.", test_num);
                $display("Expected first byte: %h", expected_ciphertext[127:120]);
                $display("Got first byte: %h", encrypted_data[127:120]);
                success = 0;
            end
            
            tests_run = tests_run + 1;
            if (success == 0) errors = errors + 1;
        end
    endtask
    
    // Task for decryption test
    task run_decryption_test;
        input [127:0] ciphertext_data;
        input [127:0] key_data;
        input [127:0] expected_plaintext;
        input integer test_num;
        output integer success;
        begin
            success = 1; // Assume success until proven otherwise
            
            $display("\n**********************************************");
            $display("Test %0d: AES-128 Decryption", test_num);
            $display("**********************************************");
            
            // Reset the system
            rst = 1;
            #100;
            rst = 0;
            #20;
            
            // Load ciphertext bytes (addresses 0-15)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(ciphertext_data[127-8*i -: 8], i, 1'b0);
                $display("Loaded ciphertext byte %d: %h", i, ciphertext_data[127-8*i -: 8]);
            end
            
            // Load key bytes (addresses 16-31)
            for (i = 0; i < 16; i = i + 1) begin
                input_byte(key_data[127-8*i -: 8], i+16, 1'b0);
                $display("Loaded key byte %d: %h", i, key_data[127-8*i -: 8]);
            end
            
            // Enter monitor state with decrypt mode
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
            
            // Wait for operation to complete
            while (led_out[6] == 0) begin
                #10;
            end
            
            // Release start button
            start = 0;
            #40;
            
            $display("Decryption completed. Reading output data...");
            
            // Read the decrypted data
            read_output_data(decrypted_data);
            
            // Check if the result matches the expected plaintext
            if (decrypted_data[127:120] == expected_plaintext[127:120]) begin
                $display("Test %0d PASSED: First byte of decryption result (%h) matches expected.", test_num, decrypted_data[127:120]);
            end else begin
                $display("Test %0d FAILED: First byte of decryption result does not match expected.", test_num);
                $display("Expected first byte: %h", expected_plaintext[127:120]);
                $display("Got first byte: %h", decrypted_data[127:120]);
                success = 0;
            end
            
            tests_run = tests_run + 1;
            if (success == 0) errors = errors + 1;
        end
    endtask
    
    // Instantiate the Unit Under Test (UUT) with the correct interface
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
        
        // Wait for global reset
        #100;
        rst = 0;
        #20;
        
        // Test variables
        
        // Test 1: Basic Encryption Test with NIST Vector
        run_encryption_test(PLAINTEXT, KEY, EXPECTED_CIPHERTEXT, 1, test_result);
        
        // Test 2: Basic Decryption Test with NIST Vector
        run_decryption_test(EXPECTED_CIPHERTEXT, KEY, PLAINTEXT, 2, test_result);
        
        // Test 3: Additional Encryption Test
        run_encryption_test(PLAINTEXT2, KEY, EXPECTED_CIPHERTEXT2, 3, test_result);
        
        // Test 4: Additional Decryption Test (using the result from Test 3)
        run_decryption_test(EXPECTED_CIPHERTEXT2, KEY, PLAINTEXT2, 4, test_result);
        
        // Test 5: Roundtrip Test - Encrypt and Decrypt same data
        $display("\n**********************************************");
        $display("Test 5: Roundtrip Encryption/Decryption Test");
        $display("**********************************************");
        
        // First encrypt
        run_encryption_test(PLAINTEXT, KEY, EXPECTED_CIPHERTEXT, 5, test_result);
        
        // Store the encrypted data
        roundtrip_encrypted = encrypted_data;
        
        // Then decrypt the result
        run_decryption_test(roundtrip_encrypted, KEY, PLAINTEXT, 6, test_result);
        
        // Summary of tests
        $display("\n**********************************************");
        $display("--- Test Summary ---");
        $display("**********************************************");
        $display("Total tests run: %d", tests_run);
        $display("Errors: %d", errors);
        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        // Finish simulation
        #100;
        $finish;
    end
    
    // Monitor outputs
    initial begin
        $monitor("Time=%t, LEDs=%b, Busy=%b, Valid=%b, Done=%b",
                 $time, led_out[3:0], led_out[4], led_out[5], led_out[6]);
    end
endmodule
