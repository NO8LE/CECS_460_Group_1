`timescale 1ns / 1ps

module tb_cdc_interleaved();
    // Clock periods
    parameter CLK_90MHZ_PERIOD = 11.11; // 90 MHz in ns
    parameter CLK_65MHZ_PERIOD = 15.38; // 65 MHz in ns
    
    // Clocks and reset
    reg clk_90mhz = 0;
    reg clk_65mhz = 0;
    reg rst_n = 0;
    
    // Test control
    reg start_test = 0;
    integer errors = 0;
    integer i;
    
    // Instantiate modules for direct testing
    // Command FIFO (Master → Memory)
    wire cmd_fifo_wr_en;
    wire [16:0] cmd_fifo_wr_data;
    wire cmd_fifo_full;
    wire cmd_fifo_rd_en;
    wire [16:0] cmd_fifo_rd_data;
    wire cmd_fifo_empty;
    
    // Response FIFO (Memory → Master)
    wire resp_fifo_wr_en;
    wire [7:0] resp_fifo_wr_data;
    wire resp_fifo_full;
    wire resp_fifo_rd_en;
    wire [7:0] resp_fifo_rd_data;
    wire resp_fifo_empty;
    
    // BRAM Interface
    wire [7:0] bram_address;
    wire [7:0] bram_data_in;
    wire [7:0] bram_data_out;
    wire bram_wr_en;
    wire bram_rd_en;
    wire bram_op_done;
    
    // Status signals
    wire master_busy;
    wire operation_success;
    
    // Test data
    reg [7:0] expected_data [0:31];
    
    // Clock generation
    always #(CLK_90MHZ_PERIOD/2) clk_90mhz = ~clk_90mhz;
    always #(CLK_65MHZ_PERIOD/2) clk_65mhz = ~clk_65mhz;
    
    // Instantiate the Command FIFO
    async_fifo #(
        .DATA_WIDTH(17),    // 17-bit data: [16] = op_type, [15:8] = address, [7:0] = write_data
        .ADDR_WIDTH(4)      // 16 entries
    ) cmd_fifo_inst (
        .wr_clk(clk_90mhz),
        .wr_rst_n(rst_n),
        .wr_en(cmd_fifo_wr_en),
        .wr_data(cmd_fifo_wr_data),
        .wr_full(cmd_fifo_full),
        .rd_clk(clk_65mhz),
        .rd_rst_n(rst_n),
        .rd_en(cmd_fifo_rd_en),
        .rd_data(cmd_fifo_rd_data),
        .rd_empty(cmd_fifo_empty)
    );
    
    // Instantiate the Response FIFO
    async_fifo #(
        .DATA_WIDTH(8),     // 8-bit data
        .ADDR_WIDTH(4)      // 16 entries
    ) resp_fifo_inst (
        .wr_clk(clk_65mhz),
        .wr_rst_n(rst_n),
        .wr_en(resp_fifo_wr_en),
        .wr_data(resp_fifo_wr_data),
        .wr_full(resp_fifo_full),
        .rd_clk(clk_90mhz),
        .rd_rst_n(rst_n),
        .rd_en(resp_fifo_rd_en),
        .rd_data(resp_fifo_rd_data),
        .rd_empty(resp_fifo_empty)
    );
    
    // Instantiate the Master Module
    master_module master_inst (
        .clk(clk_90mhz),
        .rst_n(rst_n),
        .cmd_fifo_wr_en(cmd_fifo_wr_en),
        .cmd_fifo_data(cmd_fifo_wr_data),
        .cmd_fifo_full(cmd_fifo_full),
        .resp_fifo_rd_en(resp_fifo_rd_en),
        .resp_fifo_data(resp_fifo_rd_data),
        .resp_fifo_empty(resp_fifo_empty),
        .start_operations(start_test),
        .busy(master_busy),
        .debug_data(),
        .operation_success(operation_success)
    );
    
    // Instantiate the Memory Controller Interface
    memory_controller_interface mem_ctrl_interface_inst (
        .clk(clk_65mhz),
        .rst_n(rst_n),
        .cmd_fifo_rd_en(cmd_fifo_rd_en),
        .cmd_fifo_data(cmd_fifo_rd_data),
        .cmd_fifo_empty(cmd_fifo_empty),
        .resp_fifo_wr_en(resp_fifo_wr_en),
        .resp_fifo_data(resp_fifo_wr_data),
        .resp_fifo_full(resp_fifo_full),
        .bram_address(bram_address),
        .bram_data_in(bram_data_in),
        .bram_data_out(bram_data_out),
        .bram_wr_en(bram_wr_en),
        .bram_rd_en(bram_rd_en),
        .bram_op_done(bram_op_done)
    );
    
    // Instantiate the BRAM Module
    BRAM_Module bram_inst (
        .clk(clk_65mhz),
        .rst_n(rst_n),
        .address(bram_address),
        .data_in(bram_data_in),
        .wr_en(bram_wr_en),
        .rd_en(bram_rd_en),
        .data_out(bram_data_out),
        .op_done(bram_op_done)
    );
    
    // Test sequence
    initial begin
        // Setup waveform dumping for Vivado
        $display("Starting Interleaved CDC Operations Test");
        
        // Reset system
        rst_n = 0;
        start_test = 0;
        #100;
        rst_n = 1;
        #100;
        
        // Prepare for interleaved operations test
        $display("\nTest: Interleaved Read/Write Operations Across Clock Domains");
        
        // Start the test sequence
        start_test = 1;
        #20;
        start_test = 0;
        
        // Wait for busy signal
        @(posedge master_busy);
        $display("Master module started processing at %t", $time);
        
        // Track read-after-write sequences
        fork
            // Monitor write commands
            begin
                forever begin
                    @(posedge clk_90mhz);
                    if (cmd_fifo_wr_en && !cmd_fifo_full && cmd_fifo_wr_data[16]) begin
                        $display("[90MHz] Write command issued - Addr: %h, Data: %h at %t", 
                                 cmd_fifo_wr_data[15:8], cmd_fifo_wr_data[7:0], $time);
                        expected_data[cmd_fifo_wr_data[15:8]] = cmd_fifo_wr_data[7:0];
                    end
                end
            end
            
            // Monitor read commands
            begin
                forever begin
                    @(posedge clk_90mhz);
                    if (cmd_fifo_wr_en && !cmd_fifo_full && !cmd_fifo_wr_data[16]) begin
                        $display("[90MHz] Read command issued - Addr: %h at %t", 
                                 cmd_fifo_wr_data[15:8], $time);
                    end
                end
            end
            
            // Monitor read data coming back
            begin
                forever begin
                    @(posedge clk_90mhz);
                    if (resp_fifo_rd_en && !resp_fifo_empty) begin
                        $display("[90MHz] Read data returned: %h at %t", resp_fifo_rd_data, $time);
                    end
                end
            end
            
            // Monitor BRAM operations in 65 MHz domain
            begin
                forever begin
                    @(posedge clk_65mhz);
                    if (bram_wr_en) begin
                        $display("[65MHz] BRAM write - Addr: %h, Data: %h at %t",
                                 bram_address, bram_data_in, $time);
                    end
                    else if (bram_rd_en) begin
                        $display("[65MHz] BRAM read - Addr: %h at %t",
                                 bram_address, $time);
                    end
                    else if (bram_op_done && bram_rd_en) begin
                        $display("[65MHz] BRAM read complete - Data: %h at %t",
                                 bram_data_out, $time);
                    end
                end
            end
            
            // Monitor CDC operation
            begin
                forever begin
                    @(posedge clk_65mhz);
                    if (cmd_fifo_rd_en && !cmd_fifo_empty) begin
                        $display("[CDC 90→65] Command crossed domains at %t", $time);
                    end
                end
            end
            
            begin
                forever begin
                    @(posedge clk_90mhz);
                    if (resp_fifo_rd_en && !resp_fifo_empty) begin
                        $display("[CDC 65→90] Response crossed domains at %t", $time);
                    end
                end
            end
            
            // Termination condition
            begin
                wait(!master_busy);
                #500;
                $display("Test completed at %t", $time);
                if (operation_success)
                    $display("INTERLEAVED TEST PASSED: All operations verified successfully");
                else
                    $display("INTERLEAVED TEST FAILED: Data verification errors detected");
                $finish;
            end
        join
    end
    
    // Monitor Gray code pointers to observe synchronization
    wire [4:0] cmd_wr_ptr_gray = cmd_fifo_inst.wr_ptr_gray;
    wire [4:0] cmd_rd_ptr_gray = cmd_fifo_inst.rd_ptr_gray;
    wire [4:0] cmd_wr_ptr_gray_sync = cmd_fifo_inst.rd_ptr_gray_sync2;
    wire [4:0] cmd_rd_ptr_gray_sync = cmd_fifo_inst.wr_ptr_gray_sync2;
    
    // Log Gray code transitions to illustrate CDC synchronization
    always @(cmd_wr_ptr_gray) begin
        $display("CMD FIFO: Write pointer changed to Gray code %b at %t", cmd_wr_ptr_gray, $time);
    end
    
    always @(cmd_rd_ptr_gray) begin
        $display("CMD FIFO: Read pointer changed to Gray code %b at %t", cmd_rd_ptr_gray, $time);
    end
    
    always @(cmd_wr_ptr_gray_sync) begin
        $display("CMD FIFO: Write pointer synchronized to read domain: %b at %t", cmd_wr_ptr_gray_sync, $time);
    end
    
    always @(cmd_rd_ptr_gray_sync) begin
        $display("CMD FIFO: Read pointer synchronized to write domain: %b at %t", cmd_rd_ptr_gray_sync, $time);
    end
    
    // Monitor deadlock situations
    initial begin
        #100000; // 100 μs timeout
        $display("ERROR: Test timeout - possible deadlock detected");
        $finish;
    end

endmodule