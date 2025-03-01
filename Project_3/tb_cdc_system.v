`timescale 1ns / 1ps

module tb_cdc_system();
    // Inputs to DUT
    reg clk_125mhz = 0;
    reg rst_n = 0;
    reg start_test = 0;
    
    // Outputs from DUT
    wire busy;
    wire success;
    
    // Instantiate the top module
    top dut (
        .clk(clk_125mhz),
        .rst_n(rst_n),
        .start_test(start_test),
        .busy(busy),
        .success(success)
    );
    
    // Clock generation
    // 125 MHz clock = 8 ns period
    always #4 clk_125mhz = ~clk_125mhz;
    
    // Internal monitoring signals (connect to internal signals in the DUT for probing)
    wire clk_90mhz = dut.clk_90mhz;
    wire clk_65mhz = dut.clk_65mhz;
    wire pll_locked = dut.pll_locked;
    
    // Monitor FIFO pointers and flags for CDC analysis
    wire cmd_fifo_full = dut.cmd_fifo_full;
    wire cmd_fifo_empty = dut.cmd_fifo_empty;
    wire resp_fifo_full = dut.resp_fifo_full;
    wire resp_fifo_empty = dut.resp_fifo_empty;
    
    // Test sequence
    initial begin
        // Dump waves (for waveform viewing)
        $dumpfile("cdc_system.vcd");
        $dumpvars(0, tb_cdc_system);
        
        // Apply initial reset
        rst_n = 0;
        start_test = 0;
        #100;
        
        // Release reset and wait for PLL to lock
        rst_n = 1;
        #200;
        
        // Wait for clock domain reset synchronizers
        #100;
        
        // Verify PLL is locked
        if (pll_locked) 
            $display("Time %t: PLL locked successfully", $time);
        else begin
            $display("Time %t: ERROR - PLL failed to lock", $time);
            $finish;
        end
        
        // Start test sequence
        $display("Time %t: Starting test sequence", $time);
        start_test = 1;
        #20;
        start_test = 0;
        
        // Wait for test to complete (watch busy signal)
        wait(!busy);
        #500;
        
        // Check test result
        if (success)
            $display("Time %t: TEST PASSED - All operations verified successfully", $time);
        else
            $display("Time %t: TEST FAILED - Data verification errors detected", $time);
        
        // Additional delay to observe waveforms
        #1000;
        $finish;
    end
    
    // Monitor for stalls or deadlocks
    initial begin
        #50000; // Maximum simulation time (50 μs)
        $display("Time %t: TIMEOUT - Simulation did not complete within expected time", $time);
        $finish;
    end
    
    // Monitor and analyze the CDC behavior
    always @(posedge clk_90mhz) begin
        if (dut.cmd_fifo_wr_en && !cmd_fifo_full)
            $display("Time %t: [90MHz] Command FIFO Write: %h", $time, dut.cmd_fifo_wr_data);
    end
    
    always @(posedge clk_65mhz) begin
        if (dut.cmd_fifo_rd_en && !cmd_fifo_empty)
            $display("Time %t: [65MHz] Command FIFO Read: %h", $time, dut.cmd_fifo_rd_data);
    end
    
    always @(posedge clk_65mhz) begin
        if (dut.resp_fifo_wr_en && !resp_fifo_full)
            $display("Time %t: [65MHz] Response FIFO Write: %h", $time, dut.resp_fifo_wr_data);
    end
    
    always @(posedge clk_90mhz) begin
        if (dut.resp_fifo_rd_en && !resp_fifo_empty)
            $display("Time %t: [90MHz] Response FIFO Read: %h", $time, dut.resp_fifo_rd_data);
    end
    
    // Additional CDC signal monitoring
    // Gray code pointer monitoring for visualization
    wire [4:0] cmd_fifo_wr_ptr_gray = dut.cmd_fifo_inst.wr_ptr_gray;
    wire [4:0] cmd_fifo_rd_ptr_gray = dut.cmd_fifo_inst.rd_ptr_gray;
    wire [4:0] cmd_fifo_rd_ptr_gray_sync = dut.cmd_fifo_inst.wr_ptr_gray_sync2;
    wire [4:0] cmd_fifo_wr_ptr_gray_sync = dut.cmd_fifo_inst.rd_ptr_gray_sync2;
    
    // Display full/empty flag transitions for verification
    always @(posedge clk_90mhz) begin
        if ($rose(cmd_fifo_full))
            $display("Time %t: [90MHz] Command FIFO became FULL", $time);
        if ($fell(cmd_fifo_full))
            $display("Time %t: [90MHz] Command FIFO no longer FULL", $time);
        if ($rose(resp_fifo_empty))
            $display("Time %t: [90MHz] Response FIFO became EMPTY", $time);
        if ($fell(resp_fifo_empty))
            $display("Time %t: [90MHz] Response FIFO no longer EMPTY", $time);
    end
    
    always @(posedge clk_65mhz) begin
        if ($rose(cmd_fifo_empty))
            $display("Time %t: [65MHz] Command FIFO became EMPTY", $time);
        if ($fell(cmd_fifo_empty))
            $display("Time %t: [65MHz] Command FIFO no longer EMPTY", $time);
        if ($rose(resp_fifo_full))
            $display("Time %t: [65MHz] Response FIFO became FULL", $time);
        if ($fell(resp_fifo_full))
            $display("Time %t: [65MHz] Response FIFO no longer FULL", $time);
    end

endmodule