`timescale 1ns / 1ps

module bram_memory (
    input wire clk,
    input wire rst,
    input wire [9:0] addr_a,     // 10 bits to address 1024 locations
    input wire [9:0] addr_b,     // Dual port memory
    input wire we_a,             // Write enable for port A
    input wire we_b,             // Write enable for port B
    input wire [7:0] data_in_a,  // 8-bit signed data input for port A
    input wire [7:0] data_in_b,  // 8-bit signed data input for port B
    output reg [7:0] data_out_a, // 8-bit signed data output from port A
    output reg [7:0] data_out_b  // 8-bit signed data output from port B
);

    // Memory array: 1024 words x 8 bits
    reg [7:0] mem [0:1023];
    
    // Integer for reset loop
    integer i;
    
    // Memory initialization (for simulation only)
    // For synthesis, the memory will be initialized by the initial writes from the testbench
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 8'b0;
        end
    end
    
    // Port A (synchronous read/write)
    always @(posedge clk) begin
        if (rst) begin
            data_out_a <= 8'b0;
        end else begin
            if (we_a) begin
                mem[addr_a] <= data_in_a;
            end
            data_out_a <= mem[addr_a];
        end
    end
    
    // Port B (synchronous read/write)
    always @(posedge clk) begin
        if (rst) begin
            data_out_b <= 8'b0;
        end else begin
            if (we_b) begin
                mem[addr_b] <= data_in_b;
            end
            data_out_b <= mem[addr_b];
        end
    end

endmodule
