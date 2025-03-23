`timescale 1ns / 1ps

module fir_pipelined (
    input wire clk,
    input wire rst,
    input wire start,                // Signal to start processing
    input wire [9:0] input_addr,     // Starting address for input samples
    input wire [9:0] output_addr,    // Starting address for output samples
    input wire [9:0] sample_count,   // Number of samples to process
    output reg done,                 // Signal processing is complete
    
    // Memory interface
    output reg [9:0] mem_addr_a,     // Address for reading from memory
    input wire [7:0] mem_data_out_a, // Data read from memory
    output reg [9:0] mem_addr_b,     // Address for writing to memory
    output reg [7:0] mem_data_in_b,  // Data to write to memory
    output reg mem_we_b              // Write enable signal
);

    // Filter coefficients (fixed)
    localparam signed [7:0] h0 = 8'd1;
    localparam signed [7:0] h1 = 8'd2;
    localparam signed [7:0] h2 = 8'd3;
    localparam signed [7:0] h3 = 8'd2;
    localparam signed [7:0] h4 = 8'd1;
    
    // State definitions
    localparam IDLE          = 3'd0;
    localparam PIPELINE_FILL = 3'd1;
    localparam PROCESSING    = 3'd2;
    localparam PIPELINE_FLUSH = 3'd3;
    localparam DONE          = 3'd4;
    
    // State register
    reg [2:0] state, next_state;
    
    // Processing registers
    reg [9:0] read_sample_idx;    // Current sample being read
    reg [9:0] write_sample_idx;   // Current sample being written
    
    // Pipeline registers
    
    // Stage 1: Sample read and buffer shift
    reg signed [7:0] x0_s1, x1_s1, x2_s1, x3_s1, x4_s1;
    
    // Stage 2: Multiply-accumulate operations
    reg signed [15:0] mac0_s2, mac1_s2, mac2_s2, mac3_s2, mac4_s2;
    reg signed [15:0] sum_s2;
    
    // Stage 3: Output to memory
    reg signed [7:0] result_s3;
    reg output_valid_s3;
    // Removed unused output_addr_s3 register
    
    // Pipeline control signals
    reg pipeline_active;
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = PIPELINE_FILL;
                end
            end
            
            PIPELINE_FILL: begin
                // Fill the pipeline (read first 3 samples)
                if (read_sample_idx == 3'd2) begin
                    next_state = PROCESSING;
                end
            end
            
            PROCESSING: begin
                // Regular processing state
                if (read_sample_idx >= sample_count - 1) begin
                    next_state = PIPELINE_FLUSH;
                end
            end
            
            PIPELINE_FLUSH: begin
                // Flush remaining samples in pipeline
                if (write_sample_idx >= sample_count - 1) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Memory addressing
    always @(*) begin
        // Default values
        mem_addr_a = 10'd0;
        mem_addr_b = 10'd0;
        mem_data_in_b = 8'd0;
        mem_we_b = 1'b0;
        
        // Read port addressing (Stage 1)
        if (pipeline_active && state != PIPELINE_FLUSH && state != DONE) begin
            mem_addr_a = input_addr + read_sample_idx;
        end
        
        // Write port addressing (Stage 3)
        if (output_valid_s3) begin
            mem_addr_b = output_addr + write_sample_idx;
            mem_data_in_b = result_s3;
            mem_we_b = 1'b1;
        end
    end
    
    // Pipeline active control
    always @(posedge clk) begin
        if (rst) begin
            pipeline_active <= 1'b0;
        end else if (state == PIPELINE_FILL || state == PROCESSING) begin
            pipeline_active <= 1'b1;
        end else begin
            pipeline_active <= 1'b0;
        end
    end
    
    // Done signal
    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
        end else if (state == DONE) begin
            done <= 1'b1;
        end else if (state == IDLE && start) begin
            done <= 1'b0;
        end
    end
    
    // Sample index counters
    always @(posedge clk) begin
        if (rst) begin
            read_sample_idx <= 10'd0;
            write_sample_idx <= 10'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        read_sample_idx <= 10'd0;
                        write_sample_idx <= 10'd0;
                    end
                end
                
                PIPELINE_FILL, PROCESSING: begin
                    if (pipeline_active) begin
                        read_sample_idx <= read_sample_idx + 1;
                    end
                end
                
                PIPELINE_FLUSH: begin
                    // Do not read new samples in flush stage
                end
            endcase
            
            // Update write counter when stage 3 has valid output
            if (output_valid_s3) begin
                write_sample_idx <= write_sample_idx + 1;
            end
        end
    end
    
    // Pipeline Stage 1: Read sample and shift buffer
    always @(posedge clk) begin
        if (rst) begin
            x0_s1 <= 8'd0;
            x1_s1 <= 8'd0;
            x2_s1 <= 8'd0;
            x3_s1 <= 8'd0;
            x4_s1 <= 8'd0;
        end else if (pipeline_active) begin
            // Shift samples in the buffer
            x4_s1 <= x3_s1;
            x3_s1 <= x2_s1;
            x2_s1 <= x1_s1;
            x1_s1 <= x0_s1;
            x0_s1 <= mem_data_out_a; // Read new sample
        end
    end
    
    // Pipeline Stage 2: Multiply-accumulate operations
    always @(posedge clk) begin
        if (rst) begin
            mac0_s2 <= 16'd0;
            mac1_s2 <= 16'd0;
            mac2_s2 <= 16'd0;
            mac3_s2 <= 16'd0;
            mac4_s2 <= 16'd0;
            sum_s2 <= 16'd0;
        end else begin
            // Parallel multiply operations
            mac0_s2 <= x0_s1 * h0;
            mac1_s2 <= x1_s1 * h1;
            mac2_s2 <= x2_s1 * h2;
            mac3_s2 <= x3_s1 * h3;
            mac4_s2 <= x4_s1 * h4;
            
            // Accumulate all products
            sum_s2 <= mac0_s2 + mac1_s2 + mac2_s2 + mac3_s2 + mac4_s2;
        end
    end
    
    // Pipeline Stage 3: Write result to memory
    always @(posedge clk) begin
        if (rst) begin
            result_s3 <= 8'd0;
            output_valid_s3 <= 1'b0;
        end else begin
            // Take most significant bits of the accumulator result for output
            result_s3 <= sum_s2[15:8];
            
            // Set output valid flag (delayed by pipeline stages)
            if (state == IDLE) begin
                output_valid_s3 <= 1'b0;
            end else if (state == PIPELINE_FILL && read_sample_idx >= 10'd2) begin
                output_valid_s3 <= 1'b1;
            end else if (state == PIPELINE_FLUSH && write_sample_idx >= sample_count - 1) begin
                output_valid_s3 <= 1'b0;
            end
        end
    end

endmodule
