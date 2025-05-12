// SubBytes operation for AES encryption
// This module applies the S-box substitution to each byte in the state

`timescale 1ns / 1ps

module sub_bytes(
    input wire [127:0] in,  // 16-byte state array input
    output wire [127:0] out // 16-byte state array output
);
    // Instantiate 16 S-box modules, one for each byte
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: sub_gen
            wire [7:0] in_byte = in[127-i*8 -: 8];
            wire [7:0] out_byte;
            
            sbox s_box_inst (
                .in(in_byte),
                .out(out_byte)
            );
            
            // Assign the output byte to the correct position
            assign out[127-i*8 -: 8] = out_byte;
        end
    endgenerate
endmodule
