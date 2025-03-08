`timescale 1ns / 1ps

module BRAM_Module(
    input wire clk,              // 65 MHz clock domain
    input wire rst_n,            // Active low reset
    input wire [7:0] address,    // 8-bit address (supports up to 256 entries)
    input wire [7:0] data_in,    // 8-bit data input
    input wire wr_en,            // Write enable
    input wire rd_en,            // Read enable
    output reg [7:0] data_out,   // 8-bit data output
    output reg op_done           // Operation done signal
);

    // 8-bit BRAM with 256 entries
    reg [7:0] bram [0:255];

    // Initialize BRAM with a unique data pattern
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            bram[i] = i;  // Simple pattern: address = data
        end
        
        // Override with some specific patterns
        bram[10] = 8'hA5;
        bram[20] = 8'h5A;
        bram[30] = 8'hF0;
        bram[40] = 8'h0F;
        bram[50] = 8'h55;
        bram[60] = 8'hAA;
        bram[70] = 8'h33;
        bram[80] = 8'hCC;
        bram[90] = 8'h66;
        bram[100] = 8'h99;
    end

    // Read/Write operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
            op_done <= 1'b0;
        end else begin
            // Default state
            op_done <= 1'b0;
            
            // Write operation
            if (wr_en) begin
                bram[address] <= data_in;
                op_done <= 1'b1;
            end
            
            // Read operation
            if (rd_en) begin
                data_out <= bram[address];
                op_done <= 1'b1;
            end
        end
    end

endmodule
