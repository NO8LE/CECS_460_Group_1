// Inverse MixColumns operation for AES decryption
// This module performs the inverse column mixing operation by treating
// each column as a polynomial over GF(2^8) and multiplying it
// with the inverse of the fixed polynomial used in MixColumns

`timescale 1ns / 1ps

module inv_mix_columns(
    input wire [127:0] in,  // 16-byte state array input
    output wire [127:0] out // 16-byte state array output
);
    // Define the output state bytes
    wire [7:0] out_bytes [0:15];
    
    // Helper function: xtime (multiplication by x in GF(2^8))
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction
    
    // Multiplication by powers of x in GF(2^8)
    // x^2 = xtime(xtime(b))
    // x^3 = xtime(xtime(xtime(b)))
    // x^4 = xtime(xtime(xtime(xtime(b))))
    
    // Multiplication by 9 = x^3 + 1
    function [7:0] mul9;
        input [7:0] b;
        begin
            mul9 = xtime(xtime(xtime(b))) ^ b;
        end
    endfunction
    
    // Multiplication by 11 (0x0B) = x^3 + x + 1
    function [7:0] mul11;
        input [7:0] b;
        begin
            mul11 = xtime(xtime(xtime(b))) ^ xtime(b) ^ b;
        end
    endfunction
    
    // Multiplication by 13 (0x0D) = x^3 + x^2 + 1
    function [7:0] mul13;
        input [7:0] b;
        begin
            mul13 = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ b;
        end
    endfunction
    
    // Multiplication by 14 (0x0E) = x^3 + x^2 + x
    function [7:0] mul14;
        input [7:0] b;
        begin
            mul14 = xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ xtime(b);
        end
    endfunction
    
    // Generate Inverse MixColumns for each column
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: inv_mix_col_gen
            // Extract the four bytes of the current column
            wire [7:0] a0 = in[127-i*32 -: 8];
            wire [7:0] a1 = in[119-i*32 -: 8];
            wire [7:0] a2 = in[111-i*32 -: 8];
            wire [7:0] a3 = in[103-i*32 -: 8];
            
            // Calculate output bytes using the Inverse MixColumns matrix multiplication:
            // [0E 0B 0D 09]   [a0]
            // [09 0E 0B 0D] × [a1]
            // [0D 09 0E 0B]   [a2]
            // [0B 0D 09 0E]   [a3]
            
            assign out_bytes[0+i*4] = mul14(a0) ^ mul11(a1) ^ mul13(a2) ^ mul9(a3);
            assign out_bytes[1+i*4] = mul9(a0) ^ mul14(a1) ^ mul11(a2) ^ mul13(a3);
            assign out_bytes[2+i*4] = mul13(a0) ^ mul9(a1) ^ mul14(a2) ^ mul11(a3);
            assign out_bytes[3+i*4] = mul11(a0) ^ mul13(a1) ^ mul9(a2) ^ mul14(a3);
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
