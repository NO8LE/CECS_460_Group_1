#ifndef AES_KEY_EXPANSION_H
#define AES_KEY_EXPANSION_H

#include "aes_types.h"
#include "aes_sbox.h"
#include <systemc>

// KeyExpansion module for AES
class AesKeyExpansion : public sc_core::sc_module {
public:
    // TLM socket for receiving key expansion requests
    tlm_utils::simple_target_socket<AesKeyExpansion> key_socket;
    
    // Constructor
    SC_HAS_PROCESS(AesKeyExpansion);
    AesKeyExpansion(sc_core::sc_module_name name) : sc_core::sc_module(name), key_socket("key_socket") {
        // Register callback for incoming transactions
        key_socket.register_b_transport(this, &AesKeyExpansion::b_transport);
    }
    
    // TLM blocking transport method
    void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& delay) {
        // Extract data from the transaction
        AesKey* key_ptr = reinterpret_cast<AesKey*>(trans.get_data_ptr());
        AesRoundKeys* round_keys_ptr = reinterpret_cast<AesRoundKeys*>(trans.get_data_ptr());
        
        // Generate round keys
        expand_key(*key_ptr, *round_keys_ptr);
        
        // Set response status
        trans.set_response_status(tlm::TLM_OK_RESPONSE);
    }
    
    // Static method to expand a key into round keys
    static void expand_key(const AesKey& key, AesRoundKeys& round_keys) {
        // The first round key is the key itself
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            round_keys.round_keys[0].data[i] = key.key[i];
        }
        
        // Rcon values used in key expansion
        static const uint8_t rcon[10] = {
            0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36
        };
        
        // Generate the remaining round keys
        for (int i = 1; i <= AES_NUM_ROUNDS; i++) {
            // Copy the previous round key
            AesBlock& prev_key = round_keys.round_keys[i-1];
            AesBlock& curr_key = round_keys.round_keys[i];
            
            // Perform the core key schedule transformation
            // 1. Rotate the last word
            uint8_t temp[4];
            temp[0] = prev_key.data[13]; // Rotate: take from 1,3
            temp[1] = prev_key.data[14]; // Rotate: take from 2,3
            temp[2] = prev_key.data[15]; // Rotate: take from 3,3
            temp[3] = prev_key.data[12]; // Rotate: take from 0,3
            
            // 2. Apply S-box to all bytes in the rotated word
            for (int j = 0; j < 4; j++) {
                temp[j] = AesSBox::substitute(temp[j]);
            }
            
            // 3. XOR with Rcon in the first byte
            temp[0] ^= rcon[i-1];
            
            // 4. Generate the first word of the new round key
            curr_key.data[0] = prev_key.data[0] ^ temp[0];
            curr_key.data[1] = prev_key.data[1] ^ temp[1];
            curr_key.data[2] = prev_key.data[2] ^ temp[2];
            curr_key.data[3] = prev_key.data[3] ^ temp[3];
            
            // 5. Generate the remaining words
            for (int j = 1; j < 4; j++) {
                curr_key.data[j*4 + 0] = prev_key.data[j*4 + 0] ^ curr_key.data[(j-1)*4 + 0];
                curr_key.data[j*4 + 1] = prev_key.data[j*4 + 1] ^ curr_key.data[(j-1)*4 + 1];
                curr_key.data[j*4 + 2] = prev_key.data[j*4 + 2] ^ curr_key.data[(j-1)*4 + 2];
                curr_key.data[j*4 + 3] = prev_key.data[j*4 + 3] ^ curr_key.data[(j-1)*4 + 3];
            }
        }
    }
};

#endif // AES_KEY_EXPANSION_H