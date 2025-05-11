#include "../include/aes_types.h"
#include "../include/aes_sbox.h"
#include "../include/aes_shift_rows.h"
#include "../include/aes_mix_columns.h"
#include "../include/aes_key_expansion.h"
#include "../include/aes_round.h"
#include "../include/aes_top.h"
#include <systemc>
#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <chrono>
#include <ctime>

using namespace sc_core;
using namespace std;

// Utility function to convert hex string to bytes
vector<uint8_t> hex_to_bytes(const string& hex) {
    vector<uint8_t> bytes;
    for (size_t i = 0; i < hex.length(); i += 2) {
        string byteString = hex.substr(i, 2);
        uint8_t byte = static_cast<uint8_t>(strtol(byteString.c_str(), nullptr, 16));
        bytes.push_back(byte);
    }
    return bytes;
}

// Utility function to convert bytes to hex string
string bytes_to_hex(const vector<uint8_t>& bytes) {
    stringstream ss;
    ss << hex << setfill('0');
    for (uint8_t byte : bytes) {
        ss << setw(2) << static_cast<int>(byte);
    }
    return ss.str();
}

// AES Simulation module
class AesSimulation : public sc_module {
public:
    // TLM initiator socket for connecting to the AES top module
    tlm_utils::simple_initiator_socket<AesSimulation> init_socket;
    
    SC_HAS_PROCESS(AesSimulation);
    AesSimulation(sc_module_name name) : sc_module(name), init_socket("init_socket") {
        SC_THREAD(run_simulation);
    }
    
    void run_simulation() {
        cout << "=== AES-128 SystemC Simulation (Loosely Timed Model) ===" << endl;
        cout << endl;
        
        // Demonstrate encryption and decryption with a sample plaintext and key
        string plaintext_hex = "00112233445566778899aabbccddeeff";
        string key_hex = "000102030405060708090a0b0c0d0e0f";
        
        cout << "Original Plaintext: " << plaintext_hex << endl;
        cout << "Encryption Key:     " << key_hex << endl;
        cout << endl;
        
        // Encrypt the plaintext
        string ciphertext_hex = encrypt(plaintext_hex, key_hex, AesMode::NON_PIPELINED);
        cout << "Encrypted Ciphertext (Non-Pipelined): " << ciphertext_hex << endl;
        
        // Decrypt the ciphertext
        string decrypted_hex = decrypt(ciphertext_hex, key_hex, AesMode::NON_PIPELINED);
        cout << "Decrypted Plaintext (Non-Pipelined): " << decrypted_hex << endl;
        cout << endl;
        
        // Verify the result
        if (decrypted_hex == plaintext_hex) {
            cout << "Verification: SUCCESS - Decrypted plaintext matches original" << endl;
        } else {
            cout << "Verification: FAILED - Decryption did not match original plaintext" << endl;
        }
        cout << endl;
        
        // Demonstrate pipelined mode
        cout << "=== Pipelined Mode Performance Demonstration ===" << endl;
        
        // Generate a large number of blocks to process
        const int num_blocks = 1000;
        vector<string> plaintexts(num_blocks, plaintext_hex);
        
        // Measure time for non-pipelined mode
        auto start_time = chrono::high_resolution_clock::now();
        for (int i = 0; i < num_blocks; i++) {
            encrypt(plaintexts[i], key_hex, AesMode::NON_PIPELINED);
        }
        auto end_time = chrono::high_resolution_clock::now();
        auto non_pipelined_duration = chrono::duration_cast<chrono::microseconds>(end_time - start_time);
        
        // Measure time for pipelined mode
        start_time = chrono::high_resolution_clock::now();
        for (int i = 0; i < num_blocks; i++) {
            encrypt(plaintexts[i], key_hex, AesMode::PIPELINED);
        }
        end_time = chrono::high_resolution_clock::now();
        auto pipelined_duration = chrono::duration_cast<chrono::microseconds>(end_time - start_time);
        
        cout << "Processing " << num_blocks << " blocks:" << endl;
        cout << "Non-Pipelined Mode: " << non_pipelined_duration.count() << " microseconds" << endl;
        cout << "Pipelined Mode:     " << pipelined_duration.count() << " microseconds" << endl;
        cout << "Speedup Factor:     " << static_cast<double>(non_pipelined_duration.count()) / pipelined_duration.count() << "x" << endl;
        cout << endl;
        
        // Demonstrate the effect of the AES transformations
        cout << "=== AES Transformation Steps Demonstration ===" << endl;
        
        // Convert hex strings to AES blocks
        vector<uint8_t> pt_bytes = hex_to_bytes(plaintext_hex);
        vector<uint8_t> key_bytes = hex_to_bytes(key_hex);
        
        AesBlock block;
        AesKey aes_key;
        
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            block.data[i] = pt_bytes[i];
        }
        
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            aes_key.key[i] = key_bytes[i];
        }
        
        // Generate round keys
        AesRoundKeys round_keys;
        AesKeyExpansion::expand_key(aes_key, round_keys);
        
        cout << "Initial state:      " << block.to_string() << endl;
        
        // Initial AddRoundKey
        block = block ^ round_keys.round_keys[0];
        cout << "After AddRoundKey:  " << block.to_string() << endl;
        
        // First round transformations
        AesBlock after_sub_bytes = AesSBox::sub_bytes(block);
        cout << "After SubBytes:     " << after_sub_bytes.to_string() << endl;
        
        AesBlock after_shift_rows = AesShiftRows::shift_rows(after_sub_bytes);
        cout << "After ShiftRows:    " << after_shift_rows.to_string() << endl;
        
        AesBlock after_mix_columns = AesMixColumns::mix_columns(after_shift_rows);
        cout << "After MixColumns:   " << after_mix_columns.to_string() << endl;
        
        AesBlock after_add_round_key = after_mix_columns ^ round_keys.round_keys[1];
        cout << "After AddRoundKey:  " << after_add_round_key.to_string() << endl;
        cout << endl;
        
        cout << "Simulation completed successfully!" << endl;
    }
    
    string encrypt(const string& plaintext_hex, const string& key_hex, AesMode mode) {
        // Convert hex strings to bytes
        vector<uint8_t> plaintext_bytes = hex_to_bytes(plaintext_hex);
        vector<uint8_t> key_bytes = hex_to_bytes(key_hex);
        
        // Create AES block and key
        AesBlock plaintext;
        AesKey key;
        
        // Fill the block and key with data
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            plaintext.data[i] = plaintext_bytes[i];
        }
        
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            key.key[i] = key_bytes[i];
        }
        
        // Create a transaction for encryption
        tlm::tlm_generic_payload trans;
        sc_time delay = sc_time(0, SC_NS);
        
        // Set up the transaction
        trans.set_command(tlm::TLM_WRITE_COMMAND);
        trans.set_data_ptr(reinterpret_cast<unsigned char*>(&plaintext));
        trans.set_data_length(sizeof(AesBlock));
        trans.set_streaming_width(sizeof(AesBlock));
        trans.set_byte_enable_ptr(nullptr);
        trans.set_dmi_allowed(false);
        trans.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
        
        // Create and set the AES extension
        AesExtension* ext = new AesExtension();
        ext->operation = AesOperation::ENCRYPT;
        ext->mode = mode;
        ext->key = key;
        trans.set_extension(ext);
        
        // Send the transaction to the AES top module
        init_socket->b_transport(trans, delay);
        
        // Check response status
        if (trans.is_response_error()) {
            SC_REPORT_ERROR("AesSimulation", "Encryption transaction failed");
        }
        
        // Convert the result back to hex string
        string result_hex = plaintext.to_string();
        
        // Clean up
        trans.release_extension(ext);
        
        return result_hex;
    }
    
    string decrypt(const string& ciphertext_hex, const string& key_hex, AesMode mode) {
        // Convert hex strings to bytes
        vector<uint8_t> ciphertext_bytes = hex_to_bytes(ciphertext_hex);
        vector<uint8_t> key_bytes = hex_to_bytes(key_hex);
        
        // Create AES block and key
        AesBlock ciphertext;
        AesKey key;
        
        // Fill the block and key with data
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            ciphertext.data[i] = ciphertext_bytes[i];
        }
        
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            key.key[i] = key_bytes[i];
        }
        
        // Create a transaction for decryption
        tlm::tlm_generic_payload trans;
        sc_time delay = sc_time(0, SC_NS);
        
        // Set up the transaction
        trans.set_command(tlm::TLM_WRITE_COMMAND);
        trans.set_data_ptr(reinterpret_cast<unsigned char*>(&ciphertext));
        trans.set_data_length(sizeof(AesBlock));
        trans.set_streaming_width(sizeof(AesBlock));
        trans.set_byte_enable_ptr(nullptr);
        trans.set_dmi_allowed(false);
        trans.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);
        
        // Create and set the AES extension
        AesExtension* ext = new AesExtension();
        ext->operation = AesOperation::DECRYPT;
        ext->mode = mode;
        ext->key = key;
        trans.set_extension(ext);
        
        // Send the transaction to the AES top module
        init_socket->b_transport(trans, delay);
        
        // Check response status
        if (trans.is_response_error()) {
            SC_REPORT_ERROR("AesSimulation", "Decryption transaction failed");
        }
        
        // Convert the result back to hex string
        string result_hex = ciphertext.to_string();
        
        // Clean up
        trans.release_extension(ext);
        
        return result_hex;
    }
};

// Main function
int sc_main(int argc, char* argv[]) {
    // Create modules
    AesSimulation simulation("simulation");
    AesTop aes_top("aes_top");
    AesKeyExpansion key_expansion("key_expansion");
    AesRound aes_round("aes_round");
    
    // Connect modules
    simulation.init_socket.bind(aes_top.top_socket);
    aes_top.key_expansion_socket.bind(key_expansion.key_socket);
    aes_top.round_socket.bind(aes_round.round_socket);
    
    // Start simulation
    sc_start();
    
    return 0;
}