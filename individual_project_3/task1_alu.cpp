#include <systemc.h>

// ALU module definition
SC_MODULE(ALU) {
    // Input and output ports
    sc_in<int> a, b;                // Operands
    sc_in<sc_uint<2>> opcode;       // Control signal
    sc_out<int> result;             // Result output
    
    // Process function
    void compute() {
        // Perform operation based on opcode
        switch (opcode.read()) {
            case 0:  // 00 -> Addition
                result.write(a.read() + b.read());
                break;
            case 1:  // 01 -> Subtraction
                result.write(a.read() - b.read());
                break;
            case 2:  // 10 -> Multiplication
                result.write(a.read() * b.read());
                break;
            case 3:  // 11 -> Pass-through a
                result.write(a.read());
                break;
            default:
                result.write(0);
                break;
        }
    }
    
    // Constructor
    SC_CTOR(ALU) {
        // Register compute method and make it sensitive to all inputs
        SC_METHOD(compute);
        sensitive << a << b << opcode;
    }
};

// Main function
int sc_main(int argc, char* argv[]) {
    // Create signals
    sc_signal<int> a_sig, b_sig, result_sig;
    sc_signal<sc_uint<2>> opcode_sig;
    
    // Instantiate ALU
    ALU alu("alu_instance");
    
    // Connect signals to ports
    alu.a(a_sig);
    alu.b(b_sig);
    alu.opcode(opcode_sig);
    alu.result(result_sig);
    
    // Create trace file for waveform
    sc_trace_file* tf = sc_create_vcd_trace_file("alu_waveform");
    sc_trace(tf, a_sig, "a");
    sc_trace(tf, b_sig, "b");
    sc_trace(tf, opcode_sig, "opcode");
    sc_trace(tf, result_sig, "result");
    
    // Initialize the simulation
    sc_start(0, SC_NS);
    
    // Test all operations
    cout << "\n----- ALU Operations Test -----\n";
    
    // Set initial values
    a_sig.write(10);
    b_sig.write(5);
    
    // Test Addition (opcode = 00)
    opcode_sig.write(0);
    sc_start(1, SC_NS);
    cout << "Addition (10 + 5): " << result_sig.read() << endl;
    
    // Test Subtraction (opcode = 01)
    opcode_sig.write(1);
    sc_start(1, SC_NS);
    cout << "Subtraction (10 - 5): " << result_sig.read() << endl;
    
    // Test Multiplication (opcode = 10)
    opcode_sig.write(2);
    sc_start(1, SC_NS);
    cout << "Multiplication (10 * 5): " << result_sig.read() << endl;
    
    // Test Pass-through (opcode = 11)
    opcode_sig.write(3);
    sc_start(1, SC_NS);
    cout << "Pass-through (a = 10): " << result_sig.read() << endl;
    
    // Change values and test again
    a_sig.write(20);
    b_sig.write(7);
    
    // Test Addition (opcode = 00)
    opcode_sig.write(0);
    sc_start(1, SC_NS);
    cout << "Addition (20 + 7): " << result_sig.read() << endl;
    
    // Test Subtraction (opcode = 01)
    opcode_sig.write(1);
    sc_start(1, SC_NS);
    cout << "Subtraction (20 - 7): " << result_sig.read() << endl;
    
    // Test Multiplication (opcode = 10)
    opcode_sig.write(2);
    sc_start(1, SC_NS);
    cout << "Multiplication (20 * 7): " << result_sig.read() << endl;
    
    // Test Pass-through (opcode = 11)
    opcode_sig.write(3);
    sc_start(1, SC_NS);
    cout << "Pass-through (a = 20): " << result_sig.read() << endl;
    
    // End simulation
    sc_close_vcd_trace_file(tf);
    
    return 0;
}
