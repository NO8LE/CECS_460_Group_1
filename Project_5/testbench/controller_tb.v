`timescale 1ns / 1ps

module controller_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg bist_active;
    reg bist_pass;

    // Outputs
    wire start_bist;
    wire normal_active;
    wire sel_eq;
    wire [2:0] cycle_count;

    // Instantiate the Unit Under Test (UUT)
    controller uut (
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

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test scenario
    integer test_scenario;
    
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        start = 0;
        bist_active = 0;
        bist_pass = 0;
        test_scenario = 0;

        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Scenario 1: Normal operation flow - BIST pass, then start
        test_scenario = 1;
        $display("Starting Test Scenario 1: Normal operation flow");
        
        // After reset, controller should initiate BIST
        if (start_bist)
            $display("PASS: Controller correctly initiated BIST after reset");
        else
            $display("FAIL: Controller did not initiate BIST after reset");
            
        // Simulate BIST running
        bist_active = 1;
        #50;
        
        // Simulate BIST passing
        bist_active = 0;
        bist_pass = 1;
        #20;
        
        // Controller should now be waiting for start signal
        if (!normal_active)
            $display("PASS: Controller correctly waiting for start signal");
        else
            $display("FAIL: Controller entered normal operation before start signal");
            
        // Assert start signal
        start = 1;
        #20;
        start = 0;
        
        // Controller should now be in normal operation
        if (normal_active)
            $display("PASS: Controller correctly entered normal operation");
        else
            $display("FAIL: Controller did not enter normal operation after start");
            
        // Check if equation select toggles in normal operation
        #100;
        
        // Apply reset for next scenario
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Scenario 2: BIST failure handling
        test_scenario = 2;
        $display("Starting Test Scenario 2: BIST failure handling");
        
        // After reset, controller should initiate BIST
        if (start_bist)
            $display("PASS: Controller correctly initiated BIST after reset");
        else
            $display("FAIL: Controller did not initiate BIST after reset");
            
        // Simulate BIST running
        bist_active = 1;
        #50;
        
        // Simulate BIST failing
        bist_active = 0;
        bist_pass = 0;
        #20;
        
        // Controller should not allow normal operation
        start = 1;
        #20;
        start = 0;
        
        if (!normal_active)
            $display("PASS: Controller correctly prevented normal operation after BIST failure");
        else
            $display("FAIL: Controller entered normal operation despite BIST failure");
            
        #100;
        $display("All controller tests completed");
    end
    
    // Monitor controller signals
    initial begin
        $display("Controller Testbench Starting...");
        $display("Time\tState\tStart_BIST\tNormal\tSel_Eq\tCount");
        $monitor("%0t\t%d\t%b\t\t%b\t%b\t%d", $time, uut.state, start_bist, normal_active, sel_eq, cycle_count);
    end
    
    // Check equation selection toggling
    reg prev_sel_eq;
    integer toggle_count;
    
    initial begin
        prev_sel_eq = 0;
        toggle_count = 0;
    end
    
    always @(posedge clk) begin
        if (normal_active) begin
            if (sel_eq != prev_sel_eq) begin
                toggle_count = toggle_count + 1;
                $display("Equation select toggled at time %0t", $time);
            end
            prev_sel_eq = sel_eq;
            
            // Check after 10 cycles if toggling worked
            if (toggle_count == 10) begin
                $display("PASS: Equation select correctly toggled during normal operation");
                toggle_count = toggle_count + 1; // Prevent multiple displays
            end
        end
    end
    
endmodule
