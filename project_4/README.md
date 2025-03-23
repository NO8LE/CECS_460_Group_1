# Pipelined vs. Non-Pipelined FIR Filter Implementation

This project implements and compares pipelined and non-pipelined versions of a 5-tap FIR filter on the Zybo Z7-10 FPGA.

## Project Structure

```
.
├── src/
│   ├── bram_memory.v         # Dual-port BRAM for storing input and output samples
│   ├── fir_non_pipelined.v   # Non-pipelined FIR filter implementation
│   ├── fir_pipelined.v       # 3-stage pipelined FIR filter implementation
│   └── fir_top.v             # Top-level module integrating both implementations
├── testbench/
│   ├── fir_tb.v              # Testbench for functional verification and performance comparison
│   └── fir_waveform_tb.v     # Testbench for generating waveforms and analyzing pipeline stages
├── constraints/
│   └── zybo_z7_constraints.xdc # FPGA pin constraints
└── README.md                 # This file
```

## FIR Filter Specifications

- **Filter Order**: 5 taps
- **Fixed Coefficients**: h[0]=1, h[1]=2, h[2]=3, h[3]=2, h[4]=1
- **Filter Equation**: y[n] = x[n]*h[0] + x[n−1]*h[1] + x[n−2]*h[2] + x[n−3]*h[3] + x[n−4]*h[4]
- **Data Format**: 8-bit signed integers
- **Input Signal Length**: 1024 samples
- **Memory**: BRAM for storing input and output samples

## Implementation Details

### Non-Pipelined Implementation

- Processes each sample completely before moving to the next
- Sequential multiply-accumulate operations
- Requires multiple clock cycles per sample
- State machine-based approach

### Pipelined Implementation

- 3-stage pipeline architecture:
  - Stage 1: Read sample & shift buffer
  - Stage 2: Parallel multiply-accumulate operations
  - Stage 3: Store result to BRAM
- Processes one sample per clock cycle once pipeline is full
- Multiple samples in different stages simultaneously

## Simulation and Verification

### Running the Testbenches

1. In your Xilinx Vivado environment, add all source files and testbenches to your project.
2. To run the main testbench:
   - Select `fir_tb.v` as the simulation source
   - Run simulation to verify functionality and compare performance
   - The testbench will report cycle counts and speedup factor

3. To analyze waveforms:
   - Select `fir_waveform_tb.v` as the simulation source
   - Run simulation and observe the waveforms to understand pipeline behavior
   - Key signals to observe:
     - Pipeline stages (state, registers in each stage)
     - Memory access patterns
     - Timing differences between implementations

### Expected Results

- Both implementations should produce identical filtered outputs
- The pipelined version should complete processing in fewer clock cycles
- Expected speedup: approximately 3-5x (depending on sample count)

## Resource Utilization

After synthesis, compare the resource usage for both implementations:

1. In Vivado, open the synthesized design
2. View the Utilization Report
3. Compare:
   - LUT usage
   - FF usage
   - DSP slice usage
   - BRAM usage

The pipelined implementation typically uses more logic resources (LUTs and FFs) but achieves better throughput.

## FPGA Implementation

To implement on the Zybo Z7-10:

1. Create a new Vivado project targeting the Zybo Z7-10 (xc7z010clg400-1)
2. Add all source files from the `src` directory
3. Add the constraints file from the `constraints` directory
4. Run synthesis, implementation, and generate bitstream
5. Program the FPGA using Vivado Hardware Manager

## Performance Measurement

The top module includes a cycle counter that measures processing time for each implementation. This counter starts when the `start` signal is asserted and stops when the `done` signal is asserted. The final count is available on the `cycle_count` output.

## Waveform Analysis

The waveform testbench exposes internal signals from both implementations, allowing for detailed analysis of:

- Pipeline fill and flush behavior
- Parallel operations in the pipelined implementation
- Memory access patterns
- State transitions

Look for key differences in timing and execution patterns between the two implementations.
