// MixColumns operation for AES encryption
// This module performs the column mixing operation by treating
// each column as a polynomial over GF(2^8) and multiplying it
// with a fixed polynomial c(x) = 3x^3 + x^2 + x + 2

`timescale 1ns / 1ps

module mix_columns(
    input wire [127:0] in,  // 16-byte state array input
    output wire [127:0] out // 16-byte state array output
);
    // Define the output state bytes
    wire [7:0] out_bytes [0:15];
    
    // Generate MixColumns for each column
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: mix_col_gen
            // Extract the four bytes of the current column
            wire [7:0] a0 = in[127-i*32 -: 8];
            wire [7:0] a1 = in[119-i*32 -: 8];
            wire [7:0] a2 = in[111-i*32 -: 8];
            wire [7:0] a3 = in[103-i*32 -: 8];
            
            // Multiplication by 2 in GF(2^8)
            wire [7:0] a0_x2 = {a0[6:0], 1'b0} ^ (8'h1b & {8{a0[7]}});
            wire [7:0] a1_x2 = {a1[6:0], 1'b0} ^ (8'h1b & {8{a1[7]}});
            wire [7:0] a2_x2 = {a2[6:0], 1'b0} ^ (8'h1b & {8{a2[7]}});
            wire [7:0] a3_x2 = {a3[6:0], 1'b0} ^ (8'h1b & {8{a3[7]}});
            
            // Multiplication by 3 in GF(2^8) (which is x2+x1)
            wire [7:0] a0_x3 = a0_x2 ^ a0;
            wire [7:0] a1_x3 = a1_x2 ^ a1;
            wire [7:0] a2_x3 = a2_x2 ^ a2;
            wire [7:0] a3_x3 = a3_x2 ^ a3;
            
            // Calculate output bytes using the MixColumns matrix multiplication:
            // [02 03 01 01]   [a0]
            // [01 02 03 01] × [a1]
            // [01 01 02 03]   [a2]
            // [03 01 01 02]   [a3]
            
            assign out_bytes[0+i*4] = a0_x2 ^ a1_x3 ^ a2 ^ a3;
            assign out_bytes[1+i*4] = a0 ^ a1_x2 ^ a2_x3 ^ a3;
            assign out_bytes[2+i*4] = a0 ^ a1 ^ a2_x2 ^ a3_x3;
            assign out_bytes[3+i*4] = a0_x3 ^ a1 ^ a2 ^ a3_x2;
        end
    endgenerate
    
    // Combine all bytes into the output
    assign out = {
        out_bytes[0], out_bytes[1], out_bytes[2], out_bytes[3],
        out_bytes[4], out_bytes[5], out_bytes[6], out_bytes[7],
        out_bytes[8], out_bytes[9], out_bytes[10], out_bytes[11],
        out_bytes[12], out_bytes[13], out_bytes[14], out_bytes[15]
    };
endmodule
