`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4  // 2^4 = 16 entries in FIFO
)(
    // Write domain (90 MHz)
    input wire wr_clk,
    input wire wr_rst_n,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire wr_full,
    
    // Read domain (65 MHz)
    input wire rd_clk,
    input wire rd_rst_n,
    input wire rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    output wire rd_empty
);

    localparam FIFO_DEPTH = (1 << ADDR_WIDTH);
    
    // FIFO Memory
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    
    // Binary pointers for memory addressing
    reg [ADDR_WIDTH:0] wr_ptr_bin = 0;
    reg [ADDR_WIDTH:0] rd_ptr_bin = 0;
    
    // Gray code pointers for synchronization
    reg [ADDR_WIDTH:0] wr_ptr_gray = 0;
    reg [ADDR_WIDTH:0] rd_ptr_gray = 0;
    
    // Synchronized pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin_to_gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Gray code to Binary conversion
    function [ADDR_WIDTH:0] gray_to_bin;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        begin
            bin = gray;
            for (i = 1; i <= ADDR_WIDTH; i = i + 1) begin
                bin = bin ^ (bin >> i);
            end
            gray_to_bin = bin;
        end
    endfunction
    
    // Cross-domain synchronization of pointers
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // Write pointer logic
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !wr_full) begin
            fifo_mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
        end
    end
    
    // Read pointer logic
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            rd_data <= 0;
        end else if (rd_en && !rd_empty) begin
            rd_data <= fifo_mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
        end
    end
    
    // Full and Empty flags generation
    wire [ADDR_WIDTH:0] wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_sync2);
    wire [ADDR_WIDTH:0] rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_sync2);
    
    assign wr_full = (wr_ptr_bin[ADDR_WIDTH-1:0] == rd_ptr_bin_sync[ADDR_WIDTH-1:0]) && 
                     (wr_ptr_bin[ADDR_WIDTH] != rd_ptr_bin_sync[ADDR_WIDTH]);
                     
    assign rd_empty = (rd_ptr_bin == wr_ptr_bin_sync);
    
endmodule