// AES Testbench
// Tests the AES encryption/decryption implementation using NIST test vectors

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
        
        // Test 1: Encryption
        $display("Starting AES-128 Encryption Test (Non-pipelined mode)");
        key = KEY;
        data_in = PLAINTEXT;
        decrypt = 0;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == EXPECTED_CIPHERTEXT) begin
            $display("Test 1 PASSED: Encryption result matches expected ciphertext");
        end else begin
            $display("Test 1 FAILED: Encryption result does not match expected");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 2: Decryption
        $display("Starting AES-128 Decryption Test (Non-pipelined mode)");
        key = KEY;
        data_in = EXPECTED_CIPHERTEXT;
        decrypt = 1;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == PLAINTEXT) begin
            $display("Test 2 PASSED: Decryption result matches original plaintext");
        end else begin
            $display("Test 2 FAILED: Decryption result does not match original plaintext");
            $display("Expected: %h", PLAINTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 3: Encryption (Pipelined mode)
        $display("Starting AES-128 Encryption Test (Pipelined mode)");
        sel_pipelined = 1;
        key = KEY;
        data_in = PLAINTEXT;
        decrypt = 0;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == EXPECTED_CIPHERTEXT) begin
            $display("Test 3 PASSED: Pipelined encryption result matches expected ciphertext");
        end else begin
            $display("Test 3 FAILED: Pipelined encryption result does not match expected");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        #50; // Wait before starting next test
        
        // Test 4: Decryption (Pipelined mode)
        $display("Starting AES-128 Decryption Test (Pipelined mode)");
        sel_pipelined = 1;
        key = KEY;
        data_in = EXPECTED_CIPHERTEXT;
        decrypt = 1;
        start = 1;
        #10; // One clock cycle
        start = 0;
        
        // Wait for done signal
        wait(done);
        tests_run = tests_run + 1;
        
        // Check output against expected
        if (data_out == PLAINTEXT) begin
            $display("Test 4 PASSED: Pipelined decryption result matches original plaintext");
        end else begin
            $display("Test 4 FAILED: Pipelined decryption result does not match original plaintext");
            $display("Expected: %h", PLAINTEXT);
            $display("Got: %h", data_out);
            errors = errors + 1;
        end
        
        // Summary of tests
        $display("\n--- Test Summary ---");
        $display("Total tests run: %d", tests_run);
        $display("Errors: %d", errors);
        if (errors == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Some tests FAILED!");
        end
        
        // Finish simulation
        #100;
        $finish;
    end
    
    // Monitor cycle count and performance
    always @(posedge clk) begin
        if (done) begin
            $display("Operation completed in %d cycles", cycle_count);
        end
    end
endmodule
