#ifndef AES_ROUND_H
#define AES_ROUND_H

#include "aes_types.h"
#include "aes_sbox.h"
#include "aes_shift_rows.h"
#include "aes_mix_columns.h"
#include <systemc>

// AES Round module for encryption and decryption
class AesRound : public sc_core::sc_module {
public:
    // TLM socket for receiving round operation requests
    tlm_utils::simple_target_socket<AesRound> round_socket;
    
    // Constructor
    SC_HAS_PROCESS(AesRound);
    AesRound(sc_core::sc_module_name name) : sc_core::sc_module(name), round_socket("round_socket") {
        // Register callback for incoming transactions
        round_socket.register_b_transport(this, &AesRound::b_transport);
    }
    
    // TLM blocking transport method
    void b_transport(tlm::tlm_generic_payload& trans, sc_core::sc_time& delay) {
        // Extract data from the transaction
        AesBlock* block_ptr = reinterpret_cast<AesBlock*>(trans.get_data_ptr());
        
        // Get the AES extension
        AesExtension* ext = trans.get_extension<AesExtension>();
        if (!ext) {
            trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
            return;
        }
        
        // Get the round key and flags from the extension
        AesBlock round_key = ext->key.round_keys[ext->round_index];
        bool is_final_round = (ext->round_index == AES_NUM_ROUNDS);
        bool is_first_round = (ext->round_index == 0);
        
        // Process the block based on operation
        if (ext->operation == AesOperation::ENCRYPT) {
            *block_ptr = encrypt_round(*block_ptr, round_key, is_final_round);
        } else {
            *block_ptr = decrypt_round(*block_ptr, round_key, is_first_round);
        }
        
        // Set response status
        trans.set_response_status(tlm::TLM_OK_RESPONSE);
    }
    
    // Static method to perform one round of encryption
    static AesBlock encrypt_round(const AesBlock& block, const AesBlock& round_key, bool is_final_round) {
        // 1. SubBytes
        AesBlock after_sub_bytes = AesSBox::sub_bytes(block);
        
        // 2. ShiftRows
        AesBlock after_shift_rows = AesShiftRows::shift_rows(after_sub_bytes);
        
        // 3. MixColumns (skipped in final round)
        AesBlock after_mix_columns;
        if (is_final_round) {
            after_mix_columns = after_shift_rows;
        } else {
            after_mix_columns = AesMixColumns::mix_columns(after_shift_rows);
        }
        
        // 4. AddRoundKey
        return after_mix_columns ^ round_key;
    }
    
    // Static method to perform one round of decryption
    static AesBlock decrypt_round(const AesBlock& block, const AesBlock& round_key, bool is_first_round) {
        // 1. InvShiftRows
        AesBlock after_inv_shift_rows = AesShiftRows::inv_shift_rows(block);
        
        // 2. InvSubBytes
        AesBlock after_inv_sub_bytes = AesSBox::inv_sub_bytes(after_inv_shift_rows);
        
        // 3. AddRoundKey
        AesBlock after_add_round_key = after_inv_sub_bytes ^ round_key;
        
        // 4. InvMixColumns (skipped in first round)
        if (is_first_round) {
            return after_add_round_key;
        } else {
            return AesMixColumns::inv_mix_columns(after_add_round_key);
        }
    }
};

#endif // AES_ROUND_H