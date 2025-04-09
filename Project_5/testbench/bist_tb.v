`timescale 1ns / 1ps

module bist_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Inputs
    reg clk;
    reg rst;
    reg start_bist;
    reg [15:0] result_a;
    reg [15:0] result_b;

    // Outputs
    wire [7:0] x1_test;
    wire [7:0] x2_test;
    wire [7:0] v_test;
    wire [7:0] t_test;
    wire [7:0] c_test;
    wire sel_eq_test;
    wire bist_active;
    wire bist_pass;

    // Instantiate the Unit Under Test (UUT)
    bist uut (
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

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test scenarios
    integer test_scenario;
    
    // Expected test results (precomputed for test vectors)
    localparam EXPECTED_ALT_1 = 16'sd29;   // (3*3) + (4*5) = 9 + 20 = 29
    localparam EXPECTED_BAT_1 = 16'sd26;   // (2*5) + 16 = 10 + 16 = 26
    
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        start_bist = 0;
        result_a = 0;
        result_b = 0;
        test_scenario = 0;

        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Scenario 1: BIST Pass (correct results)
        test_scenario = 1;
        $display("Starting Test Scenario 1: BIST Pass (correct results)");
        
        // Start BIST
        start_bist = 1;
        #CLK_PERIOD;
        start_bist = 0;
        
        // Wait for test states and feed expected results
        wait(sel_eq_test == 0);  // Wait for altitude test
        #40; // Wait a few cycles for the test to run
        result_a = EXPECTED_ALT_1;  // Provide expected result
        
        wait(sel_eq_test == 1);  // Wait for battery test
        #40; // Wait a few cycles for the test to run
        result_b = EXPECTED_BAT_1;  // Provide expected result
        
        // Wait for BIST to complete
        wait(!bist_active);
        #CLK_PERIOD;
        
        if (bist_pass)
            $display("PASS: BIST correctly passed with correct results");
        else
            $display("FAIL: BIST should have passed with correct results");
        
        // Apply reset for next scenario
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Scenario 2: BIST Fail (incorrect altitude result)
        test_scenario = 2;
        $display("Starting Test Scenario 2: BIST Fail (incorrect altitude result)");
        
        // Start BIST
        start_bist = 1;
        #CLK_PERIOD;
        start_bist = 0;
        
        // Wait for test states and feed incorrect result for altitude
        wait(sel_eq_test == 0);  // Wait for altitude test
        #40; // Wait a few cycles for the test to run
        result_a = EXPECTED_ALT_1 + 1;  // Provide incorrect result
        
        wait(sel_eq_test == 1);  // Wait for battery test
        #40; // Wait a few cycles for the test to run
        result_b = EXPECTED_BAT_1;  // Provide expected result
        
        // Wait for BIST to complete
        wait(!bist_active);
        #CLK_PERIOD;
        
        if (!bist_pass)
            $display("PASS: BIST correctly failed with incorrect altitude result");
        else
            $display("FAIL: BIST should have failed with incorrect altitude result");
        
        // Apply reset for next scenario
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test Scenario 3: BIST Fail (incorrect battery result)
        test_scenario = 3;
        $display("Starting Test Scenario 3: BIST Fail (incorrect battery result)");
        
        // Start BIST
        start_bist = 1;
        #CLK_PERIOD;
        start_bist = 0;
        
        // Wait for test states and feed expected result for altitude
        wait(sel_eq_test == 0);  // Wait for altitude test
        #40; // Wait a few cycles for the test to run
        result_a = EXPECTED_ALT_1;  // Provide expected result
        
        wait(sel_eq_test == 1);  // Wait for battery test
        #40; // Wait a few cycles for the test to run
        result_b = EXPECTED_BAT_1 - 2;  // Provide incorrect result
        
        // Wait for BIST to complete
        wait(!bist_active);
        #CLK_PERIOD;
        
        if (!bist_pass)
            $display("PASS: BIST correctly failed with incorrect battery result");
        else
            $display("FAIL: BIST should have failed with incorrect battery result");
            
        #100;
        $display("All BIST tests completed");
    end
    
    // Monitor BIST signals
    initial begin
        $display("BIST Testbench Starting...");
        $display("Time\tState\tSel_Eq\tActive\tPass");
        $monitor("%0t\t%d\t%b\t%b\t%b", $time, uut.state, sel_eq_test, bist_active, bist_pass);
    end
    
endmodule
