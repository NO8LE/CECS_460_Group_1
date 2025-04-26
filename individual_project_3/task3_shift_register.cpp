#include <systemc.h>

// 4-bit Serial-In Parallel-Out (SIPO) Shift Register
SC_MODULE(ShiftRegister) {
    // Input and output ports
    sc_in<bool> clk;           // Clock input
    sc_in<bool> reset;         // Reset input
    sc_in<bool> serial_in;     // Serial input bit
    sc_out<sc_uint<4>> parallel_out;  // 4-bit parallel output
    
    // Internal register to hold the 4 bits
    sc_uint<4> reg_value;
    
    // Process function
    void shift_process() {
        // Initialize register value
        reg_value = 0;
        
        // Main processing loop
        while (true) {
            // Wait for the positive edge of the clock
            wait();
            
            // Check for reset
            if (reset.read()) {
                // Clear the register if reset is high
                reg_value = 0;
            } else {
                // Shift bits left (MSB first)
                reg_value = (reg_value << 1) | serial_in.read();
            }
            
            // Update the output
            parallel_out.write(reg_value);
        }
    }
    
    // Constructor
    SC_CTOR(ShiftRegister) {
        // Register the clocked thread process
        SC_CTHREAD(shift_process, clk.pos());
        // Specify reset behavior
        reset_signal_is(reset, true);  // true indicates active high reset
    }
};

// Main function
int sc_main(int argc, char* argv[]) {
    // Create signals
    sc_clock clock("clock", 5, SC_NS);  // 5ns period clock
    sc_signal<bool> reset_sig, serial_in_sig;
    sc_signal<sc_uint<4>> parallel_out_sig;
    
    // Instantiate shift register
    ShiftRegister shift_reg("shift_register");
    
    // Connect signals to ports
    shift_reg.clk(clock);
    shift_reg.reset(reset_sig);
    shift_reg.serial_in(serial_in_sig);
    shift_reg.parallel_out(parallel_out_sig);
    
    // Create trace file for waveform
    sc_trace_file* tf = sc_create_vcd_trace_file("shift_register_waveform");
    sc_trace(tf, clock, "clock");
    sc_trace(tf, reset_sig, "reset");
    sc_trace(tf, serial_in_sig, "serial_in");
    sc_trace(tf, parallel_out_sig, "parallel_out");
    
    // Initialize signals
    reset_sig.write(false);
    serial_in_sig.write(false);
    
    // Run simulation
    cout << "\n----- 4-bit SIPO Shift Register -----\n";
    cout << "Time: " << sc_time_stamp() << " Register: " << parallel_out_sig.read() << endl;
    
    // Apply serial bit stream: 1, 0, 1, 1, 0, 1
    
    // Bit 1
    serial_in_sig.write(1);
    sc_start(5, SC_NS);  // One clock cycle
    cout << "Time: " << sc_time_stamp() << " Input: 1, Register: " << parallel_out_sig.read() << endl;
    
    // Bit 2
    serial_in_sig.write(0);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " Input: 0, Register: " << parallel_out_sig.read() << endl;
    
    // Bit 3
    serial_in_sig.write(1);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " Input: 1, Register: " << parallel_out_sig.read() << endl;
    
    // Assert reset at 15 ns
    reset_sig.write(true);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " RESET, Register: " << parallel_out_sig.read() << endl;
    
    // De-assert reset
    reset_sig.write(false);
    
    // Continue bit stream
    // Bit 4
    serial_in_sig.write(1);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " Input: 1, Register: " << parallel_out_sig.read() << endl;
    
    // Bit 5
    serial_in_sig.write(0);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " Input: 0, Register: " << parallel_out_sig.read() << endl;
    
    // Bit 6
    serial_in_sig.write(1);
    sc_start(5, SC_NS);
    cout << "Time: " << sc_time_stamp() << " Input: 1, Register: " << parallel_out_sig.read() << endl;
    
    // End simulation
    sc_close_vcd_trace_file(tf);
    
    return 0;
}
