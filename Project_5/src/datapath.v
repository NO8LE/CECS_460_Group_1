`timescale 1ns / 1ps

module datapath(
    input wire clk,                  // System clock
    input wire rst,                  // Reset signal
    input wire [7:0] x1,             // Input x1 for altitude correction
    input wire [7:0] x2,             // Input x2 for altitude correction
    input wire [7:0] v,              // Input v for battery estimation
    input wire [7:0] t,              // Input t for battery estimation
    input wire [7:0] c,              // Input c for battery estimation
    input wire sel_eq,               // Select signal to alternate between equations (0: altitude, 1: battery)
    output reg [15:0] result_a,      // Result of altitude correction equation
    output reg [15:0] result_b       // Result of battery estimation equation
);

    // Constants for altitude correction
    localparam K1 = 8'sd3;           // k1 = 3 (signed)
    localparam K2 = 8'sd5;           // k2 = 5 (signed)

    // Pipeline registers
    reg [7:0] op1_reg, op2_reg;      // Operands for multiplier
    reg [15:0] mul_result;           // Multiplication result
    reg [15:0] add_term;             // Second term for addition
    reg sel_eq_stage1, sel_eq_stage2; // Pipeline stage equation selection

    // Shared resources
    wire [15:0] mul_out;             // Output from multiplier
    wire [15:0] add_out;             // Output from adder
    
    // Pipeline control signals
    reg first_term;                  // Tracks if we're processing the first or second term
    
    // First stage: Select operands for multiplication
    always @(*) begin
        if (sel_eq == 0) begin       // Altitude equation
            if (first_term) begin
                op1_reg = x1;
                op2_reg = K1;
            end else begin
                op1_reg = x2;
                op2_reg = K2;
            end
        end else begin               // Battery equation
            if (first_term) begin
                op1_reg = v;
                op2_reg = t;
            end else begin
                op1_reg = 8'd0;      // Not used in second term
                op2_reg = 8'd0;      // Not used in second term
            end
        end
    end

    // Shared multiplier (combinational)
    assign mul_out = $signed(op1_reg) * $signed(op2_reg);
    
    // Pipeline register for multiplication result
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mul_result <= 16'd0;
            add_term <= 16'd0;
            sel_eq_stage1 <= 0;
            first_term <= 1;
        end else begin
            mul_result <= mul_out;
            
            // Save first term multiplication result for addition
            if (first_term) begin
                add_term <= 16'd0;
            end else begin
                add_term <= mul_result;
            end
            
            // Toggle the first_term flag
            first_term <= ~first_term;
            
            // Pipeline the equation selection
            sel_eq_stage1 <= sel_eq;
            sel_eq_stage2 <= sel_eq_stage1;
        end
    end
    
    // Select second operand for adder
    wire [15:0] add_op2;
    assign add_op2 = (sel_eq_stage1 == 1 && !first_term) ? {{8{c[7]}}, c} : add_term;
    
    // Shared adder (combinational)
    assign add_out = mul_result + add_op2;
    
    // Output results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_a <= 16'd0;
            result_b <= 16'd0;
        end else if (!first_term) begin
            // Store results on second term calculations
            if (sel_eq_stage2 == 0) begin
                result_a <= add_out;
            end else begin
                result_b <= add_out;
            end
        end
    end
    
endmodule
