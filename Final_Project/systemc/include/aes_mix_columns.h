#ifndef AES_MIX_COLUMNS_H
#define AES_MIX_COLUMNS_H

#include "aes_types.h"
#include <systemc>

// MixColumns transformation for AES
class AesMixColumns {
private:
    // Galois Field multiplication by 2
    static uint8_t gmul2(uint8_t a) {
        uint8_t result = a << 1;
        if (a & 0x80) {
            result ^= 0x1B; // XOR with the irreducible polynomial x^8 + x^4 + x^3 + x + 1
        }
        return result;
    }
    
    // Galois Field multiplication by 3 (which is multiplication by 2 and then XOR with the original value)
    static uint8_t gmul3(uint8_t a) {
        return gmul2(a) ^ a;
    }
    
    // Galois Field multiplication by 9
    static uint8_t gmul9(uint8_t a) {
        return gmul2(gmul2(gmul2(a))) ^ a;
    }
    
    // Galois Field multiplication by 11
    static uint8_t gmul11(uint8_t a) {
        return gmul2(gmul2(gmul2(a)) ^ a) ^ a;
    }
    
    // Galois Field multiplication by 13
    static uint8_t gmul13(uint8_t a) {
        return gmul2(gmul2(gmul2(a) ^ a)) ^ a;
    }
    
    // Galois Field multiplication by 14
    static uint8_t gmul14(uint8_t a) {
        return gmul2(gmul2(gmul2(a) ^ a) ^ a);
    }
    
public:
    // Apply MixColumns transformation to a block
    static AesBlock mix_columns(const AesBlock& block) {
        AesBlock result;
        
        // Process each column
        for (int i = 0; i < 4; i++) {
            uint8_t a0 = block.data[i*4 + 0];
            uint8_t a1 = block.data[i*4 + 1];
            uint8_t a2 = block.data[i*4 + 2];
            uint8_t a3 = block.data[i*4 + 3];
            
            // Matrix multiplication in GF(2^8)
            // [ 2 3 1 1 ]   [ a0 ]
            // [ 1 2 3 1 ] × [ a1 ]
            // [ 1 1 2 3 ]   [ a2 ]
            // [ 3 1 1 2 ]   [ a3 ]
            
            result.data[i*4 + 0] = gmul2(a0) ^ gmul3(a1) ^ a2 ^ a3;
            result.data[i*4 + 1] = a0 ^ gmul2(a1) ^ gmul3(a2) ^ a3;
            result.data[i*4 + 2] = a0 ^ a1 ^ gmul2(a2) ^ gmul3(a3);
            result.data[i*4 + 3] = gmul3(a0) ^ a1 ^ a2 ^ gmul2(a3);
        }
        
        return result;
    }
    
    // Apply Inverse MixColumns transformation to a block
    static AesBlock inv_mix_columns(const AesBlock& block) {
        AesBlock result;
        
        // Process each column
        for (int i = 0; i < 4; i++) {
            uint8_t a0 = block.data[i*4 + 0];
            uint8_t a1 = block.data[i*4 + 1];
            uint8_t a2 = block.data[i*4 + 2];
            uint8_t a3 = block.data[i*4 + 3];
            
            // Matrix multiplication in GF(2^8)
            // [ 14 11 13  9 ]   [ a0 ]
            // [  9 14 11 13 ] × [ a1 ]
            // [ 13  9 14 11 ]   [ a2 ]
            // [ 11 13  9 14 ]   [ a3 ]
            
            result.data[i*4 + 0] = gmul14(a0) ^ gmul11(a1) ^ gmul13(a2) ^ gmul9(a3);
            result.data[i*4 + 1] = gmul9(a0) ^ gmul14(a1) ^ gmul11(a2) ^ gmul13(a3);
            result.data[i*4 + 2] = gmul13(a0) ^ gmul9(a1) ^ gmul14(a2) ^ gmul11(a3);
            result.data[i*4 + 3] = gmul11(a0) ^ gmul13(a1) ^ gmul9(a2) ^ gmul14(a3);
        }
        
        return result;
    }
};

#endif // AES_MIX_COLUMNS_H