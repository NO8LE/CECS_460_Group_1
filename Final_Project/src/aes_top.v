// AES Top-Level module
// Implements AES encryption/decryption with selectable pipelined/non-pipelined modes

module aes_top(
    input wire clk,               // System clock
    input wire rst,               // Reset signal
    input wire start,             // Start operation signal
    input wire sel_pipelined,     // Select pipelined (1) or non-pipelined (0) mode
    input wire [127:0] data_in,   // Input data block
    input wire [127:0] key,       // Input key
    input wire decrypt,           // 1 for decryption, 0 for encryption
    output reg done,              // Operation complete indicator
    output reg [2:0] cycle_count, // Debug output for cycle count visualization
    output reg [127:0] data_out   // Output data block
);
    // State machine states
    localparam IDLE = 2'd0;
    localparam INIT = 2'd1;
    localparam PROCESS = 2'd2;
    localparam DONE = 2'd3;
    
    // Registers for state machine and control
    reg [1:0] state, next_state;
    reg [3:0] round_counter;
    reg [7:0] full_cycle_counter;
    
    // Registers for data and key storage
    reg [127:0] state_reg;
    reg init_done;
    
    // Wires for round key expansion
    wire [127:0] round_keys [0:10];
    
    // Wires for round modules
    wire [127:0] round_out;
    wire [127:0] inv_round_out;
    wire [127:0] current_round_key;
    wire is_final_round;
    wire is_first_round;
    
    // Key expansion module instantiation
    key_expansion key_exp_inst (
        .clk(clk),
        .rst(rst),
        .key(key),
        .round_keys(round_keys)
    );
    
    // AES round module for encryption
    aes_round round_inst (
        .clk(clk),
        .rst(rst),
        .data_in(state_reg),
        .round_key(current_round_key),
        .is_final_round(is_final_round),
        .data_out(round_out)
    );
    
    // AES inverse round module for decryption
    aes_inv_round inv_round_inst (
        .clk(clk),
        .rst(rst),
        .data_in(state_reg),
        .round_key(current_round_key),
        .is_first_round(is_first_round),
        .data_out(inv_round_out)
    );
    
    // Control signals for round modules
    assign is_final_round = (round_counter == 4'd10);
    assign is_first_round = (round_counter == 4'd0);
    
    // Select the appropriate round key
    assign current_round_key = decrypt ? round_keys[10-round_counter] : round_keys[round_counter];
    
    // State machine for control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            round_counter <= 4'd0;
            full_cycle_counter <= 8'd0;
            state_reg <= 128'b0;
            done <= 1'b0;
            init_done <= 1'b0;
            cycle_count <= 3'b0;
            data_out <= 128'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= INIT;
                        round_counter <= 4'd0;
                        full_cycle_counter <= 8'd0;
                        done <= 1'b0;
                    end
                end
                
                INIT: begin
                    // Initial round: just AddRoundKey
                    if (decrypt) begin
                        // For decryption, start with the last round key
                        state_reg <= data_in ^ round_keys[10];
                    end else begin
                        // For encryption, start with the first round key
                        state_reg <= data_in ^ round_keys[0];
                    end
                    round_counter <= decrypt ? 4'd1 : 4'd1;  // Move to the first actual round
                    state <= PROCESS;
                    full_cycle_counter <= full_cycle_counter + 1;
                end
                
                PROCESS: begin
                    // Update state register with round output
                    state_reg <= decrypt ? inv_round_out : round_out;
                    
                    // Increment round counter and cycle counter
                    if (sel_pipelined || round_counter < 10) begin
                        round_counter <= round_counter + 1;
                        full_cycle_counter <= full_cycle_counter + 1;
                    end
                    
                    // Check if all rounds are complete
                    if ((decrypt && round_counter == 4'd10) || (!decrypt && round_counter == 4'd10)) begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    // Assign output data and set done flag
                    data_out <= state_reg;
                    done <= 1'b1;
                    state <= IDLE;
                    // Extract bits for cycle count debug LEDs
                    cycle_count <= full_cycle_counter[2:0];
                end
            endcase
        end
    end
    
    // Pipelined implementation logic
    // For pipelined mode, we would instantiate 10 rounds in sequence with registers in between
    // This implementation sketch would need to be expanded for full pipelining
    // Here we're just using the same round module iteratively, with cycle counting
    
    // Performance metrics
    // The cycle count will show the number of clock cycles taken to complete the operation
    // In non-pipelined mode, this should be approximately 10-12 cycles
    // In fully pipelined mode, the throughput would approach 1 block per cycle after filling the pipeline
    
endmodule
