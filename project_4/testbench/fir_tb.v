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
    wire [31:0] cycle_count;
    wire [3:0] non_pipe_state;
    wire [2:0] pipe_state;
    
    // Instantiate the top module
    fir_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .done(done),
        .cycle_count(cycle_count)
    );
    
    // Access internal signals directly
    wire [3:0] non_pipe_state = dut.non_pipe_state;
    wire [2:0] pipe_state = dut.pipe_state;
    
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
            
            // Generate test signal (sine wave) and write to memory properly
            for (i = 0; i < 1024; i = i + 1) begin
                // Calculate sample value
                data_in_a = sine_sample(i);
                
                // Write to memory using memory interface
                addr_a = i;
                we_a = 1;
                @(posedge clk); // Wait for clock edge
                
                // Apply values to memory ports
                force dut.memory.addr_a = addr_a;
                force dut.memory.we_a = we_a;
                force dut.memory.data_in_a = data_in_a;
                
                @(posedge clk); // Write happens
                #1; // Small delay
                
                // Release forces
                release dut.memory.addr_a;
                release dut.memory.we_a;
                release dut.memory.data_in_a;
            end
            
            // Wait for memory to stabilize
            we_a = 0;
            #20;
            
            $display("Memory initialized with sine wave test signal");
            
            // Alternative: step function
            /*
            for (i = 0; i < 1024; i = i + 1) begin
                // Calculate sample value
                data_in_a = step_sample(i);
                
                // Write to memory using memory interface
                addr_a = i;
                we_a = 1;
                @(posedge clk); // Wait for clock edge
                
                // Apply values to memory ports
                force dut.memory.addr_a = addr_a;
                force dut.memory.we_a = we_a;
                force dut.memory.data_in_a = data_in_a;
                
                @(posedge clk); // Write happens
                #1; // Small delay
                
                // Release forces
                release dut.memory.addr_a;
                release dut.memory.we_a;
                release dut.memory.data_in_a;
            end
            $display("Memory initialized with step function test signal");
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
                $display("mem[%d] = %d", i, $signed(dut.memory.mem[i]));
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
            for (i = 0; i < dut.sample_count; i = i + 1) begin
                non_pipelined_results[i] = dut.memory.mem[dut.output_addr + i];
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
            for (i = 0; i < dut.sample_count; i = i + 1) begin
                pipelined_output = dut.memory.mem[dut.output_addr + i]; // Pipelined result (overwrote non-pipelined)
                
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
        non_pipelined_cycles = cycle_count;
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
        pipelined_cycles = cycle_count;
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
        $monitor("Time=%t, State(Non-Pipe=%d, Pipe=%d), Done=%b", 
                 $time, non_pipe_state, pipe_state, done);
    end

endmodule
