`timescale 1ns / 1ps

module top(
    input wire clk,          // Board clock input (125 MHz)
    input wire rst_n,        // Active low reset
    input wire start_test,   // Button to start test sequence
    output wire busy,        // LED indicating operations in progress
    output wire success      // LED indicating test success
);

    // Clock signals
    wire clk_90mhz;  // 90 MHz clock for Master Module
    wire clk_65mhz;  // 65 MHz clock for Memory Controller
    wire pll_locked; // PLL lock status
    
    // Combined reset signal (external reset or PLL not locked)
    wire sys_rst_n = rst_n && pll_locked;
    
    // Reset synchronizers for each clock domain
    reg [1:0] rst_sync_90mhz = 2'b00;
    reg [1:0] rst_sync_65mhz = 2'b00;
    wire rst_n_90mhz = rst_sync_90mhz[1];
    wire rst_n_65mhz = rst_sync_65mhz[1];
    
    // Synchronize reset for 90 MHz domain
    always @(posedge clk_90mhz or negedge sys_rst_n) begin
        if (!sys_rst_n)
            rst_sync_90mhz <= 2'b00;
        else
            rst_sync_90mhz <= {rst_sync_90mhz[0], 1'b1};
    end
    
    // Synchronize reset for 65 MHz domain
    always @(posedge clk_65mhz or negedge sys_rst_n) begin
        if (!sys_rst_n)
            rst_sync_65mhz <= 2'b00;
        else
            rst_sync_65mhz <= {rst_sync_65mhz[0], 1'b1};
    end
    
    // Synchronize start_test to 90 MHz domain
    reg [1:0] start_sync_90mhz = 2'b00;
    wire start_90mhz = start_sync_90mhz[1];
    
    always @(posedge clk_90mhz or negedge rst_n_90mhz) begin
        if (!rst_n_90mhz)
            start_sync_90mhz <= 2'b00;
        else
            start_sync_90mhz <= {start_sync_90mhz[0], start_test};
    end
    
    // FIFO interfaces
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
    
    // Debug/Status signals
    wire [7:0] debug_data;
    
    // BRAM Interface
    wire [7:0] bram_address;
    wire [7:0] bram_data_in;
    wire [7:0] bram_data_out;
    wire bram_wr_en;
    wire bram_rd_en;
    wire bram_op_done;
    
    // Instantiate the Clock Generator (Xilinx MMCM/PLL)
    clock_gen clock_gen_inst (
        .clk_in(clk),       // 125 MHz board clock
        .rst_n(rst_n),      // External reset
        .clk_90mhz(clk_90mhz),
        .clk_65mhz(clk_65mhz),
        .locked(pll_locked)
    );
    
    // Master Module (90 MHz domain)
    master_module master_inst (
        .clk(clk_90mhz),
        .rst_n(rst_n_90mhz),
        // Command FIFO interface (write side)
        .cmd_fifo_wr_en(cmd_fifo_wr_en),
        .cmd_fifo_data(cmd_fifo_wr_data),
        .cmd_fifo_full(cmd_fifo_full),
        // Response FIFO interface (read side)
        .resp_fifo_rd_en(resp_fifo_rd_en),
        .resp_fifo_data(resp_fifo_rd_data),
        .resp_fifo_empty(resp_fifo_empty),
        // Control/Status
        .start_operations(start_90mhz),
        .busy(busy),
        .debug_data(debug_data),
        .operation_success(success)
    );
    
    // Command FIFO (Master → Memory)
    async_fifo #(
        .DATA_WIDTH(17),    // 17-bit data: [16] = op_type, [15:8] = address, [7:0] = write_data
        .ADDR_WIDTH(4)      // 16 entries
    ) cmd_fifo_inst (
        // Write side (90 MHz domain)
        .wr_clk(clk_90mhz),
        .wr_rst_n(rst_n_90mhz),
        .wr_en(cmd_fifo_wr_en),
        .wr_data(cmd_fifo_wr_data),
        .wr_full(cmd_fifo_full),
        // Read side (65 MHz domain)
        .rd_clk(clk_65mhz),
        .rd_rst_n(rst_n_65mhz),
        .rd_en(cmd_fifo_rd_en),
        .rd_data(cmd_fifo_rd_data),
        .rd_empty(cmd_fifo_empty)
    );
    
    // Response FIFO (Memory → Master)
    async_fifo #(
        .DATA_WIDTH(8),     // 8-bit data
        .ADDR_WIDTH(4)      // 16 entries
    ) resp_fifo_inst (
        // Write side (65 MHz domain)
        .wr_clk(clk_65mhz),
        .wr_rst_n(rst_n_65mhz),
        .wr_en(resp_fifo_wr_en),
        .wr_data(resp_fifo_wr_data),
        .wr_full(resp_fifo_full),
        // Read side (90 MHz domain)
        .rd_clk(clk_90mhz),
        .rd_rst_n(rst_n_90mhz),
        .rd_en(resp_fifo_rd_en),
        .rd_data(resp_fifo_rd_data),
        .rd_empty(resp_fifo_empty)
    );
    
    // Memory Controller Interface (65 MHz domain)
    memory_controller_interface mem_ctrl_interface_inst (
        .clk(clk_65mhz),
        .rst_n(rst_n_65mhz),
        // Command FIFO interface (read side)
        .cmd_fifo_rd_en(cmd_fifo_rd_en),
        .cmd_fifo_data(cmd_fifo_rd_data),
        .cmd_fifo_empty(cmd_fifo_empty),
        // Response FIFO interface (write side)
        .resp_fifo_wr_en(resp_fifo_wr_en),
        .resp_fifo_data(resp_fifo_wr_data),
        .resp_fifo_full(resp_fifo_full),
        // BRAM interface
        .bram_address(bram_address),
        .bram_data_in(bram_data_in),
        .bram_data_out(bram_data_out),
        .bram_wr_en(bram_wr_en),
        .bram_rd_en(bram_rd_en),
        .bram_op_done(bram_op_done)
    );
    
    // BRAM Module (65 MHz domain)
    BRAM_Module bram_inst (
        .clk(clk_65mhz),
        .rst_n(rst_n_65mhz),
        .address(bram_address),
        .data_in(bram_data_in),
        .wr_en(bram_wr_en),
        .rd_en(bram_rd_en),
        .data_out(bram_data_out),
        .op_done(bram_op_done)
    );

endmodule