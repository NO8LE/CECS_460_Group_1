#ifndef AES_TOP_H
#define AES_TOP_H

#include "aes_types.h"
#include "aes_key_expansion.h"
#include "aes_round.h"
#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>

// AES Top module for coordinating the encryption/decryption process
class AesTop : public sc_core::sc_module {
public:
    // TLM socket for receiving encryption/decryption requests
    tlm_utils::simple_target_socket<AesTop> top_socket;
    
    // TLM initiator sockets for connecting to submodules
    tlm_utils::simple_initiator_socket<AesTop> key_expansion_socket;
    tlm_utils::simple_initiator_socket<AesTop> round_socket;
    
    // Constructor
    SC_HAS_PROCESS(AesTop);
    AesTop(sc_core::sc_module_name name) : 
        sc_core::sc_module(name), 
        top_socket("top_socket"),
        key_expansion_socket("key_expansion_socket"),
        round_socket("round_socket") {
        
        // Register callback for incoming transactions
        top_socket.register_b_transport(this, &AesTop::b_transport);
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
        
        // Generate round keys
        AesRoundKeys round_keys;
        generate_round_keys(ext->key, round_keys, delay);
        
        // Process the block based on operation and mode
        if (ext->mode == AesMode::PIPELINED) {
            process_pipelined(*block_ptr, round_keys, ext->operation, delay);
        } else {
            process_non_pipelined(*block_ptr, round_keys, ext->operation, delay);
        }
        
        // Set response status
        trans.set_response_status(tlm::TLM_OK_RESPONSE);
    }
    
private:
    // Generate round keys using the key expansion module
    void generate_round_keys(const AesKey& key, AesRoundKeys& round_keys, sc_core::sc_time& delay) {
        // Create a transaction for key expansion
        tlm::tlm_generic_payload trans;
        trans.set_command(tlm::TLM_WRITE_COMMAND);
        trans.set_data_ptr(reinterpret_cast<unsigned char*>(&key));
        trans.set_data_length(sizeof(AesKey));
        trans.set_streaming_width(sizeof(AesKey));
        trans.set_byte_enable_ptr(nullptr);
        trans.set_dmi_allowed(false);
        trans.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
        
        // Send the transaction to the key expansion module
        key_expansion_socket->b_transport(trans, delay);
        
        // Check response status
        if (trans.is_response_error()) {
            SC_REPORT_ERROR("AesTop", "Key expansion failed");
        }
        
        // For simulation purposes, we'll also use the static method directly
        AesKeyExpansion::expand_key(key, round_keys);
    }
    
    // Process a block in non-pipelined mode
    void process_non_pipelined(AesBlock& block, const AesRoundKeys& round_keys, AesOperation operation, sc_core::sc_time& delay) {
        if (operation == AesOperation::ENCRYPT) {
            // Initial AddRoundKey
            block = block ^ round_keys.round_keys[0];
            
            // Process rounds 1 to 9
            for (int i = 1; i < AES_NUM_ROUNDS; i++) {
                block = AesRound::encrypt_round(block, round_keys.round_keys[i], false);
            }
            
            // Final round
            block = AesRound::encrypt_round(block, round_keys.round_keys[AES_NUM_ROUNDS], true);
        } else {
            // Initial AddRoundKey
            block = block ^ round_keys.round_keys[AES_NUM_ROUNDS];
            
            // Process rounds 9 to 1
            for (int i = AES_NUM_ROUNDS - 1; i > 0; i--) {
                block = AesRound::decrypt_round(block, round_keys.round_keys[i], false);
            }
            
            // Final round
            block = AesRound::decrypt_round(block, round_keys.round_keys[0], true);
        }
    }
    
    // Process a block in pipelined mode (simulated in LT model)
    void process_pipelined(AesBlock& block, const AesRoundKeys& round_keys, AesOperation operation, sc_core::sc_time& delay) {
        // In LT modeling, we don't actually implement the pipeline stages
        // We just process the block as in non-pipelined mode
        // The difference would be in timing, which we simulate by adjusting the delay
        
        // Process the block
        process_non_pipelined(block, round_keys, operation, delay);
        
        // In a pipelined implementation, once the pipeline is filled,
        // we would process one block per cycle. We simulate this by
        // reducing the delay for subsequent blocks.
        delay += sc_core::sc_time(10, sc_core::SC_NS); // Initial latency
    }
};

#endif // AES_TOP_H