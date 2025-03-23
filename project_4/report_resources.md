# FIR Filter Implementation Report Resources

## ASCII Block Diagrams

### Non-Pipelined FIR Filter Architecture
```
                       +-------------------+
                       |                   |
Input               +->| Memory Read Logic |
Samples             |  |                   |
[x[n], x[n-1], ...] |  +-------------------+
                    |           |
                    |           v
                    |  +-------------------+
                    |  |    Coefficient    |
                    |  |   Multiplication  |<----+  Constants
                    |  |   (Sequential)    |     |  [h0, h1, h2, h3, h4]
                    |  +-------------------+     |
                    |           |                |
                    |           v                |
                    |  +-------------------+     |
                    |  |                   |     |
                    |  |    Accumulator    |     |
                    |  |                   |     |
                    |  +-------------------+     |
                    |           |                |
                    |           v                |
                    |  +-------------------+     |
                    |  |                   |     |
                    |  | Memory Write Logic|     |
                    |  |                   |     |
                    |  +-------------------+     |
                    |           |                |
Output              |           v                |
Samples             |                            |
[y[0], y[1], ...]   +----------------------------+
                     (Next sample only after 
                      completing current sample)
```

### Pipelined FIR Filter Architecture
```
                       +-------------------+
                       |                   |
Input               +->|     STAGE 1       |
Samples             |  |  Read & Shift     |<-+
[x[n], x[n-1], ...] |  |  Sample Buffer    |  |
                    |  +-------------------+  |
                    |           |             |
                    |           v             |
                    |  +-------------------+  |     Constants
                    |  |     STAGE 2       |  |     [h0, h1, h2, h3, h4]
                    |  |  Parallel MAC     |<-+--+
                    |  |  Operations       |  |  |
                    |  +-------------------+  |  |
                    |           |             |  |
                    |           v             |  |
                    |  +-------------------+  |  |
                    |  |     STAGE 3       |  |  |
                    |  |  Store Result     |  |  |
                    |  |  To Memory        |  |  |
                    |  +-------------------+  |  |
                    |           |             |  |
Output              |           v             |  |
Samples          +--+                         |  |
[y[0], y[1], ...]+---------------------------+  |
                    |                           |
                    +---------------------------+
                     (Next sample enters pipeline
                      before current one completes)
```

### Data Flow Comparison in Processing x[n]

#### Non-Pipelined (Sequential Processing):
```
Clock Cycle 1:  Read x[n]      → Multiply by h[0] → Accumulate
Clock Cycle 2:  Read x[n-1]    → Multiply by h[1] → Accumulate
Clock Cycle 3:  Read x[n-2]    → Multiply by h[2] → Accumulate
Clock Cycle 4:  Read x[n-3]    → Multiply by h[3] → Accumulate
Clock Cycle 5:  Read x[n-4]    → Multiply by h[4] → Accumulate
Clock Cycle 6:  Write y[n]
Clock Cycle 7:  Begin processing x[n+1]
```

#### Pipelined (Overlapped Processing):
```
Clock Cycle 1:  x[n] enters Stage 1   | x[n-1] in Stage 2  | x[n-2] in Stage 3
Clock Cycle 2:  x[n+1] enters Stage 1 | x[n] in Stage 2    | x[n-1] in Stage 3
Clock Cycle 3:  x[n+2] enters Stage 1 | x[n+1] in Stage 2  | x[n] in Stage 3 (y[n] output)
Clock Cycle 4:  x[n+3] enters Stage 1 | x[n+2] in Stage 2  | x[n+1] in Stage 3 (y[n+1] output)
```

## Implementation Overview: Pipelining vs. Non-Pipelining Challenges

### Non-Pipelined Implementation Challenges

1. **State Machine Complexity**  
   The non-pipelined design requires a complex state machine with multiple states to handle the sequential operations of reading input samples, performing multiplication with each coefficient, accumulating results, and writing output samples. This leads to a larger control unit with more complex timing.

2. **Resource Efficiency**  
   While the non-pipelined approach uses fewer resources overall, it must be carefully designed to ensure proper resource sharing. The accumulator, in particular, must be correctly managed across state transitions.

3. **Latency Considerations**  
   The sequential nature of processing means that the latency for processing each sample is relatively high. Each sample requires multiple clock cycles to complete, limiting throughput.

4. **Memory Access Patterns**  
   The non-pipelined implementation has more complex memory addressing logic as it needs to perform multiple sequential reads before a write. This creates a pattern of: read → compute → read → compute → ... → write, which can be harder to debug.

### Pipelined Implementation Challenges

1. **Pipeline Stage Balancing**  
   One of the most significant challenges was balancing the three pipeline stages for optimal performance. Each stage needs to complete within one clock cycle, so the operations must be distributed carefully. For our implementation:
   - Stage 1 handles sample reading and buffer shifting
   - Stage 2 performs all multiply-accumulate operations in parallel
   - Stage 3 handles result storage

2. **Pipeline Control Logic**  
   Managing the pipeline requires careful control logic to handle:
   - Pipeline filling (first few cycles where not all stages have valid data)
   - Steady-state operation (all stages processing different samples)
   - Pipeline flushing (final cycles where no new samples are available)

3. **Data Hazard Prevention**  
   Special care was needed to ensure that no data hazards occur between pipeline stages. Each stage must operate on the correct data, which requires proper buffering and register design.

4. **Resource Multiplication**  
   The pipelined approach requires dedicated hardware for each parallel operation, leading to higher resource usage:
   - 5 parallel multipliers (one for each tap)
   - Multiple pipeline registers to hold intermediate data
   - Parallel adder tree for final accumulation

5. **Timing Closure**  
   With more parallel logic, meeting timing constraints for the pipelined design can be more challenging, especially if the FIR filter becomes more complex (more taps or higher precision).

## Performance Comparison

### Processing Time

1. **Non-Pipelined FIR Filter**
   - For a 5-tap filter, processing each sample requires approximately 13 clock cycles:
     - 5 cycles for reading and multiplying each sample with its coefficient
     - 5 cycles for accumulation
     - 1 cycle for result writing
     - 2 cycles for control overhead
   - For 1024 samples, this results in approximately 13,312 clock cycles (13 * 1024)
   - Initial latency: 13 clock cycles for first result
   - Throughput: 1 sample per 13 clock cycles

2. **Pipelined FIR Filter**
   - After initial filling, the 3-stage pipeline processes 1 sample per clock cycle
   - For 1024 samples, this results in approximately 1,024 + 3 = 1,027 clock cycles
     - 3 cycles for pipeline filling
     - 1,024 cycles for processing samples (1 per cycle)
   - Initial latency: 3 clock cycles for first result
   - Throughput: 1 sample per clock cycle

3. **Expected Speedup**
   - Theoretical speedup: ~13x
   - Practical speedup: ~10-12x (accounting for real-world implementation factors)
   - For smaller sample counts, the speedup will be less dramatic due to pipeline filling/flushing overhead

### Resource Utilization

1. **Non-Pipelined FIR Filter**
   - **LUTs**: Moderate usage, primarily for the state machine control logic
   - **Flip-Flops**: Lower usage, only needed for control registers and accumulator
   - **DSP Slices**: 1-2 slices (can reuse a single multiplier sequentially)
   - **BRAM**: Shared with pipelined design for sample storage
   - **Expected Total Resources**: ~10-15% of available resources on the Zybo Z7-10

2. **Pipelined FIR Filter**
   - **LUTs**: Higher usage for parallel operations and pipeline control
   - **Flip-Flops**: Significantly higher due to pipeline registers in each stage
   - **DSP Slices**: 5 slices (one for each parallel multiplication)
   - **BRAM**: Shared with non-pipelined design for sample storage
   - **Expected Total Resources**: ~20-30% of available resources on the Zybo Z7-10

3. **Resource Tradeoffs**
   - The pipelined design offers ~10-13x performance improvement at the cost of ~2x resource usage
   - The DSP slice usage shows the most dramatic difference due to parallel vs. sequential multiplication
   - Critical resource on smaller FPGAs: DSP slices are typically limited, potentially making the pipelined design challenging to implement on the smallest devices

### Verification in Xilinx Vivado

When you run simulations in Vivado, you should look for the following key performance indicators:

1. **Clock Cycle Counts**
   - The testbench will report the exact number of clock cycles for both implementations
   - Verify the ratio is close to the expected ~10-13x speedup

2. **Resource Reports**
   - After synthesis, examine the resource utilization reports
   - Compare DSP slice usage (should be ~5x higher for pipelined)
   - Compare FF and LUT usage (should be ~2x higher for pipelined)

3. **Timing Analysis**
   - Check that both designs meet timing requirements (should achieve 125 MHz operation)
   - The pipelined design may have slightly tighter timing due to more complex parallel paths

4. **Waveform Validation**
   - Using the waveform testbench, verify:
     - Non-pipelined: sequential operation with one active sample
     - Pipelined: overlapped processing with multiple samples in different stages
     - Both: identical output results despite different processing methods
