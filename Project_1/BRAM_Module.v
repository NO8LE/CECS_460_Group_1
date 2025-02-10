`timescale 1ns / 1ps

module BRAM_Module(
    input wire clk,
    input wire [3:0] address,
    output reg [3:0] data_out
);

    reg [3:0] bram [9:0];

    initial begin
        bram[0] = 4'b1010;  // A  -> 1010
        bram[1] = 4'b1100;  // C  -> 1100
        bram[2] = 4'b1111;  // F  -> 1111
        bram[3] = 4'b0001;  // 1  -> 0001
        bram[4] = 4'b0110;  // 6  -> 0110
        bram[5] = 4'b1000;  // 8  -> 1000
        bram[6] = 4'b0101;  // 5  -> 0101
        bram[7] = 4'b0011;  // 3  -> 0011
        bram[8] = 4'b1110;  // E  -> 1110
        bram[9] = 4'b0010;  // 2  -> 0010
    end


    always @(posedge clk) begin
        if (address < 10) 
            data_out <= bram[address];
        else
            data_out <= 4'b0000; // Default error value
    end

endmodule
