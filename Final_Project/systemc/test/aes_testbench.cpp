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
#include <cassert>

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

// Testbench module
class AesTestbench : public sc_module {
public:
    // TLM initiator socket for connecting to the AES top module
    tlm_utils::simple_initiator_socket<AesTestbench> init_socket;
    
    SC_HAS_PROCESS(AesTestbench);
    AesTestbench(sc_module_name name) : sc_module(name), init_socket("init_socket") {
        SC_THREAD(run_tests);
    }
    
    void run_tests() {
        cout << "Starting AES tests..." << endl;
        
        // Test vectors from NIST FIPS 197 Appendix C
        test_aes_encryption(
            "00112233445566778899aabbccddeeff", // plaintext
            "000102030405060708090a0b0c0d0e0f", // key
            "69c4e0d86a7b0430d8cdb78070b4c55a"  // expected ciphertext
        );
        
        // Test decryption (reverse of the above)
        test_aes_decryption(
            "69c4e0d86a7b0430d8cdb78070b4c55a", // ciphertext
            "000102030405060708090a0b0c0d0e0f", // key
            "00112233445566778899aabbccddeeff"  // expected plaintext
        );
        
        // Additional test vectors
        test_aes_encryption(
            "3243f6a8885a308d313198a2e0370734", // plaintext
            "2b7e151628aed2a6abf7158809cf4f3c", // key
            "3925841d02dc09fbdc118597196a0b32"  // expected ciphertext
        );
        
        test_aes_decryption(
            "3925841d02dc09fbdc118597196a0b32", // ciphertext
            "2b7e151628aed2a6abf7158809cf4f3c", // key
            "3243f6a8885a308d313198a2e0370734"  // expected plaintext
        );
        
        // Test pipelined mode
        test_aes_encryption(
            "00112233445566778899aabbccddeeff", // plaintext
            "000102030405060708090a0b0c0d0e0f", // key
            "69c4e0d86a7b0430d8cdb78070b4c55a", // expected ciphertext
            AesMode::PIPELINED
        );
        
        cout << "All tests completed successfully!" << endl;
    }
    
    void test_aes_encryption(const string& plaintext_hex, const string& key_hex, 
                            const string& expected_ciphertext_hex, AesMode mode = AesMode::NON_PIPELINED) {
        // Convert hex strings to bytes
        vector<uint8_t> plaintext_bytes = hex_to_bytes(plaintext_hex);
        vector<uint8_t> key_bytes = hex_to_bytes(key_hex);
        vector<uint8_t> expected_ciphertext_bytes = hex_to_bytes(expected_ciphertext_hex);
        
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
            SC_REPORT_ERROR("AesTestbench", "Encryption transaction failed");
        }
        
        // Check the result
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            if (plaintext.data[i] != expected_ciphertext_bytes[i]) {
                cout << "Encryption failed!" << endl;
                cout << "Expected: " << expected_ciphertext_hex << endl;
                cout << "Got:      " << plaintext.to_string() << endl;
                SC_REPORT_ERROR("AesTestbench", "Encryption result mismatch");
                return;
            }
        }
        
        cout << "Encryption test passed for mode " << (mode == AesMode::PIPELINED ? "PIPELINED" : "NON_PIPELINED") << endl;
        cout << "Plaintext:  " << plaintext_hex << endl;
        cout << "Key:        " << key_hex << endl;
        cout << "Ciphertext: " << expected_ciphertext_hex << endl;
        cout << endl;
        
        // Clean up
        trans.release_extension(ext);
    }
    
    void test_aes_decryption(const string& ciphertext_hex, const string& key_hex, 
                            const string& expected_plaintext_hex, AesMode mode = AesMode::NON_PIPELINED) {
        // Convert hex strings to bytes
        vector<uint8_t> ciphertext_bytes = hex_to_bytes(ciphertext_hex);
        vector<uint8_t> key_bytes = hex_to_bytes(key_hex);
        vector<uint8_t> expected_plaintext_bytes = hex_to_bytes(expected_plaintext_hex);
        
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
            SC_REPORT_ERROR("AesTestbench", "Decryption transaction failed");
        }
        
        // Check the result
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            if (ciphertext.data[i] != expected_plaintext_bytes[i]) {
                cout << "Decryption failed!" << endl;
                cout << "Expected: " << expected_plaintext_hex << endl;
                cout << "Got:      " << ciphertext.to_string() << endl;
                SC_REPORT_ERROR("AesTestbench", "Decryption result mismatch");
                return;
            }
        }
        
        cout << "Decryption test passed for mode " << (mode == AesMode::PIPELINED ? "PIPELINED" : "NON_PIPELINED") << endl;
        cout << "Ciphertext: " << ciphertext_hex << endl;
        cout << "Key:        " << key_hex << endl;
        cout << "Plaintext:  " << expected_plaintext_hex << endl;
        cout << endl;
        
        // Clean up
        trans.release_extension(ext);
    }
};

// Main function
int sc_main(int argc, char* argv[]) {
    // Create modules
    AesTestbench testbench("testbench");
    AesTop aes_top("aes_top");
    AesKeyExpansion key_expansion("key_expansion");
    AesRound aes_round("aes_round");
    
    // Connect modules
    testbench.init_socket.bind(aes_top.top_socket);
    aes_top.key_expansion_socket.bind(key_expansion.key_socket);
    aes_top.round_socket.bind(aes_round.round_socket);
    
    // Start simulation
    sc_start();
    
    return 0;
}