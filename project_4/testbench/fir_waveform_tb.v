`timescale 1ns / 1ps

module fir_waveform_tb();
    // Clock and reset
    reg clk = 0;
    reg rst = 0;
    
    // Control signals
    reg start = 0;
    reg sel_pipelined = 0;
    
    // Output signals
    wire done;
    wire [2:0] cycle_count;  // Now only 3 bits
    
    // Access the full 32-bit cycle counter inside the DUT
    wire [31:0] full_cycle_counter;
    assign full_cycle_counter = dut.cycle_counter;
    
    // FIR top instance
    fir_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .done(done),
        .cycle_count(cycle_count)
    );
    
    // Generate clock
    always #5 clk = ~clk;  // 100 MHz clock
    
    // We'll use the DUT's built-in cycle counter for performance tracking
    // (no need for a separate cycle counter)
    
    // Test signals for waveform analysis with diagnostic outputs
    task run_filter;
        input sel_pipe;
        begin
            sel_pipelined = sel_pipe;
            $display("Starting %s filter run at time %t", 
                    sel_pipe ? "pipelined" : "non-pipelined", $time);
            #20;  // Shorter delay before starting
            start = 1;
            #20; // Shorter start pulse for quicker test
            start = 0;
            $display("%s start pulse completed at time %t", 
                    sel_pipe ? "Pipelined" : "Non-pipelined", $time);
            wait(done);
            $display("%s implementation completed in %d cycles at time %t", 
                     sel_pipe ? "Pipelined" : "Non-pipelined", full_cycle_counter, $time);
            #20;  // Shorter delay for visualization
        end
    endtask
    
    // Memory array for holding test pattern
    reg [7:0] test_pattern [0:63];  // Reduced from 1024 to 64 entries
    
    // Initialize memory with test signal
    task init_test_signal;
        integer i;
        reg we_a;
        reg [9:0] addr_a;
        reg [7:0] data_in_a;
        begin
            // Reset memory first
            rst = 1;
            #50; // Longer reset
            rst = 0;
            #50; // More stabilization time
            
            $display("Initializing memory at time %t", $time);
            // Generate test pattern (reduced to match array size)
            // Generate 20 samples instead of 64 for quicker simulation
            for (i = 0; i < 20; i = i + 1) begin
                // Calculate sample value - simple step function for clear waveform visualization
                if (i < 5) begin
                    // Initial impulse
                    test_pattern[i] = 8'd64;
                end else if (i >= 10 && i < 15) begin
                    // Second impulse
                    test_pattern[i] = 8'd32;
                end else begin
                    test_pattern[i] = 8'd0;
                end
            end
            
            // Now actually initialize DUT's memory with the test pattern
            for (i = 0; i < 64; i = i + 1) begin
                // Prepare data
                addr_a = i;
                data_in_a = test_pattern[i];
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
            #50; // Longer stabilization
            
            // Verify a few memory values to ensure initialization worked
            $display("DUT Memory initialized with test pattern for waveform analysis");
            
            // Read memory locations using address and data ports
            force dut.mem_addr_a = 0;
            @(posedge clk);
            @(posedge clk); // Wait for registered read
            $display("Memory[0] = %d (should be 64)", $signed(dut.mem_data_out_a));
            release dut.mem_addr_a;
            
            force dut.mem_addr_a = 10;
            @(posedge clk);
            @(posedge clk); // Wait for registered read
            $display("Memory[10] = %d (should be 32)", $signed(dut.mem_data_out_a));
            release dut.mem_addr_a;
            
            force dut.mem_addr_a = 20;
            @(posedge clk);
            @(posedge clk); // Wait for registered read
            $display("Memory[20] = %d (should be 0)", $signed(dut.mem_data_out_a));
            release dut.mem_addr_a;
        end
    endtask
    
    // Main simulation sequence with added diagnostics
    initial begin
        $display("Starting waveform testbench at time %t", $time);
        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        $display("Reset complete at time %t", $time);
        
        // Initialize test signal
        init_test_signal();
        
        // Run non-pipelined first
        $display("Running non-pipelined filter for waveform analysis...");
        run_filter(0);
        
        // Run pipelined next
        $display("Running pipelined filter for waveform analysis...");
        run_filter(1);
        
        // Add more time for waveform analysis
        #200;
        
        $display("Waveform analysis simulation complete");
        $finish;
    end
    
    // Expose internal pipeline registers for waveform visualization
    // Non-pipelined internal signals
    wire [3:0] non_pipe_state = dut.non_pipelined_filter.state;
    wire [9:0] non_pipe_current_sample = dut.non_pipelined_filter.current_sample;
    wire signed [15:0] non_pipe_accumulator = dut.non_pipelined_filter.accumulator;
    // Use memory input/output instead of removed sample registers
    wire signed [7:0] non_pipe_mem_out = dut.non_pipelined_filter.mem_data_out_a;
    
    // Pipelined internal signals
    wire [2:0] pipe_state = dut.pipelined_filter.state;
    wire [9:0] pipe_read_idx = dut.pipelined_filter.read_sample_idx;
    wire [9:0] pipe_write_idx = dut.pipelined_filter.write_sample_idx;
    wire pipe_active = dut.pipelined_filter.pipeline_active;
    
    // Stage 1 pipeline registers
    wire signed [7:0] pipe_x0_s1 = dut.pipelined_filter.x0_s1;
    wire signed [7:0] pipe_x1_s1 = dut.pipelined_filter.x1_s1;
    wire signed [7:0] pipe_x2_s1 = dut.pipelined_filter.x2_s1;
    wire signed [7:0] pipe_x3_s1 = dut.pipelined_filter.x3_s1;
    wire signed [7:0] pipe_x4_s1 = dut.pipelined_filter.x4_s1;
    
    // Stage 2 pipeline registers - direct sum accumulation
    wire signed [15:0] pipe_sum_s2 = dut.pipelined_filter.sum_s2;
    
    // Stage 3 pipeline registers
    wire signed [7:0] pipe_result_s3 = dut.pipelined_filter.result_s3;
    wire pipe_output_valid_s3 = dut.pipelined_filter.output_valid_s3;
    
    // Memory interface signals for monitoring
    wire [9:0] mem_addr_a = dut.mem_addr_a;
    wire [9:0] mem_addr_b = dut.mem_addr_b;
    wire [7:0] mem_data_out_a = dut.mem_data_out_a;
    wire [7:0] mem_data_in_b = dut.mem_data_in_b;
    wire mem_we_b = dut.mem_we_b;
    
    // Variables for verification - ensure they're connected
    reg [9:0] verify_addr;
    reg [7:0] verify_data;  // Changed from wire to reg as it receives procedural assignment
    
    // Connect verify_data to memory output via procedural assignment
    // We can't directly access memory array, so we'll use a task instead
    task read_memory_value;
        input [9:0] addr;
        output [7:0] data;
        begin
            force dut.mem_addr_a = addr;
            @(posedge clk);
            @(posedge clk); // Wait for registered read
            data = dut.mem_data_out_a;
            release dut.mem_addr_a;
        end
    endtask
    
    // Using the task to read a value when needed
    always @(verify_addr) begin
        read_memory_value(verify_addr, verify_data);
    end
    
    // Performance metrics
    reg [31:0] non_pipelined_cycles;
    reg [31:0] pipelined_cycles;
    real speedup;
    
    // Process to capture performance metrics with diagnostics
    always @(posedge clk) begin
        if (done && sel_pipelined == 0) begin
            non_pipelined_cycles = full_cycle_counter;
            $display("Non-pipelined cycles (captured): %d at time %t", 
                     non_pipelined_cycles, $time);
        end
        else if (done && sel_pipelined == 1) begin
            pipelined_cycles = full_cycle_counter;
            $display("Pipelined cycles (captured): %d at time %t", 
                     pipelined_cycles, $time);
            // Calculate speedup after both runs are complete
            if (non_pipelined_cycles > 0) begin
                speedup = non_pipelined_cycles * 1.0 / pipelined_cycles;
                $display("Speedup: %0.2f x", speedup);
            end
        end
    end
    
    // Enhanced monitoring of counter and state signals
    initial begin
        $monitor("Time=%t, Full Counter=%d, Cycle Count=%d, Done=%b, NP State=%d, P State=%d", 
                 $time, full_cycle_counter, cycle_count, done, 
                 dut.non_pipelined_filter.state, dut.pipelined_filter.state);
                 
        // Force simulation to run for a minimum time
        #10000 $display("Simulation timeout at 10,000ns");
        $finish;
    end

endmodule
