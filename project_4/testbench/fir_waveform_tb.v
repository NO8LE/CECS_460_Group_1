`timescale 1ns / 1ps

module fir_waveform_tb();
    // Clock and reset
    reg clk = 0;
    reg rst = 0;
    
    // Control signals
    reg start = 0;
    reg sel_pipelined = 0;
    reg [9:0] input_addr = 10'd0;
    reg [9:0] output_addr = 10'd512;
    reg [9:0] sample_count = 10'd20;  // Use fewer samples for clearer waveforms
    
    // Output signals
    wire done;
    wire [31:0] cycle_count;
    
    // FIR top instance
    fir_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .sample_count(sample_count),
        .done(done),
        .cycle_count(cycle_count),
        .non_pipe_state(),
        .pipe_state()
    );
    
    // Generate clock
    always #5 clk = ~clk;  // 100 MHz clock
    
    // Test signals for waveform analysis
    task run_filter;
        input sel_pipe;
        input [9:0] out_addr;
        begin
            sel_pipelined = sel_pipe;
            output_addr = out_addr;
            #10;
            start = 1;
            #10;
            start = 0;
            wait(done);
            $display("%s implementation completed in %d cycles", 
                     sel_pipe ? "Pipelined" : "Non-pipelined", cycle_count);
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
        run_filter(0, 10'd512);
        
        // Run pipelined next
        $display("Running pipelined filter for waveform analysis...");
        run_filter(1, 10'd600);
        
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
    wire signed [7:0] non_pipe_x0 = dut.non_pipelined_filter.x0;
    wire signed [7:0] non_pipe_x1 = dut.non_pipelined_filter.x1;
    wire signed [7:0] non_pipe_x2 = dut.non_pipelined_filter.x2;
    wire signed [7:0] non_pipe_x3 = dut.non_pipelined_filter.x3;
    wire signed [7:0] non_pipe_x4 = dut.non_pipelined_filter.x4;
    
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
    
    // Stage 2 pipeline registers
    wire signed [15:0] pipe_mac0_s2 = dut.pipelined_filter.mac0_s2;
    wire signed [15:0] pipe_mac1_s2 = dut.pipelined_filter.mac1_s2;
    wire signed [15:0] pipe_mac2_s2 = dut.pipelined_filter.mac2_s2;
    wire signed [15:0] pipe_mac3_s2 = dut.pipelined_filter.mac3_s2;
    wire signed [15:0] pipe_mac4_s2 = dut.pipelined_filter.mac4_s2;
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

endmodule
