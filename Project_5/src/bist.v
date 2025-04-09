`timescale 1ns / 1ps

module bist(
    input wire clk,                  // System clock
    input wire rst,                  // Reset signal
    input wire start_bist,           // Signal to start BIST procedure
    input wire [15:0] result_a,      // Result from altitude equation
    input wire [15:0] result_b,      // Result from battery equation
    output reg [7:0] x1_test,        // Test value for x1
    output reg [7:0] x2_test,        // Test value for x2
    output reg [7:0] v_test,         // Test value for v
    output reg [7:0] t_test,         // Test value for t
    output reg [7:0] c_test,         // Test value for c
    output reg sel_eq_test,          // Test value for equation select
    output reg bist_active,          // Indicates BIST is in progress
    output reg bist_pass             // BIST pass/fail status
);

    // BIST state definitions
    localparam IDLE       = 3'd0;
    localparam TEST_ALT_1 = 3'd1;    // Test altitude equation (first set)
    localparam TEST_ALT_2 = 3'd2;    // Test altitude equation (second set)
    localparam TEST_BAT_1 = 3'd3;    // Test battery equation (first set)
    localparam TEST_BAT_2 = 3'd4;    // Test battery equation (second set)
    localparam TEST_DONE  = 3'd5;    // Testing complete

    reg [2:0] state, next_state;
    reg [3:0] cycle_count;
    reg test_failed;
    
    // Expected test results (precomputed for test vectors)
    wire [15:0] expected_alt_1 = 16'sd29;   // (3*3) + (4*5) = 9 + 20 = 29
    wire [15:0] expected_bat_1 = 16'sd26;   // (2*5) + 16 = 10 + 16 = 26

    // State machine for BIST
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cycle_count <= 0;
            bist_active <= 0;
            bist_pass <= 0;
            test_failed <= 0;
        end else begin
            // Handle state transitions
            state <= next_state;
            
            // Count cycles in each test state
            if (state == next_state) begin
                if (bist_active)
                    cycle_count <= cycle_count + 1;
            end else begin
                cycle_count <= 0;  // Reset counter on state change
            end
            
            // Check test results
            case (state)
                TEST_ALT_2: begin
                    // Enough cycles passed for result to be ready (at least 4 cycles)
                    if (cycle_count >= 4 && result_a != expected_alt_1) begin
                        test_failed <= 1;
                    end
                end
                
                TEST_BAT_2: begin
                    // Enough cycles passed for result to be ready (at least 4 cycles)
                    if (cycle_count >= 4 && result_b != expected_bat_1) begin
                        test_failed <= 1;
                    end
                end
                
                TEST_DONE: begin
                    bist_active <= 0;
                    bist_pass <= !test_failed;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;  // Default: stay in current state
        
        case (state)
            IDLE: begin
                if (start_bist) begin
                    next_state = TEST_ALT_1;
                    bist_active = 1;
                end
            end
            
            TEST_ALT_1: begin
                if (cycle_count >= 2) next_state = TEST_ALT_2;
            end
            
            TEST_ALT_2: begin
                if (cycle_count >= 4) next_state = TEST_BAT_1;
            end
            
            TEST_BAT_1: begin
                if (cycle_count >= 2) next_state = TEST_BAT_2;
            end
            
            TEST_BAT_2: begin
                if (cycle_count >= 4) next_state = TEST_DONE;
            end
            
            TEST_DONE: begin
                // Stay in TEST_DONE state
            end
        endcase
    end
    
    // Generate test vectors based on current state
    always @(*) begin
        // Default test values (safe values)
        x1_test = 8'd0;
        x2_test = 8'd0;
        v_test = 8'd0;
        t_test = 8'd0;
        c_test = 8'd0;
        sel_eq_test = 0;
        
        case (state)
            TEST_ALT_1, TEST_ALT_2: begin
                // Test altitude equation: A = (x1 * 3) + (x2 * 5)
                // With x1=3, x2=4, result should be 29
                x1_test = 8'sd3;
                x2_test = 8'sd4;
                sel_eq_test = 0;  // Select altitude equation
            end
            
            TEST_BAT_1, TEST_BAT_2: begin
                // Test battery equation: B = (v * t) + c
                // With v=2, t=5, c=16, result should be 26
                v_test = 8'sd2;
                t_test = 8'sd5;
                c_test = 8'sd16;
                sel_eq_test = 1;  // Select battery equation
            end
            
            default: begin
                // In other states, use safe values
            end
        endcase
    end
    
endmodule
