`timescale 1ns / 1ps

module fir_tb();
    // Clock and reset
    reg clk = 0;
    reg rst = 0;
    
    // Control signals
    reg start = 0;
    reg sel_pipelined = 0;
    reg [9:0] input_addr = 10'd0;
    reg [9:0] output_addr = 10'd512;  // Output starts at address 512
    reg [9:0] sample_count = 10'd100;  // Process 100 samples for test
    
    // Output signals
    wire done;
    wire [2:0] cycle_count;      // Now only 3 bits
    
    // Internal counters for performance measurement
    reg [31:0] performance_counter = 0;
    
    // Instantiate the top module
    fir_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .done(done),
        .cycle_count(cycle_count)
    );
    
    // Using cycle count for basic monitoring
    reg [31:0] cycle_counter = 0;
    
    // Track cycles during each test
    always @(posedge clk) begin
        if (start) begin
            cycle_counter <= 0;
        end else if (!done) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
    
    // Memory access variables for test
    reg [9:0] verify_addr;
    wire [7:0] verify_data;
    
    // Performance metrics
    integer non_pipelined_cycles;
    integer pipelined_cycles;
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
    
    // Memory array for test data
    reg [7:0] test_memory [0:1023];
    
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
            for (i = 0; i < 1024; i = i + 1) begin
                test_memory[i] = sine_sample(i);
            end
            
            $display("Test memory initialized with sine wave test signal");
            
            // Alternative: step function could be used instead
            /*
            for (i = 0; i < 1024; i = i + 1) begin
                test_memory[i] = step_sample(i);
            end
            $display("Test memory initialized with step function test signal");
            */
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
                $display("mem[%d] = %d", i, $signed(test_memory[i]));
            end
        end
    endtask
    
    // Array to store non-pipelined results for comparison
    reg [7:0] non_pipelined_results [0:255];
    
    // Task to save filter outputs from non-pipelined run
    task save_non_pipelined_outputs;
        integer i;
        begin
            $display("Saving non-pipelined filter results...");
            for (i = 0; i < sample_count; i = i + 1) begin
                non_pipelined_results[i] = test_memory[output_addr + i];
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
                pipelined_output = test_memory[output_addr + i]; // Pipelined result
                
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
        // Initialize test
        rst = 1;
        #20;
        rst = 0;
        #10;
        
        // Load test signal into memory
        initialize_memory();
        
        // Display a few input samples for verification
        display_memory_range(0, 9);
        
        // Run non-pipelined implementation
        $display("\nStarting non-pipelined FIR filter test...");
        sel_pipelined = 0;  // Select non-pipelined
        // Note: output_addr is now hardcoded in fir_top.v as 512
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        wait(done);
        non_pipelined_cycles = cycle_counter;
        $display("Non-pipelined execution completed in %d cycles", non_pipelined_cycles);
        
        // Display a few output samples - use the hardcoded output_addr = 512
        display_memory_range(10'd512, 10'd512 + 9);
        
        // Save non-pipelined results for comparison
        save_non_pipelined_outputs();
        
        // Wait between tests
        #20;
        
        // Run pipelined implementation
        $display("\nStarting pipelined FIR filter test...");
        sel_pipelined = 1;  // Select pipelined
        // Note: output is now written to the same location (512) for both implementations
        start = 1;
        #10;
        start = 0;
        
        // Wait for completion
        wait(done);
        pipelined_cycles = cycle_counter;
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
    
    // Optional: Monitor interesting signals during simulation
    initial begin
        $monitor("Time=%t, Cycle Counter=%d, Done=%b", 
                 $time, cycle_counter, done);
    end

endmodule
