#include <systemc.h>

// Fibonacci Sequence Generator module
SC_MODULE(FibonacciGenerator) {
    // Output port
    sc_out<int> fib_out;
    
    // Process function
    void generate_sequence() {
        // Initialize first two Fibonacci numbers
        int a = 0, b = 1, c;
        
        // Output the first Fibonacci number (0)
        fib_out.write(a);
        cout << "Time: " << sc_time_stamp() << " Fibonacci: " << a << endl;
        wait(3, SC_NS);
        
        // Output the second Fibonacci number (1)
        fib_out.write(b);
        cout << "Time: " << sc_time_stamp() << " Fibonacci: " << b << endl;
        wait(3, SC_NS);
        
        // Generate the next 6 Fibonacci numbers
        for (int i = 2; i < 8; i++) {
            c = a + b;
            fib_out.write(c);
            cout << "Time: " << sc_time_stamp() << " Fibonacci: " << c << endl;
            a = b;
            b = c;
            
            // Wait for 3ns before generating the next number
            if (i < 7) {  // Don't wait after the last number
                wait(3, SC_NS);
            }
        }
    }
    
    // Constructor
    SC_CTOR(FibonacciGenerator) {
        // Register the thread process
        SC_THREAD(generate_sequence);
    }
};

// Main function
int sc_main(int argc, char* argv[]) {
    // Create signal
    sc_signal<int> fib_sig;
    
    // Instantiate Fibonacci generator
    FibonacciGenerator fib_gen("fib_generator");
    
    // Connect signal to port
    fib_gen.fib_out(fib_sig);
    
    // Create trace file for waveform
    sc_trace_file* tf = sc_create_vcd_trace_file("fibonacci_waveform");
    sc_trace(tf, fib_sig, "fibonacci");
    
    // Run simulation
    cout << "\n----- Fibonacci Sequence Generator -----\n";
    
    // Start simulation with enough time to generate all 8 numbers
    // 7 transitions with 3ns delay each = 21ns total
    sc_start(22, SC_NS);
    
    // End simulation
    sc_close_vcd_trace_file(tf);
    
    return 0;
}
