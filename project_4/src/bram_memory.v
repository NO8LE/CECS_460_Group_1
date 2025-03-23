`timescale 1ns / 1ps

// Define Xilinx BRAM attributes to help inference
(* ram_style = "block" *) 

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

    // Memory array with explicit BRAM attribute
    (* ram_style = "block" *) reg [7:0] mem [0:1023];
    
    // Register for registered reads (needed for proper BRAM inference)
    reg [9:0] addr_a_reg, addr_b_reg;
    
    // Integer for reset loop
    integer i;
    
    // Memory initialization (for simulation only)
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 8'b0;
        end
    end
    
    // Register addresses (needed for proper BRAM inference)
    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
    end
    
    // Port A (Xilinx BRAM inference pattern)
    always @(posedge clk) begin
        if (we_a) begin
            mem[addr_a] <= data_in_a;
        end
        
        if (rst) begin
            data_out_a <= 8'b0;
        end else begin
            data_out_a <= mem[addr_a_reg]; // Use registered address for read
        end
    end
    
    // Port B (Xilinx BRAM inference pattern)
    always @(posedge clk) begin
        if (we_b) begin
            mem[addr_b] <= data_in_b;
        end
        
        if (rst) begin
            data_out_b <= 8'b0;
        end else begin
            data_out_b <= mem[addr_b_reg]; // Use registered address for read
        end
    end

endmodule
