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
2. **Important: Set Simulation Runtime to 40000ns**
   - The default 1000ns runtime is **insufficient** to complete the FIR operations
   - With the default setting, variables like 'done', 'cycle_count', 'non_pipelined_cycles', 'pipelined_cycles', and 'speedup' will show as 0 or X
   - To set the runtime to 40000ns:
     * **Method 1**: Before launching simulation, go to "Settings → Simulation → Simulation" and set "xsim.simulate.runtime" to "40000ns"
     * **Method 2**: After launching simulation, enter "run 40000ns" in the Tcl Console
     * **Method 3**: Edit the fir_tb.tcl file and change "run 1000ns" to "run 40000ns"

3. To run the main testbench:
   - Select `fir_tb.v` as the simulation source
   - Run simulation to verify functionality and compare performance
   - The testbench will report cycle counts and speedup factor
   - If you don't see results in the console, check if the simulation ran long enough (40000ns is recommended)

4. To analyze waveforms:
   - Select `fir_waveform_tb.v` as the simulation source
   - Run simulation with 40000ns runtime
   - Observe the waveforms to understand pipeline behavior
   - Key signals to observe:
     - Pipeline stages (state, registers in each stage)
     - Memory access patterns
     - Timing differences between implementations
     - Cycle counter values and done signals

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

The top module includes a cycle counter that measures processing time for each implementation. This counter starts when the `start` signal is asserted and stops when the `done` signal is asserted. The final count is available on the `cycle_count` output. Note that only 3 bits of the internal 32-bit counter are connected to FPGA outputs to conserve I/O pins.

## Troubleshooting and Implementation Notes

### BRAM Inference

For proper Block RAM (BRAM) inference in Vivado synthesis:

1. The memory module uses Xilinx-specific attributes:
   ```verilog
   (* ram_style = "block" *) reg [7:0] mem [0:1023];
   ```

2. Registered read pattern is implemented, which is required for Xilinx BRAM inference:
   - Address signals are registered
   - Read operations use the registered address
   - This ensures proper hardware implementation

### Simulation Library Configuration

To resolve "[Vivado 12-13277] Compiled library path does not exist" warnings:

1. Use Vivado's built-in simulation library compilation:
   - In Vivado, go to Tools → Compile Simulation Libraries
   - Select your simulator (e.g., XSim)
   - Choose a directory for the compiled libraries
   - Click OK to start the compilation process

2. Configure your project to use these libraries:
   - Go to Project Settings → Simulation
   - Set the "Compiled Library Location" to your compiled library path

This is a one-time setup that creates proper simulation libraries for your environment.

### Memory Initialization in Testbenches

The testbenches include special handling for memory initialization:

1. A three-cycle approach accounts for registered reads in the BRAM:
   - First cycle: Set up address and data signals
   - Second cycle: Write data and register address
   - Third cycle: Ensure proper read completion

2. Custom signal forcing is used to initialize the BRAM memory in the DUT through the top-level interface signals:
   ```verilog
   force dut.mem_addr_a = addr_a;
   force dut.mem_we_b = we_a;
   force dut.mem_data_in_b = data_in_a;
   ```

## Waveform Analysis

The waveform testbench exposes internal signals from both implementations, allowing for detailed analysis of:

- Pipeline fill and flush behavior
- Parallel operations in the pipelined implementation
- Memory access patterns
- State transitions

Look for key differences in timing and execution patterns between the two implementations.
