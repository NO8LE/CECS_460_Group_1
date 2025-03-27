`timescale 1ns/1ps

module cdc_synchronizer_tb;

    // Test signals
    reg clk_A;
    reg clk_B;
    reg reset;
    reg IN;
    wire B;
    
    // Internal signals for monitoring (from the DUT)
    wire A_mon;
    wire B1_mon;
    
    // Clock parameters
    parameter CLK_A_PERIOD = 10;  // 100 MHz
    parameter CLK_B_PERIOD = 15;  // ~66.7 MHz (different domain)
    
    // Random delay for metastability testing
    real random_delay;
    
    // Instantiate the CDC synchronizer module with internal signal monitoring
    cdc_synchronizer dut (
        .clk_A(clk_A),
        .clk_B(clk_B),
        .reset(reset),
        .IN(IN),
        .B(B),
        // Monitor signals
        .A_mon(A_mon),
        .B1_mon(B1_mon)
    );
    
    // Clock generation for domain A
    initial begin
        clk_A = 0;
        forever #(CLK_A_PERIOD/2) clk_A = ~clk_A;
    end
    
    // Clock generation for domain B (different frequency)
    initial begin
        clk_B = 0;
        forever #(CLK_B_PERIOD/2) clk_B = ~clk_B;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        IN = 0;
        
        // Apply reset for a few clock cycles
        #30;
        reset = 0;
        #20;
        
        // Test case 1: Simple transition (0->1)
        $display("Test case 1: Simple transition (0->1)");
        IN = 1;
        #100;
        
        // Test case 2: Multiple transitions
        $display("Test case 2: Multiple transitions");
        repeat (5) begin
            #25 IN = ~IN;
        end
        #100;
        
        // Test case 3: Metastability inducing transitions
        $display("Test case 3: Metastability inducing transitions");
        repeat (10) begin
            // Generate random delay to induce potential metastability
            random_delay = $urandom_range(1, 1000) * 1e-12; // Picoseconds range
            #(random_delay);
            
            // Toggle input near clock edge to induce setup/hold violations
            @(posedge clk_A);
            #(CLK_A_PERIOD/2 - 0.1); // Just before next clock edge
            IN = ~IN;
        end
        #200;
        
        // Test case 4: Rapid transitions during clock alignment
        $display("Test case 4: Rapid transitions during clock alignment");
        // Wait for clocks to be nearly aligned
        #(CLK_A_PERIOD * 5);
        // Rapidly toggle input when clocks might align
        repeat (20) begin
            #1 IN = ~IN;
        end
        #200;
        
    // End simulation
        $display("Simulation complete");
        $finish;
    end
    
    // Monitor for signal changes
    initial begin
        $monitor("Time: %t, clk_A: %b, clk_B: %b, IN: %b, A: %b, B1: %b, B: %b", 
                 $time, clk_A, clk_B, IN, A_mon, B1_mon, B);
    end

endmodule