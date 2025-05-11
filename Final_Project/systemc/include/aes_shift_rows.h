#ifndef AES_SHIFT_ROWS_H
#define AES_SHIFT_ROWS_H

#include "aes_types.h"
#include <systemc>

// ShiftRows transformation for AES
class AesShiftRows {
public:
    // Apply ShiftRows transformation to a block
    static AesBlock shift_rows(const AesBlock& block) {
        AesBlock result;
        
        // Arrange the block in a 4x4 matrix (column-major order)
        // The state array is arranged as follows:
        // [ 0  4  8 12 ]
        // [ 1  5  9 13 ]
        // [ 2  6 10 14 ]
        // [ 3  7 11 15 ]
        
        // Row 0: No shift
        result.data[0] = block.data[0];
        result.data[4] = block.data[4];
        result.data[8] = block.data[8];
        result.data[12] = block.data[12];
        
        // Row 1: Shift left by 1
        result.data[1] = block.data[5];
        result.data[5] = block.data[9];
        result.data[9] = block.data[13];
        result.data[13] = block.data[1];
        
        // Row 2: Shift left by 2
        result.data[2] = block.data[10];
        result.data[6] = block.data[14];
        result.data[10] = block.data[2];
        result.data[14] = block.data[6];
        
        // Row 3: Shift left by 3
        result.data[3] = block.data[15];
        result.data[7] = block.data[3];
        result.data[11] = block.data[7];
        result.data[15] = block.data[11];
        
        return result;
    }
    
    // Apply Inverse ShiftRows transformation to a block
    static AesBlock inv_shift_rows(const AesBlock& block) {
        AesBlock result;
        
        // Row 0: No shift
        result.data[0] = block.data[0];
        result.data[4] = block.data[4];
        result.data[8] = block.data[8];
        result.data[12] = block.data[12];
        
        // Row 1: Shift right by 1
        result.data[1] = block.data[13];
        result.data[5] = block.data[1];
        result.data[9] = block.data[5];
        result.data[13] = block.data[9];
        
        // Row 2: Shift right by 2
        result.data[2] = block.data[10];
        result.data[6] = block.data[14];
        result.data[10] = block.data[2];
        result.data[14] = block.data[6];
        
        // Row 3: Shift right by 3
        result.data[3] = block.data[7];
        result.data[7] = block.data[11];
        result.data[11] = block.data[15];
        result.data[15] = block.data[3];
        
        return result;
    }
};

#endif // AES_SHIFT_ROWS_H