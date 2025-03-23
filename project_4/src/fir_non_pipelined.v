`timescale 1ns / 1ps

module fir_non_pipelined (
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
    localparam IDLE          = 4'd0;
    localparam LOAD_X0       = 4'd1;
    localparam COMPUTE_X0    = 4'd2;
    localparam LOAD_X1       = 4'd3;
    localparam COMPUTE_X1    = 4'd4;
    localparam LOAD_X2       = 4'd5;
    localparam COMPUTE_X2    = 4'd6;
    localparam LOAD_X3       = 4'd7;
    localparam COMPUTE_X3    = 4'd8;
    localparam LOAD_X4       = 4'd9;
    localparam COMPUTE_X4    = 4'd10;
    localparam WRITE_RESULT  = 4'd11;
    localparam CHECK_DONE    = 4'd12;
    
    // State register
    reg [3:0] state, next_state;
    
    // Processing registers
    reg [9:0] current_sample;            // Index of the current sample being processed
    reg signed [15:0] accumulator;       // 16-bit for handling multiplication growth
    // Note: We don't need to store the sample values in registers since we only use them once
    wire signed [7:0] current_sample_value; // Current sample from memory
    
    // Assign the current sample value from memory output
    assign current_sample_value = mem_data_out_a;
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state and output logic
    always @(*) begin
        // Default values
        next_state = state;
        mem_addr_a = 10'd0;
        mem_addr_b = 10'd0;
        mem_data_in_b = 8'd0;
        mem_we_b = 1'b0;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD_X0;
                end
            end
            
            LOAD_X0: begin
                // Read current sample (x[n])
                mem_addr_a = input_addr + current_sample;
                next_state = COMPUTE_X0;
            end
            
            COMPUTE_X0: begin
                // Multiply x[n] by h[0] and start accumulation
                next_state = LOAD_X1;
            end
            
            LOAD_X1: begin
                // Read x[n-1] if available, otherwise use 0
                mem_addr_a = (current_sample >= 1) ? (input_addr + current_sample - 1) : 10'd0;
                next_state = COMPUTE_X1;
            end
            
            COMPUTE_X1: begin
                // Multiply x[n-1] by h[1] and accumulate
                next_state = LOAD_X2;
            end
            
            LOAD_X2: begin
                // Read x[n-2] if available, otherwise use 0
                mem_addr_a = (current_sample >= 2) ? (input_addr + current_sample - 2) : 10'd0;
                next_state = COMPUTE_X2;
            end
            
            COMPUTE_X2: begin
                // Multiply x[n-2] by h[2] and accumulate
                next_state = LOAD_X3;
            end
            
            LOAD_X3: begin
                // Read x[n-3] if available, otherwise use 0
                mem_addr_a = (current_sample >= 3) ? (input_addr + current_sample - 3) : 10'd0;
                next_state = COMPUTE_X3;
            end
            
            COMPUTE_X3: begin
                // Multiply x[n-3] by h[3] and accumulate
                next_state = LOAD_X4;
            end
            
            LOAD_X4: begin
                // Read x[n-4] if available, otherwise use 0
                mem_addr_a = (current_sample >= 4) ? (input_addr + current_sample - 4) : 10'd0;
                next_state = COMPUTE_X4;
            end
            
            COMPUTE_X4: begin
                // Multiply x[n-4] by h[4] and accumulate
                next_state = WRITE_RESULT;
            end
            
            WRITE_RESULT: begin
                // Write the computed result to memory
                mem_addr_b = output_addr + current_sample;
                mem_data_in_b = accumulator[15:8]; // Take upper 8 bits of result
                mem_we_b = 1'b1;
                next_state = CHECK_DONE;
            end
            
            CHECK_DONE: begin
                if (current_sample == sample_count - 1) begin
                    next_state = IDLE; // Processing complete
                end else begin
                    next_state = LOAD_X0; // Process next sample
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Sample processing control
    always @(posedge clk) begin
        if (rst) begin
            current_sample <= 10'd0;
            accumulator <= 16'd0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        current_sample <= 10'd0;
                        accumulator <= 16'd0;
                        done <= 1'b0;
                    end
                end
                
                COMPUTE_X0: begin
                    // Directly use mem_data_out_a without storing in x0
                    accumulator <= mem_data_out_a * h0;
                end
                
                COMPUTE_X1: begin
                    // Directly use mem_data_out_a without storing in x1
                    accumulator <= accumulator + mem_data_out_a * h1;
                end
                
                COMPUTE_X2: begin
                    // Directly use mem_data_out_a without storing in x2
                    accumulator <= accumulator + mem_data_out_a * h2;
                end
                
                COMPUTE_X3: begin
                    // Directly use mem_data_out_a without storing in x3
                    accumulator <= accumulator + mem_data_out_a * h3;
                end
                
                COMPUTE_X4: begin
                    // Directly use mem_data_out_a without storing in x4
                    accumulator <= accumulator + mem_data_out_a * h4;
                end
                
                CHECK_DONE: begin
                    if (current_sample == sample_count - 1) begin
                        done <= 1'b1;
                    end else begin
                        current_sample <= current_sample + 1;
                        accumulator <= 16'd0;
                    end
                end
            endcase
        end
    end

endmodule
