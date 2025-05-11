#ifndef AES_TYPES_H
#define AES_TYPES_H

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include <array>
#include <vector>
#include <cstdint>

// Define AES constants
constexpr int AES_BLOCK_SIZE = 16;  // 128 bits = 16 bytes
constexpr int AES_KEY_SIZE = 16;    // 128 bits = 16 bytes
constexpr int AES_NUM_ROUNDS = 10;  // For AES-128

// Define operation modes
enum class AesOperation {
    ENCRYPT,
    DECRYPT
};

// Define processing modes
enum class AesMode {
    PIPELINED,
    NON_PIPELINED
};

// Define a structure for AES data blocks
struct AesBlock {
    std::array<uint8_t, AES_BLOCK_SIZE> data;
    
    // Default constructor initializes to zero
    AesBlock() {
        data.fill(0);
    }
    
    // Constructor from raw data
    AesBlock(const uint8_t* raw_data) {
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            data[i] = raw_data[i];
        }
    }
    
    // XOR operator for AddRoundKey
    AesBlock operator^(const AesBlock& other) const {
        AesBlock result;
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            result.data[i] = data[i] ^ other.data[i];
        }
        return result;
    }
    
    // Equality operator for testing
    bool operator==(const AesBlock& other) const {
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            if (data[i] != other.data[i]) {
                return false;
            }
        }
        return true;
    }
    
    // Print the block as a hex string
    std::string to_string() const {
        std::stringstream ss;
        for (int i = 0; i < AES_BLOCK_SIZE; i++) {
            ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(data[i]);
        }
        return ss.str();
    }
};

// Define a structure for AES key
struct AesKey {
    std::array<uint8_t, AES_KEY_SIZE> key;
    
    // Default constructor initializes to zero
    AesKey() {
        key.fill(0);
    }
    
    // Constructor from raw data
    AesKey(const uint8_t* raw_key) {
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            key[i] = raw_key[i];
        }
    }
    
    // Print the key as a hex string
    std::string to_string() const {
        std::stringstream ss;
        for (int i = 0; i < AES_KEY_SIZE; i++) {
            ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(key[i]);
        }
        return ss.str();
    }
};

// Define a structure for AES round keys
struct AesRoundKeys {
    std::array<AesBlock, AES_NUM_ROUNDS + 1> round_keys;
};

// Define a TLM payload extension for AES operations
class AesExtension : public tlm::tlm_extension<AesExtension> {
public:
    AesOperation operation;
    AesMode mode;
    AesKey key;
    
    AesExtension() : operation(AesOperation::ENCRYPT), mode(AesMode::NON_PIPELINED) {}
    
    virtual tlm::tlm_extension_base* clone() const override {
        AesExtension* ext = new AesExtension();
        ext->operation = this->operation;
        ext->mode = this->mode;
        ext->key = this->key;
        return ext;
    }
    
    virtual void copy_from(const tlm::tlm_extension_base& ext) override {
        const AesExtension& other = static_cast<const AesExtension&>(ext);
        this->operation = other.operation;
        this->mode = other.mode;
        this->key = other.key;
    }
};

#endif // AES_TYPES_H