# Resource Sharing & BIST for Drone Flight Controller

This project implements a shared arithmetic resource design with Built-In Self-Test (BIST) for a lightweight autonomous drone flight controller. To save FPGA area, a single multiplier and adder are shared to compute altitude correction and battery life prediction in alternating clock cycles.

## Project Structure

```
Project_5/
├── src/                    # Source code
│   ├── datapath.v          # Shared datapath with multiplier and adder
│   ├── bist.v              # Built-In Self-Test module
│   ├── controller.v        # System controller
│   └── top_module.v        # Top-level system integration
├── testbench/              # Simulation testbenches
│   ├── datapath_tb.v       # Datapath testbench
│   ├── bist_tb.v           # BIST testbench
│   ├── controller_tb.v     # Controller testbench
│   └── top_module_tb.v     # System testbench
└── constraints/            # FPGA constraints
    └── zybo_z7_constraints.xdc # Zybo Z7 board constraints
```

## Implementation Details

### Shared Datapath
- Single 8-bit multiplier and 16-bit adder shared between two operations
- Two-stage pipelined architecture for efficient computation
- Operand multiplexing based on the active equation
- Supports signed 8-bit operations with 16-bit results

### Operations
1. Altitude Correction: A = (x₁ * k₁) + (x₂ * k₂), where k₁ = 3, k₂ = 5
2. Battery Estimation: B = (v * t) + c

### Control Flow
1. At reset, the BIST routine runs to validate the multiplier and adder
2. If BIST passes, the system waits for the start signal
3. In normal operation, the system alternates between altitude and battery calculations each clock cycle

### Built-In Self-Test
- Performs a sequence of known-answer tests at startup
- Tests both arithmetic operations with predetermined inputs and expected outputs
- Only allows normal operation after successful validation

## Hardware Target
- Xilinx Zynq xc7z010-1clg400c (Zybo-Z7 board)

## Usage

### Simulation
To simulate any of the modules:
1. Use your preferred Verilog simulator (e.g., ModelSim, Vivado Simulator)
2. Load the corresponding testbench file from the `testbench/` directory
3. Run the simulation

### Synthesis and Implementation
1. Create a new project in Xilinx Vivado
2. Add all files from the `src/` directory
3. Add the constraints file from the `constraints/` directory
4. Run synthesis, implementation, and generate bitstream
5. Program the Zybo-Z7 board

## I/O Description

### Inputs
- `clk`: System clock (125 MHz from Zybo board)
- `rst`: Reset signal (BTN0)
- `start`: Start normal operation (BTN1)
- `sel_pipelined`: Mode select (SW0) - Reserved for future use

### Outputs
- `done`: Indicates normal operation is active (LD0)
- `cycle_count[2:0]`: Debug counter visualization (LD1-LD3)
