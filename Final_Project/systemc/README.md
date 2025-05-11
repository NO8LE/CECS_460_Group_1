# AES FPGA SystemC Simulation

This directory contains a SystemC simulation of the AES-128 encryption/decryption engine using the Loosely Timed (LT) modeling style. The simulation focuses on high-level functional correctness rather than cycle-accurate timing.

## Overview

The simulation implements the AES-128 algorithm with the following components:

- **AES Top Module**: Coordinates the encryption/decryption process
- **Key Expansion Module**: Generates round keys from the initial key
- **AES Round Module**: Implements the core AES round operations
- **S-box Module**: Implements the SubBytes transformation
- **ShiftRows Module**: Implements the ShiftRows transformation
- **MixColumns Module**: Implements the MixColumns transformation

The implementation supports both pipelined and non-pipelined modes, allowing for performance comparison between the two approaches.

## Directory Structure

```
systemc/
├── include/              # Header files
│   ├── aes_types.h       # Common data types and structures
│   ├── aes_sbox.h        # S-box implementation
│   ├── aes_shift_rows.h  # ShiftRows implementation
│   ├── aes_mix_columns.h # MixColumns implementation
│   ├── aes_key_expansion.h # Key expansion implementation
│   ├── aes_round.h       # AES round implementation
│   └── aes_top.h         # Top-level controller
├── src/                  # Source files
│   └── aes_simulation.cpp # Main simulation file
├── test/                 # Test files
│   └── aes_testbench.cpp # Testbench for verification
├── Makefile              # Compilation instructions
└── README.md             # This file
```

## Requirements

- SystemC 2.3.3 or later
- C++17 compatible compiler (g++ or clang++)
- Make build system

## Building and Running

1. Make sure SystemC is installed on your system. If not, download it from [Accellera](https://www.accellera.org/downloads/standards/systemc) and follow the installation instructions.

2. Update the `SYSTEMC_HOME` variable in the Makefile to point to your SystemC installation directory.

3. Build the simulation:
   ```
   cd systemc
   make all
   ```

4. Run the simulation:
   ```
   make run_simulation
   ```

5. Run the testbench:
   ```
   make run_testbench
   ```

## Simulation Features

- **Functional Verification**: The simulation verifies the correctness of the AES implementation using NIST test vectors.
- **Performance Comparison**: The simulation demonstrates the performance difference between pipelined and non-pipelined modes.
- **Transformation Visualization**: The simulation shows the effect of each AES transformation on the data.

## Implementation Details

### Loosely Timed (LT) Modeling

This simulation uses the Loosely Timed (LT) modeling style, which focuses on functional correctness rather than cycle-accurate timing. The TLM-2.0 standard is used for communication between modules, with blocking transport interfaces.

### AES Algorithm

The AES-128 algorithm consists of the following steps:

1. **Key Expansion**: The initial 128-bit key is expanded into 11 round keys (including the initial key).
2. **Initial Round**: AddRoundKey operation only.
3. **Main Rounds (1-9)**: SubBytes, ShiftRows, MixColumns, and AddRoundKey operations.
4. **Final Round (10)**: SubBytes, ShiftRows, and AddRoundKey operations (no MixColumns).

### Pipelined vs. Non-Pipelined

- **Non-Pipelined Mode**: Each block is processed through all rounds sequentially before the next block is processed.
- **Pipelined Mode**: Multiple blocks are processed simultaneously, with each block in a different stage of the pipeline.

## Test Vectors

The simulation is verified using the following NIST test vectors:

1. Plaintext: `00112233445566778899aabbccddeeff`
   Key: `000102030405060708090a0b0c0d0e0f`
   Ciphertext: `69c4e0d86a7b0430d8cdb78070b4c55a`

2. Plaintext: `3243f6a8885a308d313198a2e0370734`
   Key: `2b7e151628aed2a6abf7158809cf4f3c`
   Ciphertext: `3925841d02dc09fbdc118597196a0b32`

## License

This simulation is provided for educational purposes only.