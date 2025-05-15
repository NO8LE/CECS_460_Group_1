// AES Top Module Testbench
// Tests the top-level AES module with serial interface for the ZYBO Z7-10 FPGA

`timescale 1ns / 1ps

module aes_top_tb;
    // Inputs
    reg clk;
    reg rst;
    reg [7:0] data_in;
    reg [4:0] addr;
    reg wr_en;
    reg start;
    reg decrypt;
    
    // Outputs
    wire [7:0] data_out;
    wire busy;
    wire valid;
    wire done;
    
    // Test vector from NIST FIPS 197 Appendix C.1
    localparam [127:0] PLAINTEXT = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] EXPECTED_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    // Variables to store the read output
    reg [127:0] read_data;
    integer i;
    integer errors;
    
    // Instantiate the Unit Under Test (UUT)
    aes_top uut (
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test procedure
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        addr = 0;
        wr_en = 0;
        start = 0;
        decrypt = 0;
        errors = 0;
        
        // Apply reset
        #100;
        rst = 0;
        #20;
        
        // Test 1: Encryption
        $display("Starting AES-128 Encryption Test with Serial Interface");
        
        // Load plaintext bytes (addresses 0-15)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = i;
            data_in = PLAINTEXT[127-8*i -: 8];
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
            #10;
        end
        
        // Load key bytes (addresses 16-31)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = 16 + i;
            data_in = KEY[127-8*i -: 8];
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
            #10;
        end
        
        // Start encryption
        decrypt = 0;
        start = 1;
        
        // Wait for operation to complete
        @(posedge done);
        
        // Read result bytes (addresses 0-15)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = i;
            @(posedge clk);
            read_data[127-8*i -: 8] = data_out;
            #10;
        end
        
        // Check result
        if (read_data == EXPECTED_CIPHERTEXT) begin
            $display("Encryption test PASSED!");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got:      %h", read_data);
        end else begin
            $display("Encryption test FAILED!");
            $display("Expected: %h", EXPECTED_CIPHERTEXT);
            $display("Got:      %h", read_data);
            errors = errors + 1;
        end
        
        // Release start and wait a bit
        #20;
        start = 0;
        #100;
        
        // Test 2: Decryption
        $display("\nStarting AES-128 Decryption Test with Serial Interface");
        
        // Reset the system
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Load ciphertext bytes (addresses 0-15)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = i;
            data_in = EXPECTED_CIPHERTEXT[127-8*i -: 8];
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
            #10;
        end
        
        // Load key bytes (addresses 16-31)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = 16 + i;
            data_in = KEY[127-8*i -: 8];
            wr_en = 1;
            @(posedge clk);
            wr_en = 0;
            #10;
        end
        
        // Start decryption
        decrypt = 1;
        start = 1;
        
        // Wait for operation to complete
        @(posedge done);
        
        // Read result bytes (addresses 0-15)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr = i;
            @(posedge clk);
            read_data[127-8*i -: 8] = data_out;
            #10;
        end
        
        // Check result
        if (read_data == PLAINTEXT) begin
            $display("Decryption test PASSED!");
            $display("Expected: %h", PLAINTEXT);
            $display("Got:      %h", read_data);
        end else begin
            $display("Decryption test FAILED!");
            $display("Expected: %h", PLAINTEXT);
            $display("Got:      %h", read_data);
            errors = errors + 1;
        end
        
        // Release start
        #20;
        start = 0;
        
        // Summary
        $display("\n--- Test Summary ---");
        if (errors == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("%d tests FAILED!", errors);
        end
        
        // Finish simulation
        #100;
        $finish;
    end
    
    // Monitor status signals
    always @(posedge clk) begin
        if (busy) begin
            $display("Time %t: AES core is busy", $time);
        end
        if (valid) begin
            $display("Time %t: Output data is valid", $time);
        end
        if (done) begin
            $display("Time %t: Operation complete", $time);
        end
    end
endmodule