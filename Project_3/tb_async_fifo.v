`timescale 1ns / 1ps

module tb_async_fifo();
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = (1 << ADDR_WIDTH);
    
    // Clock periods
    parameter CLK_90MHZ_PERIOD = 11.11; // 90 MHz in ns
    parameter CLK_65MHZ_PERIOD = 15.38; // 65 MHz in ns
    
    // Write domain signals (90 MHz)
    reg wr_clk = 0;
    reg wr_rst_n = 0;
    reg wr_en = 0;
    reg [DATA_WIDTH-1:0] wr_data = 0;
    wire wr_full;
    
    // Read domain signals (65 MHz)
    reg rd_clk = 0;
    reg rd_rst_n = 0;
    reg rd_en = 0;
    wire [DATA_WIDTH-1:0] rd_data;
    wire rd_empty;
    
    // Test control
    integer i, errors;
    reg [DATA_WIDTH-1:0] expected_data [0:FIFO_DEPTH-1];
    
    // DUT instantiation
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .wr_rst_n(wr_rst_n),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .wr_full(wr_full),
        .rd_clk(rd_clk),
        .rd_rst_n(rd_rst_n),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .rd_empty(rd_empty)
    );
    
    // Gray code pointer monitoring
    wire [ADDR_WIDTH:0] wr_ptr_gray = dut.wr_ptr_gray;
    wire [ADDR_WIDTH:0] rd_ptr_gray = dut.rd_ptr_gray;
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync = dut.rd_ptr_gray_sync2;
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync = dut.wr_ptr_gray_sync2;
    
    // Clock generation
    always #(CLK_90MHZ_PERIOD/2) wr_clk = ~wr_clk;
    always #(CLK_65MHZ_PERIOD/2) rd_clk = ~rd_clk;
    
    // Main test procedure
    initial begin
        // Setup waveform dumping for Vivado
        $display("Starting CDC FIFO Test");
        errors = 0;
        
        // Initialize
        wr_rst_n = 0;
        rd_rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        
        // Apply reset
        #50;
        wr_rst_n = 1;
        rd_rst_n = 1;
        #50;
        
        // Test Case 1: Basic write and read across clock domains
        $display("Test Case 1: Basic Write/Read Across Domains");
        
        // Write data from 90 MHz domain
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge wr_clk);
            #1; // Small delay after clock edge
            if (!wr_full) begin
                wr_en = 1;
                wr_data = 8'hA0 + i;
                expected_data[i] = 8'hA0 + i;
                $display("Writing data: %h at time %t", wr_data, $time);
            end
            @(posedge wr_clk);
            #1;
            wr_en = 0;
            #20; // Wait a bit between writes
        end
        
        // Read data from 65 MHz domain
        #100; // Ensure data propagates across domains
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge rd_clk);
            #1;
            if (!rd_empty) begin
                rd_en = 1;
                @(posedge rd_clk);
                #1;
                $display("Read data: %h at time %t", rd_data, $time);
                if (rd_data !== expected_data[i]) begin
                    $display("ERROR: Read data mismatch! Expected %h, Got %h at time %t", 
                             expected_data[i], rd_data, $time);
                    errors = errors + 1;
                end
            end
            rd_en = 0;
            #30; // Wait a bit between reads
        end
        
        // Test Case 2: Read-after-Write verification with closer timing
        $display("\nTest Case 2: Read-after-Write Verification");
        #100;
        
        for (i = 0; i < 4; i = i + 1) begin
            // Write from 90 MHz domain
            @(posedge wr_clk);
            #1;
            wr_en = 1;
            wr_data = 8'h50 + i;
            expected_data[i] = 8'h50 + i;
            $display("RAW: Writing data: %h at time %t", wr_data, $time);
            @(posedge wr_clk);
            #1;
            wr_en = 0;
            
            // Wait for data to propagate
            #50;
            
            // Read immediately after
            @(posedge rd_clk);
            #1;
            if (!rd_empty) begin
                rd_en = 1;
                @(posedge rd_clk);
                #1;
                $display("RAW: Read data: %h at time %t", rd_data, $time);
                if (rd_data !== expected_data[i]) begin
                    $display("ERROR: RAW read data mismatch! Expected %h, Got %h at time %t", 
                             expected_data[i], rd_data, $time);
                    errors = errors + 1;
                end
            end else begin
                $display("ERROR: FIFO empty when data expected at time %t", $time);
                errors = errors + 1;
            end
            rd_en = 0;
        end
        
        // Test Case 3: Interleaved operations
        $display("\nTest Case 3: Interleaved Operations");
        #100;
        
        fork
            // Write process from 90 MHz domain
            begin
                for (i = 0; i < 10; i = i + 1) begin
                    @(posedge wr_clk);
                    #1;
                    if (!wr_full) begin
                        wr_en = 1;
                        wr_data = 8'hC0 + i;
                        expected_data[i] = 8'hC0 + i;
                        $display("Interleaved: Writing data: %h at time %t", wr_data, $time);
                    end
                    @(posedge wr_clk);
                    #1;
                    wr_en = 0;
                    #(CLK_90MHZ_PERIOD * 3); // Wait 3 clock cycles
                end
            end
            
            // Read process from 65 MHz domain
            begin
                #(CLK_65MHZ_PERIOD * 2); // Initial delay to let some writes happen
                for (i = 0; i < 10; i = i + 1) begin
                    @(posedge rd_clk);
                    #1;
                    if (!rd_empty) begin
                        rd_en = 1;
                        $display("Interleaved: Reading at time %t", $time);
                    end
                    @(posedge rd_clk);
                    #1;
                    if (rd_en) begin
                        $display("Interleaved: Read data: %h at time %t", rd_data, $time);
                        if (rd_data !== expected_data[i]) begin
                            $display("ERROR: Interleaved read data mismatch! Expected %h, Got %h at time %t", 
                                     expected_data[i], rd_data, $time);
                            errors = errors + 1;
                        end
                    end
                    rd_en = 0;
                    #(CLK_65MHZ_PERIOD * 5); // Wait 5 clock cycles
                end
            end
        join
        
        // Test Case 4: Test flags (near-full and near-empty conditions)
        $display("\nTest Case 4: FIFO Flag Testing");
        #100;
        
        // Reset FIFO
        wr_rst_n = 0;
        rd_rst_n = 0;
        #50;
        wr_rst_n = 1;
        rd_rst_n = 1;
        #50;
        
        // Fill FIFO to test full flag
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            @(posedge wr_clk);
            #1;
            wr_en = 1;
            wr_data = 8'h30 + i;
            $display("Flag Test: Writing data %h at time %t", wr_data, $time);
            if (wr_full) begin
                $display("ERROR: FIFO full detected prematurely at time %t", $time);
                errors = errors + 1;
            end
            @(posedge wr_clk);
            #1;
            wr_en = 0;
            #10;
        end
        
        // One more write should make it full
        @(posedge wr_clk);
        #1;
        wr_en = 1;
        wr_data = 8'hFF;
        @(posedge wr_clk);
        #1;
        wr_en = 0;
        
        if (!wr_full) begin
            $display("ERROR: FIFO not full when expected at time %t", $time);
            errors = errors + 1;
        end else begin
            $display("Flag Test: FIFO full flag correctly asserted at time %t", $time);
        end
        
        // Empty the FIFO
        while (!rd_empty) begin
            @(posedge rd_clk);
            #1;
            rd_en = 1;
            @(posedge rd_clk);
            #1;
            rd_en = 0;
            #10;
        end
        
        if (!rd_empty) begin
            $display("ERROR: FIFO not empty when expected at time %t", $time);
            errors = errors + 1;
        end else begin
            $display("Flag Test: FIFO empty flag correctly asserted at time %t", $time);
        end
        
        // Test complete
        #100;
        if (errors == 0) begin
            $display("\nTEST PASSED: All CDC FIFO operations verified successfully");
        end else begin
            $display("\nTEST FAILED: %d errors detected in CDC FIFO verification", errors);
        end
        
        #100;
        $finish;
    end
    
    // Monitor Flag Transitions
    always @(posedge wr_clk) begin
        if (wr_full && wr_en)
            $display("Warning: Write attempt to full FIFO at time %t", $time);
    end
    
    always @(posedge rd_clk) begin
        if (rd_empty && rd_en)
            $display("Warning: Read attempt from empty FIFO at time %t", $time);
    end
    
    // Monitor Gray code pointers
    always @(wr_ptr_gray) begin
        $display("Write Pointer Gray: %b at time %t", wr_ptr_gray, $time);
    end
    
    always @(rd_ptr_gray) begin
        $display("Read Pointer Gray: %b at time %t", rd_ptr_gray, $time);
    end
    
    always @(wr_ptr_gray_sync) begin
        $display("Write Pointer Gray (synced to read domain): %b at time %t", wr_ptr_gray_sync, $time);
    end
    
    always @(rd_ptr_gray_sync) begin
        $display("Read Pointer Gray (synced to write domain): %b at time %t", rd_ptr_gray_sync, $time);
    end

endmodule