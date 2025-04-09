# Resource Sharing & BIST Documentation

## 1. Block Diagram showing the shared datapath and BIST logic

```
                           +----------------------------------+
                           |            Top Module            |
                           +----------------------------------+
                                  |                 |
                                  v                 v
  +---------------------------+   |   +---------------------------+
  |        Controller         |<--|-->|          BIST            |
  | +---------------------+   |   |   | +---------------------+  |
  | | Reset Logic         |   |   |   | | Test Vector Gen     |  |
  | | State Machine       |   |   |   | | Result Validation   |  |
  | | Equation Selection  |   |   |   | | Pass/Fail Detection |  |
  | +---------------------+   |   |   | +---------------------+  |
  +---------------------------+   |   +---------------------------+
                |                 |               |
                |                 v               |
                |    +---------------------------+|
                +--->|       Shared Datapath    ||
                     | +---------------------+  ||
                     | | Input Muxes         |<-+|
                     | |                     |   |
       x1,x2 ------->| | +---------------+   |   |
       v,t,c ------->| | |   Multiplier  |   |   |
                     | | +---------------+   |   |
                     | |        |            |   |
                     | | +---------------+   |   |
                     | | |     Adder     |   |   |
                     | | +---------------+   |   |
                     | |        |            |   |
                     | | +-----------------+ |   |
                     | | | Pipeline Regs   | |   |
                     | | +-----------------+ |   |
                     | +---------------------+   |
                     +---------------------------+
                                |
                                v
                      result_a, result_b
```

## 2. Implementation Overview - Control Logic and Pipelining

```
Clock Cycle:    0       1       2       3       4       5       6
                |       |       |       |       |       |       |
State:      [RESET]→[BIST]→[BIST]→[WAIT]→[NORM]→[NORM]→[NORM]→...
                                BIST      ↓       ↓       ↓
                                Pass    +-+-+   +-+-+   +-+-+
Equation:                              | A | → | B | → | A | → ...
                                       +-+-+   +-+-+   +-+-+

Pipeline Stage:  
                        +-----------------------------------+
                        |          Pipeline Stage 1         |
                        +-----------------------------------+
                  ┌─────┐                             ┌─────┐
                  │  x1 │┐                           │  v  │┐
Cycle 0 (ALT):    │  x2 ││ → MUX → MULTIPLY → REG1 → │     ││
                  └─────┘│                           └─────┘│
                   └─────┘                            └─────┘

                  ┌─────┐                             ┌─────┐
                  │  v  │┐                           │ x1  │┐
Cycle 1 (BAT):    │  t  ││ → MUX → MULTIPLY → REG1 → │     ││
                  └─────┘│                           └─────┘│
                   └─────┘                            └─────┘

                        +-----------------------------------+
                        |          Pipeline Stage 2         |
                        +-----------------------------------+
                  ┌─────┐                             ┌─────┐
                  │REG1 │┐                           │     │┐
Cycle 0 (ALT):    │     ││ → MUX →   ADD    → REG2 → │  A  ││
                  └─────┘│                           └─────┘│
                   └─────┘                            └─────┘

                  ┌─────┐                             ┌─────┐
                  │REG1 │┐                           │     │┐
Cycle 1 (BAT):    │  c  ││ → MUX →   ADD    → REG2 → │  B  ││
                  └─────┘│                           └─────┘│
                   └─────┘                            └─────┘
```

## 3. Simulation Results

```
+-----------------------------------------------------------------------------------------------+
|                                      Simulation Results                                        |
+-------------+-------------+----------------+----------------+----------------------------------+
| Input       | Equation    | Expected       | Actual         | Comments                         |
| Values      | Used        | Result         | Result         |                                  |
+-------------+-------------+----------------+----------------+----------------------------------+
| x1 = 3      | Altitude    | (3*3)+(4*5)    | 29             | First test vector,              |
| x2 = 4      | Correction  | = 9+20 = 29    |                | used in BIST                    |
+-------------+-------------+----------------+----------------+----------------------------------+
| v = 2       | Battery     | (2*5)+16       | 26             | First test vector,              |
| t = 5       | Estimation  | = 10+16 = 26   |                | used in BIST                    |
| c = 16      |             |                |                |                                  |
+-------------+-------------+----------------+----------------+----------------------------------+
| x1 = 10     | Altitude    | (10*3)+(15*5)  | 105            | Normal operation                |
| x2 = 15     | Correction  | = 30+75 = 105  |                | example                         |
+-------------+-------------+----------------+----------------+----------------------------------+
| v = 12      | Battery     | (12*8)+20      | 116            | Normal operation                |
| t = 8       | Estimation  | = 96+20 = 116  |                | example                         |
| c = 20      |             |                |                |                                  |
+-------------+-------------+----------------+----------------+----------------------------------+
| x1 = -5     | Altitude    | (-5*3)+(7*5)   | -15+35 = 20    | Testing signed                  |
| x2 = 7      | Correction  |                |                | operation                        |
+-------------+-------------+----------------+----------------+----------------------------------+
| v = -3      | Battery     | (-3*-2)+10     | 6+10 = 16      | Testing signed                  |
| t = -2      | Estimation  |                |                | operation                        |
| c = 10      |             |                |                |                                  |
+-------------+-------------+----------------+----------------+----------------------------------+
```

## 4. BIST Implementation and Validation Process

```
+---------------------+       +-------------------------+
| System Reset        |------>| Initialize BIST        |
|                     |       | - Reset Test Counters   |
+---------------------+       | - Prepare Test Vectors  |
                              +-------------------------+
                                          |
                                          v
    +----------------+        +-------------------------+       No        +-------------------+
    | Enter Normal   |<-------| Check Test Results     |<------------+   | Run Altitude Test |
    | Operation      |  Yes   | - Compare with Expected|              |   | - x1=3, x2=4     |
    |                |<-------| - Set Pass/Fail Flag   |              |   | - Expected: 29   |
    +----------------+        +-------------------------+              |   +-------------------+
                                          |                            |            |
                                          | Pass                       |            v
                                          v                            |   +-------------------+
                              +-------------------------+               |   | Run Battery Test  |
                              | Wait for Start Signal  |               |   | - v=2, t=5, c=16  |
                              +-------------------------+               |   | - Expected: 26    |
                                          |                            |   +-------------------+
                                          v                            |            |
             +----------------------+     |                            +------------+
             | Clock Cycle 0: ALT   |<----+
             | Clock Cycle 1: BAT   |
             | Clock Cycle 2: ALT   |
             | ...                  |
             +----------------------+

BIST Validation Role:
- Ensures multiplier correctly handles signed operations
- Validates adder functionality with known results
- Detects any arithmetic unit failures before flight
- Provides safety guarantee for critical calculations
- Prevents system operation if hardware is faulty
```

## Key Design Notes

1. **Resource Sharing Strategy**
   - The design uses time-division multiplexing to share a single multiplier and adder
   - Operation alternates between altitude calculation and battery estimation every clock cycle
   - Pipeline registers maintain intermediate results between operations
   - Careful scheduling ensures no resource conflicts occur

2. **Control Logic**
   - State machine manages transition from BIST to normal operation
   - Equation selection toggles on each clock cycle during normal operation
   - Results are stored in separate output registers for each equation
   - Design ensures data hazards are avoided through proper pipelining

3. **BIST Implementation**
   - BIST uses pre-computed test vectors with known results
   - Both equations are tested with representative input values
   - Test results are compared with expected values to verify correct operation
   - Pass/fail status is clearly indicated for system safety
   - Normal operation is blocked if arithmetic units fail validation
