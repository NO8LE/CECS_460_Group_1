// AES Testbench
// Tests the AES encryption/decryption implementation using NIST test vectors
// Enhanced to thoroughly test both pipelined and non-pipelined modes

`timescale 1ns / 1ps

module aes_tb;
    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg sel_pipelined;
    reg [127:0] data_in;
    reg [127:0] key;
    reg decrypt;
    
    // Outputs
    wire done;
    wire [2:0] cycle_count;
    wire [127:0] data_out;
    
    // Instantiate the Unit Under Test (UUT)
    aes_top uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .data_in(data_in),
        .key(key),
        .decrypt(decrypt),
        .done(done),
        .cycle_count(cycle_count),
        .data_out(data_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test vector from NIST FIPS 197 Appendix C.1
    localparam PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    // Additional test vectors
    localparam PLAINTEXT2 = 128'hffffffffffffffffffffffffffffffff;
    localparam EXPECTED_CIPHERTEXT2 = 128'h8dae3b9ddf5b89df7a1cdc68b8847e14; // Pre-calculated
    
    // Variables for test management
    integer errors = 0;
    integer tests_run = 0;
    
    // Test procedure
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        sel_pipelined = 0; // Start with non-pipelined mode
        data_in = 0;
        key = 0;
        decrypt = 0;
        
        // Wait for global reset
        #100;
        rst = 0;
        #20;
        
        // Test 1: Encryption (Non-pipelined mode)
        $display("**********************************************");
        $display("Test 1: AES-128 Encryption (Non-pipelined mode)");
        $display("**********************************************");
        key = KEY;
        data_in = PLAINTEXT;
        decrypt = 0;
        sel_pipelined = 0;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == EXPECTED_CIPHERTEXT) begin
            $display("Test 1 PASSED: Encryption result matches expected ciphertext");
            $display("Plaintext:  %h", PLAINTEXT);
            $display("Ciphertext: %h", data_out);
        end else begin
            $display("Test 1 FAILED: Encryption result does not match expected");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 2: Decryption (Non-pipelined mode)
        $display("\n**********************************************");
        $display("Test 2: AES-128 Decryption (Non-pipelined mode)");
        $display("**********************************************");
        key = KEY;
        data_in = EXPECTED_CIPHERTEXT;
        decrypt = 1;
        sel_pipelined = 0;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == PLAINTEXT) begin
            $display("Test 2 PASSED: Decryption result matches original plaintext");
            $display("Ciphertext: %h", EXPECTED_CIPHERTEXT);
            $display("Plaintext:  %h", data_out);
        end else begin
            $display("Test 2 FAILED: Decryption result does not match original plaintext");
            $display("Expected: %h", PLAINTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 3: Encryption (Pipelined mode)
        $display("\n**********************************************");
        $display("Test 3: AES-128 Encryption (Pipelined mode)");
        $display("**********************************************");
        key = KEY;
        data_in = PLAINTEXT;
        decrypt = 0;
        sel_pipelined = 1;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == EXPECTED_CIPHERTEXT) begin
            $display("Test 3 PASSED: Pipelined encryption result matches expected ciphertext");
            $display("Plaintext:  %h", PLAINTEXT);
            $display("Ciphertext: %h", data_out);
        end else begin
            $display("Test 3 FAILED: Pipelined encryption result does not match expected");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 4: Decryption (Pipelined mode)
        $display("\n**********************************************");
        $display("Test 4: AES-128 Decryption (Pipelined mode)");
        $display("**********************************************");
        key = KEY;
        data_in = EXPECTED_CIPHERTEXT;
        decrypt = 1;
        sel_pipelined = 1;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == PLAINTEXT) begin
            $display("Test 4 PASSED: Pipelined decryption result matches original plaintext");
            $display("Ciphertext: %h", EXPECTED_CIPHERTEXT);
            $display("Plaintext:  %h", data_out);
        end else begin
            $display("Test 4 FAILED: Pipelined decryption result does not match original plaintext");
            $display("Expected: %h", PLAINTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        // Test 5: Additional Encryption and Decryption Test (Non-pipelined)
        $display("\n**********************************************");
        $display("Test 5: Additional Encryption/Decryption (Non-pipelined mode)");
        $display("**********************************************");
        
        // Reset before test
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Encrypt additional plaintext
        key = KEY;
        data_in = PLAINTEXT2;
        decrypt = 0;
        sel_pipelined = 0;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done
        wait(done);
        tests_run = tests_run + 1;
        
        // Store ciphertext
        reg [127:0] ciphertext2 = data_out;
        
        // Check encryption
        if (ciphertext2 == EXPECTED_CIPHERTEXT2) begin
            $display("Test 5a PASSED: Non-pipelined encryption of additional vector successful");
            $display("Plaintext:  %h", PLAINTEXT2);
            $display("Ciphertext: %h", ciphertext2);
        end else begin
            $display("Test 5a FAILED: Non-pipelined encryption of additional vector incorrect");
            $display("Expected: %h", EXPECTED_CIPHERTEXT2);
            $display("Got: %h", ciphertext2);
            errors = errors + 1;
        end
        
        #50;
        
        // Decrypt the ciphertext
        data_in = ciphertext2;
        decrypt = 1;
        sel_pipelined = 0;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done
        wait(done);
        tests_run = tests_run + 1;
        
        // Check decryption result
        if (data_out == PLAINTEXT2) begin
            $display("Test 5b PASSED: Non-pipelined decryption of additional vector successful");
            $display("Ciphertext: %h", ciphertext2);
            $display("Decrypted:  %h", data_out);
        end else begin
            $display("Test 5b FAILED: Non-pipelined decryption of additional vector incorrect");
            $display("Expected: %h", PLAINTEXT2);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        // Test 6: Additional Encryption and Decryption Test (Pipelined)
        $display("\n**********************************************");
        $display("Test 6: Additional Encryption/Decryption (Pipelined mode)");
        $display("**********************************************");
        
        // Reset before test
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Encrypt additional plaintext
        key = KEY;
        data_in = PLAINTEXT2;
        decrypt = 0;
        sel_pipelined = 1;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done
        wait(done);
        tests_run = tests_run + 1;
        
        // Store ciphertext
        ciphertext2 = data_out;
        
        // Check encryption
        if (ciphertext2 == EXPECTED_CIPHERTEXT2) begin
            $display("Test 6a PASSED: Pipelined encryption of additional vector successful");
            $display("Plaintext:  %h", PLAINTEXT2);
            $display("Ciphertext: %h", ciphertext2);
        end else begin
            $display("Test 6a FAILED: Pipelined encryption of additional vector incorrect");
            $display("Expected: %h", EXPECTED_CIPHERTEXT2);
            $display("Got: %h", ciphertext2);
            errors = errors + 1;
        end
        
        #50;
        
        // Decrypt the ciphertext
        data_in = ciphertext2;
        decrypt = 1;
        sel_pipelined = 1;
        start = 1;
        #10;
        start = 0;
        
        // Wait for done
        wait(done);
        tests_run = tests_run + 1;
        
        // Check decryption result
        if (data_out == PLAINTEXT2) begin
            $display("Test 6b PASSED: Pipelined decryption of additional vector successful");
            $display("Ciphertext: %h", ciphertext2);
            $display("Decrypted:  %h", data_out);
        end else begin
            $display("Test 6b FAILED: Pipelined decryption of additional vector incorrect");
            $display("Expected: %h", PLAINTEXT2);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
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
    
    // Monitor cycle count and performance
    always @(posedge clk) begin
        if (done) begin
            $display("Operation completed in %d cycles (mode: %s, operation: %s)", 
                     cycle_count,
                     sel_pipelined ? "pipelined" : "non-pipelined",
                     decrypt ? "decrypt" : "encrypt");
        end
    end
endmodule
