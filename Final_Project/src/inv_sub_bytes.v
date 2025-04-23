// Inverse SubBytes operation for AES decryption
// This module applies the inverse S-box substitution to each byte in the state

module inv_sub_bytes(
    input wire [127:0] in,  // 16-byte state array input
    output wire [127:0] out // 16-byte state array output
);
    // Instantiate 16 inverse S-box modules, one for each byte
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: inv_sub_gen
            wire [7:0] in_byte = in[127-i*8 -: 8];
            wire [7:0] out_byte;
            
            inv_sbox inv_s_box_inst (
                .in(in_byte),
                .out(out_byte)
            );
            
            // Assign the output byte to the correct position
            assign out[127-i*8 -: 8] = out_byte;
        end
    endgenerate
endmodule
