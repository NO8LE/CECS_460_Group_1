`timescale 1ns / 1ps

module top_module_tb;
    // Parameters
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg sel_pipelined;

    // Outputs
    wire done;
    wire [2:0] cycle_count;
    
    // Internal signals for monitoring
    wire [15:0] result_a;
    wire [15:0] result_b;
    
    // Instantiate the Unit Under Test (UUT)
    top_module uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .sel_pipelined(sel_pipelined),
        .done(done),
        .cycle_count(cycle_count)
    );

    // Access internal signals for monitoring
    assign result_a = uut.result_a;
    assign result_b = uut.result_b;

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test scenario
    integer test_phase;
    integer i;
    
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        start = 0;
        sel_pipelined = 0;
        test_phase = 0;

        // Apply reset
        rst = 1;
        #20;
        rst = 0;
        test_phase = 1;
        $display("Phase 1: Reset applied, waiting for BIST to complete");
        
        // Wait for BIST to complete
        wait(uut.bist_inst.state == 5); // Wait for TEST_DONE state
        #30;
        
        if (uut.bist_pass) begin
            $display("BIST passed successfully");
        end else begin
            $display("ERROR: BIST failed");
        end
        
        // Start normal operation
        test_phase = 2;
        $display("Phase 2: Starting normal operation");
        start = 1;
        #20;
        start = 0;
        
        // Wait for normal operation to begin
        wait(done);
        $display("Normal operation started");
        
        // Run for several cycles to observe results
        test_phase = 3;
        $display("Phase 3: Running normal operation for multiple cycles");
        
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (i % 2 == 0) begin
                $display("Cycle %0d: Altitude result = %0d", i, $signed(result_a));
            end else begin
                $display("Cycle %0d: Battery result = %0d", i, $signed(result_b));
            end
        end
        
        // Apply reset again to test restart
        test_phase = 4;
        $display("Phase 4: Testing system reset and restart");
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        // Wait for BIST to complete again
        wait(uut.bist_inst.state == 5); // Wait for TEST_DONE state
        #30;
        
        // Start normal operation again
        start = 1;
        #20;
        start = 0;
        
        // Wait for normal operation to begin
        wait(done);
        $display("System successfully restarted after reset");
        
        // Run for a few more cycles
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
        end
        
        $display("All tests completed");
        #100;
    end
    
    // Monitor important signals
    initial begin
        $display("Top Module Testbench Starting...");
        $display("Time\tRST\tStart\tDone\tCycle\tBIST_Active\tBIST_Pass");
        $monitor("%0t\t%b\t%b\t%b\t%d\t%b\t\t%b", 
                 $time, rst, start, done, cycle_count, 
                 uut.bist_active, uut.bist_pass);
    end
    
    // Detailed monitoring of equation selection and results
    always @(posedge clk) begin
        if (done) begin
            $display("@%0t: sel_eq=%b, result_a=%0d, result_b=%0d", 
                     $time, uut.sel_eq, $signed(result_a), $signed(result_b));
        end
    end
    
    // Check resource sharing
    always @(posedge clk) begin
        if (done && uut.sel_eq == 0) begin
            // When computing altitude correction
            $display("Computing Altitude: A = (x1 * k1) + (x2 * k2)");
            $display("Inputs: x1=%0d, x2=%0d", 
                    $signed(uut.datapath_inst.x1), 
                    $signed(uut.datapath_inst.x2));
        end else if (done && uut.sel_eq == 1) begin
            // When computing battery estimation
            $display("Computing Battery: B = (v * t) + c");
            $display("Inputs: v=%0d, t=%0d, c=%0d", 
                    $signed(uut.datapath_inst.v), 
                    $signed(uut.datapath_inst.t), 
                    $signed(uut.datapath_inst.c));
        end
    end
    
endmodule
