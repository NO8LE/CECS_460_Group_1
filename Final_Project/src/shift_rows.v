// ShiftRows operation for AES encryption
// This module performs the row shifting operation:
// - Row 0: No shift
// - Row 1: Shift left by 1 byte
// - Row 2: Shift left by 2 bytes
// - Row 3: Shift left by 3 bytes

module shift_rows(
    input wire [127:0] in,  // 16-byte state array input
    output wire [127:0] out // 16-byte state array output
);
    // Interpret bytes in column-major order (AES standard)
    // Input state array: [0 4 8  12]
    //                    [1 5 9  13]
    //                    [2 6 10 14]
    //                    [3 7 11 15]
    
    // Extract all bytes from the input
    wire [7:0] in_0  = in[127:120];  // Byte 0
    wire [7:0] in_1  = in[119:112];  // Byte 1
    wire [7:0] in_2  = in[111:104];  // Byte 2
    wire [7:0] in_3  = in[103:96];   // Byte 3
    wire [7:0] in_4  = in[95:88];    // Byte 4
    wire [7:0] in_5  = in[87:80];    // Byte 5
    wire [7:0] in_6  = in[79:72];    // Byte 6
    wire [7:0] in_7  = in[71:64];    // Byte 7
    wire [7:0] in_8  = in[63:56];    // Byte 8
    wire [7:0] in_9  = in[55:48];    // Byte 9
    wire [7:0] in_10 = in[47:40];    // Byte 10
    wire [7:0] in_11 = in[39:32];    // Byte 11
    wire [7:0] in_12 = in[31:24];    // Byte 12
    wire [7:0] in_13 = in[23:16];    // Byte 13
    wire [7:0] in_14 = in[15:8];     // Byte 14
    wire [7:0] in_15 = in[7:0];      // Byte 15
    
    // Perform the ShiftRows operation
    // Row 0: no shift
    wire [7:0] out_0  = in_0;       // Byte 0  (no shift)
    wire [7:0] out_4  = in_4;       // Byte 4  (no shift)
    wire [7:0] out_8  = in_8;       // Byte 8  (no shift)
    wire [7:0] out_12 = in_12;      // Byte 12 (no shift)
    
    // Row 1: shift left by 1
    wire [7:0] out_1  = in_5;       // Byte 1  (from pos 5)
    wire [7:0] out_5  = in_9;       // Byte 5  (from pos 9)
    wire [7:0] out_9  = in_13;      // Byte 9  (from pos 13)
    wire [7:0] out_13 = in_1;       // Byte 13 (from pos 1)
    
    // Row 2: shift left by 2
    wire [7:0] out_2  = in_10;      // Byte 2  (from pos 10)
    wire [7:0] out_6  = in_14;      // Byte 6  (from pos 14)
    wire [7:0] out_10 = in_2;       // Byte 10 (from pos 2)
    wire [7:0] out_14 = in_6;       // Byte 14 (from pos 6)
    
    // Row 3: shift left by 3
    wire [7:0] out_3  = in_15;      // Byte 3  (from pos 15)
    wire [7:0] out_7  = in_3;       // Byte 7  (from pos 3)
    wire [7:0] out_11 = in_7;       // Byte 11 (from pos 7)
    wire [7:0] out_15 = in_11;      // Byte 15 (from pos 11)
    
    // Combine all bytes into the output
    assign out = {out_0, out_1, out_2, out_3, out_4, out_5, out_6, out_7, 
                 out_8, out_9, out_10, out_11, out_12, out_13, out_14, out_15};
endmodule
