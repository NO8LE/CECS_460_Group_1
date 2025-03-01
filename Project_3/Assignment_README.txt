Objective:

Develop a Verilog module that implements a Clock Domain Crossing (CDC) mechanism using an Asynchronous FIFO to interface 
a Memory Controller (BRAM access, 65 MHz) with a Master Module (90 MHz). 
The FIFO must ensure proper synchronization and data integrity when transferring read/write requests across these clock domains.

You must reuse the BRAM controller from the previous assignment, modifying it if necessary to interface with the FIFO.
Design Requirements

Module Implementation:

    Asynchronous FIFO Interface:
        Implement a dual-clock FIFO that bridges the 90 MHz Master Module and the 65 MHz Memory Controller.
        Synchronize FIFO pointers using Gray coding.
        Implement FIFO Full and Empty flags to prevent overflow/underflow.

    Master Module (90 MHz):
        Generates read/write requests and sends them to the FIFO.
        Reads responses from the FIFO.
        Implements proper handshake signals with FIFO.

    Memory Controller (65 MHz, Use Previous Design):
        Reads requests from the FIFO and performs BRAM access.
        Writes read data back to the FIFO for the Master Module to retrieve.
        Uses 8-bit BRAM, preloaded with a unique data pattern.

Simulation and Testbench:

    Verify Asynchronous FIFO Operation:
        Simulate write operations from the 90 MHz domain and read operations from the 65 MHz domain.
        Demonstrate proper FIFO pointer synchronization and flag operation.

    Test Read/Write Transactions Across CDC:
        Verify correct data integrity for read-after-write sequences.
        Handle interleaved read/write operations across clock domains.

    Waveform Analysis:
        Capture simulation waveforms to illustrate CDC behavior.

Documentation:

Submit a 2–3 page report including:

    Block Diagram showing FIFO, Master, and Memory Controller.
    Implementation Overview, focusing on CDC challenges.
    Simulation Results with waveform screenshots.
    Challenges & Lessons Learned.

Deliverables

Verilog Source Code (Master Module, Asynchronous FIFO, Modified Memory Controller) (Optional - GitHub Repository)
Testbench & Simulation Results
Report (PDF, 2–3 pages)
