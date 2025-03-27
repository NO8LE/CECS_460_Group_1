module cdc_synchronizer (
    input wire clk_A,      // Clock domain A
    input wire clk_B,      // Clock domain B
    input wire reset,      // Reset signal
    input wire IN,         // Input signal in clock domain A
    output wire B,         // Output signal in clock domain B
    // Monitor outputs
    output wire A_mon,     // Monitor for FF A
    output wire B1_mon     // Monitor for FF B1
);

    // Internal flip-flop signals
    reg A;      // First flip-flop in domain A
    reg B1;     // First flip-flop in domain B
    reg B2;     // Second flip-flop in domain B (output)

    // First stage - Sample input in clock domain A
    always @(posedge clk_A or posedge reset) begin
        if (reset) begin
            A <= 1'b0;
        end else begin
            A <= IN;
        end
    end

    // Second stage - Synchronize to clock domain B with dual flip-flops
    always @(posedge clk_B or posedge reset) begin
        if (reset) begin
            B1 <= 1'b0;
            B2 <= 1'b0;
        end else begin
            B1 <= A;    // First flip-flop in domain B captures A
            B2 <= B1;   // Second flip-flop in domain B captures B1
        end
    end

    // Assign the final synchronized output
    assign B = B2;
    
    // Expose internal signals for monitoring
    assign A_mon = A;
    assign B1_mon = B1;

endmodule