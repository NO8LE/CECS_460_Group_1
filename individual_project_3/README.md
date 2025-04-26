# SystemC SoC Introduction

This project contains three SystemC modules.

## Project Overview

The project consists of three separate tasks, each demonstrating different SystemC process types and modeling techniques:

1. **Task 1: Parameterized ALU** - An arithmetic logic unit implemented using SC_METHOD
2. **Task 2: Fibonacci Generator** - A sequence generator implemented using SC_THREAD
3. **Task 3: Shift Register** - A clocked 4-bit SIPO register implemented using SC_CTHREAD

## Requirements

- SystemC Library (version 2.3.3 or later recommended)
- C++ Compiler with C++11 support (g++ or equivalent)

## SystemC Installation

For detailed instructions on installing and configuring SystemC on macOS, please refer to the included [SystemC Installation Guide](systemc_installation_guide.md). This guide provides step-by-step instructions for:

- Downloading and building SystemC from GitHub
- Setting up environment variables
- Configuring Visual Studio Code for SystemC development

> **Note for Apple Silicon (M1/M2/M3) Mac Users**: If you're using a Mac with Apple Silicon (arm64/aarch64), you must use CMake to build SystemC as the traditional configure script does not support this architecture. See the installation guide for detailed instructions specifically for Apple Silicon Macs.

## File Structure

- `task1_alu.cpp` - ALU implementation and test bench
- `task2_fibonacci.cpp` - Fibonacci sequence generator implementation
- `task3_shift_register.cpp` - Shift register implementation
- `README.md` - This documentation file

## Task Descriptions

### Task 1: Parameterized ALU Module using SC_METHOD

An ALU (Arithmetic Logic Unit) that performs operations based on a 2-bit control signal:
- Addition (opcode 00)
- Subtraction (opcode 01)
- Multiplication (opcode 10)
- Pass-through of operand A (opcode 11)

The module uses SC_METHOD process type and is sensitive to changes in inputs.

### Task 2: Fibonacci Sequence Generator using SC_THREAD

Generates the first 8 numbers of the Fibonacci sequence, outputting a new value every 3 nanoseconds using the SC_THREAD process type with wait() statements.

### Task 3: Clocked Shift Register using SC_CTHREAD

A 4-bit Serial-In Parallel-Out (SIPO) shift register that:
- Shifts in data on each positive clock edge
- Provides a 4-bit parallel output
- Resets when the reset signal is high
- Uses SC_CTHREAD process type

## Compilation and Execution

This project includes a Makefile that handles compilation for both Linux and macOS environments. To use it:

1. Ensure SystemC is installed and `SYSTEMC_HOME` is set to your SystemC installation directory
2. Run the following commands:

```bash
# Get system information and verify configuration
make system-info

# Build all tasks
make all

# Build a specific task
make task1_alu

# Run a specific task
make run_task1

# Clean up
make clean
```

The Makefile automatically detects your operating system (macOS/Linux) and configures the appropriate library paths and environment variables.

To run each executable:

```bash
./task1_alu
./task2_fibonacci
./task3_shift_register
```

## Expected Output

### Task 1: ALU
The ALU test bench will simulate all four operations with two sets of operands and display the results.

### Task 2: Fibonacci Generator
The Fibonacci generator will output the first 8 numbers of the sequence (0, 1, 1, 2, 3, 5, 8, 13) along with the simulation time at each step.

### Task 3: Shift Register
The shift register test bench will input a serial bit stream, demonstrate reset functionality, and display the parallel output at each clock cycle.

## VCD Waveform Files

Each task generates a VCD (Value Change Dump) file that can be viewed with waveform viewers like GTKWave:

- `alu_waveform.vcd` - For Task 1
- `fibonacci_waveform.vcd` - For Task 2
- `shift_register_waveform.vcd` - For Task 3

These files provide a visual representation of the signals over time, useful for debugging and understanding the behavior of the modules.
