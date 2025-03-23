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
    
    // Internal cycle counter for performance measurement
    reg [31:0] cycle_counter = 0;
    
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
    
    // Track cycles during each test
    always @(posedge clk) begin
        if (start) begin
            cycle_counter <= 0;
        end else if (!done) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
    
    // Test signals for waveform analysis
    task run_filter;
        input sel_pipe;
        begin
            sel_pipelined = sel_pipe;
            #50;  // Longer delay before starting
            start = 1;
            #100; // Longer start pulse (was 10)
            start = 0;
            wait(done);
            $display("%s implementation completed in %d cycles", 
                     sel_pipe ? "Pipelined" : "Non-pipelined", cycle_counter);
            #50;  // Add some delay for visualization
        end
    endtask
    
    // Initialize memory with test signal
    task init_test_signal;
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
            
            // Simple step function for clear visualization in waveforms
            for (i = 0; i < 1024; i = i + 1) begin
                // Calculate sample value
                if (i < 5) begin
                    // Initial impulse
                    data_in_a = 8'd64;
                end else if (i >= 10 && i < 15) begin
                    // Second impulse
                    data_in_a = 8'd32;
                end else begin
                    data_in_a = 8'd0;
                end
                
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
            
            $display("Memory initialized with test pattern for waveform analysis");
        end
    endtask
    
    // Main simulation sequence
    initial begin
        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        
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
    wire [7:0] verify_data;
    
    // Connect verify_data to memory output
    assign verify_data = dut.memory.mem[verify_addr];
    
    // Performance metrics
    reg [31:0] non_pipelined_cycles;
    reg [31:0] pipelined_cycles;
    real speedup;
    
    // Process to capture performance metrics
    always @(posedge clk) begin
        if (done && sel_pipelined == 0) begin
            non_pipelined_cycles = cycle_counter;
        end
        else if (done && sel_pipelined == 1) begin
            pipelined_cycles = cycle_counter;
            // Calculate speedup after both runs are complete
            if (non_pipelined_cycles > 0) begin
                speedup = non_pipelined_cycles * 1.0 / pipelined_cycles;
            end
        end
    end

endmodule
