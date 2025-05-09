`timescale 1ns / 1ps

module top_module(
    input wire clk,                  // System clock
    input wire rst,                  // Reset signal
    input wire start,                // Start normal operation
    input wire sel_pipelined,        // Control for pipeline mode (reserved for future use)
    output wire done,                // Indicates normal operation is active
    output wire [2:0] cycle_count    // Debug output for cycle counting
);

    // We use sel_pipelined to select between different test data sets
    // during normal operation, though the primary pipelining strategy
    // remains the same.
    wire use_alt_data;
    assign use_alt_data = sel_pipelined;

    // Internal signals
    wire start_bist;                 // Signal to start BIST
    wire bist_active;                // BIST is in progress
    wire bist_pass;                  // BIST pass/fail status
    wire normal_active;              // Normal operation active
    wire sel_eq;                     // Equation select
    
    // Operand signals
    wire [7:0] x1, x2;               // Inputs for altitude correction
    wire [7:0] v, t, c;              // Inputs for battery estimation
    wire [15:0] result_a;            // Result of altitude correction
    wire [15:0] result_b;            // Result of battery estimation
    
    // Input selection (normal vs. test mode)
    reg [7:0] x1_in, x2_in, v_in, t_in, c_in;
    reg sel_eq_in;
    
    // Test input signals from BIST
    wire [7:0] x1_test, x2_test, v_test, t_test, c_test;
    wire sel_eq_test;
    
    // Controller instantiation
    controller controller_inst(
        .clk(clk),
        .rst(rst),
        .start(start),
        .bist_active(bist_active),
        .bist_pass(bist_pass),
        .start_bist(start_bist),
        .normal_active(normal_active),
        .sel_eq(sel_eq),
        .cycle_count(cycle_count)
    );
    
    // BIST instantiation
    bist bist_inst(
        .clk(clk),
        .rst(rst),
        .start_bist(start_bist),
        .result_a(result_a),
        .result_b(result_b),
        .x1_test(x1_test),
        .x2_test(x2_test),
        .v_test(v_test),
        .t_test(t_test),
        .c_test(c_test),
        .sel_eq_test(sel_eq_test),
        .bist_active(bist_active),
        .bist_pass(bist_pass)
    );
    
    // Input selection (normal operation vs BIST)
    always @(*) begin
        if (bist_active) begin
            // During BIST, use test vectors
            x1_in = x1_test;
            x2_in = x2_test;
            v_in = v_test;
            t_in = t_test;
            c_in = c_test;
            sel_eq_in = sel_eq_test;
        end else begin
            // During normal operation, use runtime inputs with data set selected by sel_pipelined
            // In a real implementation, these would come from sensors or external inputs
            if (use_alt_data) begin
                // Alternative data set when sel_pipelined is active
                x1_in = 8'sd7;           // Alternative altitude sensor input
                x2_in = 8'sd9;           // Alternative altitude sensor input
                v_in = 8'sd6;            // Alternative voltage reading
                t_in = 8'sd4;            // Alternative time value
                c_in = 8'sd15;           // Alternative constant value
            end else begin
                // Default data set
                x1_in = 8'sd10;          // Default altitude sensor input
                x2_in = 8'sd15;          // Default altitude sensor input
                v_in = 8'sd12;           // Default voltage reading
                t_in = 8'sd8;            // Default time value
                c_in = 8'sd20;           // Default constant value
            end
            sel_eq_in = sel_eq;          // Use controller's equation selection
        end
    end
    
    // Datapath instantiation
    datapath datapath_inst(
        .clk(clk),
        .rst(rst),
        .x1(x1_in),
        .x2(x2_in),
        .v(v_in),
        .t(t_in),
        .c(c_in),
        .sel_eq(sel_eq_in),
        .result_a(result_a),
        .result_b(result_b)
    );
    
    // Output assignments
    assign done = normal_active;
    
endmodule
