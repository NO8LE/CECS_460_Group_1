`timescale 1ns / 1ps

module controller(
    input wire clk,              // System clock
    input wire rst,              // Reset signal
    input wire start,            // Start normal operation
    input wire bist_active,      // BIST is in progress
    input wire bist_pass,        // BIST pass/fail status
    output reg start_bist,       // Signal to start BIST
    output reg normal_active,    // Normal operation active
    output reg sel_eq,           // Equation select (0: altitude, 1: battery)
    output reg [2:0] cycle_count // Debug output for cycle counting
);

    // State definitions
    localparam RESET       = 2'd0;  // Initial reset state
    localparam WAIT_BIST   = 2'd1;  // Waiting for BIST to complete
    localparam WAIT_START  = 2'd2;  // Waiting for start signal (after BIST passed)
    localparam NORMAL_OP   = 2'd3;  // Normal operation

    reg [1:0] state, next_state;
    
    // State machine - sequential part
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= RESET;
            cycle_count <= 0;
            normal_active <= 0;
        end else begin
            state <= next_state;
            
            // Handle cycle counter for debugging
            if (state == NORMAL_OP)
                cycle_count <= cycle_count + 1;
            
            // Set normal operation flag
            normal_active <= (state == NORMAL_OP);
        end
    end
    
    // State machine - combinational part
    always @(*) begin
        // Default values
        next_state = state;
        start_bist = 0;
        
        case (state)
            RESET: begin
                next_state = WAIT_BIST;
                start_bist = 1;  // Trigger BIST on entry to WAIT_BIST
            end
            
            WAIT_BIST: begin
                if (!bist_active) begin  // BIST has completed
                    if (bist_pass)
                        next_state = WAIT_START;
                    else
                        next_state = WAIT_BIST;  // Stay in error state if BIST fails
                end
            end
            
            WAIT_START: begin
                if (start)
                    next_state = NORMAL_OP;
            end
            
            NORMAL_OP: begin
                // Continue normal operation once started
            end
        endcase
    end
    
    // Alternating equation select during normal operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sel_eq <= 0;  // Start with altitude calculation
        end else if (state == NORMAL_OP) begin
            // Toggle between equations on every clock cycle
            sel_eq <= ~sel_eq;
        end
    end
    
endmodule
