`timescale 1ns / 1ps

module fir_tb();
    // Clock and reset
    reg clk = 0;
    reg rst = 0;
    
    // Control signals
    reg start = 0;
    reg sel_pipelined = 0;
    reg [9:0] input_addr = 10'd0;
    reg [9:0] output_addr = 10'd32;  // Output starts at address 32 (reduced to fit in smaller memory)
    reg [9:0] sample_count = 10'd5;   // Use very small sample count for quick testing
    
    // Output signals
    wire done;
    wire [2:0] cycle_count;      // Now only 3 bits
    
    // Access the full 32-bit cycle counter inside the DUT
    wire [31:0] full_cycle_counter;
    assign full_cycle_counter = dut.cycle_counter;
    
    // Instantiate the top module
    fir_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .done(done),
        .cycle_count(cycle_count)
    );
    
    // We'll use the DUT's built-in cycle counter for tracking performance
    // The cycle_count port only shows the lowest 3 bits for visualization 
    // We'll access the full 32-bit counter directly from the DUT
    
    // Performance metrics
    reg [31:0] non_pipelined_cycles = 0;  // Expanded to hold full counter value
    reg [31:0] pipelined_cycles = 0;
    real speedup;
    
    // Generate clock
    always #5 clk = ~clk;  // 100 MHz clock
    
    // Test data generator (sine wave)
    function [7:0] sine_sample;
        input integer i;
        real pi, angle, sine_value;
        begin
            pi = 3.14159265359;
            angle = (i % 40) * (2.0 * pi / 40.0);  // Period of 40 samples
            sine_value = $sin(angle) * 64.0;       // Scale to fit in 8-bit signed
            sine_sample = $rtoi(sine_value);
        end
    endfunction
    
    // Test data generator (step function)
    function [7:0] step_sample;
        input integer i;
        begin
            if (i < 50)
                step_sample = 8'd40;  // Step up
            else
                step_sample = -8'd40; // Step down
        end
    endfunction
    
    // Memory array for test data (reduced size)
    reg [7:0] test_memory [0:63];  // Reduced from 512 to 64 entries
    
    // Task to initialize memory with test data
    task initialize_memory;
        integer i;
        reg we_a;
        reg [9:0] addr_a;
        reg [7:0] data_in_a;
        begin
            // Reset memory first
            rst = 1;
            #20;
            rst = 0;
            #10;
            
            // Generate test signal (sine wave) and store in local memory
            // Only fill up to array size
            for (i = 0; i < 64; i = i + 1) begin
                test_memory[i] = sine_sample(i);
            end
            
            // Now actually initialize DUT's memory with the test data
            for (i = 0; i < 64; i = i + 1) begin
                // Prepare data
                addr_a = i;
                data_in_a = test_memory[i];
                we_a = 1;
                
                // Two-cycle initialization to account for registered reads
                // First cycle: Setup signals
                @(posedge clk);
                
                // Force memory control signals (properly initialize DUT memory)
                force dut.mem_addr_a = addr_a;
                force dut.mem_we_b = we_a;
                force dut.mem_data_in_b = data_in_a;
                
                // Second cycle: Wait for data to be written and address to be registered
                @(posedge clk);
                
                // Third cycle: Ensure registered read completes
                @(posedge clk);
                #1; // Small delay
                
                // Release forces
                release dut.mem_addr_a;
                release dut.mem_we_b;
                release dut.mem_data_in_b;
            end
            
            // Wait for memory to stabilize
            we_a = 0;
            #20;
            
            $display("DUT Memory initialized with sine wave test signal");
        end
    endtask
    
    // Task to display memory contents for debugging
    task display_memory_range;
        input [9:0] start_addr;
        input [9:0] end_addr;
        integer i;
        begin
            $display("Memory contents from %d to %d:", start_addr, end_addr);
            for (i = start_addr; i <= end_addr; i = i + 1) begin
                // Read from DUT memory instead of local memory
                // Use a safer way to read from memory by reading the output port
                // This is a workaround since we can't directly access the memory array
                force dut.mem_addr_a = i;
                @(posedge clk);
                @(posedge clk); // Wait for registered read
                $display("mem[%d] = %d", i, $signed(dut.mem_data_out_a));
                release dut.mem_addr_a;
            end
        end
    endtask
    
    // Array to store non-pipelined results for comparison
    reg [7:0] non_pipelined_results [0:31];  // Reduced from 256 to 32 entries
    
    // Task to save filter outputs from non-pipelined run
    task save_non_pipelined_outputs;
        integer i;
        begin
            $display("Saving non-pipelined filter results...");
            for (i = 0; i < sample_count; i = i + 1) begin
                // Read memory using port instead of direct access
                force dut.mem_addr_a = output_addr + i;
                @(posedge clk);
                @(posedge clk); // Wait for registered read
                non_pipelined_results[i] = dut.mem_data_out_a;
                release dut.mem_addr_a;
            end
        end
    endtask
    
    // Task to compare filter outputs
    task compare_outputs;
        integer i;
        reg [7:0] pipelined_output;
        reg mismatch;
        
        begin
            mismatch = 0;
            
            $display("Comparing output results...");
            for (i = 0; i < sample_count; i = i + 1) begin
                // Read memory using port instead of direct access
                force dut.mem_addr_a = output_addr + i;
                @(posedge clk);
                @(posedge clk); // Wait for registered read
                pipelined_output = dut.mem_data_out_a;
                release dut.mem_addr_a;
                
                if (non_pipelined_results[i] !== pipelined_output) begin
                    $display("Mismatch at sample %d: Non-pipelined=%d, Pipelined=%d", 
                             i, $signed(non_pipelined_results[i]), $signed(pipelined_output));
                    mismatch = 1;
                end
            end
            
            if (mismatch == 0)
                $display("All outputs match between non-pipelined and pipelined versions.");
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize test - print diagnostic at the very beginning
        $display("Starting testbench at time %t", $time);
        rst = 1;
        #20;
        rst = 0;
        #10;
        $display("Reset complete at time %t", $time);
        
        // Load test signal into memory
        initialize_memory();
        
        // Display a few input samples for verification
        display_memory_range(0, 9);
        
        // Run non-pipelined implementation with shorter run time
        $display("\nStarting non-pipelined FIR filter test at time %t...", $time);
        sel_pipelined = 0;  // Select non-pipelined
        start = 1;
        #20;  // Shorter start pulse
        start = 0;
        $display("Start pulse completed at time %t", $time);
        
        // Wait for completion
        wait(done);
        non_pipelined_cycles = full_cycle_counter; // Use the full 32-bit counter
        $display("Non-pipelined execution completed in %d cycles", non_pipelined_cycles);
        
        // Display a few output samples
        display_memory_range(output_addr, output_addr + 9);
        
        // Save non-pipelined results for comparison
        save_non_pipelined_outputs();
        
        // Wait between tests - shorter delay
        #10;
        $display("Starting pipelined test at time %t", $time);
        
        // Run pipelined implementation
        $display("\nStarting pipelined FIR filter test...");
        sel_pipelined = 1;  // Select pipelined
        start = 1;
        #20;  // Shorter start pulse
        start = 0;
        
        // Wait for completion
        wait(done);
        pipelined_cycles = full_cycle_counter; // Use the full 32-bit counter
        $display("Pipelined execution completed in %d cycles", pipelined_cycles);
        
        // Display a few output samples
        display_memory_range(output_addr, output_addr + 9);
        
        // Calculate speedup
        speedup = non_pipelined_cycles * 1.0 / pipelined_cycles;
        $display("\nPerformance comparison:");
        $display("Non-pipelined: %d cycles", non_pipelined_cycles);
        $display("Pipelined: %d cycles", pipelined_cycles);
        $display("Speedup: %0.2f x", speedup);
        
        // Compare results from both implementations
        compare_outputs();
        
        $display("\nTest complete");
        $finish;
    end
    
    // Enhanced monitoring of signals
    initial begin
        $monitor("Time=%t, Full Counter=%d, Cycle Counter=%d, Done=%b, State(non-pipe)=%d", 
                 $time, full_cycle_counter, cycle_count, done, dut.non_pipelined_filter.state);
                 
        // Force simulation to run longer
        #10000 $display("Simulation timeout at 10,000ns");
        $finish;
    end

endmodule
