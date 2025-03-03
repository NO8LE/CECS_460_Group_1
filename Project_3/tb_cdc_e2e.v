`timescale 1ns / 1ps

module tb_cdc_e2e();
    // Inputs to DUT
    reg clk_125mhz = 0;
    reg rst_n = 0;
    reg start_test = 0;
    
    // Outputs from DUT
    wire busy;
    wire success;
    
    // Internal monitoring
    reg [7:0] known_data_values [0:15];
    integer test_phase = 0;
    integer i;
    
    // Instantiate the top module
    top dut (
        .clk(clk_125mhz),
        .rst_n(rst_n),
        .start_test(start_test),
        .busy(busy),
        .success(success)
    );
    
    // Clock generation - 125 MHz system clock
    always #4 clk_125mhz = ~clk_125mhz;  // 8ns period
    
    // Internal clock monitoring
    wire clk_90mhz = dut.clk_90mhz;
    wire clk_65mhz = dut.clk_65mhz;
    
    // Test data initialization
    initial begin
        // Initialize test data patterns that will be written to BRAM
        for (i = 0; i < 16; i = i + 1) begin
            known_data_values[i] = 8'h10 + i * 4;  // Creates unique pattern
        end
    end
    
    // CDC data transfer monitoring
    wire [16:0] cmd_fifo_wr_data = dut.cmd_fifo_wr_data;
    wire cmd_fifo_wr_en = dut.cmd_fifo_wr_en;
    wire cmd_fifo_full = dut.cmd_fifo_full;
    wire cmd_fifo_empty = dut.cmd_fifo_empty;
    wire cmd_fifo_rd_en = dut.cmd_fifo_rd_en;
    wire [16:0] cmd_fifo_rd_data = dut.cmd_fifo_rd_data;
    
    wire [7:0] resp_fifo_wr_data = dut.resp_fifo_wr_data;
    wire resp_fifo_wr_en = dut.resp_fifo_wr_en;
    wire resp_fifo_full = dut.resp_fifo_full;
    wire resp_fifo_empty = dut.resp_fifo_empty;
    wire resp_fifo_rd_en = dut.resp_fifo_rd_en;
    wire [7:0] resp_fifo_rd_data = dut.resp_fifo_rd_data;
    
    // BRAM operation monitoring
    wire [7:0] bram_address = dut.bram_address;
    wire [7:0] bram_data_in = dut.bram_data_in;
    wire [7:0] bram_data_out = dut.bram_data_out;
    wire bram_wr_en = dut.bram_wr_en;
    wire bram_rd_en = dut.bram_rd_en;
    wire bram_op_done = dut.bram_op_done;
    
    // Main test sequence
    initial begin
        // Setup waveform dumping
        $display("Starting CDC End-to-End Verification");
        
        // Apply initial reset
        rst_n = 0;
        start_test = 0;
        #100;
        
        // Release reset and wait for PLL locking
        rst_n = 1;
        #200;
        
        // Wait for reset synchronizers
        #100;
        
        // Verify PLL is locked
        if (dut.pll_locked) 
            $display("Time %t: PLL locked successfully", $time);
        else begin
            $display("Time %t: ERROR - PLL failed to lock", $time);
            $finish;
        end
        
        // Test Phase 1: Basic CDC Operation - Single Write/Read
        test_phase = 1;
        $display("\nTest Phase %0d: Basic CDC Operation - Single Write/Read", test_phase);
        start_test = 1;
        #20;
        start_test = 0;
        
        // Wait for busy signal to assert
        wait(busy);
        $display("Time %t: Operation started, busy signal asserted", $time);
        
        // Monitor for CDC transactions
        $display("Monitoring CDC transactions...");
        
        // Wait for completion
        wait(!busy);
        #100;
        
        // Check result
        if (success)
            $display("Time %t: Test Phase %0d PASSED", $time, test_phase);
        else begin
            $display("Time %t: Test Phase %0d FAILED - Data verification error", $time, test_phase);
        end
        
        // Allow system to settle
        #500;
        
        // Test Phase 2: Multiple Write/Read Operations
        test_phase = 2;
        $display("\nTest Phase %0d: Multiple Write/Read Operations", test_phase);
        
        // Reset the system for next test
        rst_n = 0;
        #100;
        rst_n = 1;
        #300;
        
        // Start test sequence
        start_test = 1;
        #20;
        start_test = 0;
        
        // Wait for busy signal to assert
        wait(busy);
        $display("Time %t: Operation started, busy signal asserted", $time);
        
        // Wait for completion
        wait(!busy);
        #100;
        
        // Check result
        if (success)
            $display("Time %t: Test Phase %0d PASSED", $time, test_phase);
        else begin
            $display("Time %t: Test Phase %0d FAILED - Data verification error", $time, test_phase);
        end
        
        // Allow system to settle
        #500;
        
        // Test Phase 3: Stress Test - Rapid Operations
        test_phase = 3;
        $display("\nTest Phase %0d: Stress Test - Rapid Operations", test_phase);
        
        // Reset the system for next test
        rst_n = 0;
        #100;
        rst_n = 1;
        #300;
        
        // Perform multiple rapid start/stop cycles
        for (i = 0; i < 5; i = i + 1) begin
            $display("Starting rapid operation cycle %0d", i);
            start_test = 1;
            #10;
            start_test = 0;
            
            // Wait for busy to assert and then deassert
            wait(busy);
            wait(!busy);
            
            // Check success after each cycle
            if (success)
                $display("Rapid cycle %0d: PASSED", i);
            else begin
                $display("Rapid cycle %0d: FAILED", i);
            end
            
            #50; // Short delay between cycles
        end
        
        $display("Time %t: Test Phase %0d completed", $time, test_phase);
        
        // Allow system to settle
        #500;
        
        // Test Phase 4: Long-Running Test
        test_phase = 4;
        $display("\nTest Phase %0d: Long-Running Test", test_phase);
        
        // Reset the system for next test
        rst_n = 0;
        #100;
        rst_n = 1;
        #300;
        
        // Start test sequence and let it run for longer
        start_test = 1;
        #20;
        start_test = 0;
        
        // Wait for busy signal to assert
        wait(busy);
        $display("Time %t: Long-running operation started", $time);
        
        // Wait for completion with timeout
        fork
            begin
                wait(!busy);
                $display("Time %t: Long-running operation completed normally", $time);
            end
            begin
                #50000; // 50μs timeout
                if (busy) begin
                    $display("Time %t: ERROR - Timeout waiting for operation to complete", $time);
                    $finish;
                end
            end
        join_any
        
        // Check result
        if (success)
            $display("Time %t: Test Phase %0d PASSED", $time, test_phase);
        else begin
            $display("Time %t: Test Phase %0d FAILED - Data verification error", $time, test_phase);
        end
        
        // Final test summary
        #500;
        $display("\n==== CDC End-to-End Verification Summary ====");
        if (success)
            $display("TEST PASSED: All CDC operations verified successfully");
        else
            $display("TEST FAILED: Data integrity errors detected");
        
        #100;
        $finish;
    end
    
    // Monitor CDC crossings - Command FIFO (90 MHz to 65 MHz)
    always @(posedge clk_90mhz) begin
        if (cmd_fifo_wr_en && !cmd_fifo_full) begin
            $display("CDC Monitor [90MHz → 65MHz]: Command write at time %t", $time);
            $display("  Command: %s Address: 0x%h Data: 0x%h", 
                     cmd_fifo_wr_data[16] ? "WRITE" : "READ",
                     cmd_fifo_wr_data[15:8],
                     cmd_fifo_wr_data[7:0]);
        end
    end
    
    always @(posedge clk_65mhz) begin
        if (cmd_fifo_rd_en && !cmd_fifo_empty) begin
            $display("CDC Monitor [90MHz → 65MHz]: Command received at time %t", $time);
            $display("  Command: %s Address: 0x%h Data: 0x%h", 
                     cmd_fifo_rd_data[16] ? "WRITE" : "READ",
                     cmd_fifo_rd_data[15:8],
                     cmd_fifo_rd_data[7:0]);
        end
    end
    
    // Monitor CDC crossings - Response FIFO (65 MHz to 90 MHz)
    always @(posedge clk_65mhz) begin
        if (resp_fifo_wr_en && !resp_fifo_full) begin
            $display("CDC Monitor [65MHz → 90MHz]: Response write at time %t", $time);
            $display("  Data: 0x%h", resp_fifo_wr_data);
        end
    end
    
    always @(posedge clk_90mhz) begin
        if (resp_fifo_rd_en && !resp_fifo_empty) begin
            $display("CDC Monitor [65MHz → 90MHz]: Response received at time %t", $time);
            $display("  Data: 0x%h", resp_fifo_rd_data);
        end
    end
    
    // Monitor BRAM operations
    always @(posedge clk_65mhz) begin
        if (bram_wr_en) begin
            $display("BRAM Monitor: Write operation at time %t", $time);
            $display("  Address: 0x%h Data: 0x%h", bram_address, bram_data_in);
        end
        
        if (bram_rd_en) begin
            $display("BRAM Monitor: Read operation at time %t", $time);
            $display("  Address: 0x%h", bram_address);
        end
        
        if (bram_op_done) begin
            $display("BRAM Monitor: Operation complete at time %t", $time);
            if (bram_rd_en)
                $display("  Read Data: 0x%h", bram_data_out);
        end
    end
    
    // Monitor Gray code pointers in both FIFOs
    wire [ADDR_WIDTH:0] cmd_wr_ptr_gray = dut.cmd_fifo_inst.wr_ptr_gray;
    wire [ADDR_WIDTH:0] cmd_rd_ptr_gray = dut.cmd_fifo_inst.rd_ptr_gray;
    wire [ADDR_WIDTH:0] resp_wr_ptr_gray = dut.resp_fifo_inst.wr_ptr_gray;
    wire [ADDR_WIDTH:0] resp_rd_ptr_gray = dut.resp_fifo_inst.rd_ptr_gray;
    
    // Parameter for monitoring
    parameter ADDR_WIDTH = 4;

endmodule