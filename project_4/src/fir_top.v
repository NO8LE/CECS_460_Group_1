`timescale 1ns / 1ps

module fir_top (
    input wire clk,
    input wire rst,
    input wire start,                // Start signal
    input wire sel_pipelined,        // 0: non-pipelined, 1: pipelined
    output wire done,                // Processing complete signal
    output wire [31:0] cycle_count   // Performance counter (only MSBs will be connected)
);
    // Default parameters (hardcoded to avoid requiring external pins)
    localparam [9:0] input_addr = 10'd0;     // Starting address for input samples
    localparam [9:0] output_addr = 10'd512;  // Starting address for output samples
    localparam [9:0] sample_count = 10'd100; // Number of samples to process

    // Internal debug signals (not connected to external pins)
    wire [3:0] non_pipe_state;
    wire [2:0] pipe_state;

    // Internal signals for BRAM interface
    wire [9:0] mem_addr_a_non_pipe, mem_addr_a_pipe;
    wire [9:0] mem_addr_b_non_pipe, mem_addr_b_pipe;
    wire [7:0] mem_data_in_b_non_pipe, mem_data_in_b_pipe;
    wire mem_we_b_non_pipe, mem_we_b_pipe;
    
    // Actual memory interface signals (muxed based on sel_pipelined)
    reg [9:0] mem_addr_a, mem_addr_b;
    reg [7:0] mem_data_in_b;
    reg mem_we_b;
    wire [7:0] mem_data_out_a;
    
    // Done signals from both implementations
    wire done_non_pipe, done_pipe;
    
    // Performance counters
    reg [31:0] cycle_counter;
    reg counting;
    
    // Memory instance
    bram_memory memory (
        .clk(clk),
        .rst(rst),
        .addr_a(mem_addr_a),
        .addr_b(mem_addr_b),
        .we_a(1'b0),              // Port A is only used for reading
        .we_b(mem_we_b),
        .data_in_a(8'd0),         // Not used for writing
        .data_in_b(mem_data_in_b),
        .data_out_a(mem_data_out_a),
        .data_out_b()             // Not used in this design
    );
    
    // Non-pipelined filter instance
    fir_non_pipelined non_pipelined_filter (
        .clk(clk),
        .rst(rst),
        .start(start && !sel_pipelined),  // Start only when selected
        .input_addr(input_addr),
        .output_addr(output_addr),
        .sample_count(sample_count),
        .done(done_non_pipe),
        
        // Memory interface
        .mem_addr_a(mem_addr_a_non_pipe),
        .mem_data_out_a(sel_pipelined ? 8'd0 : mem_data_out_a),  // Only valid when selected
        .mem_addr_b(mem_addr_b_non_pipe),
        .mem_data_in_b(mem_data_in_b_non_pipe),
        .mem_we_b(mem_we_b_non_pipe)
    );
    
    // Pipelined filter instance
    fir_pipelined pipelined_filter (
        .clk(clk),
        .rst(rst),
        .start(start && sel_pipelined),  // Start only when selected
        .input_addr(input_addr),
        .output_addr(output_addr),
        .sample_count(sample_count),
        .done(done_pipe),
        
        // Memory interface
        .mem_addr_a(mem_addr_a_pipe),
        .mem_data_out_a(sel_pipelined ? mem_data_out_a : 8'd0),  // Only valid when selected
        .mem_addr_b(mem_addr_b_pipe),
        .mem_data_in_b(mem_data_in_b_pipe),
        .mem_we_b(mem_we_b_pipe)
    );
    
    // Assign the done signal based on the selected implementation
    assign done = sel_pipelined ? done_pipe : done_non_pipe;
    
    // Output current cycle count
    assign cycle_count = cycle_counter;
    
    // Debug signals
    assign non_pipe_state = non_pipelined_filter.state;
    assign pipe_state = pipelined_filter.state;
    
    // Memory interface multiplexing
    always @(*) begin
        if (sel_pipelined) begin
            // Use pipelined filter memory interface
            mem_addr_a = mem_addr_a_pipe;
            mem_addr_b = mem_addr_b_pipe;
            mem_data_in_b = mem_data_in_b_pipe;
            mem_we_b = mem_we_b_pipe;
        end else begin
            // Use non-pipelined filter memory interface
            mem_addr_a = mem_addr_a_non_pipe;
            mem_addr_b = mem_addr_b_non_pipe;
            mem_data_in_b = mem_data_in_b_non_pipe;
            mem_we_b = mem_we_b_non_pipe;
        end
    end
    
    // Performance counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_counter <= 32'd0;
            counting <= 1'b0;
        end else begin
            if (start) begin
                // Reset counter when starting
                cycle_counter <= 32'd0;
                counting <= 1'b1;
            end else if (done) begin
                // Stop counting when done
                counting <= 1'b0;
            end else if (counting) begin
                // Count cycles during processing
                cycle_counter <= cycle_counter + 1;
            end
        end
    end

endmodule
