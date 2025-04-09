`timescale 1ns / 1ps

module datapath_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Inputs
    reg clk;
    reg rst;
    reg [7:0] x1;
    reg [7:0] x2;
    reg [7:0] v;
    reg [7:0] t;
    reg [7:0] c;
    reg sel_eq;

    // Outputs
    wire [15:0] result_a;
    wire [15:0] result_b;

    // Instantiate the Unit Under Test (UUT)
    datapath uut (
        .clk(clk), 
        .rst(rst), 
        .x1(x1), 
        .x2(x2), 
        .v(v), 
        .t(t), 
        .c(c), 
        .sel_eq(sel_eq), 
        .result_a(result_a), 
        .result_b(result_b)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test data
    reg [7:0] test_x1_values [0:2];
    reg [7:0] test_x2_values [0:2];
    reg [7:0] test_v_values [0:2];
    reg [7:0] test_t_values [0:2];
    reg [7:0] test_c_values [0:2];
    
    integer i;
    
    initial begin
        // Initialize test data
        test_x1_values[0] = 8'sd3;   // Test case 1
        test_x2_values[0] = 8'sd4;
        test_v_values[0] = 8'sd2;
        test_t_values[0] = 8'sd5;
        test_c_values[0] = 8'sd16;
        
        test_x1_values[1] = 8'sd10;  // Test case 2
        test_x2_values[1] = 8'sd15;
        test_v_values[1] = 8'sd12;
        test_t_values[1] = 8'sd8;
        test_c_values[1] = 8'sd20;
        
        test_x1_values[2] = -8'sd5;  // Test case 3 (negative values)
        test_x2_values[2] = 8'sd7;
        test_v_values[2] = -8'sd3;
        test_t_values[2] = -8'sd2;
        test_c_values[2] = 8'sd10;
        
        // Initialize Inputs
        clk = 0;
        rst = 0;
        x1 = 8'd0;
        x2 = 8'd0;
        v = 8'd0;
        t = 8'd0;
        c = 8'd0;
        sel_eq = 0;

        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Test alternating equations
        for (i = 0; i < 3; i = i + 1) begin
            // Load test case
            x1 = test_x1_values[i];
            x2 = test_x2_values[i];
            v = test_v_values[i];
            t = test_t_values[i];
            c = test_c_values[i];
            
            // Test altitude equation
            sel_eq = 0;
            #CLK_PERIOD;
            
            // Test battery equation
            sel_eq = 1;
            #CLK_PERIOD;
        end
        
        // Test continuous alternating for multiple cycles
        for (i = 0; i < 20; i = i + 1) begin
            sel_eq = ~sel_eq;
            #CLK_PERIOD;
        end
    end
    
    // Monitor results
    initial begin
        $display("Datapath Testbench Starting...");
        $display("Time\tsel_eq\tresult_a\tresult_b");
        $monitor("%0t\t%b\t%0d\t%0d", $time, sel_eq, $signed(result_a), $signed(result_b));
    end
    
    // Calculate expected results for comparison
    function [15:0] calc_altitude;
        input [7:0] x1_val;
        input [7:0] x2_val;
        begin
            calc_altitude = ($signed(x1_val) * 3) + ($signed(x2_val) * 5);
        end
    endfunction
    
    function [15:0] calc_battery;
        input [7:0] v_val;
        input [7:0] t_val;
        input [7:0] c_val;
        begin
            calc_battery = ($signed(v_val) * $signed(t_val)) + $signed(c_val);
        end
    endfunction
    
    // Check results at appropriate times
    always @(posedge clk) begin
        if (!rst) begin
            // Add delay for pipeline stages to complete
            #25;
            
            if (sel_eq == 0) begin
                $display("Expected Altitude Result: %0d", 
                    calc_altitude(x1, x2));
            end else begin
                $display("Expected Battery Result: %0d", 
                    calc_battery(v, t, c));
            end
        end
    end
    
endmodule
