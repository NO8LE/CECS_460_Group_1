// Pipelined AES Testbench
// Performs a throughput comparison between pipelined and non-pipelined implementations
// Enhanced to thoroughly test decryption functionality

`timescale 1ns / 1ps

module aes_pipelined_tb;
    // Inputs
    reg clk;
    reg rst;
    reg enable;
    reg [127:0] data_in;
    reg [127:0] key;
    reg decrypt;
    
    // Outputs
    wire valid_out;
    wire [127:0] data_out;
    
    // Test vector from NIST FIPS 197 Appendix C.1
    localparam PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    // Additional test vectors for throughput testing
    localparam NUM_TEST_BLOCKS = 16;
    reg [127:0] test_blocks [0:NUM_TEST_BLOCKS-1];
    reg [127:0] encrypted_blocks [0:NUM_TEST_BLOCKS-1];
    reg [127:0] decrypted_blocks [0:NUM_TEST_BLOCKS-1];
    integer block_count = 0;
    integer output_count = 0;
    integer decryption_errors = 0;
    integer start_time;
    integer end_time;
    real throughput;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Instantiate the Unit Under Test (UUT)
    aes_pipelined uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .key(key),
        .decrypt(decrypt),
        .valid_out(valid_out),
        .data_out(data_out)
    );
    
    // Test procedure
    initial begin
        // Initialize inputs
        rst = 1;
        enable = 0;
        data_in = 0;
        key = 0;
        decrypt = 0;
        
        // Initialize test blocks
        test_blocks[0] = PLAINTEXT;
        test_blocks[1] = 128'h11111111111111111111111111111111;
        test_blocks[2] = 128'h22222222222222222222222222222222;
        test_blocks[3] = 128'h33333333333333333333333333333333;
        test_blocks[4] = 128'h44444444444444444444444444444444;
        test_blocks[5] = 128'h55555555555555555555555555555555;
        test_blocks[6] = 128'h66666666666666666666666666666666;
        test_blocks[7] = 128'h77777777777777777777777777777777;
        test_blocks[8] = 128'h88888888888888888888888888888888;
        test_blocks[9] = 128'h99999999999999999999999999999999;
        test_blocks[10] = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
        test_blocks[11] = 128'hbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
        test_blocks[12] = 128'hcccccccccccccccccccccccccccccccc;
        test_blocks[13] = 128'hdddddddddddddddddddddddddddddddd;
        test_blocks[14] = 128'heeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
        test_blocks[15] = 128'hffffffffffffffffffffffffffffffff;
        
        // Wait for global reset
        #100;
        rst = 0;
        #20;
        
        // Set up for encryption
        key = KEY;
        decrypt = 0;
        
        // First, verify basic functionality with a single block
        $display("Test 1: Single Block Encryption with NIST Test Vector");
        data_in = PLAINTEXT;
        enable = 1;
        #10; // One clock cycle
        enable = 0;
        
        // Wait for valid output
        wait(valid_out);
        // Wait for one more cycle to capture the result
        #10;
        
        // Check result against expected
        if (data_out == EXPECTED_CIPHERTEXT) begin
            $display("Basic encryption test PASSED: Result matches expected ciphertext");
            $display("Plaintext:  %h", PLAINTEXT);
            $display("Ciphertext: %h", data_out);
        end else begin
            $display("Basic encryption test FAILED: Result does not match expected");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got: %h", data_out);
        end
        
        #50; // Wait a bit
        
        // Test 2: Basic decryption of a single block using the NIST test vector
        $display("\nTest 2: Single Block Decryption with NIST Test Vector");
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        key = KEY;
        decrypt = 1;
        data_in = EXPECTED_CIPHERTEXT;
        enable = 1;
        #10; // One clock cycle
        enable = 0;
        
        // Wait for valid output
        wait(valid_out);
        // Wait for one more cycle to capture the result
        #10;
        
        // Check result against expected
        if (data_out == PLAINTEXT) begin
            $display("Basic decryption test PASSED: Result matches original plaintext");
            $display("Ciphertext: %h", EXPECTED_CIPHERTEXT);
            $display("Plaintext:  %h", data_out);
        end else begin
            $display("Basic decryption test FAILED: Result does not match original plaintext");
            $display("Expected: %h", PLAINTEXT);
            $display("Got: %h", data_out);
        end
        
        #50; // Wait a bit
        
        // Test 3: Pipeline throughput test with multiple blocks
        $display("\nTest 3: Pipeline Throughput with %d Blocks", NUM_TEST_BLOCKS);
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        key = KEY;
        decrypt = 0; // Encryption
        
        // Start timer
        start_time = $time;
        
        // Feed all blocks into the pipeline, one per clock cycle
        for (block_count = 0; block_count < NUM_TEST_BLOCKS; block_count = block_count + 1) begin
            data_in = test_blocks[block_count];
            enable = 1;
            #10; // One clock cycle
        end
        enable = 0;
        
        // Wait until all blocks have been processed
        output_count = 0;
        while (output_count < NUM_TEST_BLOCKS) begin
            if (valid_out) begin
                encrypted_blocks[output_count] = data_out;
                output_count = output_count + 1;
            end
            #10; // One clock cycle
        end
        
        // Record end time
        end_time = $time;
        
        // Calculate throughput
        throughput = (NUM_TEST_BLOCKS * 128.0) / ((end_time - start_time) / 1000.0); // bits/ns = Gbps
        
        $display("Pipeline encryption test completed");
        $display("Total time for %d blocks: %d ns", NUM_TEST_BLOCKS, (end_time - start_time));
        $display("Theoretical throughput: %.2f Gbps at 100MHz", throughput);
        $display("First encrypted block: %h", encrypted_blocks[0]);
        $display("Last encrypted block: %h", encrypted_blocks[NUM_TEST_BLOCKS-1]);
        
        // Test 4: Multi-block decryption test
        $display("\nTest 4: Multi-Block Decryption Test");
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        key = KEY;
        decrypt = 1; // Decryption
        
        // Start timer for decryption
        start_time = $time;
        
        // Feed all encrypted blocks into the pipeline, one per clock cycle
        for (block_count = 0; block_count < NUM_TEST_BLOCKS; block_count = block_count + 1) begin
            data_in = encrypted_blocks[block_count];
            enable = 1;
            #10; // One clock cycle
        end
        enable = 0;
        
        // Wait until all blocks have been processed
        output_count = 0;
        decryption_errors = 0;
        while (output_count < NUM_TEST_BLOCKS) begin
            if (valid_out) begin
                decrypted_blocks[output_count] = data_out;
                // Check if decrypted block matches original
                if (decrypted_blocks[output_count] != test_blocks[output_count]) begin
                    decryption_errors = decryption_errors + 1;
                    $display("Decryption error in block %d:", output_count);
                    $display("  Original: %h", test_blocks[output_count]);
                    $display("  Decrypted: %h", decrypted_blocks[output_count]);
                end
                output_count = output_count + 1;
            end
            #10; // One clock cycle
        end
        
        // Record end time for decryption
        end_time = $time;
        
        // Calculate decryption throughput
        throughput = (NUM_TEST_BLOCKS * 128.0) / ((end_time - start_time) / 1000.0); // bits/ns = Gbps
        
        $display("Pipeline decryption test completed");
        $display("Total time for decrypting %d blocks: %d ns", NUM_TEST_BLOCKS, (end_time - start_time));
        $display("Decryption throughput: %.2f Gbps at 100MHz", throughput);
        
        if (decryption_errors == 0) begin
            $display("ALL DECRYPTION TESTS PASSED! All %d blocks were correctly decrypted.", NUM_TEST_BLOCKS);
        end else begin
            $display("DECRYPTION TESTS FAILED! %d out of %d blocks had errors.", decryption_errors, NUM_TEST_BLOCKS);
        end
        
        // Finish simulation
        #100;
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Valid output at time %t: %h", $time, data_out);
        end
    end
endmodule
