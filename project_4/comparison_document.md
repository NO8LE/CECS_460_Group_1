# FIR Filter Implementation Comparison

This document highlights the key differences between non-pipelined and pipelined FIR filter implementations.

## Theoretical Performance Comparison

| Aspect | Non-Pipelined | Pipelined |
|--------|---------------|-----------|
| Throughput | 1 sample per ~13 clock cycles | 1 sample per clock cycle (after initial latency) |
| Latency | ~13 clock cycles | ~3 clock cycles |
| Resource Usage | Lower | Higher |
| Max Clock Frequency | Potentially higher | Potentially lower (but better overall throughput) |

## Implementation Differences

### Non-Pipelined
- **Processing Flow**: Sequential read-compute-write for each sample
- **State Machine**: Complex with ~13 states for a complete sample processing cycle
- **Resource Sharing**: Reuses same resources for all computations
- **Execution Pattern**: Process one tap calculation at a time

```
x[n] → h[0] → Accumulate
x[n-1] → h[1] → Accumulate
x[n-2] → h[2] → Accumulate
x[n-3] → h[3] → Accumulate
x[n-4] → h[4] → Accumulate → Store y[n]
```

### Pipelined
- **Processing Flow**: Parallel operations with 3 pipeline stages
- **State Machine**: Simpler with focus on pipeline control
- **Resource Multiplication**: Dedicated hardware for each calculation
- **Execution Pattern**: Multiple samples in different stages of processing

```
Stage 1: Load new x[n], shift buffer
         ↓
Stage 2: Parallel h[i]*x[n-i] calculations and accumulation
         ↓
Stage 3: Store result y[n]
```

## Expected Simulation Results

### Performance Metrics
- **Non-Pipelined**: ~13N clock cycles to process N samples
- **Pipelined**: ~(N+3) clock cycles to process N samples (pipeline fill + process + flush)
- **Speedup**: For large N, approaching 13x theoretical speedup

### Waveform Analysis
When analyzing waveforms, look for:

1. **Non-Pipelined**:
   - Sequential memory accesses
   - Sequential multiplication and accumulation
   - Single active sample at any time

2. **Pipelined**:
   - Multiple samples in different stages
   - Parallel multiplication operations
   - Continuous memory operations (read and write)
   - Pipeline fill and flush effects at start and end

## Resource Utilization Expectations

| Resource | Non-Pipelined | Pipelined | Explanation |
|----------|---------------|-----------|-------------|
| LUTs | Lower | Higher | Pipelined needs more combinational logic for parallel operations |
| Flip-Flops | Lower | Higher | Pipelined uses more registers for stage buffering |
| DSP Slices | 1-2 | 5 | Non-pipelined can reuse a single multiplier; pipelined needs 5 parallel multipliers |
| BRAM | Same | Same | Both use the same memory architecture |

## Design Tradeoffs

- **Non-Pipelined**
  - **Advantages**: Lower resource usage, simpler to implement for small filters
  - **Disadvantages**: Lower throughput, not scalable for high-performance applications

- **Pipelined**
  - **Advantages**: Higher throughput, scalable for processing streams of data
  - **Disadvantages**: Higher resource usage, slightly more complex design

## Conclusion

The choice between pipelined and non-pipelined implementation depends on:

1. **Application Requirements**:
   - High-throughput applications benefit from pipelined design
   - Resource-constrained applications might prefer non-pipelined design

2. **Resource Budget**:
   - Smaller FPGAs might need the resource efficiency of non-pipelined design
   - Larger FPGAs can take advantage of pipelined performance

3. **Development Time**:
   - Non-pipelined design can be simpler to implement and verify
   - Pipelined design requires more careful planning of data flow
